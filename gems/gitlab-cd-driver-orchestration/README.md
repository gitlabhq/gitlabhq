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
  fail to load. The engine binds `gitlab_function_run`, `call_api`, `post_value`, `evaluate`,
  `ALLOW`, `DENY`, `REQUIRE_APPROVAL` and `get_object` (all via `load`), `gl_run`, `_require`,
  `_STEPS`, `_STAGE_TYPE`, `_APPROVAL_TYPE`, `_TOPIC`, `_ACCEPTED`, `_destination`,
  `_problem`, `_build_emitter`, `failure`, `_emit_step_failed`,
  `_report_failure`, `_service_reporter`, `_build_asker`, `_FLAGS`, `_feature_flags`,
  `_build_gate`, `_ACTION_TRIGGERS`, `register`, `_WAIT_TYPE`, `_wait`, `_check_step_shape`,
  `_shape_failure_data`, `_check_flow_document`, `_step_environment`, `_rollout_resource`,
  `_step_resource`, `_gated_by`, `_plan`, `_owned_steps`, `_validate_flow`, `_bind_handlers`,
  `_step_boundary`, `_run_step`, `_check_hitl`, and `main`.

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
leaves the payload's `step_type` saying nothing about who found the problem. The engine does
not enforce the namespace at run time; a driver holds itself to it in its own tests.

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

`action` declares what a step of this type is to governance, from the keys of
`_ACTION_TRIGGERS`, which holds `com.gitlab.cd.action.promote` today. Policy then matches on the
action instead of on a driver's step-type strings, so rebinding an environment to another driver
keeps a rule matching where one naming `com.gitlab.cd.argo.canary.promote` would silently stop.
A value that table does not hold fails at load rather than leaving the step ungated, and the
value it maps to is the trigger the engine evaluates such a step under.

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
wait step's `seconds` is a whole number, that an approval step's `reason` is a string, and
that both environment maps are objects keyed by
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

Together with the builder refusal above and the governance refusals below, those are the
whole of the engine's vocabulary.

Every refusal — the document's, the engine's and a validator's — is a
`com.gitlab.cd.step_failed` event, and none is preceded by a `stage_started`, even when the
step at fault sits inside a stage: all happen before the walk, so the stage never begins — and
so there is no `stage_failed` either. Each names the position of the step it blames, except a
document-level refusal with no one step behind it — no steps at all, or an `environments` that
is not an object — whose position is empty, the same shape a refused identity reports.
`step_type` and `stage_name` ride along whenever the document check had already confirmed them
before the failure it reports: a wait step's own `seconds`, or a stage's `steps`, fail with
their type and (for a stage's own `steps`) its name already known, so both are attached; a
step's own shape failing — not an object, no `type`, or a `type` of the wrong kind — carries
neither, because that failure is what leaves them unknown.

Everything else in the fragment is the driver's own: use the engine's `gl_run` to
call CD Functions, and its `get_object` to read a cluster, rather than loading
`module:gitlab-function` or `module:kubernetes` again. `get_object` is bound under
its upstream name and unwrapped rather than behind a `gl_run`-style helper: it is a
derived action, so a caller gathers it, and a `poll` can drive it.
Progress reporting stays the engine's, which reports each of the driver's steps at
the boundaries it dispatches them from; a fragment must not load `module:gitlab` and
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
rather than replacing a described failure with an uncatchable abort.

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
does a stage, which has no environment of its own to name. A stage boundary carries no
`step_type` either: a stage is not a step. A service boundary carries
its step's fields plus the `service` name; `position` still names the step, because a
service is not a position in the document. A `step_failed` or `service_failed` adds the
`reason` code and the `error` it was described with. An `approval_requested` adds the `resource`
being gated, the `decision_id` it was asked under, the `channel` an answer routes back on, and a
`reason` that is prose rather than a code. Everything else a consumer resolves from the flow
definition it already holds.

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
a failed deploy is a `step_failed` with no `rollout_succeeded` behind it. Two cases are
still uncovered. The uncatchable abort — a `fail()`, or a CD Function error through
`gl_run` — ends the workflow mid-walk and so leaves a `step_started` with no terminal
event; no report can close that, because the workflow is gone. And a deploy parked on an
approval nobody answers has no terminal event yet either, until it gains a deadline.

`main()` takes the destination as two optional kwargs, `callback_token` and
`rollout_id`, which the approval request is sent with too. A flow started without both still deploys and simply reports nowhere,
which is what keeps the harness and any other non-Rails caller working. An absent id is
never guessed at: the endpoint answers `401` for an id the token does not name,
indistinguishable from a bad token.

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
names, so a rename does not change every name derived from it.

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
anything else, as a `step_failed` whose position is empty: the identity belongs to no step, and
every report about a step or a stage carries a position.

Refusing an identity is the one refusal a consumer may never see: the report is addressed by
`rollout_id`, so an offending or absent one addresses nowhere. Both leave the refusal in the
kas log and the workflow completing having deployed nothing.

## The ledger

As the engine walks the flow it keeps a ledger of the stages it has closed, one entry per stage
in the order they closed. It is a local of `main()`, logged at each stage boundary and sent as
the `ledger` of every governance request (see [Governance gates](#governance-gates)).

```json
[{ "environment": "staging", "outcome": "healthy" }]
```

A rule of the "staging must be green before production" kind is answerable from it, because a
stage's own entry is appended only once its steps are done: at the moment a stage begins, the
ledger holds the stages closed before it and none after.

`environment` is the stage's name, which is the environment tier a rule matches on. The
environment id its steps carry is a join key into the flow definition, not something a policy
is written against, so it is not what an entry records.

`outcome` is `healthy` when every step in the stage succeeded, `unhealthy` when one failed, and
`refused` when a policy refused one: a stage stopped by a governance decision deployed nothing
wrong, so calling it unhealthy would say something about the workload that is not true. Any of
the last two ends the run, so such an entry is the last one written and no gate is ever handed
one: what a rule reads is the stages that closed healthy before it. The value earns its place in
the log and in the shape a decision point would keep for itself, not yet in anything a rule can
match.

One entry stands for one stage, and a stage is a tier rather than a single environment: a
`production` stage may deploy `eu-west-1` and `eu-west-2`, and its entry says the production
tier came out healthy. Walking every step in the stage is what makes that true, so nothing
constrains a stage to one environment.

An entry names its tier and nothing narrower, so two stages of the same tier read alike. A rule
that needs to tell them apart cannot; that is a deliberate limit of this shape.

The ledger is the engine's own assertion about what happened, not an independent record.

## Governance gates

The engine consults kas's `policy` module at three boundaries, so enforcement has one
implementation and a driver cannot forget to run it:

| Trigger | Asked | Named |
| --- | --- | --- |
| `com.gitlab.cd.deployment_requested` | once, before the flow is checked, planned or validated | the rollout |
| `com.gitlab.cd.environment_advanced` | on entry to each stage, before it begins | the stage |
| `com.gitlab.cd.deployment_promoted` | before each step whose declared `action` is `com.gitlab.cd.action.promote` | the step |

The deploy is asked about first because a validator is free to probe a cluster or a registry,
and a refused deploy should reach none of them.

Each call carries the boundary's name and a context of the ledger so far, plus the tier the
boundary sits in, which is the stage's name for the same reason a ledger entry's
`environment` is:

```json
{ "environment": { "tier": "production" }, "ledger": [] }
```

The deploy as a whole names no tier, and neither does a step outside any stage, so those two
send the ledger alone. A boundary asked again
after an approval carries a third key; see Parking on an approval.

Only an `allow` proceeds. Every other answer stops the deploy, including one this engine does
not recognise and one that is missing altogether: an unrecognised verdict fails closed. A `require_approval` is the exception: it parks the deploy and asks a person.

A refusal is a `failure()` like any other, so it stops the run the way every other failure
does: a `com.gitlab.cd.step_failed` naming the boundary, and no `rollout_succeeded` behind it,
which is what keeps a refused deploy from reading as a finished one. Its `reason` is what
separates a refusal from a broken cluster, and the three are distinct:
`com.gitlab.cd.reason.policy_denied` for a policy saying no,
`com.gitlab.cd.reason.policy_requires_approval` for one asking for a further approval after one
was spent, and `com.gitlab.cd.reason.policy_verdict_unknown` for one whose contract has moved.
The refused boundary emits no event of its own first, exactly as a step the engine cannot run
emits no `stage_started`.

### The approval step

`com.gitlab.cd.steps.approval` is a common step a pipeline author puts in the flow. It parks
the deploy until a person approves or rejects it, whatever the `governance` flag says: no
policy is involved, and the author asking is the whole reason.

It takes an optional `reason` in prose, shown to whoever decides; without one the engine
sends a reason naming what the approval gates, which is the next step, the stage that follows
it, or the deploy's completion. It reports
`com.gitlab.cd.step_started`, then the request described below, then
`com.gitlab.cd.step_succeeded` on an approve. A reject is
`com.gitlab.cd.reason.approval_denied` naming the actor, which stops the run and is followed
by `com.gitlab.cd.stage_failed` when the step sits in a stage.

A flow carrying one is refused before the walk begins if this run cannot serve it — the
`hitl` flag off, or no credentials to send the request — at that step's own position, and
ahead of any driver validator, which is free to probe a cluster or a registry. A flow with no
approval step is unaffected by the flag.

The type is reserved: `register()` refuses it, the way it refuses the stage type. A
registered handler is called `fn(step, environment, services, version_set, report)`, which
reaches neither the emitter nor the asker, so a driver handler could not park even if it
wanted to.

### Parking on an approval

A `require_approval` says the boundary is allowed once a person says so, so the engine asks one.
It mints a channel, announces it with `post_value` as `com.gitlab.cd.approval_requested` — the
boundary's own payload plus the `resource` being gated, the `decision_id` it was answered
under, the `reply` channel an answer arrives on, and a `reason` in prose rather than the reason
code a failure carries — and then parks on that channel. The park is durable and holds nothing
open in kas, so a deploy can wait for days.

`post_value` is the one send that can carry a channel, and kas attaches a token addressing it
to the request body, which is what authorizes the answer. Everything else the engine reports
still goes by `call_api`, to the same endpoint with the same bearer token; kas sets a
`post_value`'s `Content-Type` and `Idempotency-Key` itself and rejects an override, so the
engine sets neither.

The channel is minted per park rather than once per run. A run-long channel would buffer a
decision that arrived late for an earlier step and hand it to the next park, where the position
check would refuse a park that should still have been waiting.

A deploy that cannot ask is refused as `com.gitlab.cd.reason.approval_unavailable` rather than
parked: without the `hitl` feature flag, or without the credentials to send the request,
nothing would ever answer. A request that does not land is refused the same way rather than
failing the flow, because a park behind a lost request waits for a reader that was never told.

A decision arrives as an ordinary dict:
`{"position": [0, 1], "result": "approve", "actor": {…}}`, where `result` is `approve` or
`reject`. A channel outlives the request it
answers, so the engine takes only a decision naming the position it advertised; the shape
carries no id to match, and the request's `decision_id` is there for the trail rather than the
check. Anything else is
`com.gitlab.cd.reason.approval_invalid`: an approval granted for one promotion must not satisfy
the next, and waiting for a better value needs a deadline the engine does not have yet.
`com.gitlab.cd.reason.approval_denied`, naming the actor, is a person refusing.

An approval is not the verdict. The policy is asked again, under the same trigger and resource,
with a third context key naming the decision it is resuming and who approved it:

```json
{
  "environment": { "tier": "production" },
  "ledger": [],
  "approval": { "decision_id": "01JD…", "actor": { "name": "alice", "id": "42" } }
}
```

`actor` is `null` where the decision named none the engine can forward: only two rendered
scalars reach a policy, because an actor travels there through `json.encode`, which raises
uncatchably on a value the engine did not build. So nothing but an allow lets the boundary
through. A policy that asks for a further approval is refused rather than parked again: a
second park is unbounded until the wait gains a deadline, and a second request at the same
position cannot be told apart from a stale answer to the first. A refusal after an approval
names the approval it overrode, since the decision refusing it carries an id of its own.

A refusal of the deploy itself locates nothing, so its position is empty, the same shape a
refused identity reports. A stage and a step each report the position they already carry. Two
stops report nothing at all: a request the module itself refuses raises out of `gather()`, which
no Starlark can catch, and a decision point that is merely unreachable never reaches the engine,
because the activity retries it.

Gating is off unless `main()` is given `feature_flags = {"governance": True}`, so no deploy
behaves differently until a caller asks for one that does. An absent `feature_flags` leaves
every flag off; one that is not an object at all is refused as
`com.gitlab.cd.reason.feature_flags_invalid`, as is a flag the engine reads whose value is
not `True` or `False`. Starlark truthiness would otherwise read a `false` passed as a string
as on, so a caller who meant to turn gating off would get it. A flag the engine does not read
is ignored, whatever it holds. Governance
also needs the rollout identity, and a flow asking to be governed without it is refused as
`com.gitlab.cd.reason.governance_unnameable`: a decision point cannot form an identity for an
unnamed boundary, and one silently left ungated is worse than a deploy refused before it
starts.

Turn `hitl` on wherever `governance` is on. With it off, a policy answering `require_approval`
refuses that boundary as `com.gitlab.cd.reason.approval_unavailable` part way through the walk,
leaving the rollout deployed as far as it got. Unlike an approval step's, that refusal cannot
come before the walk, because only the policy knows whether an approval is ever needed.

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
