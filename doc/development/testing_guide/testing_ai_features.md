---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
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

## DAP feature tests in core feature pages

To test that DAP features are functional in a core feature page and core features are functional with DAP components,
use the following shared context and examples in a feature spec:

- Include the shared context `include_context 'with duo features enabled and agentic chat available for group on SaaS'`
  to load DAP components in a feature page by default.
- Include the shared examples `it_behaves_like 'user can use agentic chat'` to test DAP features in a feature page.

For instance, `ee/spec/features/epic_boards/epic_boards_spec.rb` asserts the following scenario:

- Epic board is functional on a page that loads DAP components in the sidebar.
- DAP feature is functional in a page where the epic board is rendered.
  1. User visits a core feature page and opens GitLab Duo Agentic Chat from the sidebar.
  1. User asks a question in the chat.
  1. Frontend JS/Vue initiates websocket connection with Workhorse (This Workhorse instance runs locally in the test environment).
  1. Frontend JS/Vue sends a gRPC request to DWS through Workhorse (This DWS instance runs locally in the test environment).
     LLM responses are mocked for explicit assertions therefore test failures are reproducible.

### Run DAP feature tests when making a change in AI Gateway

These feature tests also run when we make a change to the AI Gateway repository, to verify that an MR does not accidentally break DAP features, for example:

1. A developer opens an MR in AI Gateway project.
1. A pipeline runs for the MR, which triggers downstream pipeline in GitLab project against `aigw/test-branch` test branch.
   This branch points to the same SHA as master.
1. If a pipeline fails, the developer should investigate if the proposed change doesn't accidentally introduce regressions.

> [!note]
> `aigw/test-branch` branch is unprotected by default for allowing AIGW & DWS maintainers to trigger downstream pipelines in GitLab project.

### Run a feature spec locally with your DWS/AIGW change

1. Run `gdk start` to start services including DWS.
1. Open terminal at `<gdk-root>/gitlab` and use one of the following options:
   - Run `export TEST_AI_GATEWAY_REPO_REF=<your-remote-feature-branch>` and delete `<gitlab-rails-root>/tmp/tests/gitlab-ai-gateway/` cache dir, _OR_
   - Run `export TEST_DUO_WORKFLOW_SERVICE_ENABLED="false" && export TEST_DUO_WORKFLOW_SERVICE_PORT=<your-local-dws-port>`.
     This allows the feature tests to request to your local DWS instance. Make sure the following configuration is set to your local DWS and it's running:
     - Set `true` to `AIGW_MOCK_MODEL_RESPONSES`
     - Set `true` to `AIGW_USE_AGENTIC_MOCK`
1. Run a feature spec e.g. `bundle exec rspec ee/spec/features/epic_boards/epic_boards_spec.rb`.

### See logs of a test case

DAP consists of multiple services and API calls.
To debug a test case failure, you may need to examine service logs to identify the root cause.
Here are the couple of pointers:

- GitLab-Rails REST API ... `log/api_json.log`
- GitLab-Rails GraphQL API ... `log/graphql_json.log`
- GitLab-Workhorse ... `log/workhorse-test.log`
- DWS ... Either stdout or `DUO_WORKFLOW_LOGGING__TO_FILE` in `gitlab-ai-gateway` repo.
- You can also examine the state of VueJS app by having JS console log output:

  ```ruby
  it 'runs a test' do
    ...

    # This prints the browser logs. Combine with `console.log()` in JavaScript.
    browser_logs.each do |log|
      puts "#{log.level}: #{log.message}"
    end

    ...
  end
  ```

## End-to-End testing

Use [end-to-end tests](end_to_end/_index.md) sparingly to verify AI features work with real provider responses. Key considerations:

- Keep tests minimal due to slower execution and potential provider outages.
- Account for non-deterministic AI responses in test design. For example, use deterministic assertions on controlled elements like chatbot names, not AI-generated content.

### E2E test examples

- GitLab: [`specs/features/ee/browser_ui/3_create/web_ide/code_suggestions_in_web_ide_spec.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/57d17110ef8f137ec8c1507e8d1a60ec194d6876/qa/qa/specs/features/ee/browser_ui/3_create/web_ide/code_suggestions_in_web_ide_spec.rb)
- JetBrains: [`test/kotlin/com/gitlab/plugin/e2eTest/tests/CodeSuggestionTest.kt`](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/blob/72bf52a7a652794546e7def85ea30a6fdd40a6f9/src/test/kotlin/com/gitlab/plugin/e2eTest/tests/CodeSuggestionTest.kt)

### Live environment testing

- **GitLab.com**: We run minimal E2E tests continuously against staging and production environments. For example, [Code Suggestions smoke tests](https://gitlab.com/gitlab-org/gitlab/-/blob/57d17110ef8f137ec8c1507e8d1a60ec194d6876/qa/qa/specs/features/ee/browser_ui/3_create/web_ide/code_suggestions_in_web_ide_spec.rb#L75).
- **GitLab Self-Managed**: We use the [`gitlab-qa`](https://gitlab.com/gitlab-org/gitlab-qa) orchestrator with [AI Gateway scenarios](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/what_tests_can_be_run.md#aigateway-scenarios) to test AI features on GitLab Self-Managed instances.

### Duo Agent Platform foundational flows

The Duo Agent Platform foundational-flow smoke tests are orchestrated end-to-end tests that drive a flow through a real CI pipeline.
The `gitlab-qa` orchestrator runs both tests as the `duo-agent-platform` job in the `e2e:test-on-omnibus-ee` child pipeline.

The `developer/v1` test creates a workflow through `POST /ai/duo_workflows/workflows` with `start_workflow: true`, then asserts that the `duo_workflow` source pipeline succeeds and the workflow reaches `finished`.
The `code_review/v1` test creates a merge request, then assigns the `GitLabDuo` review bot as its reviewer, the way a review is requested in the product.
It then asserts that the `duo_workflow` source pipeline succeeds, the flow reaches `finished`, and the review bot posts its review summary on the merge request.

The tests span two repositories.
The GitLab repository holds the specs and the flow provisioning helpers.
The [`gitlab-qa`](https://gitlab.com/gitlab-org/gitlab-qa) orchestrator holds the infrastructure that boots the Duo Workflow Service and routes the GitLab instance to it:

- `Component::DuoWorkflowService` boots the Duo Workflow Service from the same `model-gateway` image as the AI Gateway, switched to gRPC and agentic-mock mode, and captures the container logs to the job artifacts on teardown.
- `Test::Integration::AiGatewayBase` wires the Duo Workflow Service into the scenario and passes the `GITLAB_DUO_WORKFLOW_SERVICE_URL` and `GITLAB_DUO_WORKFLOW_SECURE` values into the omnibus Rails environment.
- `Test::Integration::DuoAgentPlatform` is a dedicated scenario, a subclass of the AI Gateway scenario, so the flows run in their own `duo-agent-platform` omnibus job and the Duo Workflow Service container stays out of the `ai-gateway` job.

The agentic-mock mode returns deterministic responses driven by directives, instead of calling a real model, the same approach the Duo Chat and Code Suggestions tests use for the AI Gateway.
Where those directives go depends on the flow.
The `developer/v1` goal is free-form, so its test puts directives in the flow goal.
A `code_review/v1` goal is validated to be a merge request IID or a merge request URL, so anything else returns `400`.
The Code Review test instead puts its directives in custom instructions, committed to the project's default branch as `.gitlab/duo/mr-review-instructions.yaml`, because that is the only field the flow copies into the model prompt unescaped.

Getting the escaping wrong makes the mock silently return placeholder text, so keep these rules in mind:

1. The mock parses the entire prompt as XML, so any unescaped `<`, `>`, or `&` anywhere in the merge request diff or title makes every scripted response degrade to a placeholder.
   Keep the seeded diff plain ASCII.
1. The mock reads only the text of the `<tool_calls>` element, so the JSON payload inside it must have its `<`, `>`, and `&` XML-escaped.
1. Each step of a flow builds its own model instance, so the script replays from the beginning in every step of the flow that calls a model.
   A tool call that a given step's toolset does not include fails that step, which then advances anyway.

`Gitlab::Duo::CodeReview::Modes::Dap` refuses Duo Agent Platform routing for a user holding a Duo Enterprise seat unless the root namespace has recorded consent for `:code_review_flow_dap_routing`.
Without that consent the reviewer assignment still succeeds, but falls back to the non-agentic review service, so no flow starts at all.
`enable_on_group!` therefore sends `create_code_review_flow_consent: true` whenever `code_review/v1` is the flow being enabled.
The API ignores that parameter when the namespace has no Duo Enterprise add-on, where consent is not required.

The following files in the GitLab repository make up the tests:

| File | Description |
| ---- | ----------- |
| `qa/qa/specs/features/ee/api/16_ai_powered/duo_foundational_flow_in_ci_spec.rb` | The Duo Developer flow spec. Provisions the flow, creates the workflow, and asserts the pipeline and workflow status. |
| `qa/qa/specs/features/ee/api/16_ai_powered/duo_code_review_flow_in_ci_spec.rb` | The Code Review flow spec. Seeds a merge request and the agentic-mock script, requests a review from the bot, then asserts the pipeline, the flow status, and the review posted on the merge request. |
| `qa/qa/ee/flow/foundational_flow.rb` | Provisioning helpers for the group, project, Duo seat, and flow consumer, and for requesting a code review from the bot. |
| `qa/qa/ee/resource/ai/duo_workflow.rb` | The `DuoWorkflow` API resource, the `FOUNDATIONAL_FLOWS` registry of flow references the resource can create, and the finder for a flow that GitLab created itself. |
| `qa/qa/ee/scenario/test/integration/duo_agent_platform.rb` | The scenario that selects the specs into the `duo-agent-platform` omnibus job. |

A foundational flow runs after four setup steps have completed in `foundational_flow.rb`:

1. `assign_duo_seat!` assigns a Duo seat to the acting user.
1. `enable_on_group!` enables the flow on the top-level group, which cascades to create an item consumer and service account.
1. `enable_remote_flows_on_project!` enables remote flows on the project.
1. `wait_for_flow_consumer!` waits until the consumer, its active service account, and the service-account project membership all resolve.
   The cascade in step 2 can lag on a cold instance, so this helper re-enables the flow until provisioning settles.

To add another foundational flow:

1. Pass the flow reference to the provisioning helpers from the spec.
1. Extend `enable_on_group!` if the flow gates on namespace consent or on a specific add-on.
1. Work out where the flow's prompt accepts mock directives, because the goal is not always available for that.
1. If the spec creates the flow through `POST /ai/duo_workflows/workflows`, register the flow reference in the `FOUNDATIONAL_FLOWS` registry in `qa/qa/ee/resource/ai/duo_workflow.rb`, with a `default_goal` only if the flow's goal is static.
   A flow whose goal names a resource, as Code Review does, needs `goal`, and `source_branch` if the flow checks out a branch, supplied by the spec.
   A flow that GitLab triggers itself is discovered with `DuoWorkflow.find_latest_in_project` instead, and needs no registry entry.

Custom catalog flows do not use the foundational flows list, so you must create the catalog item and its consumer directly rather than call `enable_on_group!`.

## Exploratory testing

Perform exploratory testing before significant milestones to uncover bugs outside expected workflows and UX issues. This is especially important for AI features as they progress through experiment, beta, and GA phases.

## Dogfooding

We [dogfood](https://handbook.gitlab.com/handbook/engineering/development/principles/#dogfooding) everything. This is especially important for AI features given the rapidly changing nature of the field. See the [dogfooding process](https://handbook.gitlab.com/handbook/product/product-processes/dogfooding-for-r-d/) for details.
