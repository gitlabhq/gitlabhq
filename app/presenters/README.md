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

Every presenter should inherit from `Gitlab::View::Presenter::Simple`, which
provides a `.presents` the method which allows you to define an accessor for the
presented object. It also includes common helpers like `Gitlab::Routing` and
`Gitlab::Allowable`.

```ruby
class LabelPresenter < Gitlab::View::Presenter::Simple
  presents :label

  def text_color
    label.color.to_s
  end

  def to_partial_path
    'projects/labels/show'
  end
end
```

In some cases, it can be more practical to transparently delegate all missing
method calls to the presented object, in these cases, you can make your
presenter inherit from `Gitlab::View::Presenter::Delegated`:

```ruby
class LabelPresenter < Gitlab::View::Presenter::Delegated
  presents :label

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
