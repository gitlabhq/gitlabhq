---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Style guide for writing end-to-end tests
---

This document describes the conventions used at GitLab for writing End-to-end (E2E) tests using the GitLab QA project.

This guide is an extension of the primary [testing standards and style guidelines](../_index.md). If this guide defines a rule that contradicts the primary guide, this guide takes precedence.

## `click_` versus `go_to_`

### When to use `click_`?

When selecting a single link to navigate, use `click_`.

For example:

```ruby
def click_add_badge_button
  click_element 'add-badge-button'
end
```

From a testing perspective, if we want to check that selecting a link, or a button (a single interaction) is working as intended, we would want the test to read as:

- Select a certain element
- Verify the action took place

### When to use `go_to_`?

When interacting with multiple elements to go to a page, use `go_to_`.

For example:

```ruby
def go_to_applications
  click_element('nav-item-link', submenu_item: 'Applications')
end
```

`go_to_` fits the definition of interacting with multiple elements very well given it's more of a meta-navigation action that includes multiple interactions.

Notice that in the above example, before selecting the `'nav-item-link'`, another element is hovered over.

> We can create these methods as helpers to abstract multi-step navigation.

## Element naming convention

When adding new elements to a page, it's important that we have a uniform element naming convention.

We follow a simple formula roughly based on Hungarian notation.

*Formula*: `element :<descriptor>_<type>`

- `descriptor`: The natural-language description of what the element is. On the login page, this could be `username`, or `password`.
- `type`: A generic control on the page that can be seen by a user.
  - `-button`
  - `-checkbox`
  - `-container`: an element that includes other elements, but doesn't present visible content itself. For example, an element that has a third-party editor inside it, but which isn't the editor itself and so doesn't include the editor's content.
  - `-content`: any element that contains text, images, or any other content displayed to the user.
  - `-dropdown`
  - `-field`: a text input element.
  - `-link`
  - `-modal`: a popup modal dialog, for example, a confirmation prompt.
  - `-placeholder`: a temporary element that appears while content is loading. For example, the elements that are displayed instead of discussions while the discussions are being fetched.
  - `-radio`
  - `-tab`
  - `-menu_item`

NOTE:
If none of the listed types are suitable, open a merge request to add an appropriate type to the list.

### Examples

**Good**

```ruby
view '...' do
  element 'edit-button'
  element 'notes-tab'
  element 'squash-checkbox'
  element 'username-field'
  element 'issue-title-content'
end
```

**Bad**

```ruby
view '...' do
  # `'-confirmation'` should be `'-field'`. what sort of confirmation? a checkbox confirmation? no real way to disambiguate.
  # an appropriate replacement would be `element 'password-confirmation-field'`
  element 'password-confirmation'

  # `'clone-options'` is too vague. If it's a dropdown menu, it should be `'clone-dropdown'`.
  # If it's a checkbox, it should be `'clone-checkbox'`
  element 'clone-options'

  # how is this url being displayed? is it a textbox? a simple span?
  # If it is content on the page, it should be `'ssh-clone-url-content'`
  element 'ssh-clone-url'
end
```

## Block argument naming

To have a standard on what we call pages and resources when using the `.perform` method,
we use the name of the page object in [snake_case](https://en.wikipedia.org/wiki/Snake_case)
(all lowercase, with words separated by an underscore). See good and bad examples below.

While we prefer to follow the standard in most cases, it is also acceptable to
use common abbreviations (for example, `mr`) or other alternatives, as long as
the name is not ambiguous. This can include appending `_page` if it helps to
avoid confusion or make the code more readable. For example, if a page object is
named `New`, it could be confusing to name the block argument `new` because that
is used to instantiate objects, so `new_page` would be acceptable.

We chose not to use `page` because that would shadow the
Capybara DSL, potentially leading to confusion and bugs.

### Examples

**Good**

```ruby
Page::Project::Members.perform do |members|
  members.do_something
end
```

```ruby
Resource::MergeRequest.fabricate! do |merge_request|
  merge_request.do_something_else
end
```

```ruby
Resource::MergeRequest.fabricate! do |mr|
  mr.do_something_else
end
```

```ruby
Page::Project::New.perform do |new_page|
  new_page.do_something
end
```

**Bad**

```ruby
Page::Project::Members.perform do |project_settings_members_page|
  project_settings_members_page.do_something
end
```

```ruby
Page::Project::New.perform do |page|
  page.do_something
end
```

> Besides the advantage of having a standard in place, by following this standard we also write shorter lines of code.
