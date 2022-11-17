---
type: reference, dev
stage: none
group: Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Ruby style guide

This is a GitLab-specific style guide for Ruby code. Everything documented in this page can be [reopened for discussion](https://about.gitlab.com/handbook/values/#disagree-commit-and-disagree).

We use [RuboCop](../rubocop_development_guide.md) to enforce Ruby style guide rules.

Where a RuboCop rule is absent, refer to the following style guides as general guidelines to write idiomatic Ruby:

- [Ruby Style Guide](https://github.com/rubocop/ruby-style-guide).
- [Rails Style Guide](https://github.com/rubocop/rails-style-guide).
- [RSpec Style Guide](https://github.com/rubocop/rspec-style-guide).

Generally, if a style is not covered by existing RuboCop rules or the above style guides, it shouldn't be a blocker.

Some styles we have decided [no one should not have a strong opinion on](#styles-we-have-no-opinion-on).

See also:

- [Guidelines for reusing abstractions](../reusing_abstractions.md).
- [Test-specific style guides and best practices](../testing_guide/index.md).

## Styles we have no rule for

These styles are not backed by a RuboCop rule.

For every style added to this section, link the discussion from the section's [version history note](../documentation/versions.md#add-a-version-history-item) to provide context and serve as a reference.

### Instance variable access using `attr_reader`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/52351) in GitLab 14.1.

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

In addition to the RuboCops `Layout/EmptyLinesAroundMethodBody` and `Cop/LineBreakAroundConditionalBlock` that enforce some newline styles, we have the following guidelines that are not backed by RuboCop.

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

## Styles we have no opinion on

If a RuboCop rule is proposed and we choose not to add it, we should document that decision in this guide so it is more discoverable and link the relevant discussion as a reference.

### Quoting string literals

Due to the sheer amount of work to rectify, we do not care whether string
literals are single or double-quoted.

Previous discussions include:

- <https://gitlab.com/gitlab-org/gitlab-foss/-/issues/44234>
- <https://gitlab.com/gitlab-org/gitlab-foss/-/issues/36076>
- <https://gitlab.com/gitlab-org/gitlab/-/issues/198046>
