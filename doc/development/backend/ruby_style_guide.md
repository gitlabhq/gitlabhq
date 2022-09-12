---
type: reference, dev
stage: none
group: Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Ruby style guide

This is a GitLab-specific style guide for Ruby code.

Generally, if a style is not covered by [existing RuboCop rules or style guides](../contributing/style_guides.md#ruby-rails-rspec), it shouldn't be a blocker.
Before adding a new cop to enforce a given style, make sure to discuss it with your team.
When the style is approved by a backend EM or by a BE staff eng, add a new section to this page to
document the new rule. For every new guideline, add it in a new section and link the discussion from the section's
[version history note](../documentation/versions.md#add-a-version-history-item)
to provide context and serve as a reference.

See also [guidelines for reusing abstractions](../reusing_abstractions.md).

Everything listed here can be [reopened for discussion](https://about.gitlab.com/handbook/values/#disagree-commit-and-disagree).

## Instance variable access using `attr_reader`

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

## Newlines style guide

This style guide recommends best practices for newlines in Ruby code.

### Rule: separate code with newlines only to group together related logic

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

### Rule: separate code and block with newlines

#### Newline before block

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

### Rule: Newline after block

```ruby
# bad
def method
  if issue.save
    issue.send_email
  end
  render json: issue
end
```

```ruby
# good
def method
  if issue.save
    issue.send_email
  end

  render json: issue
end
```

#### Exception: no need for newline when code block starts or ends right inside another code block

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
