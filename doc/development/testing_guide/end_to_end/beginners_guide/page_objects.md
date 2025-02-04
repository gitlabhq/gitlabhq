---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Page objects in GitLab QA
---

In GitLab QA we are using a known pattern, called _Page Objects_.

This means that we have built an abstraction for all pages in GitLab that we use
to drive GitLab QA scenarios. Whenever we do something on a page, like filling
in a form or selecting a button, we do that only through a page object
associated with this area of GitLab.

For example, when GitLab QA test harness signs in into GitLab, it needs to fill
in user login and user password. To do that, we have a class, called
`Page::Main::Login` and `sign_in_using_credentials` methods, that is the only
piece of the code, that reads the `user-login` and `user-password`
fields.

## Why do we need that?

We need page objects because we need to reduce duplication and avoid problems
whenever someone changes some selectors in the GitLab source code.

Imagine that we have a hundred specs in GitLab QA, and we need to sign in to
GitLab each time, before we make assertions. Without a page object, one would
need to rely on volatile helpers or invoke Capybara methods directly. Imagine
invoking `fill_in 'user-login'` in every `*_spec.rb` file / test example.

When someone later changes `t.text_field 'login'` in the view associated with
this page to `t.text_field 'username'` it generates a different field
identifier, what would effectively break all tests.

Because we are using `Page::Main::Login.perform(&:sign_in_using_credentials)`
everywhere, when we want to sign in to GitLab, the page object is the single
source of truth, and we must update `fill_in 'user-login'`
to `fill_in 'user-username'` only in one place.

## What problems did we have in the past?

We do not run QA tests for every commit, because of performance reasons, and
the time it would take to build packages and test everything.

That is why when someone changes `t.text_field 'login'` to
`t.text_field 'username'` in the _new session_ view we don't know about this
change until our GitLab QA nightly pipeline fails, or until someone triggers
`package-and-qa` action in their merge request.

Such a change would break all tests. We call this problem a _fragile
tests problem_.

To make GitLab QA more reliable and robust, we had to solve this
problem by introducing coupling between GitLab CE / EE views and GitLab QA.

## How did we solve fragile tests problem?

Currently, when you add a new `Page::Base` derived class, you must also
define all selectors that your page objects depend on.

Whenever you push your code to CE / EE repository, `qa:selectors` sanity test
job runs as a part of a CI pipeline.

This test validates all page objects that we have implemented in
`qa/page` directory. When it fails, it notifies you about missing
or invalid views/selectors definition.

## How to properly implement a page object?

We have built a DSL to define coupling between a page object and GitLab views
it is actually implemented by. See an example below.

```ruby
module Page
  module Main
    class Login < Page::Base
      view 'app/views/devise/passwords/edit.html.haml' do
        element 'password-field'
        element 'password-confirmation'
        element 'change-password-button'
      end

      view 'app/views/devise/sessions/_new_base.html.haml' do
        element 'login-field'
        element 'password-field'
        element 'sign-in-button'
      end

      # ...
    end
  end
end
```

### Defining Elements

The `view` DSL method corresponds to the Rails view, partial, or Vue component that renders the elements.

The `element` DSL method in turn declares an element for which a corresponding
`testid=element-name` data attribute must be added, if not already, to the view file.

You can also define a value (String or Regexp) to match to the actual view
code but **this is deprecated** in favor of the above method for two reasons:

- Consistency: there is only one way to define an element
- Separation of concerns: Tests use dedicated `data-testid` attributes instead of reusing code
  or classes used by other components (for example, `js-*` classes etc.)

```ruby
view 'app/views/my/view.html.haml' do

  ### Good ###

  # Implicitly require the CSS selector `[data-testid="logout-button"]` to be present in the view
  element 'logout-button'

  ### Bad ###

  ## This is deprecated and forbidden by the `QA/ElementWithPattern` RuboCop cop.
  # Require `f.submit "Sign in"` to be present in `my/view.html.haml
  element :my_button, 'f.submit "Sign in"' # rubocop:disable QA/ElementWithPattern

  ## This is deprecated and forbidden by the `QA/ElementWithPattern` RuboCop cop.
  # Match every line in `my/view.html.haml` against
  # `/link_to .* "My Profile"/` regexp.
  element :profile_link, /link_to .* "My Profile"/ # rubocop:disable QA/ElementWithPattern
end
```

### Adding Elements to a View

Given the following elements...

```ruby
view 'app/views/my/view.html.haml' do
  element 'login-field'
  element 'password-field'
  element 'sign-in-button'
end
```

To add these elements to the view, you must change the Rails view, partial, or Vue component by adding a `data-testid` attribute
for each element defined.

In our case, `data-testid="login-field"`, `data-testid="password-field"` and `data-testid="sign-in-button"`

`app/views/my/view.html.haml`

```haml
= f.text_field :login, class: "form-control top", autofocus: "autofocus", autocapitalize: "off", autocorrect: "off", required: true, title: "This field is required.", data: { testid: 'login_field' }
= f.password_field :password, class: "form-control bottom", required: true, title: "This field is required.", data: { testid: 'password_field' }
= f.submit "Sign in", class: "btn btn-confirm", data: { testid: 'sign_in_button' }
```

Things to note:

- The name of the element and the `data-testid` must match and be kebab cased
- If the element appears on the page unconditionally, add `required: true` to the element. See
  [Dynamic element validation](../best_practices/dynamic_element_validation.md)
- You should not see `data-qa-selector` classes in Page Objects.
  We should use the [`data-testid`](#data-testid-vs-data-qa-selector)
  method of definition

### `data-testid` vs `data-qa-selector`

> - Introduced in GitLab 16.1

Any existing `data-qa-selector` class should be considered deprecated
and we should use the `data-testid` method of definition.

### Dynamic element selection

A common occurrence in automated testing is selecting a single "one-of-many" element.
In a list of several items, how do you differentiate what you are selecting on?
The most common workaround for this is via text matching. Instead, a better practice is
by matching on that specific element by a unique identifier, rather than by text.

We got around this by adding the `data-qa-*` extensible selection mechanism.

#### Examples

**Example 1**

Given the following Rails view (using GitLab Issues as an example):

```haml
%ul.issues-list
 - @issues.each do |issue|
   %li.issue{data: { testid: 'issue', qa_issue_title: issue.title } }= link_to issue
```

We can select on that specific issue by matching on the Rails model.

```ruby
class Page::Project::Issues::Index < Page::Base
  def has_issue?(issue)
    has_element?(:issue, issue_title: issue)
  end
end
```

In our test, we can validate that this particular issue exists.

```ruby
describe 'Issue' do
  it 'has an issue titled "hello"' do
    Page::Project::Issues::Index.perform do |index|
      expect(index).to have_issue('hello')
    end
  end
end
```

**Example 2**

*By an index...*

```haml
%ol
  - @some_model.each_with_index do |model, idx|
    %li.model{ data: { testid: 'model', qa_index: idx } }
```

```ruby
expect(the_page).to have_element(:model, index: 1) #=> select on the first model that appears in the list
```

### Exceptions

In some cases, it might not be possible or worthwhile to add a selector.

Some UI components use external libraries, including some maintained by third parties.
Even if a library is maintained by GitLab, the selector sanity test only runs
on code within the GitLab project, so it's not possible to specify the path for
the view for code in a library.

In such rare cases it's reasonable to use CSS selectors in page object methods,
with a comment explaining why an `element` can't be added.

### Define Page concerns

Some pages share common behaviors, and/or are prepended with EE-specific modules that adds EE-specific methods.

These modules must:

1. Extend from the `QA::Page::PageConcern` module, with `extend QA::Page::PageConcern`.
1. Override the `self.prepended` method if they need to `include`/`prepend` other modules themselves, and/or define
   `view` or `elements`.
1. Call `super` as the first thing in `self.prepended`.
1. Include/prepend other modules and define their `view`/`elements` in a `base.class_eval` block to ensure they're
   defined in the class that prepends the module.

These steps ensure the sanity selectors check detect problems properly.

For example, `qa/qa/ee/page/merge_request/show.rb` adds EE-specific methods to `qa/qa/page/merge_request/show.rb` (with
`QA::Page::MergeRequest::Show.prepend_mod_with('Page::MergeRequest::Show', namespace: QA)`) and following is how it's implemented
(only showing the relevant part and referring to the 4 steps described above with inline comments):

```ruby
module QA
  module EE
    module Page
      module MergeRequest
        module Show
          extend QA::Page::PageConcern # 1.

          def self.prepended(base) # 2.
            super # 3.

            base.class_eval do # 4.
              prepend Page::Component::LicenseManagement

              view 'app/assets/javascripts/vue_merge_request_widget/components/states/sha_mismatch.vue' do
                element 'head-mismatch', "The source branch HEAD has recently changed."
              end

              [...]
            end
          end
        end
      end
    end
  end
end
```

## Running the test locally

During development, you can run the `qa:selectors` test by running

```shell
bin/qa Test::Sanity::Selectors
```

from within the `qa` directory.

## Where to ask for help?

If you need more information, ask for help on `#test-platform` channel on Slack
(internal, GitLab Team only).

If you are not a Team Member, and you still need help to contribute,
open an issue in GitLab CE issue tracker with the `~QA` label.
