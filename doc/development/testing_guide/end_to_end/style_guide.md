---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Style guide for writing end-to-end tests

This document describes the conventions used at GitLab for writing End-to-end (E2E) tests using the GitLab QA project.

## `click_` versus `go_to_`

### When to use `click_`?

When clicking in a single link to navigate, use `click_`.

E.g.:

```ruby
def click_ci_cd_pipelines
  within_sidebar do
    click_element(:link_pipelines)
  end
end
```

From a testing perspective, if we want to check that clicking a link, or a button (a single interaction) is working as intended, we would want the test to read as:

- Click a certain element
- Verify the action took place

### When to use `go_to_`?

When interacting with multiple elements to go to a page, use `go_to_`.

E.g.:

```ruby
def go_to_operations_environments
  hover_operations do
    within_submenu do
      click_element(:operations_environments_link)
    end
  end
end
```

`go_to_` fits the definition of interacting with multiple elements very well given it's more of a meta-navigation action that includes multiple interactions.

Notice that in the above example, before clicking the `:operations_environments_link`, another element is hovered over.

> We can create these methods as helpers to abstract multi-step navigation.

## Element naming convention

When adding new elements to a page, it's important that we have a uniform element naming convention.

We follow a simple formula roughly based on Hungarian notation.

*Formula*: `element :<descriptor>_<type>`

- `descriptor`: The natural-language description of what the element is. On the login page, this could be `username`, or `password`.
- `type`: A generic control on the page that can be seen by a user.
  - `_button`
  - `_checkbox`
  - `_container`: an element that includes other elements, but doesn't present visible content itself. E.g., an element that has a third-party editor inside it, but which isn't the editor itself and so doesn't include the editor's content.
  - `_content`: any element that contains text, images, or any other content displayed to the user.
  - `_dropdown`
  - `_field`: a text input element.
  - `_link`
  - `_modal`: a popup modal dialog, e.g., a confirmation prompt.
  - `_placeholder`: a temporary element that appears while content is loading. For example, the elements that are displayed instead of discussions while the discussions are being fetched.
  - `_radio`
  - `_tab`
  - `_menu_item`

NOTE:
If none of the listed types are suitable, please open a merge request to add an appropriate type to the list.

### Examples

**Good**

```ruby
view '...' do
  element :edit_button
  element :notes_tab
  element :squash_checkbox
  element :username_field
  element :issue_title_content
end
```

**Bad**

```ruby
view '...' do
  # `_confirmation` should be `_field`. what sort of confirmation? a checkbox confirmation? no real way to disambiguate.
  # an appropriate replacement would be `element :password_confirmation_field`
  element :password_confirmation

  # `clone_options` is too vague. If it's a dropdown menu, it should be `clone_dropdown`.
  # If it's a checkbox, it should be `clone_checkbox`
  element :clone_options

  # how is this url being displayed? is it a textbox? a simple span?
  # If it is content on the page, it should be `ssh_clone_url_content`
  element :ssh_clone_url
end
```

## Block argument naming

To have a standard on what we call pages and resources when using the `.perform` method,
we use the name of the page object in [snake_case](https://en.wikipedia.org/wiki/Snake_case)
(all lowercase, with words separated by an underscore). See good and bad examples below.

While we prefer to follow the standard in most cases, it is also acceptable to
use common abbreviations (e.g., `mr`) or other alternatives, as long as
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
