# Presenters

This type of class is responsible for giving the view an object which defines
**view-related logic/data methods**. It is usually useful to extract such
methods from models to presenters.

## When to use a presenter?

### When your view is full of logic

When your view is full of logic (`if`, `else`, `select` on arrays etc.), it's time
to create a presenter!

For instance this view is full of logic: https://gitlab.com/gitlab-org/gitlab-ce/blob/d61f8a18e0f7e9d0ed162827f4e8ae2de3756f5c/app/views/projects/builds/_sidebar.html.haml
can be improved as follows: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/7073/diffs

### When your model has a lot of view-related logic/data methods

When your model has a lot of view-related logic/data methods, you can easily
move them to a presenter.

## Why using presenters instead of helpers?

We don't use presenters to generate complex view output that would rely on helpers.

Presenters should be used for:

- Data and logic methods that can be pulled & combined into single methods from
  view. This can include loops extracted from views too. A good example is
  https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/7073/diffs.
- Data and logic methods that can be pulled from models
- Simple text output methods: it's ok if the method returns a string, but not a
  whole DOM element for which we'd need HAML, a view context, helpers etc.

## Why using presenters instead of model concerns?

We should strive to follow the single-responsibility principle, and view-related
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
- makes the testing easier & faster as presenters are Plain Old Ruby Object (PORO)
- makes views much more readable and maintainable
- decreases number of CE -> EE merge conflicts since code is in separate files
- moves the conflicts from views (not always obvious) to presenters (a lot easier to resolve)

## What not to do with presenters?

- Don't use helpers in presenters. Presenters are not aware of the view context.
- Don't generate complex DOM elements, forms etc. with presenters. Presenters
  can return simple data as texts, and URL using URL helpers from
  `Gitlab::Routing` but nothing much more fancy.

## Implementation

### Presenter definition

Every presenters should include `Gitlab::View::Presenter`, which provides a
`.presents` method which allows you to define an accessor for the presented
object. It also includes common helpers like `Gitlab::Routing` and
`Gitlab::Allowable`.

```ruby
class LabelPresenter
  include Gitlab::View::Presenter

  presents :label

  def blue?
    label.color == :blue
  end

  def to_partial_path
    'projects/labels/show'
  end
end
```

In some cases, it can be more practical to transparently delegates all missing
method calls to the presented object, in these cases, you can make your
presenter inherit from `SimpleDelegator`:

```ruby
class LabelPresenter < SimpleDelegator
  include Gitlab::View::Presenter

  presents :label

  def blue?
    # color is delegated to label
    color == :blue
  end

  def to_partial_path
    'projects/labels/show'
  end
end
```

### Presenter instantiation

Instantiation must be done via the `Gitlab::View::PresenterFactory` class which
handles presenters subclassing `SimpleDelegator` as well as those who don't.

```ruby
class Projects::LabelsController < Projects::ApplicationController
  def edit
    @label = Gitlab::View::PresenterFactory
      .new(@label, user: current_user)
      .fabricate!
  end
end
```

You can also define a method on the model:

```ruby
class Label
  def present(current_user)
    Gitlab::View::PresenterFactory
      .new(self, user: current_user)
      .fabricate!
  end
end
```

and then in the controller:

```ruby
class Projects::LabelsController < Projects::ApplicationController
  def edit
    @label = @label.present(current_user)
  end
end
```

### Presenter usage

```ruby
= @label.blue?

= render partial: @label, label: @label
```

You can also present the model in the view:

```ruby
- label = @label.present(current_user)

= render partial: label, label: label
```
