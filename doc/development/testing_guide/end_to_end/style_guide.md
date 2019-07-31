# Style guide for writing end-to-end tests

This document describes the conventions used at GitLab for writing End-to-end (E2E) tests using the GitLab QA project.

## `click_` versus `go_to_`

### When to use `click_`?

When clicking in a single link to navigate, use `click_`.

E.g.:

```ruby
def click_ci_cd_pipelines
  within_sidebar do
    click_element :link_pipelines
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

We follow a simple formula roughly based on hungarian notation.

*Formula*: `element :<descriptor>_<type>`

- `descriptor`: The natural-language description of what the element is. On the login page, this could be `username`, or `password`.
- `type`: A physical control on the page that can be seen by a user.
  - `_button`
  - `_link`
  - `_tab`
  - `_dropdown`
  - `_field`
  - `_checkbox`
  - `_radio`
  - `_content`

*Note: This list is a work in progress. This list will eventually be the end-all enumeration of all available types.
        I.e., any element that does not end with something in this list is bad form.*

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
