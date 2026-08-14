# The orchestration engine: main(), and the register() machinery deploy driver
# fragments plug into. Gitlab::Cd::Driver::Orchestration.assemble combines this with
# each driver's fragment into the single program kas runs.

load("module:gitlab-function", gitlab_function_run = "run")
load("module:gitlab", "call_api")

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

# The one topic the rollouts API accepts. Every report the engine makes is a
# deployment progress report, so it is a constant rather than a parameter.
_TOPIC = "com.gitlab.cd.deployment"

# Builds this run's emit(event_type, data), the one place in the repo that calls
# call_api. A closure over the destination rather than a value the walk carries,
# because Starlark freezes globals so a per-run value cannot be stashed in one.
def _build_emitter(kwargs):
    callback_token = kwargs.get("callback_token")
    rollout_id = kwargs.get("rollout_id")

    # Reporting nowhere is not an error, the flow still deploys. Rails passes a token
    # but not yet an id, and a guessed id draws a 401 no different from a bad token.
    if callback_token == None or rollout_id == None:
        print("deploy progress will not be reported: main() needs both a callback_token and a rollout_id kwarg")

        def emit_nowhere(event_type, data, or_fail = True):
            return None

        return emit_nowhere

    path = "/api/v4/rollouts/%s" % rollout_id
    headers = {
        "Content-Type": "application/json",
        # The endpoint reads the token from a "Bearer "-prefixed header and answers
        # 401 without the prefix. Built with + rather than %s: Starlark refuses to
        # add a sensitive_string to a string, so a non-plain token fails here.
        "Authorization": "Bearer " + callback_token,
    }

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

        # call_api returns a non-2xx as an ordinary status and a transport failure as
        # the fourth element of its tuple, so neither arrives as a raised error.
        problem = None
        if error != None:
            problem = "reporting %s: %s" % (event_type, error)
        elif status != 202:
            problem = "reporting %s: rollouts API returned %d: %s" % (event_type, status, body)

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

_ACTIONS_ALLOWED = ("com.gitlab.cd.action.promote",)

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
#   action declares what a step of this type is to governance, from _ACTIONS_ALLOWED, and
#     its absence is the signal: a step type with no action is never gated.
# build and validate are each called once, handed every step whose type registered that same
# function, in flow order, each entry carrying that step's own environment, services and
# version_set; a failure from either is reported against the first step it owns.
def register(step_type, *, run = None, build = None, validate = None, action = None):
    if step_type == _STAGE_TYPE:
        fail("step type is reserved by the orchestration engine: %s" % step_type)
    if step_type in _STEPS:
        fail("step type already registered: %s" % step_type)
    if (run == None) == (build == None):
        fail("step type %s needs exactly one of run and build" % step_type)
    if action != None and action not in _ACTIONS_ALLOWED:
        fail("unknown step action %s: expected one of %s" % (action, ", ".join(_ACTIONS_ALLOWED)))
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
    if type(flow_definition) != "dict":
        return {}, failure(
            "com.gitlab.cd.reason.flow_definition_invalid",
            "flow_definition is %s, not an object" % type(flow_definition),
        )
    if type(environments) != "dict":
        return {}, failure(
            "com.gitlab.cd.reason.environments_invalid",
            "environments is %s, not an object keyed by environment id" % type(environments),
        )

    # Absent is legal — a flow of only common steps declares none — but present and
    # misshapen is not.
    if type(flow_definition.get("environments", {})) != "dict":
        return {}, failure(
            "com.gitlab.cd.reason.environments_invalid",
            "flow_definition.environments is %s, not an object keyed by environment id" %
            type(flow_definition["environments"]),
        )

    if "steps" not in flow_definition:
        return {}, failure(
            "com.gitlab.cd.reason.flow_definition_invalid",
            "flow_definition has no steps",
        )
    steps = flow_definition["steps"]
    if type(steps) != "list":
        return {}, failure(
            "com.gitlab.cd.reason.flow_definition_invalid",
            "flow_definition.steps is %s, not an array of steps" % type(steps),
        )
    if not steps:
        return {}, failure(
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
    for action in plan:
        if action["kind"] != "step":
            continue

        step = action["step"]
        data = dict(action["data"], step_type = step["type"])

        # Named before the step is resolved, so a refusal names the environment it could
        # not resolve. str() to match the id _step_environment keys by.
        if "environment" in step:
            data["environment"] = str(step["environment"])

        if step["type"] not in _STEPS:
            return None, data, failure("com.gitlab.cd.reason.unsupported_step_type", "unsupported step type: %s" % step["type"])

        environment, services, f = _step_environment(step, environments, service_envs)
        if f != None:
            return None, data, f

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

def _run_step(emit, action, version_set, handlers):
    step = action["step"]

    # A flow that reports nowhere still leaves this in the kas log, so the run is
    # followable even then.
    at = ""
    if action["resource"] != None:
        at = " at %s" % action["resource"]

    print("running step %s%s" % (step["type"], at))
    emit("com.gitlab.cd.step_started", action["data"])

    report = _service_reporter(emit, action["data"])
    f = handlers[step["type"]](step, action["environment"], action["services"], version_set, report)
    if f != None:
        _emit_step_failed(emit, action["data"], f)
        return f
    emit("com.gitlab.cd.step_succeeded", action["data"])
    return None

def main(w, *args, **kwargs):
    flow_definition = _require(kwargs, "flow_definition")
    environments = _require(kwargs, "environments")
    version_set = _require(kwargs, "version_set")

    emit = _build_emitter(kwargs)

    rollout, f = _rollout_resource(kwargs.get("organization_id"), kwargs.get("rollout_id"))
    if f != None:
        _emit_step_failed(emit, {}, f)
        return

    # A name built from a guessed id would name another rollout's step, and a decision
    # recorded against it would be untraceable.
    if rollout == None:
        print("deploy steps will not be named: main() needs both an organization_id and a rollout_id kwarg")

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
        data, f = _validate_flow(plan, version_set)
    if f == None:
        handlers, data, f = _bind_handlers(plan, version_set)
    if f != None:
        _emit_step_failed(emit, data, f)
        return

    # A failure stops the run: the steps behind it act on what the failed one was meant to
    # leave in place, so a degraded rollout must not reach the promotion that follows it.
    stage = None

    # What the flow has already done, in the order it did it. A local because kas freezes
    # the globals before main() runs.
    ledger = []

    for action in plan:
        kind = action["kind"]
        if kind == "step":
            if _run_step(emit, action, version_set, handlers) != None:
                if stage != None:
                    name = stage["data"]["stage_name"]
                    ledger.append({"environment": name, "outcome": "unhealthy"})
                    print("stage %s unhealthy, ledger %s" % (name, json.encode(ledger)))
                    _report_failure(emit, "com.gitlab.cd.stage_failed", stage["data"])
                return
        elif kind == "stage_started":
            stage = action

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
