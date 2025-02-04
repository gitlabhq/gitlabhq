---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Ruby style guide
---

This is a GitLab-specific style guide for Ruby code. Everything documented in this page can be [reopened for discussion](https://handbook.gitlab.com/handbook/values/#disagree-commit-and-disagree).

We use [RuboCop](../rubocop_development_guide.md) to enforce Ruby style guide rules.

Where a RuboCop rule is absent, refer to the following style guides as general guidelines to write idiomatic Ruby:

- [Ruby Style Guide](https://github.com/rubocop/ruby-style-guide).
- [Rails Style Guide](https://github.com/rubocop/rails-style-guide).
- [RSpec Style Guide](https://github.com/rubocop/rspec-style-guide).

Generally, if a style is not covered by existing RuboCop rules or the above style guides, it shouldn't be a blocker.

Some styles we have decided [no one should not have a strong opinion on](#styles-we-have-no-opinion-on).

See also:

- [Guidelines for reusing abstractions](../reusing_abstractions.md).
- [Test-specific style guides and best practices](../testing_guide/_index.md).

## Styles we have no rule for

These styles are not backed by a RuboCop rule.

For every style added to this section, link the discussion from the section's [history note](../documentation/styleguide/availability_details.md#history) to provide context and serve as a reference.

### Instance variable access using `attr_reader`

Instance variables can be accessed in a variety of ways in a class:

```ruby
# public
class Foo
  attr_reader :my_var

  def initialize(my_var)
    @my_var = my_var
  end

  def do_stuff
    puts my_var
  end
end

# private
class Foo
  def initialize(my_var)
    @my_var = my_var
  end

  private

  attr_reader :my_var

  def do_stuff
    puts my_var
  end
end

# direct
class Foo
  def initialize(my_var)
    @my_var = my_var
  end

  private

  def do_stuff
    puts @my_var
  end
end
```

Public attributes should only be used if they are accessed outside of the class.
There is not a strong opinion on what strategy is used when attributes are only
accessed internally, as long as there is consistency in related code.

### Newlines style guide

In addition to the RuboCop's `Layout/EmptyLinesAroundMethodBody` and `Cop/LineBreakAroundConditionalBlock` that enforce some newline styles, we have the following guidelines that are not backed by RuboCop.

#### Rule: separate code with newlines only to group together related logic

```ruby
# bad
def method
  issue = Issue.new

  issue.save

  render json: issue
end
```

```ruby
# good
def method
  issue = Issue.new
  issue.save

  render json: issue
end
```

#### Rule: newline before block

```ruby
# bad
def method
  issue = Issue.new
  if issue.save
    render json: issue
  end
end
```

```ruby
# good
def method
  issue = Issue.new

  if issue.save
    render json: issue
  end
end
```

##### Exception: no need for a newline when code block starts or ends right inside another code block

```ruby
# bad
def method
  if issue

    if issue.valid?
      issue.save
    end

  end
end
```

```ruby
# good
def method
  if issue
    if issue.valid?
      issue.save
    end
  end
end
```

## Avoid ActiveRecord callbacks

[ActiveRecord callbacks](https://guides.rubyonrails.org/active_record_callbacks.html) allow
you to "trigger logic before or after an alteration of an object's state."

Use callbacks when no superior alternative exists, but employ them only if you
thoroughly understand the reasons for doing so.

When adding new lifecycle events for ActiveRecord objects, it is preferable to
add the logic to a service class instead of a callback.

## Why callbacks should be avoided

In general, callbacks should be avoided because:

- Callbacks are hard to reason about because invocation order is not obvious and
  they break code narrative.
- Callbacks are harder to locate and navigate because they rely on reflection to
  trigger rather than being ordinary method calls.
- Callbacks make it difficult to apply changes selectively to an object's state
  because changes always trigger the entire callback chain.
- Callbacks trap logic in the ActiveRecord class. This tight coupling encourages
  fat models that contain too much business logic, which could instead live in
  service objects that are more reusable, composable, and are easier to test.
- Illegal state transitions of an object can be better enforced through
  attribute validations.
- Heavy use of callbacks affects factory creation speed. With some classes
  having hundreds of callbacks, creating an instance of that object for
  an automated test can be a very slow operation, resulting in slow specs.

Some of these examples are discussed in this [video from thoughtbot](https://www.youtube.com/watch?v=GLBMfB8N1G8).

The GitLab codebase relies heavily on callbacks and it is hard to refactor them
once added due to invisible dependencies. As a result, this guideline does not
call for removing all existing callbacks.

### When to use callbacks

Callbacks can be used in special cases. Some examples of cases where adding a
callback makes sense:

- A dependency uses callbacks and we would like to override the callback
  behavior.
- Incrementing cache counts.
- Data normalization that only relates to data on the current model.

### Example of moving from a callback to a service

There is a project with the following basic data model:

```ruby
class Project
  has_one :repository
end

class Repository
  belongs_to :project
end
```

Say we want to create a repository after a project is created and use the
project name as the repository name. A developer familiar with Rails might
immediately think: sounds like a job for an ActiveRecord callback! And add this
code:

```ruby
class Project
  has_one :repository

  after_initialize :create_random_name
  after_create :create_repository

  def create_random_name
    SecureRandom.alphanumeric
  end

  def create_repository
    Repository.create!(project: self)
  end
end

class Repository
  after_initialize :set_name

  def set_name
    name = project.name
  end
end

class ProjectsController
  def create
    Project.create! # also creates a repository and names it
  end
end
```

While this seems pretty harmless for a baby Rails app, adding this type of logic
via callbacks has many downsides once your Rails app becomes large and complex
(all of which are listed in this documentation). Instead, we can add this
logic to a service class:

```ruby
class Project
  has_one :repository
end

class Repository
  belongs_to :project
end

class ProjectCreator
  def self.execute
    ApplicationRecord.transaction do
      name = SecureRandom.alphanumeric
      project = Project.create!(name: name)
      Repository.create!(project: project, name: name)
    end
  end
end

class ProjectsController
  def create
    ProjectCreator.execute
  end
end
```

With an application this simple, it can be hard to see the benefits of the second
approach. But we already some benefits:

- Can test `Repository` creation logic separate from `Project` creation logic. Code
  no longer violates law of demeter (`Repository` class doesn't need to know
  `project.name`).
- Clarity of invocation order.
- Open to change: if we decide there are some scenarios where we do not want a
  repository created for a project, we can create a new service class rather
  than needing to refactor to `Project` and `Repository` classes.
- Each instance of a `Project` factory does not create a second (`Repository`) object.

## Styles we have no opinion on

If a RuboCop rule is proposed and we choose not to add it, we should document that decision in this guide so it is more discoverable and link the relevant discussion as a reference.

### Quoting string literals

Due to the sheer amount of work to rectify, we do not care whether string
literals are single or double-quoted.

Previous discussions include:

- <https://gitlab.com/gitlab-org/gitlab-foss/-/issues/44234>
- <https://gitlab.com/gitlab-org/gitlab-foss/-/issues/36076>
- <https://gitlab.com/gitlab-org/gitlab/-/issues/198046>

### Type safety

Now that we've upgraded to Ruby 3, we have more options available
to enforce [type safety](https://en.wikipedia.org/wiki/Type_safety).

Some of these options are supported as part of the Ruby syntax and do not require the use of specific type safety tools like [Sorbet](https://sorbet.org/) or [RBS](https://github.com/ruby/rbs). However, we might consider these tools in the future as well.

For more information, see [Type safety](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/lib/remote_development#type-safety) in the `remote_development` domain README.

### Functional patterns

Although Ruby and especially Rails are primarily based on [object-oriented programming](https://en.wikipedia.org/wiki/Object-oriented_programming) patterns, Ruby is a very flexible language and supports [functional programming](https://en.wikipedia.org/wiki/Functional_programming) patterns as well.

Functional programming patterns, especially in domain logic, can often result in more readable, maintainable, and bug-resistant code while still using idiomatic and familiar Ruby patterns.
However, functional programming patterns should be used carefully because some patterns would cause confusion and should be avoided even if they're directly supported by Ruby. The [`curry` method](https://www.rubydoc.info/stdlib/core/Method:curry) is a likely example.

For more information, see:

- [Functional patterns](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/lib/remote_development#functional-patterns)
- [Railway-oriented programming and the `Result` class](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/lib/remote_development#railway-oriented-programming-and-the-result-class)
