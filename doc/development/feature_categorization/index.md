---
stage: Enablement
group: Infrastructure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Feature Categorization

> [Introduced](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/269) in GitLab 13.2.

Each Sidekiq worker, controller action, or API endpoint
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

The [Scalability
team](https://about.gitlab.com/handbook/engineering/infrastructure/team/scalability/)
currently maintains the `feature_categories.yml` file. They will automatically be
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
class Boards::ListsController < ApplicationController
  feature_category :kanban_boards
end
```

The feature category can be limited to a list of actions using the
second argument:

```ruby
class DashboardController < ApplicationController
  feature_category :issue_tracking, [:issues, :issues_calendar]
  feature_category :code_review, [:merge_requests]
end
```

These forms cannot be mixed: if a controller has more than one category,
every single action must be listed.

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

The spec also validates if the used feature categories are known. And if
the actions used in configuration still exist as routes.

## API endpoints

Grape API endpoints can use the `feature_category` class method, like
[Rails controllers](#rails-controllers) do:

```ruby
module API
  class Issues < ::API::Base
    feature_category :issue_tracking
  end
end
```

The second argument can be used to specify feature categories for
specific routes:

```ruby
module API
  class Users < ::API::Base
    feature_category :users, ['/users/:id/custom_attributes', '/users/:id/custom_attributes/:key']
  end
end
```

Or the feature category can be specified in the action itself:

```ruby
module API
  class Users < ::API::Base
    get ':id', feature_category: :users do
    end
  end
end
```

As with Rails controllers, an API class must specify the category for
every single action unless the same category is used for every action
within that class.
