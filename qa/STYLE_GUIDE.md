# Style guide for writing GUI tests

This document describes the conventions used at GitLab for writing GUI tests using the GitLab QA project.

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