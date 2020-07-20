# Feature Categorization

> [Introduced](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/269) in GitLab 13.2.

Each Sidekiq worker, controller action, or (eventually) API endpoint
must declare a `feature_category` attribute. This attribute maps each
of these to a [feature
category](https://about.gitlab.com/handbook/product/product-categories/). This
is done for error budgeting, alert routing, and team attribution.

The list of feature categories can be found in the file `config/feature_categories.yml`.
This file is generated from the
[`stages.yml`](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml)
data file used in the GitLab Handbook and other GitLab resources.

## Updating `config/feature_categories.yml`

Occasionally new features will be added to GitLab stages, groups, and
product categories. When this occurs, you can automatically update
`config/feature_categories.yml` by running
`scripts/update-feature-categories`. This script will fetch and parse
[`stages.yml`](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml)
and generate a new version of the file, which needs to be committed to
the repository.

The [Scalabilitity
team](https://about.gitlab.com/handbook/engineering/infrastructure/team/scalability)
currently maintains the `stages.yml` file. They will automatically be
notified on Slack when the file becomes outdated.

## Sidekiq workers

The declaration uses the `feature_category` class method, as shown below.

```ruby
class SomeScheduledTaskWorker
  include ApplicationWorker

  # Declares that this worker is part of the
  # `continuous_integration` feature category
  feature_category :continuous_integration

  # ...
end
```

The feature categories specified using `feature_category` should be
defined in
[`config/feature_categories.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/feature_categories.yml). If
not, the specs will fail.

### Excluding Sidekiq workers from feature categorization

A few Sidekiq workers, that are used across all features, cannot be mapped to a
single category. These should be declared as such using the `feature_category_not_owned!`
declaration, as shown below:

```ruby
class SomeCrossCuttingConcernWorker
  include ApplicationWorker

  # Declares that this worker does not map to a feature category
  feature_category_not_owned!

  # ...
end
```

## Rails controllers

Specifying feature categories on controller actions can be done using
the `feature_category` class method.

A feature category can be specified on an entire controller
using:

```ruby
class Projects::MergeRequestsController < ApplicationController
  feature_category :source_code_management
end
```

The feature category can be limited to a list of actions using the
`only` argument, actions can be excluded using the `except` argument.

```ruby
class Projects::MergeRequestsController < ApplicationController
  feature_category :code_testing, only: [:metrics_reports]
  feature_category :source_code_management, except: [:test_reports, :coverage_reports]
end
```

`except` and `only` arguments can not be combined.

When specifying `except` all other actions will get the specified
category assigned.

The assignment can also be scoped using `if` and `unless` procs:

```ruby
class Projects::MergeRequestsController < ApplicationController
  feature_category :source_code_management,
                   unless: -> (action) { action.include?("reports") }
                   if: -> (action) { action.include?("widget") }
end
```

In this case, both procs need to be satisfied for the action to get
the category assigned.

### Excluding controller actions from feature categorization

In the rare case an action cannot be tied to a feature category this
can be done using the `not_owned` feature category.

```ruby
class Admin::LogsController < ApplicationController
  feature_category :not_owned
end
```

### Ensuring feature categories are valid

The `spec/controllers/every_controller_spec.rb` will iterate over all
defined routes, and check the controller to see if a category is
assigned to all actions.

The spec also validates if the used feature categories are known. And
if the actions used in `only` and `except` configuration still exist
as routes.
