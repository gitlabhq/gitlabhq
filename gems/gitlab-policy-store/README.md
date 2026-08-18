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
  name: "My approval policy",
  trigger_type: "deployment_requested",
  rules: [{ type: "scan_finding" }],
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
# => "package gitlab.scope\n\napplicable := [result.policy | some result in results; result.applies]\n\n..."
```

The generated program is `package gitlab.scope`, per
[GOVERN-006: Policy scope as Rego and quick-check strategy](https://gitlab.com/gitlab-org/architecture/govern/design-doc/-/blob/main/decisions/006-policy-scope-rego-quick-check.md).
The gem compiles it. Evaluating a program against a project is the engine's job.

## Repository Contract

Any storage adapter must implement the `Gitlab::PolicyStore::Ports::PolicyRepository`
interface:

- `#create(attributes)` - Creates a new policy, returns a `Policy` value object
- `#update(id, attributes)` - Changes an existing policy and bumps its `version` by one, or returns it untouched when no supplied value differs
- `#find(id)` - Returns a `Policy` by ID, raises `NotFound` if not found
- `#delete(id)` - Deletes a policy by ID, raises `NotFound` if not found
- `#list(organization_id:, trigger_type: nil)` - Returns an organization's policies, optionally for one trigger

Every method that returns a policy returns copies of its structured attributes, so a
caller cannot reach stored data through one.

`spec/support/shared_examples/policy_repository_shared_examples.rb` is the executable
form of this contract, and every adapter runs it.
