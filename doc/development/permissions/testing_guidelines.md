---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Testing guidelines
---

This page provides guidance on how to write policy specs for authorization
changes in GitLab.

- Unit tests live in `spec/policies/` and `ee/spec/policies/`.

## Structure

### One `describe` block per permission

Each permission should have its own `describe` block. Do not group multiple
permissions into a single block - this makes it harder to identify which
permission a failing test relates to.

```ruby
# bad - multiple permissions in one block
describe 'read and update issue' do
  it { expect_allowed(:read_issue) }
  it { expect_allowed(:update_issue) }
end

# good - one block per permission
describe 'read_issue' do
  # ...
end

describe 'update_issue' do
  # ...
end
```

### Use the policy helpers

Use `expect_allowed` and `expect_disallowed`, not `be_allowed` and `be_disallowed`.
The helpers check each permission separately and report every one that fails.
`be_allowed(:a, :b)` reports only that the whole set failed.

If one example checks several permissions, pass them to one call:

```ruby
it 'disallows all permissions' do
  expect_disallowed(:read_issue, :update_issue, :delete_issue)
end
```

### Role grants

`ee/spec/lib/authz/role_definitions_spec.rb` checks that each role in `config/authz/roles/`
gets exactly the permissions its YAML lists.
Do not repeat this check role by role in policy specs.

Instead, test what the policy adds:

- Prevents, such as licenses, feature flags, settings, visibility, feature access levels,
  archived projects, and admin mode.
- Grants outside role YAML, such as custom roles and deploy tokens.

Pair each prevent with one allowed example, so the test fails if no one holds the permission.

### Delegating policies

If a policy only delegates to another policy, check the delegation with `delegate_to`
and test only the rules the policy adds.

```ruby
it { is_expected.to delegate_to(ProjectPolicy) }
```

### Specify the subject in every block

Always define the subject explicitly inside each `describe` block using
`let_it_be`. Do not rely on a subject defined at a higher scope - this avoids
accidental test pollution and makes each block self-contained.

```ruby
# bad - subject defined at top level, shared across all blocks
let_it_be(:project) { create(:project) }

describe 'read_vulnerability' do
  # implicitly uses the project above
end

# good - subject defined inside each block
describe 'read_vulnerability' do
  let_it_be(:project) { private_project }

  where(:current_user, :allowed) do
    # ...
  end
end
```

Use a descriptively named project fixture that reflects the visibility or
state being tested (`private_project`, `public_project`, `archived_project`),
rather than a generic `project`.

## Full example

```ruby
RSpec.describe ProjectPolicy do
  describe 'write_example_feature' do
    let_it_be(:project) { private_project }

    before do
      stub_feature_flags(example_feature: true)
      stub_licensed_features(example_feature: true)
    end

    where(:current_user, :allowed) do
      ref(:owner)      | true
      ref(:reporter)   | true
      ref(:planner)    | false
      ref(:guest)      | false
      ref(:non_member) | false
    end

    with_them do
      if params[:allowed]
        it { expect_allowed(:write_example_feature) }
      else
        it { expect_disallowed(:write_example_feature) }
      end
    end

    context 'with admin mode enabled', :enable_admin_mode do
      let(:current_user) { admin }

      it { expect_allowed(:write_example_feature) }
    end

    context 'without admin mode enabled' do
      let(:current_user) { admin }

      it { expect_disallowed(:write_example_feature) }
    end

    context 'when example_feature feature flag is disabled' do
      before do
        stub_feature_flags(example_feature: false)
      end

      it { expect_disallowed(:write_example_feature) }
    end

    context 'when example_feature licensed feature is disabled' do
      before do
        stub_licensed_features(example_feature: false)
      end

      it { expect_disallowed(:write_example_feature) }
    end
  end
end
```
