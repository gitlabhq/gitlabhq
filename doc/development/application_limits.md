---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Application limits development

This document provides a development guide for contributors to add application
limits to GitLab.

## Documentation

First of all, you have to gather information and decide which are the different
limits that are set for the different GitLab tiers. You also need to
coordinate with others to [document](../administration/instance_limits.md)
and communicate those limits.

There is a guide about [introducing application
limits](https://about.gitlab.com/handbook/product/product-processes/#introducing-application-limits).

## Development

### Insert database plan limits

In the `plan_limits` table, create a new column and insert the limit values.
It's recommended to create two separate migration script files.

1. Add a new column to the `plan_limits` table with non-null default value that
   represents desired limit, such as:

   ```ruby
   add_column(:plan_limits, :project_hooks, :integer, default: 100, null: false)
   ```

   Plan limits entries set to `0` mean that limits are not enabled. You should
   use this setting only in special and documented circumstances.

1. (Optionally) Create the database migration that fine-tunes each level with a
   desired limit using `create_or_update_plan_limit` migration helper, such as:

   ```ruby
   class InsertProjectHooksPlanLimits < ActiveRecord::Migration[5.2]
     include Gitlab::Database::MigrationHelpers

     def up
       create_or_update_plan_limit('project_hooks', 'default', 0)
       create_or_update_plan_limit('project_hooks', 'free', 10)
       create_or_update_plan_limit('project_hooks', 'bronze', 20)
       create_or_update_plan_limit('project_hooks', 'silver', 30)
       create_or_update_plan_limit('project_hooks', 'premium', 30)
       create_or_update_plan_limit('project_hooks', 'premium_trial', 30)
       create_or_update_plan_limit('project_hooks', 'gold', 100)
       create_or_update_plan_limit('project_hooks', 'ultimate', 100)
       create_or_update_plan_limit('project_hooks', 'ultimate_trial', 100)
     end

     def down
       create_or_update_plan_limit('project_hooks', 'default', 0)
       create_or_update_plan_limit('project_hooks', 'free', 0)
       create_or_update_plan_limit('project_hooks', 'bronze', 0)
       create_or_update_plan_limit('project_hooks', 'silver', 0)
       create_or_update_plan_limit('project_hooks', 'premium', 0)
       create_or_update_plan_limit('project_hooks', 'premium_trial', 0)
       create_or_update_plan_limit('project_hooks', 'gold', 0)
       create_or_update_plan_limit('project_hooks', 'ultimate', 0)
       create_or_update_plan_limit('project_hooks', 'ultimate_trial', 0)
     end
   end
   ```

   Some plans exist only on GitLab.com. This is a no-op for plans
   that do not exist.

### Plan limits validation

#### Get current limit

Access to the current limit can be done through the project or the namespace,
such as:

```ruby
project.actual_limits.project_hooks
```

#### Check current limit

There is one method `PlanLimits#exceeded?` to check if the current limit is
being exceeded. You can use either an `ActiveRecord` object or an `Integer`.

Ensures that the count of the records does not exceed the defined limit, such as:

```ruby
project.actual_limits.exceeded?(:project_hooks, ProjectHook.where(project: project))
```

Ensures that the number does not exceed the defined limit, such as:

```ruby
project.actual_limits.exceeded?(:project_hooks, 10)
```

#### `Limitable` concern

The [`Limitable` concern](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/concerns/limitable.rb)
can be used to validate that a model does not exceed the limits. It ensures
that the count of the records for the current model does not exceed the defined
limit.

You must specify the limit scope of the object being validated
and the limit name if it's different from the pluralized model name.

```ruby
class ProjectHook
  include Limitable

  self.limit_name = 'project_hooks' # Optional as ProjectHook corresponds with project_hooks
  self.limit_scope = :project
end
```

To test the model, you can include the shared examples.

```ruby
it_behaves_like 'includes Limitable concern' do
  subject { build(:project_hook, project: create(:project)) }
end
```

### Testing instance-wide limits

Instance-wide features always use `default` Plan, as instance-wide features
do not have license assigned.

```ruby
class InstanceVariable
  include Limitable

  self.limit_name = 'instance_variables' # Optional as InstanceVariable corresponds with instance_variables
  self.limit_scope = Limitable::GLOBAL_SCOPE
end
```

### Subscription Plans

Self-managed:

- `default`: Everyone.

GitLab.com:

- `default`: Any system-wide feature.
- `free`: Namespaces and projects with a Free subscription.
- `bronze`: Namespaces and projects with a Bronze subscription. This tier is no longer available for purchase.
- `silver`: Namespaces and projects with a Premium subscription.
- `premium`: Namespaces and projects with a Premium subscription.
- `premium_trial`: Namespaces and projects with a Premium Trial subscription.
- `gold`: Namespaces and projects with an Ultimate subscription.
- `ultimate`: Namespaces and projects with an Ultimate subscription.
- `ultimate_trial`: Namespaces and projects with an Ultimate Trial subscription.

The `test` environment doesn't have any plans.
