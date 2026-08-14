# gitlab-cd-driver-orchestration

The orchestration engine for GitLab CD deploy drivers.

Rails sends a single Starlark program to AutoFlow (KAS) per rollout. That program has
to drive every step in the flow definition, regardless of which deploy driver handles
each step. This gem owns the top-level engine so individual drivers don't have to:

- `scripts/main.star` — the Starlark engine. It defines the `main()` entrypoint
  AutoFlow calls, the `register(step_type, run = …)` machinery drivers use to contribute
  step handlers, and the shared `gl_run` helper. `main()` walks the flow definition's
  top-level steps and dispatches each one to its registered handler, unrolling a
  stage into the steps it groups. As it walks it reports progress at each stage and
  step boundary to GitLab's rollouts API, and closes a deploy that ran to the end
  with a terminal event, so a consumer can follow a deploy without polling.
  Before the walk it builds the whole plan and makes a validation pass, handing each
  validator every step of the types it registered, so a flow the engine cannot run, or
  that a driver rejects as contradictory, fails before the first step does any work.
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
  fail to load. The engine binds `gitlab_function_run` and `call_api` (both via
  `load`), `gl_run`, `_require`, `_STEPS`, `_STAGE_TYPE`, `_TOPIC`,
  `_build_emitter`, `failure`, `_emit_step_failed`, `_report_failure`,
  `_service_reporter`, `_ACTIONS_ALLOWED`, `register`, `_wait`, `_step_environment`,
  `_step_resource`, `_plan`, `_owned_steps`, `_validate_flow`, `_bind_handlers`,
  `_run_step`, and `main`.

A step handler is called `fn(step, environment, services, version_set, report)`: the
raw step dict, the target environment's entry in the top-level `environments` kwarg
(holding its `cluster_agent_id`), that environment's per-service configuration
from `flow_definition.environments`, the unindexed version set, and the service walk
described below. A step naming no environment gets `None` and an empty
dict, and it is the driver's job to say so if its step cannot work without one.

A handler returns `None` when the step succeeded, or `failure(reason, message)` to report
one it could not complete: a sync that errored, a rollout that degraded, a poll that timed
out, a manifest it cannot drive. `reason` is a machine-readable code the driver owns;
`message` is the sentence a human reads. The engine reports it as a
`com.gitlab.cd.step_failed` event carrying both, then stops the run — so the steps behind
the failed one do not run, and a step inside a stage is followed by
`com.gitlab.cd.stage_failed` rather than `stage_succeeded`.

A `reason` is reverse-DNS and namespaced by whoever owns it, like a step type. The
engine's own are `com.gitlab.cd.reason.*`; a driver's belong under its own namespace, so
the Argo Rollouts driver reports `com.gitlab.cd.argo.reason.*`. Telling the two apart
matters because the engine reports its own refusals against a *driver's* step, which
leaves the payload's `step_type` saying nothing about who found the problem. It also keeps
two drivers that both have a notion of a failed sync from colliding on one bare
`sync_failed` that a policy cannot separate. The engine does not enforce the namespace at
run time, because raising there would replace a described failure with an abort; a driver
holds itself to it in its own tests.

The run then ends *successfully*: a deploy that failed for a reason the driver can
describe is an outcome, and the events carry it. Only a problem nothing can describe
still aborts the workflow — a `fail()`, or a CD Function returning an error through
`gl_run`, which is uncatchable in Starlark and so leaves a `step_started` with no
terminal event.

`register(step_type, run = …, build = …, validate = …, action = …)` files one record per step
type. Everything after the step type is keyword-only, so an unknown keyword is refused by the
runtime; both or neither of `run` and `build` is refused by the engine.

`run` is the handler described above. `build` is the alternative: rather than filing a
handler, a driver files a function the engine calls to make one, once the flow is in view.

`validate` is a validator for that step type. The engine makes a full validation pass over
the flow's steps before it runs any of them, so a flow a validator rejects has read,
committed and synced nothing.

A validator is called `fn(steps)`, once for the whole flow: `steps` is every step whose
type registered this same validator, in flow order. Each entry is a dict of `step`,
`environment`, `services`, and `version_set`, the four a handler is given for that step,
so a check spanning steps reads them the same way a handler would. One validator
registered against several step types is handed all of them, which is how a check
compares a step of one type against steps of another.

Being called once rather than once per step means a check is a plain fold over `steps`,
and a check that probes a cluster or a registry issues one probe rather than one per
step. It also means a validator needs no state between calls, which matters: Starlark
freezes module-level values once the program has loaded, so a driver cannot accumulate in
a global. Build what you need from `steps` instead.

A validator never sees a step it does not own, so a driver learns nothing of the rest of
the flow. The steps it is handed are the flow's own dicts, not copies, so it must treat
them as read-only.

A validator whose type never appears in the flow is not called at all, rather than called
with an empty list. A check phrased as an absence, such as "no canary step reaches 100%",
relies on this: it must not fire on a flow with no canary steps.

A validator returns `None` when the flow is acceptable, or a `failure(reason, message)` for
the first problem it finds. The engine reports it as a `com.gitlab.cd.step_failed` against
the first step that validator owns — a check spanning steps belongs to no single one of
them, and that step is the earliest place in the document to look — runs no later
validator and no step, and returns. Reporting every problem from every driver together,
and running a check once per environment rather than once per driver, are both still to
come.

That attribution is honest only for a check that genuinely spans steps. A validator that
also runs a per-step check on `steps` — one that fails on a single entry with nothing to
do with the others — is reported the same way, against the validator's first owned step
rather than the step the check actually failed on. `step_type` and `position` can then
name a different step than `message` describes. The message stays authoritative; a driver
adding a per-step check to a shared validator should word it so it names the step itself,
since the payload's `step_type` and `position` may not.

`build` is how a handler acts on more than the step in hand. The engine calls it once, as
`build(steps)`, with the list a validator of those step types would be handed, after every
validator has passed and before the first `stage_started`. It returns a pair: a dict of step
type to handler, which the engine dispatches in place of the ones those step types
registered, and `None` or a `failure(reason, message)`, attributed like a validator's against
the first step the builder owns. A builder whose step types never appear is not called, as a
validator is not.

A built handler is an ordinary handler; what differs is when it was made. Starlark freezes
module-level values once the program has loaded, and freezing a function freezes what it
captured, so a value spanning steps — a canary's whole weight ladder — fits in neither a
global nor a load-time closure. A closure made during `build` holds one, because `build` runs
while the flow does.

The engine reports what a builder hands back if it cannot dispatch it, under
`com.gitlab.cd.reason.handler_builder_invalid`: something other than a dict, a handler for a
step type the builder did not register, or no handler for a type the flow runs. Each is a
driver bug, but a reported one: an abort mid-workflow would end it having emitted nothing.

`action` declares what a step of this type is to governance, from `_ACTIONS_ALLOWED`,
which holds `com.gitlab.cd.action.promote` today. Policy then matches on the action instead of
on a driver's step-type strings, so rebinding an environment to another driver keeps a rule
matching where one naming `com.gitlab.cd.argo.canary.promote` would silently stop. A value
not in that set fails at load rather than leaving the step ungated.

Declaring nothing is the default and leaves a step ungated, so adding a step type cannot
accidentally add a gate. A driver only declares; it never consults a policy itself, so
enforcement has one implementation and no driver can forget to run it.

Leaving a deploy step undeclared is safe because the stage it sits in was gated on entry. The
engine trusts the flow definition to have been validated for that rather than enforcing it:
only a stage or a common step may appear at the top level, and a driver step that reached the
top level would emit no stage boundary for anything to gate.

A step the engine itself cannot run, because nothing registered its type or because its
environment does not resolve, is refused before any validator runs. Such a step never
reaches a validator, and the refusal carries a `reason` of
`com.gitlab.cd.reason.unsupported_step_type`,
`com.gitlab.cd.reason.environment_not_found`, or
`com.gitlab.cd.reason.service_environment_not_found`.

Ahead of even that, the engine checks the shape of the document itself: that there are steps,
that each is an object naming a type, that a stage carries a name and steps of its own, that a
wait step's `seconds` is a whole number, and that both environment maps are objects keyed by
environment id, each entry holding a `services` object. A document that fails one of those
carries `com.gitlab.cd.reason.flow_definition_invalid` or
`com.gitlab.cd.reason.environments_invalid`, with the message naming the offending field by
its path — `steps[1].steps[0].seconds`. These checks exist because the engine indexes into the
document to walk it: without them a missing field is a Starlark key error, which aborts the
workflow rather than reporting a failure a consumer can read. A flow definition is validated
against the schema before it reaches kas, so reaching one of these means it got here another
way.

Ahead of the document, the engine checks the identity it was handed: `organization_id` and
`rollout_id` must each be digits when passed, because both are interpolated into a step's name
and `rollout_id` also into the callback path. One that is not carries
`com.gitlab.cd.reason.rollout_identity_invalid`.

Those six are the whole of the engine's vocabulary.

Every refusal — the document's, the engine's and a validator's — is a
`com.gitlab.cd.step_failed` event, and none is preceded by a `stage_started`, even when the
step at fault sits inside a stage: all happen before the walk, so the stage never begins — and
so there is no `stage_failed` either. Each names the position of the step it blames, except a
document-level refusal with no one step behind it — no steps at all, or an `environments` that
is not an object — which carries no position. `step_type` and `stage_name` ride along whenever
the document check had already confirmed them before the failure it reports: a wait step's own
`seconds`, or a stage's `steps`, fail with their type and (for a stage's own `steps`) its name
already known, so both are attached; a step's own shape failing — not an object, no `type`, or
a `type` of the wrong kind — carries neither, because that failure is what leaves them unknown.

Everything else in the fragment is the driver's own: use the engine's `gl_run` to
call CD Functions rather than loading `module:gitlab-function` again. Progress
reporting stays the engine's, which reports each of the driver's steps at the
boundaries it dispatches them from; a fragment must not load `module:gitlab` and
call `call_api` itself, so one flow reports with one voice.

The one thing the engine cannot see is *which* service a step is on. A step's
`services` are the driver's own field — the flow definition leaves a driver step's
shape to the driver — so the engine dispatches the whole step and only the handler
knows what it is about to deploy. `report` closes that gap:
`report(services, deploy_one)` takes the names of the services this step deploys and
a callback, and for each name emits `com.gitlab.cd.service_started`, calls
`deploy_one(service)`, then emits `com.gitlab.cd.service_succeeded`. A name is all it
takes, so a handler keeps whatever else it needs keyed by that name.

A `failure()` the callback returns ends the walk: the engine emits
`com.gitlab.cd.service_failed` for that service, carrying the same `reason` and
`error` as the `step_failed` behind it, and hands the failure back for the handler to
return. So a handler never reports a service's outcome, cannot blame the wrong
service, cannot leave a `service_started` with no terminal event behind it, and
cannot deploy the services behind a failed one. The pairing is this loop, not a rule
a handler keeps, so a driver has no protocol here to get wrong.

`assemble` raises `ArgumentError` on either violation, so a fragment that would
fail to load inside KAS at rollout time is rejected at build time instead.

## Progress reporting

Each stage, step and service boundary is `POST`ed to `/api/v4/rollouts/<rollout_id>`
with a body of `topic`, `type` and `data`, authenticated by the per-rollout callback
token as a `Bearer` header. The endpoint answers `202`; anything else, or a transport
error, fails the flow, because a consumer that never sees the event holds a wrong
view of the deploy. The exceptions are the three reports on the failure path,
`step_failed`, `stage_failed` and `service_failed`: those are logged and stepped over,
because raising there would turn a failure the driver had described back into the
uncatchable abort that reporting it exists to replace.

The three granularities nest. A stage encloses its steps, and a step encloses the
services its handler deploys:

```
com.gitlab.cd.stage_started
  com.gitlab.cd.step_started
    com.gitlab.cd.service_started    com.gitlab.cd.service_succeeded
    com.gitlab.cd.service_started    com.gitlab.cd.service_failed
  com.gitlab.cd.step_failed
com.gitlab.cd.stage_failed
```

Service events come only from a step whose handler reports them, so a step that
deploys nothing — the engine's own wait — sits inside its `step_started` and
`step_succeeded` alone.

`data` says where in the flow definition the report is about: a `position` path, and
the `stage_name` of the stage it sits in. A step boundary adds the `step_type`, and
the `environment` id when its step names one — a common step names none, and neither
does a stage, which has no environment of its own to name. A service boundary carries
its step's fields plus the `service` name; `position` still names the step, because a
service is not a position in the document. A `step_failed` or `service_failed` adds the
`reason` code and the `error` it was described with. Everything else a consumer
resolves from the flow definition it already holds.

A deploy that reached the end of the walk is closed by exactly one
`com.gitlab.cd.rollout_succeeded`, the last thing the engine reports. It is the only
event about the rollout rather than about a step or a stage, so it has nowhere in the
flow to be located: `data` is empty, and `position` is omitted rather than sent as
`[]`, the same way a step outside a stage omits `stage_name`. Without it a consumer
could only tell a finished deploy from a stalled one by counting the flow's stages and
reading silence as an answer, which a consumer that never saw the flow definition
cannot do at all.

There is deliberately no `rollout_failed`. Every failure path reports `step_failed`,
and `stage_failed` when a stage is open, and then returns without walking further, so
a failed deploy is a `step_failed` with no `rollout_succeeded` behind it. A second
event carrying the same news would be a second thing to keep consistent. The one case
still uncovered is the uncatchable abort — a `fail()`, or a CD Function error through
`gl_run` — which ends the workflow mid-walk and so leaves a `step_started` with no
terminal event; no report can close that, because the workflow is gone.

`main()` takes the destination as two optional kwargs, `callback_token` and
`rollout_id`. A flow started without both still deploys and simply reports nowhere,
which is what keeps the harness and any other non-Rails caller working. Guessing an
id is deliberately not done: the endpoint answers `401` for an id the token does not
name, indistinguishable from a bad token.

## Step names

Every step has a canonical name, which is the rollout's own name extended by the step's
position. A stage has one too, being a step in `steps[]` like any other:

```text
organizations/9/rollouts/7/steps/2/steps/1
```

The engine builds it from the `organization_id` and `rollout_id` kwargs, appending one
`/steps/<index>` segment per element of the step's position. Indices are the walk's own, so
a name and the `position` in a progress report always agree, and the flow definition is
pinned when the rollout starts, so the name keeps resolving to the same step for as long as
anything recorded against it is worth reading. Segments are ids and positions, never stage
names, because a rename would otherwise change every name derived from it.

A name is what the decision point records a governance decision against. Two steps of the same
type against the same environment differ by name, which is what lets a decision be recorded
against one of them and not the other.

`organization_id` is optional alongside `rollout_id`, and a flow started without either
names nothing rather than naming a step from a guess, because a decision recorded against
another rollout's step could not be traced back. Such a flow says so once in the kas log, the
way one that reports nowhere does.

Each id must be digits, checked whenever it is passed, whether or not the other is. Rails sends
both as strings, so a string of digits is accepted; anything with a separator, a space or an
empty value is not, because an id of `7/steps/0` would name a step of another rollout and
`rollout_id` also addresses the callback path. The flow is refused before it names or reports
anything else, as a `step_failed` carrying no position.

Refusing an identity is the one refusal a consumer may never see. The report is addressed by
`rollout_id`, so a `rollout_id` that is itself the offending value addresses nowhere, and one
that was never passed leaves the engine reporting nowhere at all. Both leave the refusal in the
kas log and the workflow completing having deployed nothing.

## The ledger

As the engine walks the flow it keeps a ledger of the stages it has closed, one entry per stage
in the order they closed. It is a local of `main()`, and today nothing reads it: the engine logs
it at each stage boundary and the governance gate that will consume it is still to come. What
follows is the shape that gate is being built against.

```json
[{ "environment": "staging", "outcome": "healthy" }]
```

A rule of the "staging must be green before production" kind is answerable from it, because a
stage's own entry is appended only once its steps are done: at the moment a stage begins, the
ledger holds the stages closed before it and none after.

`environment` is the stage's name, which is the environment tier a rule matches on. The
environment id its steps carry is a join key into the flow definition, not something a policy
is written against, so it is not what an entry records.

`outcome` is `healthy` when every step in the stage succeeded, and `unhealthy` when one
failed. A failing step ends the run, so an unhealthy entry is the last one written; it exists
so that what a rule reads about a stage does not depend on the run having got past it.

One entry stands for one stage, and a stage is a tier rather than a single environment: a
`production` stage may deploy `eu-west-1` and `eu-west-2`, and its entry says the production
tier came out healthy. Walking every step in the stage is what makes that true, so nothing
constrains a stage to one environment.

An entry names its tier and nothing narrower, so two stages of the same tier read alike. A rule
that needs to tell them apart cannot, which is a deliberate limit of this shape: the entry says
what the decision point was told to match on.

The ledger is the engine's own assertion about what happened, not an independent record. A
ledger the decision point keeps for itself is the harder guarantee; an entry is shaped so that
moving the trust there does not change what a rule reads.

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
