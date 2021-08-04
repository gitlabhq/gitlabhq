---
type: reference, dev
stage: none
group: Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Ruby style guide

This is a GitLab-specific style guide for Ruby code.

Generally, if a style is not covered by [existing rubocop rules or styleguides](../contributing/style_guides.md#ruby-rails-rspec), it shouldn't be a blocker.
Before adding a new cop to enforce a given style, make sure to discuss it with your team.
When the style is approved by a backend EM or by a BE staff eng, add a new section to this page to
document the new rule. For every new guideline, add it in a new section and link the discussion from the section's
[version history note](../documentation/styleguide/index.md#version-text-in-the-version-history)
to provide context and serve as a reference.

Just because something is listed here does not mean it cannot be reopened for discussion.

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
