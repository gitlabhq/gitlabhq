# Presenters

This type of class is responsible for giving the view an object which defines
**view-related logic/data methods**. It is usually useful to extract such
methods from models to presenters.

## When to use a presenter?

### When your view is full of logic

When your view is full of logic (`if`, `else`, `select` on arrays, etc.), it's
time to create a presenter!

### When your model has a lot of view-related logic/data methods

When your model has a lot of view-related logic/data methods, you can easily
move them to a presenter.

## Why are we using presenters instead of helpers?

We don't use presenters to generate complex view output that would rely on helpers.

Presenters should be used for:

- Data and logic methods that can be pulled & combined into single methods from
  view. This can include loops extracted from views too. A good example is
  https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/7073/diffs.
- Data and logic methods that can be pulled from models.
- Simple text output methods: it's ok if the method returns a string, but not a
  whole DOM element for which we'd need HAML, a view context, helpers, etc.

## Why use presenters instead of model concerns?

We should strive to follow the single-responsibility principle and view-related
logic/data methods are definitely not the responsibility of models!

Another reason is as follows:

> Avoid using concerns and use presenters instead. Why? After all, concerns seem
to be a core part of Rails and can DRY up code when shared among multiple models.
Nonetheless, the main issue is that concerns don’t make the model object more
cohesive. The code is just better organized. In other words, there’s no real
change to the API of the model.

– https://www.toptal.com/ruby-on-rails/decoupling-rails-components

## Benefits

By moving pure view-related logic/data methods from models & views to presenters,
we gain the following benefits:

- rules are more explicit and centralized in the presenter => improves security
- testing is easier and faster as presenters are Plain Old Ruby Object (PORO)
- views are more readable and maintainable
- decreases the number of CE -> EE merge conflicts since code is in separate files
- moves the conflicts from views (not always obvious) to presenters (a lot easier to resolve)

## What not to do with presenters?

- Don't use helpers in presenters. Presenters are not aware of the view context.
- Don't generate complex DOM elements, forms, etc. with presenters. Presenters
  can return simple data like texts, and URLs using URL helpers from
  `Gitlab::Routing` but nothing much fancier.

## Implementation

### Presenter definition

If you need a presenter class that has only necessary interfaces for the view-related context,
inherit from `Gitlab::View::Presenter::Simple`.

It provides a `.presents` class method which allows you to define the class the presenter is wrapping,
and specify an accessor for the presented object using the `as:` keyword.

It also includes common helpers like `Gitlab::Routing` and `Gitlab::Allowable`.

```ruby
class LabelPresenter < Gitlab::View::Presenter::Simple
  presents ::Label, as: :label

  def text_color
    label.color.to_s
  end

  def to_partial_path
    'projects/labels/show'
  end
end
```

If you need a presenter class that delegates missing method calls to the presented object,
inherit from `Gitlab::View::Presenter::Delegated`.
This is more like an "extension" in the sense that the produced object is going to have
all of interfaces of the presented object **AND** all of the interfaces in the presenter class:

```ruby
class LabelPresenter < Gitlab::View::Presenter::Delegated
  presents ::Label, as: :label

  def text_color
    # color is delegated to label
    color.to_s
  end

  def to_partial_path
    'projects/labels/show'
  end
end
```

### Presenter instantiation

Instantiation must be done via the `Gitlab::View::Presenter::Factory` class which
detects the presenter based on the presented subject's class.

```ruby
class Projects::LabelsController < Projects::ApplicationController
  def edit
    @label = Gitlab::View::Presenter::Factory
      .new(@label, current_user: current_user)
      .fabricate!
  end
end
```

You can also include the `Presentable` concern in the model:

```ruby
class Label
  include Presentable
end
```

and then in the controller:

```ruby
class Projects::LabelsController < Projects::ApplicationController
  def edit
    @label = @label.present(current_user: current_user)
  end
end
```

### Presenter usage

```ruby
%div{ class: @label.text_color }
  = render partial: @label, label: @label
```

You can also present the model in the view:

```ruby
- label = @label.present(current_user: current_user)

%div{ class: label.text_color }
  = render partial: label, label: label
```

### Validate accidental overrides

We use presenters in many places, such as Controller, Haml, GraphQL/Rest API,
it's very handy to extend the core/backend logic of Active Record models,
however, there is a risk that it accidentally overrides important logic.

For example, [this production incident](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/5498)
was caused by [including `ActionView::Helpers::UrlHelper` in a presenter](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/69537/diffs#4b581cff00ef3cc9780efd23682af383de302e7d_3_3).
The `tag` accessor in `Ci::Build` was accidentally overridden by `ActionView::Helpers::TagHelper#tag`,
and as a consequence, a wrong `tag` value was persisted into database.

Starting from GitLab 14.4, we [validate](../../lib/gitlab/utils/delegator_override/validator.rb) the presenters (specifically all of the subclasses of `Gitlab::View::Presenter::Delegated`)
that they do not accidentally override core/backend logic. In such case, a pipeline in merge requests fails with an error message,
here is an example:

```plaintext
We've detected that a presenter is overriding a specific method(s) on a subject model.
There is a risk that it accidentally modifies the backend/core logic that leads to production incident.
Please follow https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/presenters/README.md#validate-accidental-overrides
to resolve this error with caution.

Here are the conflict details.

- Ci::PipelinePresenter#tag is overriding Ci::Pipeline#tag. delegator_location: /devkitkat/services/rails/cache/ruby/2.7.0/gems/actionview-6.1.3.2/lib/action_view/helpers/tag_helper.rb:271 original_location: /devkitkat/services/rails/cache/ruby/2.7.0/gems/activemodel-6.1.3.2/lib/active_model/attribute_methods.rb:254
```

Here are the potential solutions:

- If the conflict happens on an instance method in the presenter:
  - If you intend to override the core/backend logic, define `delegator_override <method-name>` on top of the conflicted method.
    This explicitly adds the method to an allowlist.
  - If you do NOT intend to override the core/backend logic, rename the method name in the presenter.
- If the conflict happens on an included module in the presenter, remove the module from the presenter and find a workaround.

### How to use the `Gitlab::Utils::DelegatorOverride` validator

If a presenter class inherits from `Gitlab::View::Presenter::Delegated`,
you should define what object class is presented:

```ruby
class WebHookLogPresenter < Gitlab::View::Presenter::Delegated
  presents ::WebHookLog, as: :web_hook_log            # This defines that the presenter presents `WebHookLog` Active Record model.
```

These presenters are validated not to accidentally override the methods in the presented object.
You can run the validation locally with:

```shell
bundle exec rake lint:static_verification
```

To add a method to an allowlist, use `delegator_override`. For example:

```ruby
class VulnerabilityPresenter < Gitlab::View::Presenter::Delegated
  presents ::Vulnerability, as: :vulnerability

  delegator_override :description                 # This adds the `description` method to an allowlist that the override is intentional.
  def description
    vulnerability.description || finding.description
  end
```

To add methods of a module to an allowlist, use `delegator_override_with`. For example:

```ruby
module Ci
  class PipelinePresenter < Gitlab::View::Presenter::Delegated
    include ActionView::Helpers::TagHelper

    delegator_override_with ActionView::Helpers::TagHelper # TODO: Remove `ActionView::Helpers::TagHelper` inclusion as it overrides `Ci::Pipeline#tag`
```

Read the [Validate Accidental Overrides](#validate-accidental-overrides) for more information.
