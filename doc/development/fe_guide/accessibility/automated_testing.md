---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Automated accessibility testing
---

We use [axe-core](https://github.com/dequelabs/axe-core) [gems](https://github.com/dequelabs/axe-core-gems)
to run automated accessibility tests in feature tests.

[We aim to conform to level AA of the World Wide Web Consortium (W3C) Web Content Accessibility Guidelines 2.1](https://design.gitlab.com/accessibility/a11y).

## When to add accessibility tests

When adding a new view to the application, make sure to include the accessibility check in your feature test.
We aim to have full coverage for all the views.

One of the advantages of testing in feature tests is that we can check different states, not only
single components in isolation.

You can find some examples on how to approach accessibility checks below.

### Empty state

Some views have an empty state that result in a page structure that's different from the default view.
They may also offer some actions, for example to create a first issue or to enable a feature.
In this case, add assertions for both an empty state and a default view.

### Ensure compliance before user interactions

Often we test against a number of steps we expect our users to perform.
In this case, make sure to include the check early on, before any of them has been simulated.
This way we ensure there are no barriers to what we expect of users.

### Ensure compliance after changed page structure

User interactions may result in significant changes in page structure. For example, a modal is shown, or a new section is rendered.
In that case, add an assertion after any such change.
We want to make sure that users are able to interact with all available components.

### Separate file for extensive test suites

For some views, feature tests span multiple files.
Take a look at our [feature tests for a merge request](https://gitlab.com/gitlab-org/gitlab/-/tree/master/spec/features/merge_request).
The number of user interactions that needs to be covered is too big to fit into one test file.
As a result, multiple feature tests cover one view, with different user privileges, or data sets.
If we were to include accessibility checks in all of them, there is a chance we would cover the same states of a view multiple times and significantly increase the run time.
It would also make it harder to determine the coverage for accessibility, if assertions would be scattered across many files.

In that case, consider creating one test file dedicated to accessibility.
Place it in the same directory and name it `accessibility_spec.rb`, for example `spec/features/merge_request/accessibility_spec.rb`.
Make it explicit that a feature test has accessibility coverage in a separate file, and
doesn't need additional assertions. Include this comment below the opening of the
top-level block:

```ruby
# spec/features/merge_request/user_approves_spec.rb

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User approves', :js, feature_category: :code_review_workflow do
# covered by ./accessibility_spec.rb
```

### Shared examples

Often feature tests include shared examples for a number of scenarios.
If they differ only by provided data, but are based on the same user interaction, you can check for accessibility compliance outside the shared examples.
This way we only run the check once and save resources.

## How to add accessibility tests

Axe provides the custom matcher `be_axe_clean`, which can be used like the following:

```ruby
# spec/features/settings_spec.rb
it 'passes axe automated accessibility testing', :js do
  visit_settings_page

  wait_for_requests # ensures page is fully loaded

  expect(page).to be_axe_clean
end
```

If needed, you can scope testing to a specific area of the page by using `within`.

Axe also provides specific [clauses](https://github.com/dequelabs/axe-core-gems/blob/develop/packages/axe-core-rspec/README.md#clauses),
for example:

```ruby
expect(page).to be_axe_clean.within '[data-testid="element"]'

# run only WCAG 2.1 Level AA rules
expect(page).to be_axe_clean.according_to :wcag21aa

# specifies which rule to skip
expect(page).to be_axe_clean.skipping :'link-in-text-block'

# clauses can be chained
expect(page).to be_axe_clean.within('[data-testid="element"]')
                            .according_to(:wcag21aa)
```

Axe does not test hidden regions, such as inactive menus or modal windows. To test
hidden regions for accessibility, write tests that activate or render the regions visible
and run the matcher again.

You can run accessibility tests locally in the same way as you [run any feature tests](../../testing_guide/frontend_testing.md#how-to-run-a-feature-test).

After adding accessibility tests, make sure to fix all possible errors.
For help on how to do it, refer to [this guide](best_practices.md#quick-checklist).
You can also check accessibility sections in [Pajamas components' documentation](https://design.gitlab.com/components/overview).
If any of the errors require global changes, create a follow-up issue and assign these labels: `accessability`, `WG::product accessibility`.

### Good practices

Adding accessibility checks in feature tests is easier if you have domain knowledge from the product area in question.
However, there are a few things that can help you contribute to accessibility tests.

#### Find a page from a test

When you don't have the page URL, you can start by running a feature spec in preview mode. To do this, add `WEBDRIVER_HEADLESS=0` to the beginning of the command that runs the tests. You can also pair it with `live_debug` to stop the browser right inside any test case with a `:js` tag (see the documentation on [testing best practices](../../testing_guide/best_practices.md#run-js-spec-in-a-visible-browser)).

#### What parts of a page to add accessibility tests for

In most cases you do not want to test accessibility of a whole page. There are a couple of reasons:

1. We have elements that appear on every application view, such as breadcrumbs or main navigation. Including them in every feature spec takes up quite a lot of resources and multiplies something that can be done just once. These elements have their own feature specs and that's where we want to test them.

1. If a feature spec covers a whole view, the best practice would be to scope it to `<main id="content-body">` element. Here's an example of such test case:

   ```ruby
    it "passes axe automated accessibility testing" do
      expect(page).to be_axe_clean.within('#content-body')
    end
   ```

1. If a feature test covers only a part of a page, like a section that includes some components, keep the test scoped to that section. If possible, use the same selector that the feature spec uses for its test cases. Here's an example of such test case:

   ```ruby
    it 'passes axe automated accessibility testing for todo' do
      expect(page).to be_axe_clean.within(todo_selector)
    end
   ```

#### Test output not specific enough

When axe test case fails, it outputs the violation found and an element that it concerns. Because we often use Pajamas Components,
it may happen that the element will be a `<div>` without any annotation that could help you identify it. However, we can take
advantage of a fact that axe_core rules is used both for Ruby tests and Deque browser extension - axe devTools. They both
provide the same output.

1. Make sure you have axe DevTools extension installed in a browser of your choice. See [axe DevTools official website for more information](https://www.deque.com/axe/browser-extensions/).

1. Navigate to the view you're testing with a feature test.

1. Open axe DevTools extension and run a scan of the page.

1. Expand found issues and use Highlight option to see the elements on the page for each violation.

### Known accessibility violations

This section documents violations where a recommendation differs with the [design system](https://design.gitlab.com/):

- `link-in-text-block`: For now, use the `skipping` clause to skip `:'link-in-text-block'`
  rule to fix the violation. After this is fixed as part of [issue 1444](https://gitlab.com/gitlab-org/gitlab-services/design.gitlab.com/-/issues/1444)
  and underline is added to the `GlLink` component, this clause can be removed.
