# Gitlab::PolicyStore

The storage-agnostic management layer for GitLab security policies (the "Policy
Store"), distinct from the stateless Policy Engine that evaluates them.

Callers use a single public facade (`Gitlab::PolicyStore`) and never
touch persistence directly. All storage goes through an injectable repository
port (`Gitlab::PolicyStore::Ports::PolicyRepository`), so the
in-monolith backend used today can be swapped for a remote service later without
changing any caller.

```
Facade  →  Port (interface)  →  Adapter (in-memory today, persistent or remote later)
```

The facade returns `Gitlab::PolicyStore::Policy` value objects, so no
persistence object ever crosses the component boundary.

## Usage

```ruby
# Create a new policy
policy = Gitlab::PolicyStore.create(
  organization_id: 1,
  namespace_id: 7, # omit for a policy owned by the organization itself
  name: "My deployment policy",
  trigger_type: "deployment_requested",
  rules: [{ type: "environment", value: { tiers: ["production"] } }],
  actions: [{ type: "require_approval" }],
  policy_scope: { compliance_frameworks: [{ id: 5 }] },
  mode: "audit"
)

# Find a policy by ID
Gitlab::PolicyStore.find(policy.id)

# Change a policy; the version is bumped by one
Gitlab::PolicyStore.update(policy.id, name: "Renamed policy")

# List all policies for an organization
Gitlab::PolicyStore.list(organization_id: 1)

# Delete a policy
Gitlab::PolicyStore.delete(policy.id)
```

`organization_id` is the tenancy key and is required. `namespace_id` names the owning
top-level group and is optional, because a policy may be owned by the organization
itself. Neither can be changed through `update`, which raises on any attribute that is neither
updatable nor one of those known immutable ones, rather than dropping it and reporting
success. `create` does not check this yet, so it still ignores an attribute it does not
recognise.

`name` is required and unique within an organization, whether the policy is owned by a
group or by the organization itself.

`rules`, `actions`, `mode`, and `lifecycle_state` cannot be set to `nil`, because a
persistence adapter declares them `NOT NULL`. Omitting them takes their defaults on
`create` and leaves the stored value on `update`; an explicit `nil` is rejected by both.

The gem does not constrain `trigger_type`. A persistence adapter may, by mapping it onto
a column that only accepts known values, so a value this gem stores is not necessarily
one every adapter accepts.

Swap the storage backend by injecting a different repository:

```ruby
Gitlab::PolicyStore.configure do |config|
  config.repository = MyRemotePolicyRepository.new
end
```

## Scope compilation

A policy's scope is authored one of two ways:

- **Structured data in `policy_scope`**: on create,
  `Gitlab::PolicyStore::ScopeTranspiler` compiles it into `scope_rego`.
- **Rego supplied directly in `scope_rego`**: stored as authored, which always wins
  over compilation.

A policy with neither compiles to a program that applies everywhere, so `scope_rego`
is never blank after create.

`update` keeps the two forms consistent:

- **Supplying a value for one form clears the other**, matching the precedence `create`
  applies.
- **A rename regenerates a compiled program**, because the transpiler emits the policy name
  into it, but leaves an authored one alone.
- **Blanking `scope_rego`** recompiles from `policy_scope`, or widens the policy to every
  project when there is no `policy_scope` to recompile from, which is the case for a policy
  authored as Rego.
- **Blanking `policy_scope`** widens a policy compiled from it to every project, and changes
  nothing for one authored as Rego.
- **Values a change set merely restates are dropped** before any of the above is decided, so
  an update that resends a whole policy changes only what the caller actually changed.

```ruby
Gitlab::PolicyStore.create(
  organization_id: 1, name: "Framework 5 only", trigger_type: "deployment_requested",
  policy_scope: { compliance_frameworks: [{ id: 5 }] }
).scope_rego
```

```rego
package gitlab.scope

# policy "Framework 5 only" (match_mode: all)

default excluded := false

default included := false

included if {
	some framework_id in input.compliance_frameworks
	framework_id in {5}
}

default applies := false

applies if {
	not excluded
	included
}
```

The generated program is `package gitlab.scope`, per
[GOVERN-006: Policy scope as Rego and quick-check strategy](https://gitlab.com/gitlab-org/architecture/govern/design-doc/-/blob/main/decisions/006-policy-scope-rego-quick-check.md).
Its whole contract with the engine is the boolean `data.gitlab.scope.applies`, kept total
by `default applies := false` so that a context matching nothing is out of scope rather
than undefined. The `excluded` and `included` rules it is derived from, and the comment
naming the policy, are for whoever reads the stored text.

The gem compiles it. Evaluating a program against a project is the engine's job.

## Rule compilation

On create and on update, every entry in a policy's `rules` array is compiled by
`Gitlab::PolicyStore::RuleTranspiler` and the resulting program is written back to that
entry under `rego`. An update recompiles the whole array whenever `rules` is part of the
change set, and leaves the stored programs alone otherwise. It is stored per rule rather
than in a column of its own, because rules compile one program each and a policy can
carry several:

```ruby
Gitlab::PolicyStore.create(
  organization_id: 1, name: "No production deployments",
  trigger_type: "deployment_requested",
  rules: [{ type: "environment", value: { tiers: ["production"] } }]
).rules
# => [{ "type" => "environment",
#       "value" => { "tiers" => ["production"] },
#       "rego" => "package governance\n\n# rule 0: environment\n\n..." }]
```

An authored `rego` does not survive, unlike an authored `scope_rego`: it is derived from
the rule rather than authored, and a rule of type `custom` is how a program gets
hand-written. Entries are normalized to string keys, so the array a caller reads back is
the array a jsonb column would give them.

`update` keeps rule compilation consistent with `create`:

- **Supplying a changed `rules` array recompiles all of it.** Every entry runs back
  through the transpiler, the same as `create`. Resending the stored array unchanged is
  dropped as a restatement before any of this, and so is not supplying it at all, and
  both leave the stored programs alone.
- **A rename leaves a compiled program alone**, unlike a compiled `scope_rego`: a rename
  regenerates `scope_rego`, because the transpiler emits the policy name into it, but
  `RuleTranspiler` never sees the policy name, so a rename changes nothing under `rego`.
- **An authored `rego` does not survive an update either.** Resending a rule with a
  hand-written `rego` stores the compiled `package governance` program in its place, the
  same as `create`.
- **A rule that cannot compile fails the update the same way it fails a create**, naming
  the rule's index in the same message, so the policy is not stored.

The transpiler is also usable on its own, one rule at a time:

```ruby
Gitlab::PolicyStore::RuleTranspiler.new(
  { type: "environment", value: { tiers: ["production"] } },
  rule_index: 0
).transpile
# => "package governance\n\n# rule 0: environment\n\nviolation contains ..."
```

Five properties of that compilation, each of which a caller has to work with:

- **One rule in, one program out.** Each entry's `rego` carries its own `package` line,
  so `rules` is stored per rule rather than as one program per policy, and `custom` is
  stored as authored rather than reformatted. `RuleProgramMerger` combines them into one
  per-policy module, keeping a single `package governance` line and stripping it from
  every rule. That module is what the API exposes as `policy_rego`, and what a write
  supplying `rules` is measured against. A violation the transpiler emits carries its
  `rule_index` so that attribution survives a merge, since `violation` is a set and two
  rules emitting identical objects would deduplicate. A `custom` program is stored as
  authored, so only its author can do the same for it.
- **A policy still fires when any one of its rules fires**, but that OR belongs to
  whoever evaluates the programs, whether it runs each separately and concatenates the
  violations or evaluates one merged module. This is the reverse of scope compilation,
  which ANDs its criteria, because a scope narrows while a rule broadens.
- **Emitted programs are `package governance` and expose `violation`**, which is one
  of the three shapes the Policy Engine parses (`allow`, `deny[msg]`,
  `violation[{}]`). GOVERN-006 specifies `gitlab.policy` for policy evaluation;
  nothing written so far uses it, and reconciling the two is tracked separately.
- **A rule type with no emitter raises `ValidationError`**, as does a rule that could
  only compile to something inert: a freeze window with no tiers, an environment rule
  matching on nothing, or a `custom` program declaring a package other than `governance`,
  which the Policy Engine would query and find nothing in. Compilation is what stops such
  a policy from being stored, on create and on update alike. Skipping any of them would
  let a policy save, look enforcing, and enforce nothing. An empty `rules` array is not
  one of these cases: it compiles to nothing and saves.
- **Rules whose merged module exceeds `MAX_COMPILED_RULES_BYTES` are refused too**, for a
  different reason: the Policy Engine would not load a module that large, so accepting one
  would defer the failure to evaluation.
- **A `calendar` rule's raw windows are checked against that same limit before any of them
  is normalized**, since normalizing (and later emitting) each one costs far more than
  measuring their authored JSON. `RuleTranspiler` accepts the limit as `max_projected_bytes`
  rather than reading `MAX_COMPILED_RULES_BYTES` itself, so it does not depend on the
  repository layer that calls it. Through `create`/`update`, `ENTRY_SIZE_LIMIT` (a sixteenth
  of `MAX_COMPILED_RULES_BYTES`) already refuses an oversized rule first, so this check
  protects a `RuleTranspiler` used directly, outside that validation stack.
- **A `calendar` rule's windows are de-duplicated after normalization**, so two windows
  identical in name, tiers, and normalized bounds emit once. Two windows sharing only a
  name are not duplicates and both emit, since name equality alone does not mean the same
  window.

Timestamps in a `calendar` rule are normalized to UTC before being emitted, because the
generated program compares them as strings. An authored bound would otherwise sort by its
wall-clock digits rather than by the instant it denotes. Compared as a string,
`2026-12-24T00:00:00+01:00` behaves as though it were `2026-12-24T00:00:00Z`, an hour
after the `2026-12-23T23:00:00Z` it actually means, so the window would silently begin an
hour late. Normalizing every bound to `YYYY-MM-DDTHH:MM:SSZ` leaves them all fixed-width
and single-zone, so lexicographic order is chronological order. A window carrying no
offset at all is rejected, since `Time.iso8601` would read it as local time and the same
policy would then compile differently on different hosts. A bound carrying a non-zero
fraction of a second is rejected for a similar reason: keeping the fraction breaks the
ordering, because `.` sorts before `Z`, and dropping it moves the boundary by up to a
second without saying so. A zero fraction compiles, since dropping that changes no
instant. A bound naming a date or time that does not exist is refused rather than read
leniently, because `Time.iso8601` rolls an out-of-range component forward and would
otherwise compile June 31 as July 1. The accepted shape is pinned to a four-digit year, so
every emitted bound is the same width and orders against every other.

That normalization covers the authored half of the comparison only. The other half,
`input.evaluated_at`, arrives at evaluation time and has to be the literal `Z` form with no
fractional part (`2026-08-02T14:07:33Z`, the form the
[deployment context](https://gitlab.com/gitlab-org/gitlab/-/work_items/607786) declares).
The emitted program compares these as strings, so any other spelling sorts wrongly even
when it means the same instant: against a window starting `2026-12-24T00:00:00Z`, both
`2026-12-24T00:00:00+00:00` and `2026-12-24T00:00:00.000Z` denote that exact start and
neither matches it. Against the same window, an `evaluated_at` of
`2026-12-23T23:30:00-01:00` is inside it and does not match, and one of
`2026-12-24T01:00:00+02:00` is outside it and does. Worse, an `evaluated_at` that is
absent, `null`, a number, or an object produces no violation and no error, because Rego
orders across types, so the freeze window never fires at all. Neither the transpiler nor
the emitted program can tell. Whoever calls the engine owns that contract.

## Repository Contract

Any storage adapter must implement the `Gitlab::PolicyStore::Ports::PolicyRepository`
interface:

- `#create(attributes)` - Creates a new policy, returns a `Policy` value object
- `#update(id, attributes)` - Changes an existing policy and bumps its `version` by one, or returns it untouched when no supplied value differs
- `#find(id)` - Returns a `Policy` by ID, raises `NotFound` if not found
- `#delete(id)` - Deletes a policy by ID, raises `NotFound` if not found
- `#list(organization_id:, trigger_type: nil, ids: nil, offset: 0, per_page: DEFAULT_PER_PAGE)` - Returns a `Page` (`items`, `per_page`, `has_next_page?`) of an organization's policies, optionally for one trigger. When `ids` is given, returns only those ids (bypassing `offset`/`per_page`) instead of a page. Speaks offset, not page number: page-oriented callers (like the REST API) translate at their own boundary. `offset` is clamped to `MAX_OFFSET` and `per_page` to `MAX_PER_PAGE`. Carries no total count: adapters fetch one row past `per_page` to answer `has_next_page?` instead of running a separate `COUNT` query.

Every method that returns a policy returns copies of its structured attributes, so a
caller cannot reach stored data through one.

`spec/support/shared_examples/policy_repository_shared_examples.rb` is the executable
form of this contract, and every adapter runs it.
