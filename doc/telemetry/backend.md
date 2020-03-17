# Backend tracking guide

GitLab provides `Gitlab::Tracking`, an interface that wraps the [Snowplow Ruby Tracker](https://github.com/snowplow/snowplow/wiki/ruby-tracker) for tracking custom events.

## Tracking in Ruby

Custom event tracking and instrumentation can be added by directly calling the `GitLab::Tracking.event` class method, which accepts the following arguments:

| argument   | type   | default value              | description |
|:-----------|:-------|:---------------------------|:------------|
| `category` | string | 'application'              | Area or aspect of the application. This could be `HealthCheckController` or `Lfs::FileTransformer` for instance. |
| `action`   | string | 'generic'                  | The action being taken, which can be anything from a controller action like `create` to something like an Active Record callback. |
| `data`     | object | {}                         | Additional data such as `label`, `property`, `value`, and `context` as described [in our Feature Instrumentation taxonomy](https://about.gitlab.com/handbook/product/feature-instrumentation/#taxonomy). These will be set as empty strings if you don't provide them. |

Tracking can be viewed as either tracking user behavior, or can be utilized for instrumentation to monitor and visual performance over time in an area or aspect of code.

For example:

```ruby
class Projects::CreateService < BaseService
  def execute
    project = Project.create(params)

    Gitlab::Tracking.event('Projects::CreateService', 'create_project',
      label: project.errors.full_messages.to_sentence,
      value: project.valid?
    )
  end
end
```

### Performance

We use the [AsyncEmitter](https://github.com/snowplow/snowplow/wiki/Ruby-Tracker#52-the-asyncemitter-class) when tracking events, which allows for instrumentation calls to be run in a background thread. This is still an active area of development.
