# Orchestration engine for GitLab CD deploy drivers.
#
# Provides the top-level `main` entrypoint and the `register` machinery that
# concrete deploy drivers plug into. Rails concatenates this program first,
# followed by each driver's deploy() fragment. Every driver's
# deploy() is invoked at load, registering its step handlers into _STEPS
# before AutoFlow calls main().

load("module:gitlab-function", gitlab_function_run = "run")
load("module:event", event_emit = "emit")

def gl_run(function, inputs):
    return gather(gitlab_function_run(function = function, inputs = inputs))

def _require(kwargs, name):
    if name not in kwargs:
        fail("missing required kwarg: %s" % name)
    return kwargs[name]

_STEPS = {}

# The stage groups steps rather than doing work itself, so the engine handles it
# in the walk instead of through _STEPS. Reserving the type keeps a driver from
# registering a handler that would never be called.
_STAGE_TYPE = "com.gitlab.cd.steps.stage"

# An activity that is never awaited is discarded rather than run, so the future is
# gathered even though an emit has no result worth reading.
def _emit(event_type, data):
    gather(event_emit(topic = "com.gitlab.cd.deployment", type = event_type, data = json.encode(data)))

# Only the engine's own failures reach here: a handler's fail() is uncatchable, so
# it leaves a step_started with no step_succeeded and no step_failed.
def _fail_step(data, message):
    _emit("com.gitlab.cd.step_failed", dict(data, error = message))
    fail(message)

# Validators, by the step type they validate. Separate from _STEPS because most step
# types have no validator, and the engine checks membership rather than for None.
_VALIDATORS = {}

# fn handles a step of step_type. validate, if given, checks one such step before the
# flow runs any step at all: the engine makes a whole validation pass first, so a flow
# that contradicts itself is rejected without having read, committed or synced
# anything.
#
# validate takes what fn takes plus a trailing `steps`: every step whose type
# registered this same validator, in flow order, each carrying its own environment,
# services and version set. That is what lets a check span steps. A driver therefore
# sees nothing of the flow beyond the steps it owns, and needs no state of its own
# between calls, which matters because Starlark freezes module-level values once the
# program has loaded.
def register(step_type, fn, validate = None):
    if step_type == _STAGE_TYPE:
        fail("step type is reserved by the orchestration engine: %s" % step_type)
    if step_type in _STEPS:
        fail("step type already registered: %s" % step_type)
    _STEPS[step_type] = fn
    if validate != None:
        _VALIDATORS[step_type] = validate

def _wait(step, environment, services, version_set):
    sleep(step["seconds"] * time.second)

register("com.gitlab.cd.steps.wait", _wait)

# The environment a step names, as (environment, services, error): its entry in the
# top-level environments kwarg, and that environment's per-service configuration. A
# step naming no environment resolves to (None, {}).
#
# Returns the problem as a message rather than calling fail(), because the two callers
# report it differently: _run_step has a step to blame in a step_failed event, and the
# validation pass has no step in flight to close out.
def _step_environment(step, environments, service_envs):
    if "environment" not in step:
        return None, {}, None

    env_id = str(step["environment"])
    if env_id not in environments:
        return None, {}, "environment %s not found in environments" % env_id
    if env_id not in service_envs:
        return None, {}, "environment %s not found in flow_definition.environments" % env_id
    return environments[env_id], service_envs[env_id]["services"], None

# Runs one leaf step: a deploy driver step, or a common step other than a stage.
# A step naming an environment is handed that environment and its per-service
# configuration; a step naming none gets None and an empty dict.
def _run_step(step, position, environments, service_envs, version_set):
    data = dict(position, step_type = step["type"])

    step_type = step["type"]
    if step_type not in _STEPS:
        _fail_step(data, "unsupported step type: %s" % step_type)

    environment, services, error = _step_environment(step, environments, service_envs)
    if error != None:
        _fail_step(data, error)

    # Nothing consumes the emitted events yet, so this stays the progress signal.
    print("running step %s" % step_type)
    _emit("com.gitlab.cd.step_started", data)
    _STEPS[step_type](step, environment, services, version_set)
    _emit("com.gitlab.cd.step_succeeded", data)

# The leaf steps the flow will run, in order: a stage's steps unrolled in place, a
# standalone common step as itself. Stages never nest, so one level covers them.
# Used by the validation pass, which cares what will run and not where it sits.
def _leaf_steps(flow_definition):
    steps = []
    for step in flow_definition["steps"]:
        if step["type"] == _STAGE_TYPE:
            steps.extend(step["steps"])
        else:
            steps.append(step)
    return steps

# The steps one validator owns, in flow order: every leaf step whose type registered
# that same validator, so a validator registered against several step types sees all of
# them and can compare them. Each entry carries what a handler would be given for that
# step, which is what makes a cross-step check possible without the engine handing over
# the flow definition.
#
# Functions compare by identity in Starlark, so `==` groups the types sharing a
# validator.
def _validator_steps(validate, leaf_steps, environments, service_envs, version_set):
    steps = []
    for step in leaf_steps:
        if _VALIDATORS.get(step["type"]) != validate:
            continue

        environment, services, error = _step_environment(step, environments, service_envs)
        if error != None:
            continue
        steps.append({
            "step": step,
            "environment": environment,
            "services": services,
            "version_set": version_set,
        })
    return steps

# Hands every step the flow will run to the validator its type registered, before the
# flow runs any of them.
#
# A step whose type is unregistered, or whose environment does not resolve, is passed
# over here: _run_step reports both as a step_failed event naming the step's position,
# which failing on them now would lose.
#
# Walks the whole flow even when no validator is registered, so a malformed step in the
# last stage is found before the first stage deploys rather than after. Do not make
# this lazy.
def _validate_flow(flow_definition, environments, service_envs, version_set):
    leaf_steps = _leaf_steps(flow_definition)

    # Each validator's own steps, built once per registered type rather than rebuilt for
    # every step, so the pass stays linear in the size of the flow.
    owned = {}
    for step_type in _VALIDATORS:
        owned[step_type] = _validator_steps(
            _VALIDATORS[step_type],
            leaf_steps,
            environments,
            service_envs,
            version_set,
        )

    for step in leaf_steps:
        step_type = step["type"]
        if step_type not in _VALIDATORS:
            continue

        environment, services, error = _step_environment(step, environments, service_envs)
        if error == None:
            _VALIDATORS[step_type](step, environment, services, version_set, owned[step_type])

def main(w, *args, **kwargs):
    flow_definition = _require(kwargs, "flow_definition")
    environments = _require(kwargs, "environments")
    version_set = _require(kwargs, "version_set")

    # A flow whose steps are all common steps deploys nothing and so declares no
    # environments, which is why this defaults rather than indexing. A step that
    # does name an environment still fails loudly in _run_step.
    service_envs = flow_definition.get("environments", {})

    # Before anything is read, committed or synced, so a flow that contradicts itself
    # costs nothing to reject.
    _validate_flow(flow_definition, environments, service_envs, version_set)

    # Top-level steps are stages or standalone common steps. Stages never nest,
    # so a stage's steps are all leaves and one level of unrolling covers them.
    #
    # position is the path to the step in this document, so it deepens by one per
    # level and stays meaningful if the flow ever nests further.
    for top_level_index, step in enumerate(flow_definition["steps"]):
        if step["type"] == _STAGE_TYPE:
            stage = {"stage_name": step["name"], "position": [top_level_index]}
            print("running stage %s" % step["name"])
            _emit("com.gitlab.cd.stage_started", stage)
            for step_index, stage_step in enumerate(step["steps"]):
                _run_step(
                    stage_step,
                    dict(stage, position = [top_level_index, step_index]),
                    environments,
                    service_envs,
                    version_set,
                )
            _emit("com.gitlab.cd.stage_succeeded", stage)
        else:
            _run_step(step, {"position": [top_level_index]}, environments, service_envs, version_set)
