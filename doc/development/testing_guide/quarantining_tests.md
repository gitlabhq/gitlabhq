---
stage: none
group: unassigned
info: 'See the Technical Writers assigned to Development Guidelines: https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-development-guidelines'
description: Technical reference for quarantining tests in GitLab.
title: Quarantining tests
---

This page provides technical reference for implementing test quarantine in GitLab. For process information about when to quarantine, ownership, and timelines, see the [Test Quarantine Process handbook page](https://handbook.gitlab.com/handbook/engineering/testing/quarantine-process/).

## What is test quarantine?

Quarantining a test means marking it to be skipped in CI while preserving it in the codebase for future fixing. Quarantined tests run locally by default but are excluded from CI pipelines to prevent blocking other developers.

## RSpec quarantine

### Basic syntax

Use the `quarantine` metadata with the URL of the test failure issue:

```ruby
# Quarantine a single spec
it 'succeeds', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/12345' do
  expect(response).to have_gitlab_http_status(:ok)
end

# Quarantine a describe/context block
describe '#flaky-method', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/12345' do
  [...]
end
```

### Quarantine metadata types

Specify the quarantine type to categorize the reason:

```ruby
it 'is flaky', quarantine: {
  issue: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/12345',
  type: :flaky
}

it 'is due to a bug', quarantine: {
  issue: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/12345',
  type: :bug
}

context 'when these tests rely on another MR', quarantine: {
  type: :waiting_on,
  issue: 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/12345'
}
```

**Available quarantine types:**

| Type | Description |
|------|-------------|
| `:flaky` | Test fails intermittently |
| `:bug` | Test fails due to an application bug |
| `:stale` | Test is outdated due to feature changes |
| `:broken` | Test fails due to test code or framework changes |
| `:waiting_on` | Test depends on another issue or MR |
| `:investigating` | Flaky test under investigation |
| `:test_environment` | Test fails due to environment issues |
| `:dependency` | Test fails due to external dependency |

### Nested contexts

Apply quarantine to the outermost `describe` or `context` block that has relevant tags:

```ruby
# Good
RSpec.describe 'Plan', :smoke, quarantine: {
  issue: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/12345',
  type: :flaky
} do
  describe 'Feature' do
    before(:context) do
      # This before(:context) block is only executed in smoke quarantine jobs
    end
  end
end

# Bad
RSpec.describe 'Plan', :smoke do
  describe 'Feature', quarantine: {
    issue: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/12345',
    type: :flaky
  } do
    before(:context) do
      # This before(:context) block could be mistakenly executed in quarantine jobs
      # that don't have the smoke tag
    end
  end
end
```

### Running quarantined tests locally

By default, quarantined tests run in local development. To skip them:

```shell
# Bash
bin/rspec --tag ~quarantine

# ZSH
bin/rspec --tag \~quarantine
```

### Finding quarantined tests

To find all quarantined tests for a feature category, use `ripgrep`:

```shell
rg -l --multiline -w "(?s)feature_category:\s+:global_search.+quarantine:"
```

### Technical constraints

You cannot quarantine shared examples or calls to `it_behaves_like`/`include_examples`:

```ruby
# Will be flagged by Rubocop
shared_examples 'loads all the users when opened', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/12345' do
  [...]
end

# Does not work
it_behaves_like 'a shared example', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/12345'

# Does not work
include_examples 'a shared example', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/12345'
```

For more information, see:

- [Why we should not quarantine shared examples](https://gitlab.com/gitlab-org/gitlab/-/issues/404388)
- [RSpec limitation on quarantining shared examples](https://github.com/rspec/rspec-core/pull/2307#issuecomment-236006902)

### Prerequisites

Before quarantining a test:

1. Ensure the test file has a [`feature_category` metadata](../feature_categorization/_index.md#rspec-examples) for proper attribution
1. Create or identify the test failure issue in the [Test Failure Issues](https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues) project
1. Add the `~"quarantine"` label to your merge request
1. Link the MR to the test failure issue using [standard linking terms](https://gitlab.com/gitlab-org/quality/triage-ops/-/blob/8b8621ba5c0db3c044a771ebf84887a0a07353b3/triage/triage/related_issue_finder.rb#L8-18)
1. Add the `~"quarantined test"` label to the issue

For process information about when to quarantine and ownership responsibilities, see the [Test Quarantine Process handbook](https://handbook.gitlab.com/handbook/engineering/testing/quarantine-process/).

### Fast quarantine

For immediate quarantine needs, use the [fast quarantine process](https://gitlab.com/gitlab-org/quality/engineering-productivity/fast-quarantine/-/blob/main/.gitlab/merge_request_templates/Default.md#fast-quarantine-process).

**Re-running failed jobs with fast quarantine:**

- **RSpec tests (unit/integration/system)**: Re-trigger the `retrieve-tests-metadata` job, then retry the failed RSpec job. Simply restarting the job will NOT pick up new fast quarantine updates.
- **E2E tests**: Simply retry the failed E2E job - E2E tests automatically download the latest fast quarantine file.
- **Alternative**: Running a new pipeline picks up the latest fast quarantine for all test types.

For complete process information about fast quarantine timelines and follow-up requirements, see the [Fast Quarantine section in the handbook](https://handbook.gitlab.com/handbook/engineering/testing/quarantine-process/#fast-quarantine/).

## Jest quarantine

### Basic syntax

Use the `.skip` method with an ESLint disable comment:

```javascript
// quarantine: https://gitlab.com/gitlab-org/gitlab/-/issues/56789
// eslint-disable-next-line jest/no-disabled-tests
it.skip('should throw an error', () => {
  expect(response).toThrowError(expected_error)
});
```

### Running quarantined tests

Quarantined Jest tests are skipped unless run with the `--runInBand` option:

```shell
jest --runInBand
```

### Finding quarantined tests

To list all files with quarantined Jest specs:

```shell
yarn jest:quarantine
```

## Related topics

- [Test Quarantine Process (Handbook)](https://handbook.gitlab.com/handbook/engineering/testing/quarantine-process/) - Process, workflows, ownership, and timelines
- [Unhealthy Tests](unhealthy_tests.md) - Understanding and debugging flaky tests
- [Flaky Tests (Handbook)](https://handbook.gitlab.com/handbook/engineering/testing/flaky-tests/) - Detection, tracking, and urgency timelines
