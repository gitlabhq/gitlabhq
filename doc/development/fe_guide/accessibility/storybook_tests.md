---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Accessibility Storybook tests
---

## Storybook component tests

We use [Storybook test-runner](https://storybook.js.org/docs/7/writing-tests/test-runner) with [axe-playwright](https://storybook.js.org/docs/7/writing-tests/accessibility-testing#automate-accessibility-tests-with-test-runner) to automatically test Vue components for accessibility violations.

This approach allows us to test components in isolation and catch accessibility issues early in the development process.

### Prerequisites

Before running Storybook accessibility tests, ensure you have:

1. All dependencies installed (`yarn install`)
1. A built Storybook instance running

### Running Storybook accessibility tests

To run automated accessibility tests for Vue components:

#### Step 1: Start Storybook

First, start the Storybook development server. You have two options:

```shell
# Option 1: Start Storybook with fresh fixtures
yarn storybook:start

# Option 2: Start Storybook without updating fixtures (faster for subsequent runs)
yarn storybook:start:skip-fixtures-update
```

**Important:** Keep the Storybook server running throughout your testing session. The Storybook needs to be built and accessible for the tests to run properly.

#### Step 2: Run the accessibility tests

In a separate terminal, from the root directory of the GitLab project, run:

```shell
yarn storybook:dev:test
```

This command will:

1. Launch the test runner against your running Storybook instance.
1. Navigate through all stories.
1. Run axe-playwright accessibility checks on each story.
1. Report any accessibility violations found.

### Understanding test results

The test runner will output:

- **Passing tests**: Components that meet accessibility standards and have no runtime errors.
- **Failing tests**:
  - Components with runtime errors.
  - Components with accessibility violations, including:
    - Specific accessibility rules that failed
    - Elements that caused violations
    - Severity levels (critical, serious, moderate, minor)
    - Suggested fixes when available

The complete output of the test run can be found in `storybook/tmp/storybook-results.json` file.

### Best practices for Storybook accessibility testing

1. **Test all story variants**: Ensure each story in your component represents different states and configurations
1. **Include interactive states**: Create stories that show hover, focus, active, and disabled states
1. **Test with different data**: Use realistic data that reflects actual usage scenarios
1. **Address violations immediately**: Fix accessibility issues as soon as they're identified
1. **Document component accessibility**: Include accessibility considerations in your component's story documentation

### Integration with development workflow

Consider integrating Storybook accessibility testing into your development process:

1. **During component development**: Run tests frequently to catch issues early
1. **Before merge requests**: Ensure all new or modified components pass accessibility tests

### Troubleshooting

If tests fail to run:

1. **Check Storybook is running**: Ensure your Storybook server is accessible at the expected URL
1. **Verify dependencies**: Run `yarn install` to ensure all packages are installed
1. **Check for build errors**: Look for any errors in the Storybook build output
1. **Clear cache**: Try restarting Storybook if you encounter unexpected issues

## Getting help

- For accessibility testing questions, refer to our [Frontend testing guide](../../testing_guide/frontend_testing.md)
- For accessibility best practices, see our [accessibility best practices guide](best_practices.md)
- For component-specific accessibility guidance, check [Pajamas components documentation](https://design.gitlab.com/components/overview)
- If you discover accessibility issues that require global changes, create a follow-up issue with the labels: `accessibility` and accessibility severity label, for example `accessibility:critical`.
  Test output will specify the severity for you.
