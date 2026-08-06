# gitlab-cd-driver-orchestration

The orchestration engine for GitLab CD deploy drivers.

Rails sends a single Starlark program to AutoFlow (KAS) per rollout. That program has
to drive every step in the flow definition, regardless of which deploy driver handles
each step. This gem owns the top-level engine so individual drivers don't have to:

- `scripts/main.star` — the Starlark engine. It defines the `main()` entrypoint
  AutoFlow calls, the `register(step_type, fn)` machinery drivers use to contribute
  step handlers, and the shared `gl_run` helper. `main()` walks the flow definition's
  top-level steps and dispatches each one to its registered handler, unrolling a
  stage into the steps it groups. As it walks it emits a progress event at each
  stage and step boundary, so a consumer can follow a deploy without polling.
  Before the walk it makes a validation pass, handing each step to the validator its
  type registered, so a driver can reject a contradictory flow before the first step
  does any work.
- `manifest.json` — the entrypoint manifest referencing the engine program and the
  flow definition schema.
- `schemas/flow_definition.json` — the JSON schema for the flow definition: the
  environments a service is deployed to, and the ordered steps that deploy it. A
  top-level step is either a stage, which groups the deploy steps for one
  environment tier, or a common step standing outside any stage.
- `lib/` — `Gitlab::Cd::Driver::Orchestration.assemble` stitches this engine
  together with one or more driver `deploy()` fragments into the single program Rails
  sends. Each driver's module-level `def deploy(` is renamed to a gem-unique
  identifier (via `gem_name_to_identifier`) and invoked at load, so its handlers are
  registered before `main()` runs.

Unlike its sibling [`gitlab-deploy-driver-argo-rollouts`](../gitlab-deploy-driver-argo-rollouts),
which ships data only, this gem also ships Ruby, so it has its own `Gemfile` and
RSpec suite.

## The driver fragment contract

`assemble` concatenates the engine and every driver fragment into one Starlark
module, so a fragment is not a standalone program. It must:

- define exactly one module-level `def deploy():`, which registers its step
  handlers; and
- bind nothing else at module level that the engine already binds. Starlark
  rejects rebinding a global, so a collision makes the whole assembled program
  fail to load. The engine binds `gitlab_function_run` and `event_emit` (both via
  `load`), `gl_run`, `_require`, `_STEPS`, `_STAGE_TYPE`, `_emit`,
  `_fail_step`, `_VALIDATORS`, `register`, `_wait`, `_leaf_steps`,
  `_step_environment`, `_run_step`, `_validator_steps`, `_validate_flow`, and `main`.

A step handler is called `fn(step, environment, services, version_set)`: the raw
step dict, the target environment's entry in the top-level `environments` kwarg
(holding its `cluster_agent_id`), that environment's per-service configuration
from `flow_definition.environments`, and the unindexed version set. A step naming
no environment gets `None` and an empty dict, and it is the driver's job to say so
if its step cannot work without one.

`register(step_type, fn, validate)` takes an optional third argument: a validator for
that step type. The engine makes a full validation pass over the flow's steps before it
runs any of them, so a flow a validator rejects has read, committed and synced nothing.

A validator is called `fn(step, environment, services, version_set, steps)`: the four a
handler gets for the step in hand, plus every step whose type registered this same
validator, in flow order. Each entry in `steps` is a dict of `step`, `environment`,
`services`, and `version_set`, so a check spanning steps reads them the same way a
handler would. One validator registered against several step types is handed all of
them, which is how a check compares a step of one type against steps of another.

A validator never sees a step it does not own, so a driver learns nothing of the rest of
the flow. It also needs no state between calls, which matters: Starlark freezes
module-level values once the program has loaded, so a driver cannot accumulate in a
global. Build what you need from `steps` instead.

There is no end-of-pass hook, so a check that can only be made once every step has been
seen, such as "some step reaches 100%", has nowhere to run yet.

The steps handed to a validator are the flow's own dicts, not copies, so a validator
must treat them as read-only.

Everything else in the fragment is the driver's own: use the engine's `gl_run` to
call CD Functions rather than loading `module:gitlab-function` again. A driver
that wants to emit its own domain events loads `module:event` under a name of its
own, since the engine has taken `event_emit`.

`assemble` raises `ArgumentError` on either violation, so a fragment that would
fail to load inside KAS at rollout time is rejected at build time instead.

## Usage

```ruby
require "gitlab/cd/driver/orchestration"

program = Gitlab::Cd::Driver::Orchestration.assemble(
  driver_scripts: {
    "gitlab-deploy-driver-argo-rollouts" => File.read("…/scripts/deploy.star")
  }
)
```

## Development

Requires Ruby 3.2 or newer, matching `required_ruby_version` in the gemspec. CI
runs the specs and RuboCop on 3.3.

```sh
bundle install
bundle exec rspec
bundle exec rubocop
```
