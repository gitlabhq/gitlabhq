---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Testing AI features
---

This document highlights AI-specific testing considerations that complement GitLab standard [testing guidelines](_index.md). It focuses on the challenges AI features bring to testing, such as non-deterministic responses from third-party providers. Examples are included for each [testing level](testing_levels.md).

AI-powered features depend on system components outside the GitLab monolith, such as the [AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist) and IDE extensions.
In addition to these guidelines, consult any testing guidelines documented in each component project.

## Unit testing

Follow standard [unit testing guidelines](testing_levels.md#unit-tests). For AI features, always mock third-party AI provider calls to ensure fast, reliable tests.

### Unit test examples

- GitLab: [`ee/spec/lib/code_suggestions/tasks/code_completion_spec.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/904dfcf962234e18f1eef395507e959b42d17251/ee/spec/lib/code_suggestions/tasks/code_completion_spec.rb)
- VS Code extension: [`code_suggestions/code_suggestions.test.ts`](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/adedfb4189de63e7041c18e5657c048b1adfc28a/src/common/code_suggestions/code_suggestions.test.ts)

## Integration tests

Use [integration tests](testing_levels.md#integration-tests) to verify request construction and response handling for AI providers. Mock AI provider responses to ensure predictable, fast tests that handle various responses, errors, and status codes.

### Integration test examples

- GitLab: [`ee/spec/requests/api/code_suggestions_spec.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/57d17110ef8f137ec8c1507e8d1a60ec194d6876/ee/spec/requests/api/code_suggestions_spec.rb)
- VS Code extension: [`main/test/integration/chat.test.js`](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/adedfb4189de63e7041c18e5657c048b1adfc28a/test/integration/chat.test.js)

## Frontend feature tests

Use [frontend feature tests](testing_levels.md#frontend-feature-tests) to validate AI features from an end-user perspective. Mock AI providers to maintain speed and reliability. Focus on happy paths with selective negative path testing for high-risk scenarios.

### Frontend feature test example

- GitLab Duo Chat: [`ee/spec/features/duo_chat_spec.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/57d17110ef8f137ec8c1507e8d1a60ec194d6876/ee/spec/features/duo_chat_spec.rb)

## End-to-End testing

Use [end-to-end tests](end_to_end/_index.md) sparingly to verify AI features work with real provider responses. Key considerations:

- Keep tests minimal due to slower execution and potential provider outages.
- Account for non-deterministic AI responses in test design. For example, use deterministic assertions on controlled elements like chatbot names, not AI-generated content.

### E2E test examples

- GitLab: [`specs/features/ee/browser_ui/3_create/web_ide/code_suggestions_in_web_ide_spec.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/57d17110ef8f137ec8c1507e8d1a60ec194d6876/qa/qa/specs/features/ee/browser_ui/3_create/web_ide/code_suggestions_in_web_ide_spec.rb)
- JetBrains:
[`test/kotlin/com/gitlab/plugin/e2eTest/tests/CodeSuggestionTest.kt`](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/blob/72bf52a7a652794546e7def85ea30a6fdd40a6f9/src/test/kotlin/com/gitlab/plugin/e2eTest/tests/CodeSuggestionTest.kt)

### Live environment testing

- **GitLab.com**: We run minimal E2E tests continuously against staging and production environments. For example, [Code Suggestions smoke tests](https://gitlab.com/gitlab-org/gitlab/-/blob/57d17110ef8f137ec8c1507e8d1a60ec194d6876/qa/qa/specs/features/ee/browser_ui/3_create/web_ide/code_suggestions_in_web_ide_spec.rb#L75).
- **GitLab Self-Managed**: We use the [`gitlab-qa`](https://gitlab.com/gitlab-org/gitlab-qa) orchestrator with [AI Gateway scenarios](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/what_tests_can_be_run.md#aigateway-scenarios) to test AI features on self-managed installations.

## Exploratory testing

Perform exploratory testing before significant milestones to uncover bugs outside expected workflows and UX issues. This is especially important for AI features as they progress through experiment, beta, and GA phases.

## Dogfooding

We [dogfood](https://handbook.gitlab.com/handbook/engineering/development/principles/#dogfooding) everything. This is especially important for AI features given the rapidly changing nature of the field. See the [dogfooding process](https://handbook.gitlab.com/handbook/product/product-processes/dogfooding-for-r-d/) for details.
