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
permissions into a single block — this makes it harder to identify which
permission a failing test relates to.

```ruby
# bad - multiple permissions in one block
describe 'read and update issue' do
  it { is_expected.to be_allowed(:read_issue, :update_issue) }
end

# good - one block per permission
describe 'read_issue' do
  # ...
end

describe 'update_issue' do
  # ...
end
```

### Use table syntax for role-based checks

Use `where` table syntax to test each role explicitly. This makes it immediately
clear which roles are expected to have access and which are not, and avoids
repetitive `it` blocks.

```ruby
describe 'read_vulnerability' do
  where(:current_user, :allowed) do
    ref(:guest)      | false
    ref(:planner)    | false
    ref(:reporter)   | false
    ref(:developer)  | true
    ref(:maintainer) | true
    ref(:auditor)    | false
    ref(:owner)      | true
    ref(:admin)      | true
  end
end
```

Always include every role in the table — do not omit roles that are expected
to be disallowed. Explicit `false` values are as important as `true` values
because they document the intended access boundary.

### Specify the subject in every block

Always define the subject explicitly inside each `describe` block using
`let_it_be`. Do not rely on a subject defined at a higher scope — this avoids
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
  describe 'write_ai_agents' do
    let_it_be(:project) { private_project }

    before do
      stub_feature_flags(agent_registry: true)
      stub_licensed_features(ai_agents: true)
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
        it { expect_allowed(:write_ai_agents) }
      else
        it { expect_disallowed(:write_ai_agents) }
      end
    end

    context 'with admin mode enabled', :enable_admin_mode do
      let(:current_user) { admin }

      it { expect_allowed(:write_ai_agents) }
    end

    context 'without admin mode enabled' do
      let(:current_user) { admin }

      it { expect_disallowed(:write_ai_agents) }
    end

    context 'when agent_registry feature flag is disabled' do
      before do
        stub_feature_flags(agent_registry: false)
      end

      it { expect_disallowed(:write_ai_agents) }
    end

    context 'when ai_agents licensed feature is disabled' do
      before do
        stub_licensed_features(ai_agents: false)
      end

      it { expect_disallowed(:write_ai_agents) }
    end
  end
end
```
