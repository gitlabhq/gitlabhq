# The orchestration engine: main(), and the register() machinery deploy driver
# fragments plug into. Gitlab::Cd::Driver::Orchestration.assemble combines this with
# each driver's fragment into the single program kas runs.

load("module:gitlab-function", gitlab_function_run = "run")
load("module:gitlab", "call_api", "post_value")
load("module:policy", "evaluate", "ALLOW", "DENY", "REQUIRE_APPROVAL")

# Bound unwrapped rather than behind a gl_run-style wrapper: get_object is a derived
# action, so a caller gathers it, and a poll can drive it.
load("module:kubernetes?file=object.star", "get_object")

def gl_run(function, inputs):
    return gather(gitlab_function_run(function = function, inputs = inputs))

def _require(kwargs, name):
    if name not in kwargs:
        fail("missing required kwarg: %s" % name)
    return kwargs[name]

# Step type to the spec register() filed for it: everything the engine knows about a step
# type is a key of that one record.
_STEPS = {}

# Handled in the walk rather than through _STEPS; reserved so a driver cannot register
# a handler that would never be called.
_STAGE_TYPE = "com.gitlab.cd.steps.stage"

# Handled in the walk like _STAGE_TYPE: an author's approval parks regardless of governance,
# which a driver's own handler has no way to do.
_APPROVAL_TYPE = "com.gitlab.cd.steps.approval"

# The one topic the rollouts API accepts. Every report the engine makes is a
# deployment progress report, so it is a constant rather than a parameter.
_TOPIC = "com.gitlab.cd.deployment"

# The status the rollouts API answers a send with. Anything else is a send that did not land.
_ACCEPTED = 202

# Where this run reports, the header both senders carry, and whether it reports anywhere at
# all. Reporting nowhere is not an error, the flow still deploys: Rails passes a token but
# not yet an id, and a guessed id draws a 401 no different from a bad token.
def _destination(kwargs):
    callback_token = kwargs.get("callback_token")
    rollout_id = kwargs.get("rollout_id")
    if callback_token == None or rollout_id == None:
        return None, {}, False

    # The endpoint reads the token from a "Bearer "-prefixed header and answers 401 without
    # the prefix. Built with + rather than %s: Starlark refuses to add a sensitive_string to
    # a string, so a non-plain token fails here.
    return (
        "/api/v4/rollouts/%s" % rollout_id,
        {"Authorization": "Bearer " + callback_token},
        True,
    )

# A send that did not land, described, or None. Both senders answer a non-2xx as an ordinary
# status and a transport failure as the fourth element of their tuple, so neither arrives as
# a raised error.
def _problem(what, status, body, error):
    if error != None:
        return "%s: %s" % (what, error)
    if status != _ACCEPTED:
        return "%s: rollouts API returned %d: %s" % (what, status, body)
    return None

# Builds this run's emit(event_type, data). A closure over the destination rather than a
# value the walk carries, because Starlark freezes globals so a per-run value cannot be
# stashed in one.
def _build_emitter(kwargs):
    path, headers, reporting = _destination(kwargs)
    if not reporting:
        print("deploy progress will not be reported: main() needs both a callback_token and a rollout_id kwarg")

        def emit_nowhere(event_type, data, or_fail = True):
            return None

        return emit_nowhere

    headers = dict(headers)
    headers["Content-Type"] = "application/json"

    # A lost report fails the flow, because a consumer that never sees the event holds a
    # wrong view of the deploy. or_fail = False hands the problem back instead, which is
    # what lets _emit_step_failed report a step's failure without masking the step's own.
    def emit(event_type, data, or_fail = True):
        # An activity that is never awaited is discarded rather than run, so the future
        # is gathered even though the response body carries nothing worth reading.
        status, _headers, body, error = gather(call_api(
            "POST",
            path,
            headers = headers,
            body = json.encode({"topic": _TOPIC, "type": event_type, "data": data}),
        ))

        problem = _problem("reporting %s" % event_type, status, body, error)
        if problem != None and or_fail:
            fail(problem)
        return problem

    return emit

# What a step handler returns to report a failure it can describe; None means success.
def failure(reason, message):
    return {"reason": reason, "message": message}

# Reporting a failure does not end the run — main() does, by returning. The print keeps the
# failure in a kas log of a flow that reports nowhere, or whose report is itself what
# failed, and names the reason because a message does not say who it came from.
def _emit_step_failed(emit, data, f):
    print("step failed: %s: %s" % (f["reason"], f["message"]))
    _report_failure(emit, "com.gitlab.cd.step_failed", dict(data, reason = f["reason"], error = f["message"]))

# Every report on the failure path, and the only ones sent with or_fail = False: raising
# here would turn a failure the driver had described back into the uncatchable abort that
# reporting it exists to replace.
def _report_failure(emit, event_type, data):
    problem = emit(event_type, data, or_fail = False)
    if problem != None:
        print(problem)

# The walk a step handler deploys its services through: it names them, the engine brackets
# each one, so the pairing is this loop rather than a rule a handler has to keep. A name is
# all the engine takes, which leaves a step's services a field only the driver reads.
def _service_reporter(emit, data):
    # The first failure ends the walk: the services behind it would deploy against a version
    # set the flow has already stopped trusting.
    def report(services, deploy_one):
        for service in services:
            emit("com.gitlab.cd.service_started", dict(data, service = service))
            f = deploy_one(service)
            if f != None:
                _report_failure(emit, "com.gitlab.cd.service_failed", dict(
                    data,
                    service = service,
                    reason = f["reason"],
                    error = f["message"],
                ))
                return f
            emit("com.gitlab.cd.service_succeeded", dict(data, service = service))
        return None

    return report

# Builds this run's ask(request, boundary), which announces the request on a channel it mints
# and parks until a person answers, then answers (the actor, that actor as prose for a
# message, failure), and unavailable(boundary), its opening refusal.
def _build_asker(kwargs, hitl):
    path, headers, reporting = _destination(kwargs)

    # Two rendered scalars, or nothing: an actor reaches a policy through json.encode and a
    # person through a report's error, so a structured one could abort a run or overrun the
    # field. An id arriving as a number is still an id, and dropping it anonymizes the approver.
    def named(actor):
        if type(actor) != "dict":
            return None

        name = actor.get("name")
        id = actor.get("id")
        if type(name) not in ("string", "int") or type(id) not in ("string", "int"):
            return None
        return {"name": "%s" % name, "id": "%s" % id}

    def prose(actor):
        if actor == None:
            return "an actor the decision did not name"
        return "%s (%s)" % (actor["name"], actor["id"])

    def unavailable(boundary):
        if not hitl:
            return failure(
                "com.gitlab.cd.reason.approval_unavailable",
                "%s needs an approval, and the hitl feature flag is off" % boundary,
            )

        if not reporting:
            return failure(
                "com.gitlab.cd.reason.approval_unavailable",
                "%s needs an approval, and a run that reports nowhere cannot ask for one" % boundary,
            )

        return None

    def ask(request, boundary):
        f = unavailable(boundary)
        if f != None:
            return None, None, f

        # Minted per park: one channel shared across the walk would hand a decision that
        # arrived late for an earlier step to the next park, which would refuse it.
        reply = channel()

        print("awaiting approval for %s" % boundary)
        status, _headers, body, error = gather(post_value(path, value = {
            "topic": _TOPIC,
            "type": "com.gitlab.cd.approval_requested",
            "data": dict(request, reply = reply),
        }, headers = headers))

        # Refused rather than failed: a park that went ahead after a lost request would wait
        # for a Rails that was never told, and fail() is the uncatchable abort that reporting
        # a failure exists to replace.
        problem = _problem("requesting an approval for %s" % boundary, status, body, error)
        if problem != None:
            return None, None, failure("com.gitlab.cd.reason.approval_unavailable", problem)

        answer = gather(reply)

        # %s and %r rather than json.encode() on everything read off the channel: encoding a
        # value the engine did not build can raise, which would abort the run, not refuse it.
        if type(answer) != "dict":
            return None, None, failure(
                "com.gitlab.cd.reason.approval_invalid",
                "%s was answered with %s, not a decision" % (boundary, type(answer)),
            )

        # A channel carries whatever has been sent to it, so a decision names the request it
        # answers. Refusing a decision about another one is what stops an approval granted for
        # one step from satisfying the next.
        if answer.get("position") != request["position"]:
            return None, None, failure(
                "com.gitlab.cd.reason.approval_invalid",
                "%s was answered by a decision about position %s" % (boundary, answer.get("position")),
            )

        actor = named(answer.get("actor"))
        result = answer.get("result")
        if result == "approve":
            return actor, prose(actor), None
        if result == "reject":
            return None, None, failure(
                "com.gitlab.cd.reason.approval_denied",
                "%s was refused by %s" % (boundary, prose(actor)),
            )
        return None, None, failure(
            "com.gitlab.cd.reason.approval_invalid",
            "%s was answered with result %r, not approve or reject" % (boundary, result),
        )

    return ask, unavailable

# The flags a caller turns a gate on with. A flag the engine does not read is ignored; one it
# does read has to be a bool, because Starlark truthiness reads a "false" passed as a string
# as on, so a caller who meant off would get gated.
_FLAGS = ["hitl", "governance"]

def _feature_flags(kwargs):
    flags = kwargs.get("feature_flags")
    if flags == None:
        return {}, None

    if type(flags) != "dict":
        return None, failure(
            "com.gitlab.cd.reason.feature_flags_invalid",
            "feature_flags is %s, not an object of flag name to true or false" % type(flags),
        )

    for name in _FLAGS:
        if name in flags and type(flags[name]) != "bool":
            return None, failure(
                "com.gitlab.cd.reason.feature_flags_invalid",
                "feature_flags.%s is %s, not true or false" % (name, type(flags[name])),
            )
    return flags, None

# Builds this run's gate(trigger, resource, data), answering None or the failure() the caller
# reports against the boundary. data is the boundary's own report payload; see _build_emitter
# for the closure.
def _build_gate(flags, rollout, ledger, ask):
    # ledger is read on each call, not captured now: it is the list main() appends to.
    if not flags.get("governance", False):
        def gate_nothing(trigger, resource, data):
            return None

        return gate_nothing, None

    # Reporting degrades to reporting nowhere; enforcement does not.
    if rollout == None:
        return None, failure(
            "com.gitlab.cd.reason.governance_unnameable",
            "governance needs both an organization_id and a rollout_id to name what it gates",
        )

    def gate(trigger, resource, data):
        context = {"ledger": ledger}

        # A stage's name is what a rule matches as a tier, and the boundary's report already
        # carries it, so the two cannot disagree.
        tier = data.get("stage_name")
        if tier != None:
            context["environment"] = {"tier": tier}

        def decide(context):
            return gather(evaluate(
                trigger = trigger,
                resource = resource,
                context = json.encode(context),
            ))

        def boundary_of(decision):
            return "%s at %s (decision %s)" % (trigger, resource, decision.get("decision_id"))

        # None on an allow, otherwise the failure to report against the boundary. after names the
        # approval a refusal overrode, which the decision being refused carries no id for.
        def refusal(decision, after = None):
            verdict = decision.get("verdict")
            if verdict == ALLOW:
                return None

            about = boundary_of(decision)
            tail = ""
            if after != None:
                tail = ", after %s" % after

            if verdict == DENY:
                return failure("com.gitlab.cd.reason.policy_denied", "policy refused %s%s" % (about, tail))
            if verdict == REQUIRE_APPROVAL:
                return failure(
                    "com.gitlab.cd.reason.policy_requires_approval",
                    "policy requires a further approval for %s, which the engine does not ask for%s" %
                    (about, tail),
                )
            return failure(
                "com.gitlab.cd.reason.policy_verdict_unknown",
                "policy answered %s with an unknown verdict %s%s" % (about, verdict, tail),
            )

        decision = decide(context)
        if decision.get("verdict") != REQUIRE_APPROVAL:
            return refusal(decision)

        boundary = boundary_of(decision)
        decision_id = "%s" % decision.get("decision_id")
        actor, who, f = ask(dict(
            data,
            resource = resource,
            decision_id = decision_id,
            reason = "policy requires approval for %s" % boundary,
        ), boundary)
        if f != None:
            return f

        # An approval is not the verdict. The policy decides again, told which decision it is
        # resuming and who approved it, so nothing but an allow lets the boundary through.
        context["approval"] = {"decision_id": decision_id, "actor": actor}
        return refusal(decide(context), "%s approved %s" % (who, boundary))

    return gate, None

_ACTION_TRIGGERS = {"com.gitlab.cd.action.promote": "com.gitlab.cd.deployment_promoted"}

# What a step type's spec holds, exactly one of run and build:
#   run(step, environment, services, version_set, report) handles a step, returning None or a
#     failure() the engine reports against it. report(services, deploy_one) calls
#     deploy_one(service) inside a service_started/succeeded pair, and a failure it returns
#     ends the walk and is reported as service_failed — see _service_reporter.
#   build(steps) returns the handlers for the types registered against it, as (dict of step
#     type to handler, failure). A handler it makes takes run's arguments and can hold a value
#     spanning steps, which a load-time one cannot: globals freeze once the program has
#     loaded, captures included.
#   validate(steps) is called before the flow runs any step, returning None or a failure().
#   action declares what a step of this type is to governance, from _ACTION_TRIGGERS, and
#     its absence is the signal: a step type with no action is never gated.
# build and validate are each called once, handed every step whose type registered that same
# function, in flow order, each entry carrying that step's own environment, services and
# version_set; a failure from either is reported against the first step it owns.
def register(step_type, *, run = None, build = None, validate = None, action = None):
    if step_type in (_STAGE_TYPE, _APPROVAL_TYPE):
        fail("step type is reserved by the orchestration engine: %s" % step_type)
    if step_type in _STEPS:
        fail("step type already registered: %s" % step_type)
    if (run == None) == (build == None):
        fail("step type %s needs exactly one of run and build" % step_type)
    if action != None and action not in _ACTION_TRIGGERS:
        fail("unknown step action %s: expected one of %s" % (action, ", ".join(_ACTION_TRIGGERS.keys())))
    _STEPS[step_type] = {"run": run, "build": build, "validate": validate, "action": action}

_WAIT_TYPE = "com.gitlab.cd.steps.wait"

def _wait(step, environment, services, version_set, report):
    sleep(step["seconds"] * time.second)

register(_WAIT_TYPE, run = _wait)

# One step's own shape, for both a top-level step and a step inside a stage. at is the step's
# path in the document, which is what names the field a message blames.
def _check_step_shape(step, at):
    if type(step) != "dict":
        return failure(
            "com.gitlab.cd.reason.flow_definition_invalid",
            "%s is %s, not a step object" % (at, type(step)),
        )
    if "type" not in step:
        return failure(
            "com.gitlab.cd.reason.flow_definition_invalid",
            "%s has no type naming what it does" % at,
        )
    if type(step["type"]) != "string":
        return failure(
            "com.gitlab.cd.reason.flow_definition_invalid",
            "%s has a type of %s, not a string naming what it does" % (at, type(step["type"])),
        )

    # The engine owns the wait step, so its shape is checked here rather than in _wait: a
    # non-int would otherwise multiply against a duration and abort mid-walk.
    if step["type"] == _WAIT_TYPE:
        if "seconds" not in step:
            return failure(
                "com.gitlab.cd.reason.flow_definition_invalid",
                "%s is a wait step with no seconds to wait for" % at,
            )
        if type(step["seconds"]) != "int":
            return failure(
                "com.gitlab.cd.reason.flow_definition_invalid",
                "%s has seconds of %s, not a whole number of seconds" % (at, type(step["seconds"])),
            )

    # Reported verbatim, and a report the rollouts API refuses raises out of the send rather
    # than failing the step, so a reason it would reject is refused here instead.
    if step["type"] == _APPROVAL_TYPE and "reason" in step and type(step["reason"]) != "string":
        return failure(
            "com.gitlab.cd.reason.flow_definition_invalid",
            "%s has a reason of %s, not a string saying why an approval is needed" %
            (at, type(step["reason"])),
        )
    return None

# A shape failure's data, with step_type filled in when _check_step_shape had already
# confirmed it before failing further in (the wait-step checks) rather than on it.
def _shape_failure_data(position, step):
    data = {"position": position}
    if type(step) == "dict" and type(step.get("type")) == "string":
        data["step_type"] = step["type"]
    return data

# The document's shape, checked before _plan indexes into it. Rails validates the schema
# first, so this catches a flow that reached kas another way — without it a missing field
# surfaces as a Starlark key error, which aborts the run instead of reporting against a step.
def _check_flow_document(flow_definition, environments):
    # A refusal of the document itself belongs to no step; see the identity refusal in main()
    # for the empty position.
    if type(flow_definition) != "dict":
        return {"position": []}, failure(
            "com.gitlab.cd.reason.flow_definition_invalid",
            "flow_definition is %s, not an object" % type(flow_definition),
        )
    if type(environments) != "dict":
        return {"position": []}, failure(
            "com.gitlab.cd.reason.environments_invalid",
            "environments is %s, not an object keyed by environment id" % type(environments),
        )

    # Absent is legal — a flow of only common steps declares none — but present and
    # misshapen is not.
    if type(flow_definition.get("environments", {})) != "dict":
        return {"position": []}, failure(
            "com.gitlab.cd.reason.environments_invalid",
            "flow_definition.environments is %s, not an object keyed by environment id" %
            type(flow_definition["environments"]),
        )

    if "steps" not in flow_definition:
        return {"position": []}, failure(
            "com.gitlab.cd.reason.flow_definition_invalid",
            "flow_definition has no steps",
        )
    steps = flow_definition["steps"]
    if type(steps) != "list":
        return {"position": []}, failure(
            "com.gitlab.cd.reason.flow_definition_invalid",
            "flow_definition.steps is %s, not an array of steps" % type(steps),
        )
    if not steps:
        return {"position": []}, failure(
            "com.gitlab.cd.reason.flow_definition_invalid",
            "flow_definition.steps is empty, so the flow would deploy nothing",
        )

    for index, step in enumerate(steps):
        at = "steps[%d]" % index
        f = _check_step_shape(step, at)
        if f != None:
            return _shape_failure_data([index], step), f
        if step["type"] != _STAGE_TYPE:
            continue

        if type(step.get("name")) != "string" or step["name"] == "":
            return {"position": [index], "step_type": _STAGE_TYPE}, failure(
                "com.gitlab.cd.reason.flow_definition_invalid",
                "%s is a stage with no name" % at,
            )
        if "steps" not in step:
            return {"position": [index], "step_type": _STAGE_TYPE, "stage_name": step["name"]}, failure(
                "com.gitlab.cd.reason.flow_definition_invalid",
                "%s is a stage with no steps" % at,
            )
        if type(step["steps"]) != "list":
            return {"position": [index], "step_type": _STAGE_TYPE, "stage_name": step["name"]}, failure(
                "com.gitlab.cd.reason.flow_definition_invalid",
                "%s has steps of %s, not an array of steps" % (at, type(step["steps"])),
            )
        if not step["steps"]:
            return {"position": [index], "step_type": _STAGE_TYPE, "stage_name": step["name"]}, failure(
                "com.gitlab.cd.reason.flow_definition_invalid",
                "%s is a stage whose steps are empty, so it would deploy nothing" % at,
            )

        for step_index, stage_step in enumerate(step["steps"]):
            f = _check_step_shape(stage_step, "%s.steps[%d]" % (at, step_index))
            if f != None:
                data = _shape_failure_data([index, step_index], stage_step)
                data["stage_name"] = step["name"]
                return data, f
    return None, None

# A step naming no environment resolves to (None, {}), which is legal here: only the
# driver knows whether its own step type can work without one. The problem comes back as
# a failure rather than a fail(), so the caller can report it against the step.
def _step_environment(step, environments, service_envs):
    if "environment" not in step:
        return None, {}, None

    env_id = str(step["environment"])
    if env_id not in environments:
        return None, {}, failure("com.gitlab.cd.reason.environment_not_found", "environment %s not found in environments" % env_id)
    if env_id not in service_envs:
        return None, {}, failure(
            "com.gitlab.cd.reason.service_environment_not_found",
            "environment %s not found in flow_definition.environments" % env_id,
        )

    # What the environment holds beyond this is the driver's to judge; the engine only has to
    # hand a handler the services map it promises.
    entry = service_envs[env_id]
    if type(entry) != "dict" or type(entry.get("services")) != "dict":
        return None, {}, failure(
            "com.gitlab.cd.reason.environments_invalid",
            "flow_definition.environments.%s has no services object" % env_id,
        )
    return environments[env_id], entry["services"], None

# The rollout's own canonical name, which _step_resource extends per step. Both ids are
# interpolated — rollout_id also into the callback path — and a name is what a governance
# decision is recorded against, so an id carrying a separator could name another rollout.
def _rollout_resource(organization_id, rollout_id):
    for name, value in [("organization_id", organization_id), ("rollout_id", rollout_id)]:
        if value != None and not str(value).isdigit():
            return None, failure(
                "com.gitlab.cd.reason.rollout_identity_invalid",
                "%s is not a whole number, so it cannot name this rollout's steps" % name,
            )

    if organization_id == None or rollout_id == None:
        return None, None
    return "organizations/%s/rollouts/%s" % (organization_id, rollout_id), None

# A step's canonical name: the rollout's own name extended by the step's position. A
# stage has one too, being a step in steps[] like any other.
def _step_resource(rollout, position):
    if rollout == None:
        return None

    name = rollout
    for index in position:
        name += "/steps/%d" % index
    return name

# What an approval is really asking about: the next thing the walk reaches. A stage's close is
# stepped over, so an approval last in its stage names the stage that follows rather than the
# one it ends.
def _gated_by(plan, index):
    for action in plan[index + 1:]:
        if action["kind"] == "stage_started":
            return "Approve before the %s stage." % action["data"]["stage_name"]
        if action["kind"] == "step":
            stage_name = action["data"].get("stage_name")
            if stage_name == None:
                return "Approve before the next step."
            return "Approve before the next step in %s." % stage_name
    return "Approve before the deploy completes."

# One flat list of actions in the order they happen; stages never nest, so one level of
# unrolling covers them. position is the path to the step in the document. A step the
# engine cannot run is refused here rather than part way through the run, and the refusal
# comes back as the step's data and a failure for main() to report.
def _plan(flow_definition, environments, service_envs, rollout):
    plan = []
    for top_level_index, step in enumerate(flow_definition["steps"]):
        resource = _step_resource(rollout, [top_level_index])
        if step["type"] == _STAGE_TYPE:
            stage = {"stage_name": step["name"], "position": [top_level_index]}
            plan.append({"kind": "stage_started", "data": stage, "resource": resource})

            for step_index, stage_step in enumerate(step["steps"]):
                position = [top_level_index, step_index]
                plan.append({
                    "kind": "step",
                    "step": stage_step,
                    "data": dict(stage, position = position),
                    "resource": _step_resource(rollout, position),
                })

            plan.append({"kind": "stage_succeeded", "data": stage, "resource": resource})
        else:
            plan.append({
                "kind": "step",
                "step": step,
                "data": {"position": [top_level_index]},
                "resource": resource,
            })

    # A second pass, so the walk above stays a plain transcription of the document.
    for index, action in enumerate(plan):
        if action["kind"] != "step":
            continue

        step = action["step"]
        data = dict(action["data"], step_type = step["type"])

        # Named before the step is resolved, so a refusal names the environment it could
        # not resolve. str() to match the id _step_environment keys by.
        if "environment" in step:
            data["environment"] = str(step["environment"])

        if step["type"] not in _STEPS and step["type"] != _APPROVAL_TYPE:
            return None, data, failure("com.gitlab.cd.reason.unsupported_step_type", "unsupported step type: %s" % step["type"])

        environment, services, f = _step_environment(step, environments, service_envs)
        if f != None:
            return None, data, f

        if step["type"] == _APPROVAL_TYPE:
            action["default_reason"] = _gated_by(plan, index)

        action["data"] = data
        action["environment"] = environment
        action["services"] = services
    return plan, None, None

# Steps grouped by the identity of the function a spec key names, in flow order; functions
# are unhashable in Starlark, hence the list scan. A function whose types never appear gets
# no group rather than an empty one, which an absence-phrased check needs.
def _owned_steps(plan, version_set, key):
    groups = []
    for action in plan:
        if action["kind"] != "step":
            continue

        step_type = action["step"]["type"]

        # Walked by _run_step rather than registered, so it owns no validate or build hook.
        if step_type == _APPROVAL_TYPE:
            continue
        fn = _STEPS[step_type].get(key)
        if fn == None:
            continue

        entry = {
            "step": action["step"],
            "environment": action["environment"],
            "services": action["services"],
            "version_set": version_set,
        }

        group = None
        for candidate in groups:
            if candidate["fn"] == fn:
                group = candidate
                break

        if group == None:
            groups.append({
                "fn": fn,
                "types": [step_type],
                "steps": [entry],
                "data": action["data"],
            })
        else:
            if step_type not in group["types"]:
                group["types"].append(step_type)
            group["steps"].append(entry)
    return groups

# A rejection comes back against the first step the rejecting validator owns: a check
# spanning steps belongs to no single one of them, and that step is the earliest place in
# the document to look.
def _validate_flow(plan, version_set):
    for group in _owned_steps(plan, version_set, "validate"):
        f = group["fn"](group["steps"])
        if f != None:
            return group["data"], f
    return None, None

# This run's dispatch table: each step type's own run handler, or the one its builder made.
# A builder that cannot build is reported, not raised; see the README's `build`.
def _bind_handlers(plan, version_set):
    handlers = {}
    for step_type, spec in _STEPS.items():
        if spec["run"] != None:
            handlers[step_type] = spec["run"]

    for group in _owned_steps(plan, version_set, "build"):
        built, f = group["fn"](group["steps"])
        if f != None:
            return None, group["data"], f
        if type(built) != "dict":
            return None, group["data"], failure(
                "com.gitlab.cd.reason.handler_builder_invalid",
                "a handler builder returned %s, not a dict of step type to handler" % type(built),
            )

        for step_type, handler in built.items():
            registered = _STEPS.get(step_type)
            if registered == None or registered["build"] != group["fn"]:
                return None, group["data"], failure(
                    "com.gitlab.cd.reason.handler_builder_invalid",
                    "a handler builder returned a handler for %s, a step type it did not register" %
                    step_type,
                )
            handlers[step_type] = handler

        for step_type in group["types"]:
            if step_type not in handlers:
                return None, group["data"], failure(
                    "com.gitlab.cd.reason.handler_builder_invalid",
                    "a handler builder returned no handler for %s, whose steps this flow runs" %
                    step_type,
                )
    return handlers, None, None

# What a refusal calls the step: its type, and the name it carries when the rollout has one.
def _step_boundary(action):
    at = ""
    if action["resource"] != None:
        at = " at %s" % action["resource"]
    return "%s%s" % (action["step"]["type"], at)

# Answers the step's failure and what that failure makes of the stage it sits in. ask is the
# one main() built, which an approval step parks on.
def _run_step(emit, ask, gate, action, version_set, handlers):
    step = action["step"]

    # _check_hitl has already refused a flow this run cannot serve.
    if step["type"] == _APPROVAL_TYPE:
        # A flow that reports nowhere still leaves this in the kas log, so the run is
        # followable even then. The ordinary step below prints the same line.
        print("running step %s" % _step_boundary(action))
        emit("com.gitlab.cd.step_started", action["data"])

        # A reason always goes out, an author's own verbatim or one naming what the approval
        # gates. Of the two a governed request adds, only decision_id is its own.
        request = action["data"]
        if action["resource"] != None:
            request = dict(request, resource = action["resource"])

        reason = step.get("reason", "")
        if reason.strip() == "":
            reason = action["default_reason"]
        request = dict(request, reason = reason)

        _actor, who, f = ask(request, _step_boundary(action))
        if f != None:
            _emit_step_failed(emit, action["data"], f)
            return f, "refused"

        # The approval itself reports no actor: the rollouts API declares no key for one, so
        # the kas log is the only place the approver's name survives.
        print("%s approved by %s" % (_step_boundary(action), who))
        emit("com.gitlab.cd.step_succeeded", action["data"])
        return None, None

    step_action = _STEPS[step["type"]]["action"]
    if step_action != None:
        f = gate(_ACTION_TRIGGERS[step_action], action["resource"], action["data"])
        if f != None:
            _emit_step_failed(emit, action["data"], f)
            return f, "refused"

    print("running step %s" % _step_boundary(action))
    emit("com.gitlab.cd.step_started", action["data"])

    report = _service_reporter(emit, action["data"])
    f = handlers[step["type"]](step, action["environment"], action["services"], version_set, report)
    if f != None:
        _emit_step_failed(emit, action["data"], f)
        return f, "unhealthy"
    emit("com.gitlab.cd.step_succeeded", action["data"])
    return None, None

# Refuses a flow whose approval steps this run cannot serve, before anything is read,
# committed or synced. ask() is never called here: it would report a request and park before
# an earlier step ran. One approval step answers for all of them.
def _check_hitl(plan, unavailable):
    for action in plan:
        if action["kind"] != "step" or action["step"]["type"] != _APPROVAL_TYPE:
            continue

        return action["data"], unavailable(_step_boundary(action))
    return None, None

def main(w, *args, **kwargs):
    flow_definition = _require(kwargs, "flow_definition")
    environments = _require(kwargs, "environments")
    version_set = _require(kwargs, "version_set")

    emit = _build_emitter(kwargs)

    flags, f = _feature_flags(kwargs)
    if f != None:
        # Flags belong to no step, and an empty position is how a report locates nothing.
        _emit_step_failed(emit, {"position": []}, f)
        return

    rollout, f = _rollout_resource(kwargs.get("organization_id"), kwargs.get("rollout_id"))
    if f != None:
        # An identity belongs to no step, but every report about a step or a stage carries a
        # position, and an empty path is how one says it locates nothing.
        _emit_step_failed(emit, {"position": []}, f)
        return

    # A name built from a guessed id would name another rollout's step, and a decision
    # recorded against it would be untraceable.
    if rollout == None:
        print("deploy steps will not be named: main() needs both an organization_id and a rollout_id kwarg")

    # What the flow has already done, in the order it did it. A local because kas freezes
    # the globals before main() runs.
    ledger = []

    # The deploy's own report payload; see the identity refusal above.
    deploy_data = {"position": []}

    ask, unavailable = _build_asker(kwargs, flags.get("hitl", False))

    gate, f = _build_gate(flags, rollout, ledger, ask)
    if f == None:
        # The workflow's first act, so a refused deploy is never planned and reaches no
        # driver's validator, which is free to probe a cluster or a registry.
        f = gate("com.gitlab.cd.deployment_requested", rollout, deploy_data)
    if f != None:
        _emit_step_failed(emit, deploy_data, f)
        return

    # All four before anything is read, committed or synced, and all refused the same way: no
    # stage has begun, so a refusal is a step_failed with no stage_failed behind it. The
    # document is checked first, which is what lets _plan index into it freely.
    plan = None
    data, f = _check_flow_document(flow_definition, environments)
    if f == None:
        # A flow of only common steps deploys nothing and so declares no environments; a step
        # that does name one is still refused while the plan is built.
        plan, data, f = _plan(flow_definition, environments, flow_definition.get("environments", {}), rollout)
    if f == None:
        # Ahead of any driver validator, which is free to probe a cluster or a registry: a
        # flow nobody could answer should cost nothing.
        data, f = _check_hitl(plan, unavailable)
    if f == None:
        data, f = _validate_flow(plan, version_set)
    if f == None:
        handlers, data, f = _bind_handlers(plan, version_set)
    if f != None:
        _emit_step_failed(emit, data, f)
        return

    # A failure stops the run: the steps behind it act on what the failed one was meant to
    # leave in place, so a degraded rollout must not reach the promotion that follows it.
    stage = None

    for action in plan:
        kind = action["kind"]
        if kind == "step":
            f, outcome = _run_step(emit, ask, gate, action, version_set, handlers)
            if f != None:
                if stage != None:
                    name = stage["data"]["stage_name"]
                    ledger.append({"environment": name, "outcome": outcome})
                    print("stage %s %s, ledger %s" % (name, outcome, json.encode(ledger)))
                    _report_failure(emit, "com.gitlab.cd.stage_failed", stage["data"])
                return
        elif kind == "stage_started":
            stage = action

            f = gate("com.gitlab.cd.environment_advanced", stage["resource"], stage["data"])
            if f != None:
                _emit_step_failed(emit, stage["data"], f)
                return

            at = ""
            if stage["resource"] != None:
                at = " at %s" % stage["resource"]

            print("running stage %s%s, ledger %s" % (
                stage["data"]["stage_name"],
                at,
                json.encode(ledger),
            ))
            emit("com.gitlab.cd.stage_started", stage["data"])
        elif kind == "stage_succeeded":
            stage = None
            name = action["data"]["stage_name"]
            ledger.append({"environment": name, "outcome": "healthy"})
            print("stage %s healthy, ledger %s" % (name, json.encode(ledger)))
            emit("com.gitlab.cd.stage_succeeded", action["data"])

    emit("com.gitlab.cd.rollout_succeeded", {})
