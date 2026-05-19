# Accessibility Feature Tests for Golden User Journeys

This directory contains accessibility tests that cover complete golden user journeys
using axe-core-gem. These tests focus **solely on accessibility assertions** and do not
duplicate functional testing.

Accessibility tests in this directory are organized by:

- **Stage** (create, plan, etc.)
- **Golden User Journey** (writing_code, managing_issues, etc.)

Each test file covers one complete golden user journey and is mapped to multiple E2E
test cases that collectively represent that journey.

## Structure

```
spec/features/accessibility/
├── README.md                    # This file
├── create/
│   ├── writing_code_spec.rb     # Golden journey: Writing code
│   ├── reviewing_code_spec.rb   # Golden journey: Reviewing code
│   └── ...
└── plan/
    ├── managing_issues_spec.rb  # Golden journey: Managing issues
    └── ...
```

## Implementation Guidelines

When implementing these accessibility tests:

1. Read the E2E references at the top of the spec file to understand the complete user journey
1. Review the related feature test files listed for examples of:
   - How to set up test data (factories, database records)
   - How to go to the right pages
   - Common helper methods and patterns
1. Implement the test following the TODO comments:
   - Navigate through the user journey
   - Add `expect(page).to be_axe_clean` checks at key interaction points
   - Use `.within()` to scope checks to relevant page sections
   - Always call `wait_for_requests` before accessibility checks
1. Fix accessibility violations found by the tests or skipped known violations

Follow the guidelines in [Accessibility Feature Tests Documentation](../../doc/development/fe_guide/accessibility/feature_tests.md).

## Example Implementation

```ruby
context 'when using Web IDE' do
  it 'passes axe automated accessibility testing' do
    # Step 1: Navigate to project
    visit project_path(project)
    wait_for_requests

    # Check: Initial page load
    expect(page).to be_axe_clean.within('#content-body')

    # Step 2: Open Web IDE
    click_button 'Web IDE'
    wait_for_requests

    # Check: Web IDE interface loaded
    expect(page).to be_axe_clean.within('.ide-view')

    # Step 3: Create new file
    click_button 'New file'
    wait_for_requests

    # Check: New file dialog
    expect(page).to be_axe_clean.within('[role="dialog"]')
  end
end
```

## Common Patterns

### Scoping to Main Content

Most page-level checks should scope to `#content-body` to avoid testing global navigation repeatedly:

```ruby
expect(page).to be_axe_clean.within('#content-body')
```

### Testing Modals and Dialogs

Wait for a dialog to appear, then check it specifically:

```ruby
click_button 'Open Dialog'
wait_for_requests

expect(page).to be_axe_clean.within('[role="dialog"]')
```

### Handling Known Violations

If a violation requires a global fix tracked in a separate issue, skip the rule with a comment:

```ruby
# Skipping color-contrast due to global issue: https://gitlab.com/gitlab-org/gitlab/-/issues/12345
expect(page).to be_axe_clean.within('#content-body').skipping :'color-contrast'
```

## Resources

- [axe-core-rspec Documentation](https://github.com/dequelabs/axe-core-gems/blob/develop/packages/axe-core-rspec/README.md)
- [Work Item: Include axe automated accessibility checks](https://gitlab.com/groups/gitlab-org/-/work_items/11126)

## Questions or Issues?

- **For accessibility questions**: Reach out to `@gitlab-org/working-group/accessibility`
- **For testing questions**: Ask in `#development` Slack channel
- **For this initiative**: See [Golden User Journeys Work Item](https://gitlab.com/gitlab-org/gitlab/-/work_items/580804)
