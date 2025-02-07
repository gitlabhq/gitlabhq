---
stage: Systems
group: Distribution
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Application limits development
---

This document provides a development guide for contributors to add application
limits to GitLab.

## Documentation

First of all, you have to gather information and decide which are the different
limits that are set for the different GitLab tiers. Coordinate with others to [document](../administration/instance_limits.md)
and communicate those limits.

There is a guide about [introducing application limits](https://handbook.gitlab.com/handbook/product/product-processes/#introducing-application-limits).

## Implement plan limits

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
   desired limit using the `create_or_update_plan_limit` migration helper.
   The plans in this migration should match the [plans on GitLab.com](#subscription-plans).
   If a plan is missed, customers on that plan would receive the default limit, which might be
   `0` (unlimited).

   For example:

   ```ruby
   class InsertProjectHooksPlanLimits < Gitlab::Database::Migration[2.1]
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
       create_or_update_plan_limit('project_hooks', 'ultimate_trial_paid_customer', 100)
       create_or_update_plan_limit('project_hooks', 'opensource', 100)
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
       create_or_update_plan_limit('project_hooks', 'ultimate_trial_paid_customer', 0)
       create_or_update_plan_limit('project_hooks', 'opensource', 0)
     end
   end
   ```

   Some plans exist only on GitLab.com. This is a no-op for plans
   that do not exist.

   To set limits in your migration only for GitLab.com and allow other instances
   to use the default limits, add `return unless Gitlab.com?` to the start of
   the `#up` and `#down` methods to make the migration a no-op for other instances.

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
- `silver`: Namespaces and projects with a Premium subscription. This tier is no longer available for purchase.
- `premium`: Namespaces and projects with a Premium subscription.
- `premium_trial`: Namespaces and projects with a Premium Trial subscription.
- `gold`: Namespaces and projects with an Ultimate subscription. This tier is no longer available for purchase.
- `ultimate`: Namespaces and projects with an Ultimate subscription.
- `ultimate_trial`: Namespaces and projects with an Ultimate Trial subscription.
- `ultimate_trial_paid_customer`: Namespaces and projects on a Premium subscription that are trialling Ultimate for 30 days.
- `opensource`: Namespaces and projects that are member of GitLab Open Source program.

There is an `early_adopter` plan on GitLab.com that has no subscriptions.

The `test` environment doesn't have any plans.

## Implement rate limits using `Rack::Attack`

We use the [`Rack::Attack`](https://github.com/rack/rack-attack) middleware to throttle Rack requests.
This applies to Rails controllers, Grape endpoints, and any other Rack requests.

The process for adding a new throttle is loosely:

1. Add new fields to the [rate_limits JSONB column](https://gitlab.com/gitlab-org/gitlab/-/blob/63b37287ae028842fcdcf56d311e6bb0c7e09e79/app/models/application_setting.rb#L603)
   in the `ApplicationSetting` model.
1. Update the JSON schema validator for the [rate_limits column](https://gitlab.com/gitlab-org/gitlab/-/blob/63b37287ae028842fcdcf56d311e6bb0c7e09e79/app/validators/json_schemas/application_setting_rate_limits.json).
1. Extend `Gitlab::RackAttack` and `Gitlab::RackAttack::Request` to configure the new rate limit,
   and apply it to the desired requests.
1. Add the new settings to the **Admin** area form in `app/views/admin/application_settings/_ip_limits.html.haml`.
1. Document the new settings in [User and IP rate limits](../administration/settings/user_and_ip_rate_limits.md) and [Application settings API](../api/settings.md).
1. Configure the rate limit for GitLab.com and document it in [GitLab.com-specific rate limits](../user/gitlab_com/_index.md#gitlabcom-specific-rate-limits).

Refer to these past issues for implementation details:

- [Create a separate rate limit for the Files API](https://gitlab.com/gitlab-org/gitlab/-/issues/335075).
- [Create a separate rate limit for unauthenticated API traffic](https://gitlab.com/gitlab-org/gitlab/-/issues/335300).

## Implement rate limits using `Gitlab::ApplicationRateLimiter`

This module implements a custom rate limiter that can be used to throttle
certain actions. Unlike `Rack::Attack` and `Rack::Throttle`, which operate at
the middleware level, this can be used at the controller or API level.

See the `CheckRateLimit` concern for use in controllers. In other parts of the code
the `Gitlab::ApplicationRateLimiter` module can be called directly.

## Next rate limiting architecture

In May 2022 we've started working on the next iteration of our application
limits framework using a forward looking rate limiting architecture.

We are working on defining new requirements and designing the next
architecture, so if you need new functionalities to add new limits, instead of
building them right now, consider contributing to the
[Rate Limiting Architecture Working Group](https://handbook.gitlab.com/handbook/company/working-groups/rate-limit-architecture/)

Examples of what features we might want to build into the next iteration of
rate limiting architecture:

1. Making it possible to define and override limits per namespace / per plan.
1. Automatically generating documentation about what limits are implemented and
   what the defaults are.
1. Defining limits in a single place that can be found and explored.
1. Soft and hard limits, with support for notifying users when a limit is
   approaching.
