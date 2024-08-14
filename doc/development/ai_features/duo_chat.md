---
stage: AI-powered
group: Duo Chat
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# GitLab Duo Chat

GitLab Duo Chat aims to assist users with AI in ideation and creation tasks as well as in learning tasks across the entire Software Development Lifecycle (SDLC) to make them faster and more efficient.

[Chat](../../user/gitlab_duo_chat.md) is a part of the [GitLab Duo](../../user/ai_features.md)
offering.

Chat can answer different questions and perform certain tasks. It's done with
the help of [prompts](glossary.md) and [tools](#adding-a-new-tool).

To answer a user's question asked in the Chat interface, GitLab sends a
[GraphQL request](https://gitlab.com/gitlab-org/gitlab/-/blob/4cfd0af35be922045499edb8114652ba96fcba63/ee/app/graphql/mutations/ai/action.rb)
to the Rails backend. Rails backend sends then instructions to the Large
Language Model (LLM) through the [AI Gateway](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/ai_gateway/).

## Which use cases lend themselves most to contributing to Chat?

We aim to employ the Chat for all use cases and workflows that can benefit from a **conversational** interaction **between** **a user** and **an AI** that is driven by a large language model (LLM). Typically, these are:

- **Creation and ideation** task as well as **Learning** tasks that are more effectively and more efficiently solved through iteration than through a one-shot interaction.
- **Tasks** that are typically satisfiable with one-shot interactions but **that might need refinement or could turn into a conversation**.
- Among the latter are tasks where the **AI may not get it right the first time but** where **users can easily course correct** by telling the AI more precisely what they need. For instance, "Explain this code" is a common question that most of the time would result in a satisfying answer, but sometimes the user may have additional questions.
- **Tasks that benefit from the history of a conversation**, so neither the user nor the AI need to repeat themselves.

The chat aims to be context aware and ultimately have access to all the resources in GitLab that the user has access to. Initially, this context was limited to the content of individual issues and epics, as well as GitLab documentation. Since then additional contexts have been added, such as code selection and code files. Currently, work is underway contributing vulnerability context and pipeline job context, so that users can ask questions about these contexts.

To scale the context awareness and hence to scale creation, ideation, and learning use cases across the entire DevSecOps domain, the Duo Chat team welcomes contributions to the chat platform from other GitLab teams and the wider community. They are the experts for the use cases and workflows to accelerate.

### Which use cases are better implemented as stand-alone AI features?

Which use cases are better implemented as stand-alone AI features, or at least also as stand-alone AI features?

- Narrowly scoped tasks that be can accelerated by deeply integrating AI into an existing workflow.
- That can't benefit from conversations with AI.

To make this more tangible, here is an example.

Generating a commit message based on the changes is best implemented into the commit
message writing workflow.

- Without AI, commit message writing may take ten seconds.
- When autopopulating an AI-generated commit message in the **Commit message** field in the IDE, this brings the task down to one second.

Using Chat for commit message writing would probably take longer than writing the message oneself. The user would have to switch to the Chat window, type the request and then copy the result into the commit message field.

That said, it does not mean that Chat can't write commit messages, nor that it would be prevented from doing so. If Chat has the commit context (which may be added at some point for reasons other than commit message writing), the user can certainly ask to do anything with this commit content, including writing a commit message. But users are certainly unlikely to do that with Chat as they would only loose time. Note: the resulting commit messages may be different if created from chat with a prompt written by the user vs. a static prompt behind a purpose-built commit message creation.

## Set up GitLab Duo Chat

To set up Duo Chat locally, go through the
[general setup instructions for AI features](index.md).

## Working with GitLab Duo Chat

Prompts are the most vital part of GitLab Duo Chat system. Prompts are the
instructions sent to the LLM to perform certain tasks.

The state of the prompts is the result of weeks of iteration. If you want to
change any prompt in the current tool, you must put it behind a feature flag.

If you have any new or updated prompts, ask members of [Duo Chat team](https://handbook.gitlab.com/handbook/engineering/development/data-science/ai-powered/duo-chat/)
to review, because they have significant experience with them.

### Troubleshooting

When working with Chat locally, you might run into an error. Most commons
problems are documented in this section.
If you find an undocumented issue, you should document it in this section after
you find a solution.

| Problem                                                               | Solution                                                                                                                                                                                                                                                                              |
|-----------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| There is no Chat button in the GitLab UI.                             | Make sure your user is a part of a group with Premium or Ultimate license and enabled Chat.                                                                                                                                                                                              |
| Chat replies with "Forbidden by auth provider" error.                 | Backend can't access LLMs. Make sure your [AI Gateway](index.md#required-install-ai-gateway) is set up correctly.                                                                                                                                                                                      |
| Requests take too long to appear in UI                               | Consider restarting Sidekiq by running `gdk restart rails-background-jobs`. If that doesn't work, try `gdk kill` and then `gdk start`. Alternatively, you can bypass Sidekiq entirely. To do that temporary alter `Llm::CompletionWorker.perform_async` statements with `Llm::CompletionWorker.perform_inline` |
| There is no chat button in GitLab UI when GDK is running on non-SaaS mode | You do not have cloud connector access token record or seat assigned. To create cloud connector access record, in rails console put following code: `CloudConnector::Access.new(data: { available_services: [{ name: "duo_chat", serviceStartTime: ":date_in_the_future" }] }).save`. |

Please, see also the section on [error codes](#interpreting-gitlab-duo-chat-error-codes) where you can read about codes
that Chat sends to assist troubleshooting.

## Contributing to GitLab Duo Chat

From the code perspective, Chat is implemented in the similar fashion as other
AI features. Read more about GitLab [AI Abstraction layer](index.md#feature-development-abstraction-layer).

The Chat feature uses a [zero-shot agent](https://gitlab.com/gitlab-org/gitlab/blob/master/ee/lib/gitlab/llm/chain/agents/zero_shot/executor.rb)
that includes a system prompt explaining how the large language model should
interpret the question and provide an answer. The system prompt defines
available tools that can be used to gather information to answer the user's
question.

The zero-shot agent receives the user's question and decides which tools to use
to gather information to answer it. It then makes a request to the large
language model, which decides if it can answer directly or if it needs to use
one of the defined tools.

The tools each have their own prompt that provides instructions to the large
language model on how to use that tool to gather information. The tools are
designed to be self-sufficient and avoid multiple requests back and forth to the
large language model.

After the tools have gathered the required information, it is returned to the
zero-shot agent, which asks the large language model if enough information has
been gathered to provide the final answer to the user's question.

### Customizing interaction with GitLab Duo Chat

You can customize user interaction with GitLab Duo Chat in several ways.

#### Programmatically open GitLab Duo Chat

To provide users with a more dynamic way to access GitLab Duo Chat, you can
integrate functionality directly into their applications to open the GitLab Duo
Chat interface. The following example shows how to open the GitLab Duo Chat
drawer by using an event listener and the GitLab Duo Chat global state:

```javascript
import { duoChatGlobalState } from '~/super_sidebar/constants';
myFancyToggleToOpenChat.addEventListener('click', () => {
  duoChatGlobalState.isShown = true;
});
```

#### Initiating GitLab Duo Chat with a pre-defined prompt

In some scenarios, you may want to direct users towards a specific topic or
query when they open GitLab Duo Chat. We have a utility function that will
open DuoChat drawer and send a command in a queue for DuoChat to execute on.
This should trigger the loading state and the streaming with the given prompt.

```javascript
import { sendDuoChatCommand } from 'ee/ai/utils';
[...]

methods: {
  openChatWithPrompt() {
    sendDuoChatCommand(
      {
        question: '/feedback' // This is your prompt
        resourceId: 'gid:://gitlab/WorkItem/1', // A unique ID to identify the action for streaming
        variables: {} // Any additional graphql variables you want to pass to ee/app/assets/javascripts/ai/graphql/chat.mutation.graphql when executing the query
      }
    )
  }
}
```

Note that `sendDuoChatCommand` cannot be chained, meaning that you can send one command to DuoChat and have to wait until this action is done before sending a different command or the previous command might not work as expected.

This enhancement allows for a more tailored user experience by guiding the
conversation in GitLab Duo Chat towards predefined areas of interest or concern.

### Adding a new tool

To add a new tool you need to add changes both to [AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist)
and Rails Monolith. The main chat prompt is stored and assembled on AI Gateway. Rails side is responsible for assembling
required parameters of the prompt and sending them to AI Gateway. AI Gateway is responsible for assembling Chat prompt and
selecting Chat tools that are available for user based on their subscription and addon.

When LLM selects the tool to use, this tool is executed on the Rails side. Tools use different endpoint to make
a request to AI Gateway. When you add a new tool, please take into account that AI Gateway works with different clients
and GitLab applications that have different versions. That means that old versions of GitLab won't know about a new tool,
please contact Duo Chat team if you want to add a new tool. We're working on long-term solution for this [problem](https://gitlab.com/gitlab-org/gitlab/-/issues/466247).

#### Changes in AI Gateway

1. Create a new class for a tool in `ai_gateway/chat/tools/gitlab.py`. This class should include next properties:

    - `name` of the tool
    - GitLab `resource` that tool works with
    - `description` of what the tool does
    - `example` of question and desired answer

1. Add tool to `__all__` list of tools in `ai_gateway/chat/tools/gitlab.py`.

1. Add tool class to the `DuoChatToolsRegistry` in `ai_gateway/chat/toolset.py` with an appropriate Unit Primitive.

1. Add test for your changes.

#### Changes in Rails Monolith

1. Create files for the tool in the `ee/lib/gitlab/llm/chain/tools/` folder. Use existing tools like `issue_reader` or
   `epic_reader` as a template.

1. Write a class for the tool that includes instructions for the large language model on how to use the tool
to gather information - the main prompts that this tool is using.

1. Implement code in the tool to parse the response from the large language model and return it to the [chat agent](https://gitlab.com/gitlab-org/gitlab/-/blob/e0220502f1b3459b5a571d510ce5d1826877c3ce/ee/lib/gitlab/llm/chain/agents/single_action_executor.rb).

1. Add the new tool name to the `tools` array in `ee/lib/gitlab/llm/completions/chat.rb` so the agent knows about it.

#### Testing all together

Test and iterate on the prompt using RSpec tests that make real requests to the large language model.

- Prompts require trial and error, the non-deterministic nature of working with LLM can be surprising.
- Anthropic provides good [guide](https://docs.anthropic.com/claude/docs/intro-to-prompting) on working on prompts.
- GitLab [guide](prompts.md) on working with prompts.

The key things to keep in mind are properly instructing the large language model through prompts and tool descriptions,
keeping tools self-sufficient, and returning responses to the zero-shot agent. With some trial and error on prompts,
adding new tools can expand the capabilities of the Chat feature.

There are available short [videos](https://www.youtube.com/playlist?list=PL05JrBw4t0KoOK-bm_bwfHaOv-1cveh8i) covering this topic.

## Debugging

To gather more insights about the full request, use the `Gitlab::Llm::Logger` file to debug logs.
The default logging level on production is `INFO` and **must not** be used to log any data that could contain personal identifying information.

To follow the debugging messages related to the AI requests on the abstraction layer, you can use:

```shell
export LLM_DEBUG=1
gdk start
tail -f log/llm.log
```

### Debugging in production environment

All information related to debugging and troubleshooting in production environment is collected in [the Duo Chat On-Call Runbook](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/duo-chat).

## Tracing with LangSmith

Tracing is a powerful tool for understanding the behavior of your LLM application.
LangSmith has best-in-class tracing capabilities, and it's integrated with GitLab Duo Chat. Tracing can help you track down issues like:

- I'm new to GitLab Duo Chat and would like to understand what's going on under the hood.
- Where exactly the process failed when you got an unexpected answer.
- Which process was a bottle neck of the latency.
- What tool was used for an ambiguous question.

![LangSmith UI](img/langsmith.png)

Tracing is especially useful for evaluation that runs GitLab Duo Chat against large dataset.
LangSmith integration works with any tools, including [Prompt Library](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library)
and [RSpec tests](#testing-gitlab-duo-chat).

### Use tracing with LangSmith

NOTE:
Tracing is available in Development and Testing environment only.
It's not available in Production environment.

1. Access to [LangSmith](https://smith.langchain.com/) site and create an account (You can also be added to GitLab organization).
1. Create [an API key](https://docs.smith.langchain.com/#create-an-api-key) (be careful where you create API key - they can be created in personal namespace or in GL namespace).
1. Set the following environment variables in GDK. You can define it in `env.runit` or directly `export` in the terminal.

    ```shell
    export LANGCHAIN_TRACING_V2=true
    export LANGCHAIN_API_KEY='<your-api-key>'
    export LANGCHAIN_PROJECT='<your-project-name>'
    export LANGCHAIN_ENDPOINT='https://api.smith.langchain.com'
    export GITLAB_RAILS_RACK_TIMEOUT=180 # Extending puma timeout for using LangSmith with Prompt Library as the evaluation tool.
    ```

  Project name is the existing project in LangSmith or new one. It's enough to put new name in the environment variable -
project will be created during request.

1. Restart GDK.
1. Ask any question to chat.
1. Observe project in the LangSmith [page](https://smith.langchain.com/) > Projects > \[Project name\]. 'Runs' tab should contain
   your last requests.

## Testing GitLab Duo Chat

Because the success of answers to user questions in GitLab Duo Chat heavily depends
on toolchain and prompts of each tool, it's common that even a minor change in a
prompt or a tool impacts processing of some questions.

To make sure that a change in the toolchain doesn't break existing
functionality, you can use the following RSpec tests to validate answers to some
predefined questions when using real LLMs:

1. `ee/spec/lib/gitlab/llm/completions/chat_real_requests_spec.rb`
   This test validates that the zero-shot agent is selecting the correct tools
   for a set of Chat questions. It checks on the tool selection but does not
   evaluate the quality of the Chat response.
1. `ee/spec/lib/gitlab/llm/chain/agents/zero_shot/qa_evaluation_spec.rb`
   This test evaluates the quality of a Chat response by passing the question
   asked along with the Chat-provided answer and context to at least two other
   LLMs for evaluation. This evaluation is limited to questions about issues and
   epics only. Learn more about the [GitLab Duo Chat QA Evaluation Test](#gitlab-duo-chat-qa-evaluation-test).

If you are working on any changes to the GitLab Duo Chat logic, be sure to run
the [GitLab Duo Chat CI jobs](#testing-with-ci) the merge request that contains
your changes. Some of the CI jobs must be [manually triggered](../../ci/jobs/job_control.md#run-a-manual-job).

## Testing locally

To run the QA Evaluation test locally, the following environment variables
must be exported:

```ruby
ANTHROPIC_API_KEY='your-key' VERTEX_AI_PROJECT='your-project-id' REAL_AI_REQUEST=1 bundle exec rspec ee/spec/lib/gitlab/llm/completions/chat_real_requests_spec.rb
```

## Testing with CI

The following CI jobs for GitLab project run the tests tagged with `real_ai_request`:

- `rspec-ee unit gitlab-duo-chat-zeroshot`:
  the job runs `ee/spec/lib/gitlab/llm/completions/chat_real_requests_spec.rb`.
  The job must be manually triggered and is allowed to fail.

- `rspec-ee unit gitlab-duo-chat-qa`:
  The job runs the QA evaluation tests in
  `ee/spec/lib/gitlab/llm/chain/agents/zero_shot/qa_evaluation_spec.rb`.
  The job must be manually triggered and is allowed to fail.
  Read about [GitLab Duo Chat QA Evaluation Test](#gitlab-duo-chat-qa-evaluation-test).

- `rspec-ee unit gitlab-duo-chat-qa-fast`:
  The job runs a single QA evaluation test from `ee/spec/lib/gitlab/llm/chain/agents/zero_shot/qa_evaluation_spec.rb`.
  The job is always run and not allowed to fail. Although there's a chance that the QA test still might fail,
  it is cheap and fast to run and intended to prevent a regression in the QA test helpers.

- `rspec-ee unit gitlab-duo pg14`:
  This job runs tests to ensure that the GitLab Duo features are functional without running into system errors.
  The job is always run and not allowed to fail.
  This job does NOT conduct evaluations. The quality of the feature is tested in the other jobs such as QA jobs.

### Management of credentials and API keys for CI jobs

All API keys required to run the rspecs should be [masked](../../ci/variables/index.md#mask-a-cicd-variable)

The exception is GCP credentials as they contain characters that prevent them from being masked.
Because the CI jobs need to run on MR branches, GCP credentials cannot be added as a protected variable
and must be added as a regular CI variable.
For security, the GCP credentials and the associated project added to
GitLab project's CI must not be able to access any production infrastructure and sandboxed.

### GitLab Duo Chat QA Evaluation Test

Evaluation of a natural language generation (NLG) system such as
GitLab Duo Chat is a rapidly evolving area with many unanswered questions and ambiguities.

A practical working assumption is LLMs can generate a reasonable answer when given a clear question and a context.
With the assumption, we are exploring using LLMs as evaluators
to determine the correctness of a sample of questions
to track the overall accuracy of GitLab Duo Chat's responses and detect regressions in the feature.

For the discussions related to the topic,
see [the merge request](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/431)
and [the issue](https://gitlab.com/gitlab-org/gitlab/-/issues/427251).

The current QA evaluation test consists of the following components.

#### Epic and issue fixtures

The fixtures are the replicas of the _public_ issues and epics from projects and groups _owned by_ GitLab.
The internal notes were excluded when they were sampled. The fixtures have been commited into the canonical `gitlab` repository.
See [the snippet](https://gitlab.com/gitlab-org/gitlab/-/snippets/3613745) used to create the fixtures.

#### RSpec and helpers

1. [The RSpec file](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/spec/lib/gitlab/llm/chain/agents/zero_shot/qa_evaluation_spec.rb)
   and the included helpers invoke the Chat service, an internal interface with the question.

1. After collecting the Chat service's answer,
   the answer is injected into a prompt, also known as an "evaluation prompt", that instructs
   a LLM to grade the correctness of the answer based on the question and a context.
   The context is simply a JSON serialization of the issue or epic being asked about in each question.

1. The evaluation prompt is sent to two LLMs, Claude and Vertex.

1. The evaluation responses of the LLMs are saved as JSON files.

1. For each question, RSpec will regex-match for `CORRECT` or `INCORRECT`.

#### Collection and tracking of QA evaluation with CI/CD automation

The `gitlab` project's CI configurations have been setup to run the RSpec,
collect the evaluation response as artifacts and execute
[a reporter script](https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/duo_chat/reporter.rb)
that automates collection and tracking of evaluations.

When `rspec-ee unit gitlab-duo-chat-qa` job runs in a pipeline for a merge request,
the reporter script uses the evaluations saved as CI artifacts
to generate a Markdown report and posts it as a note in the merge request.

To keep track of and compare QA test results over time, you must manually
run the `rspec-ee unit gitlab-duo-chat-qa` on the `master` the branch:

1. Visit the [new pipeline page](https://gitlab.com/gitlab-org/gitlab/-/pipelines/new).
1. Select "Run pipeline" to run a pipeline against the `master` branch
1. When the pipeline first starts, the `rspec-ee unit gitlab-duo-chat-qa` job under the
   "Test" stage will not be available. Wait a few minutes for other CI jobs to
   run and then manually kick off this job by selecting the "Play" icon.

When the test runs on `master`, the reporter script posts the generated report as an issue,
saves the evaluations artifacts as a snippet, and updates the tracking issue in
[`GitLab-org/ai-powered/ai-framework/qa-evaluation#1`](https://gitlab.com/gitlab-org/ai-powered/ai-framework/qa-evaluation/-/issues/1)
in the project [`GitLab-org/ai-powered/ai-framework/qa-evaluation`](https://gitlab.com/gitlab-org/ai-powered/ai-framework/qa-evaluation).

### GitLab Duo Chat Self-managed End-to-End Tests

In MRs, the end-to-end tests exercise the Duo Chat functionality of self-managed instances by using an instance of the GitLab Linux package
integrated with the `latest` version of AI Gateway. The instance of AI Gateway is configured to return [mock responses](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist#mocking-ai-model-responses).
To view the results of these tests, open the `e2e:package-and-test-ee` child pipeline and view the `ai-gateway` job.

The `ai-gateway` job activates a cloud license and then assigns a Duo Pro seat to a test user, before the tests are run.

For further information, please refer to the [GitLab QA documentation](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/what_tests_can_be_run.md#aigateway-scenarios)

## GraphQL Subscription

The GraphQL Subscription for Chat behaves slightly different because it's user-centric. A user could have Chat open on multiple browser tabs, or also on their IDE.
We therefore need to broadcast messages to multiple clients to keep them in sync. The `aiAction` mutation with the `chat` action behaves the following:

1. All complete Chat messages (including messages from the user) are broadcasted with the `userId`, `aiAction: "chat"` as identifier.
1. Chunks from streamed Chat messages are broadcasted with the `clientSubscriptionId` from the mutation as identifier.

Examples of GraphQL Subscriptions in a Vue component:

1. Complete Chat message

   ```javascript
   import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
   [...]

   apollo: {
    $subscribe: {
      aiCompletionResponse: {
        query: aiResponseSubscription,
        variables() {
          return {
            userId, // for example "gid://gitlab/User/1"
            aiAction: 'CHAT',
          };
        },
        result({ data }) {
          // handle data.aiCompletionResponse
        },
        error(err) {
          // handle error
        },
      },
    },
   ```

1. Streamed Chat message

   ```javascript
   import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
   [...]

   apollo: {
    $subscribe: {
      aiCompletionResponseStream: {
        query: aiResponseSubscription,
        variables() {
          return {
            aiAction: 'CHAT',
            userId, // for example "gid://gitlab/User/1"
            clientSubscriptionId // randomly generated identifier for every message
            htmlResponse: false, // important to bypass HTML processing on every chunk
          };
        },
        result({ data }) {
          // handle data.aiCompletionResponse
        },
        error(err) {
          // handle error
        },
      },
    },
   ```

Please keep in mind that the clientSubscriptionId must be unique for every request. Reusing a clientSubscriptionId will cause several unwanted side effects in the subscription responses.

### Duo Chat GraphQL queries

1. [Set up GitLab Duo Chat](#set-up-gitlab-duo-chat)
1. Visit [GraphQL explorer](../../api/graphql/index.md#interactive-graphql-explorer).
1. Execute the `aiAction` mutation. Here is an example:

   ```graphql
   mutation {
     aiAction(
       input: {
         chat: {
           resourceId: "gid://gitlab/User/1",
           content: "Hello"
         }
       }
     ){
       requestId
       errors
     }
   }
   ```

1. Execute the following query to fetch the response:

   ```graphql
   query {
     aiMessages {
       nodes {
         requestId
         content
         role
         timestamp
         chunkId
         errors
       }
     }
   }
   ```

If you can't fetch the response, check `graphql_json.log`,
`sidekiq_json.log`, `llm.log` or `modelgateway_debug.log` if it contains error
information.

## Testing GitLab Duo Chat in production-like environments

GitLab Duo Chat is enabled in the [Staging](https://staging.gitlab.com/users/sign_in) and
[Staging Ref](https://staging-ref.gitlab.com/) GitLab environments.

Because GitLab Duo Chat is currently only available to members of groups in the
Premium and Ultimate tiers, Staging Ref may be an easier place to test changes as a GitLab
team member because
[you can make yourself an instance Admin in Staging Ref](https://handbook.gitlab.com/handbook/engineering/infrastructure/environments/staging-ref/#admin-access)
and, as an Admin, easily create licensed groups for testing.

### GitLab Duo Chat End-to-End Tests in live environments

Duo Chat end-to-end tests run continuously against [Staging](https://staging.gitlab.com/users/sign_in) and [Production](https://gitlab.com/) GitLab environments.

These tests run in scheduled pipelines and ensure the end-to-end user experiences are functioning correctly.
Results can be viewed in the `#qa-staging` and `#qa-production` Slack channels. The pipelines can be found below, access can be requested in `#test-platform`:

- [Staging-canary pipelines](https://ops.gitlab.net/gitlab-org/quality/staging-canary/-/pipelines)
- [Staging pipelines](https://ops.gitlab.net/gitlab-org/quality/staging/-/pipelines)
- [Canary pipelines](https://ops.gitlab.net/gitlab-org/quality/canary/-/pipelines)
- [Production pipelines](https://ops.gitlab.net/gitlab-org/quality/production/-/pipelines)

## Product Analysis

To better understand how the feature is used, each production user input message is analyzed using LLM and Ruby,
and the analysis is tracked as a Snowplow event.

The analysis can contain any of the attributes defined in the latest [iglu schema](https://gitlab.com/gitlab-org/iglu/-/blob/master/public/schemas/com.gitlab/ai_question_category/jsonschema).

- All possible "category" and "detailed_category" are listed [here](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/llm/fixtures/categories.xml).
- The following is yet to be implemented:
  - "is_proper_sentence"
- The following are deprecated:
  - "number_of_questions_in_history"
  - "length_of_questions_in_history"
  - "time_since_first_question"

[Dashboards](https://handbook.gitlab.com/handbook/engineering/development/data-science/duo-chat/#-dashboards-internal-only) can be created to visualize the collected data.

## How `access_duo_chat` policy works

This table describes the requirements for the `access_duo_chat` policy to
return `true` in different contexts.

| | GitLab.com | Dedicated or Self-managed | All instances |
|----------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------|
| for user outside of project or group (`user.can?(:access_duo_chat)`)  | User need to belong to at least one group on Premium or Ultimate tier with `duo_features_enabled` group setting switched on | - Instance needs to be on Premium or Ultimate tier<br>- Instance needs to have `duo_features_enabled` setting switched on |  |
| for user in group context (`user.can?(:access_duo_chat, group)`)     | - User needs to belong to at least one group on Premium or Ultimate tier with `experiment_and_beta_features` group setting switched on<br>- Root ancestor group of the group needs to be on Premium or Ultimate tier and the group must have `duo_features_enabled` setting switched on | - Instance needs to be on Premium or Ultimate tier<br>- Instance needs to have `duo_features_enabled` setting switched on | User must have at least _read_ permissions on the group |
| for user in project context (`user.can?(:access_duo_chat, project)`) | - User needs to belong to at least one group on the Premium or Ultimate tier with `experiment_and_beta_features` group setting enabled<br>- Project root ancestor group needs to be on Premium or Ultimate tier and project must have `duo_features_enabled` setting switched on | - Instance need to be on Ultimate tier<br>- Instance needs to have `duo_features_enabled` setting switched on | User must to have at least _read_ permission on the project |

## Running GitLab Duo Chat prompt experiments

Before being merged, all prompt or model changes for GitLab Duo Chat should both:

1. Be behind a feature flag *and*
1. Be evaluated locally

The type of local evaluation needed depends on the type of change. GitLab Duo
Chat local evaluation using the Prompt Library is an effective way of measuring
average correctness of responses to questions about issues and epics.

Follow the
[Prompt Library guide](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library/-/blob/main/doc/how-to/run_duo_chat_eval.md#configuring-duo-chat-with-local-gdk)
to evaluate GitLab Duo Chat changes locally. The prompt library documentation is
the single source of truth and should be the most up-to-date.

Please, see the video ([internal link](https://drive.google.com/file/d/1X6CARf0gebFYX4Rc9ULhcfq9LLLnJ_O-)) that covers the full setup.

## How a Chat prompt is constructed

All Chat requests are resolved with the GitLab GraphQL API. And, for now,
prompts for 3rd party LLMs are hard-coded into the GitLab codebase.

But if you want to make a change to a Chat prompt, it isn't as obvious as
finding the string in a single file. Chat prompt construction is hard to follow
because the prompt is put together over the course of many steps. Here is the
flow of how we construct a Chat prompt:

1. API request is made to the GraphQL AI Mutation; request contains user Chat
   input.
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/676cca2ea68d87bcfcca02a148c354b0e4eabc97/ee/app/graphql/mutations/ai/action.rb#L6))
1. GraphQL mutation calls `Llm::ExecuteMethodService#execute`
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/676cca2ea68d87bcfcca02a148c354b0e4eabc97/ee/app/graphql/mutations/ai/action.rb#L43))
1. `Llm::ExecuteMethodService#execute` sees that the `chat` method was sent to
   the GraphQL API and calls `Llm::ChatService#execute`
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/676cca2ea68d87bcfcca02a148c354b0e4eabc97/ee/app/services/llm/execute_method_service.rb#L36))
1. `Llm::ChatService#execute` calls `schedule_completion_worker`, which is
   defined in `Llm::BaseService` (the base class for `ChatService`)
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/676cca2ea68d87bcfcca02a148c354b0e4eabc97/ee/app/services/llm/base_service.rb#L72-87))
1. `schedule_completion_worker` calls `Llm::CompletionWorker.perform_for`, which
   asynchronously enqueues the job
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/676cca2ea68d87bcfcca02a148c354b0e4eabc97/ee/app/workers/llm/completion_worker.rb#L33))
1. `Llm::CompletionWorker#perform` is called when the job runs. It deserializes
   the user input and other message context and passes that over to
   `Llm::Internal::CompletionService#execute`
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/676cca2ea68d87bcfcca02a148c354b0e4eabc97/ee/app/workers/llm/completion_worker.rb#L44))
1. `Llm::Internal::CompletionService#execute` calls
   `Gitlab::Llm::CompletionsFactory#completion!`, which pulls the `ai_action`
   from original GraphQL request and initializes a new instance of
   `Gitlab::Llm::Completions::Chat` and calls `execute` on it
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/55b8eb6ff869e61500c839074f080979cc60f9de/ee/lib/gitlab/llm/completions_factory.rb#L89))
1. `Gitlab::Llm::Completions::Chat#execute` calls `Gitlab::Llm::Chain::Agents::SingleActionExecutor`.
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/d539f64ce6c5bed72ab65294da3bcebdc43f68c6/ee/lib/gitlab/llm/completions/chat.rb#L128-134))
1. `Gitlab::Llm::Chain::Agents::SingleActionExecutor#execute` calls
   `execute_streamed_request`, which calls `request`, a method defined in the
   `AiDependent` concern
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/d539f64ce6c5bed72ab65294da3bcebdc43f68c6/ee/lib/gitlab/llm/chain/agents/zero_shot/executor.rb#L85))
1. The `SingleActionExecutor#prompt_options` method assembles all prompt parameters for the AI Gateway request
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/971d07aa37d9f300b108ed66304505f2d7022841/ee/lib/gitlab/llm/chain/agents/single_action_executor.rb#L120-120))
1. `ai_request` is defined in `Llm::Completions::Chat` and evaluates to
   `AiGateway`([code](https://gitlab.com/gitlab-org/gitlab/-/blob/971d07aa37d9f300b108ed66304505f2d7022841/ee/lib/gitlab/llm/completions/chat.rb#L51-51))
1. `ai_request.request` routes to `Llm::Chain::Requests::AiGateway#request`,
   which calls `ai_client.stream`
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/e88256b1acc0d70ffc643efab99cad9190529312/ee/lib/gitlab/llm/chain/requests/ai_gateway.rb#L20-27))
1. `ai_client.stream` routes to `Gitlab::Llm::AiGateway::Client#stream`, which
   makes an API request to the AI Gateway `/v2/chat/agent` endpoint
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/e88256b1acc0d70ffc643efab99cad9190529312/ee/lib/gitlab/llm/ai_gateway/client.rb#L64-82))
1. AI Gateway receives the request
   ([code](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/e6f55d143ecb5409e8ca4fefc042e590e5a95158/ai_gateway/api/v2/chat/agent.py#L43-43))
1. AI Gateway gets the list of tools available for user
   ([code](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/e6f55d143ecb5409e8ca4fefc042e590e5a95158/ai_gateway/chat/toolset.py#L43-43))
1. AI GW gets definitions for each tool
   ([code](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/e6f55d143ecb5409e8ca4fefc042e590e5a95158/ai_gateway/chat/tools/gitlab.py#L11-11))
1. And they are inserted into prompt template alongside other prompt parameters that come from Rails
   ([code](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/e6f55d143ecb5409e8ca4fefc042e590e5a95158/ai_gateway/agents/definitions/chat/react/base.yml#L14-14))
1. AI Gateway makes request to LLM and return response to Rails.
   ([code](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/e6f55d143ecb5409e8ca4fefc042e590e5a95158/ai_gateway/api/v2/chat/agent.py#L103-103))
1. We've now made our first request to the AI Gateway. If the LLM says that the
   answer to the first request is a final answer, we
   [parse the answer](https://gitlab.com/gitlab-org/gitlab/-/blob/971d07aa37d9f300b108ed66304505f2d7022841/ee/lib/gitlab/llm/chain/parsers/single_action_parser.rb#L41-42)
   and stream it ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/971d07aa37d9f300b108ed66304505f2d7022841/ee/lib/gitlab/llm/chain/concerns/ai_dependent.rb#L25-25))
   and return it ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/971d07aa37d9f300b108ed66304505f2d7022841/ee/lib/gitlab/llm/chain/agents/single_action_executor.rb#L46-46))
1. If the first answer is not final, the "thoughts" and "picked tools"
   from the first LLM request are parsed and then the relevant tool class is
   called.
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/971d07aa37d9f300b108ed66304505f2d7022841/ee/lib/gitlab/llm/chain/agents/single_action_executor.rb#L54-54))
1. The tool executor classes also include `Concerns::AiDependent` and use the
   included `request` method similar to how the chat executor does
  ([example](https://gitlab.com/gitlab-org/gitlab/-/blob/70fca6dbec522cb2218c5dcee66caa908c84271d/ee/lib/gitlab/llm/chain/tools/identifier.rb#L8)).
   The `request` method uses the same `ai_request` instance
   that was injected into the `context` in `Llm::Completions::Chat`. For Chat,
   this is `Gitlab::Llm::Chain::Requests::AiGateway`. So, essentially the same
   request to the AI Gateway is put together but with a different
   `prompt` / `PROMPT_TEMPLATE` than for the first request
   ([Example tool prompt template](https://gitlab.com/gitlab-org/gitlab/-/blob/70fca6dbec522cb2218c5dcee66caa908c84271d/ee/lib/gitlab/llm/chain/tools/issue_identifier/executor.rb#L39-104))
1. If the tool answer is not final, the response is added to `agent_scratchpad`
   and the loop in `SingleActionExecutor` starts again, adding the additional
   context to the request. It loops to up to 10 times until a final answer is reached.

## Interpreting GitLab Duo Chat error codes

GitLab Duo Chat has error codes with specified meanings to assist in debugging.

See the [GitLab Duo Chat troubleshooting documentation](../../user/gitlab_duo_chat/troubleshooting.md) for a list of all GitLab Duo Chat error codes.

When developing for GitLab Duo Chat, please include these error codes when returning an error and [document them](../../user/gitlab_duo_chat/troubleshooting.md), especially for user-facing errors.

### Error Code Format

The error codes follow the format: `<Layer Identifier><Four-digit Series Number>`.

For example:

- `M1001`: A network communication error in the monolith layer.
- `G2005`: A data formatting/processing error in the AI gateway layer.
- `A3010`: An authentication or data access permissions error in a third-party API.

### Error Code Layer Identifier

| Code | Layer           |
|------|-----------------|
| M    | Monolith        |
| G    | AI Gateway      |
| A    | Third-party API |

### Error Series

| Series | Type                                                                         |
|--------|------------------------------------------------------------------------------|
| 1000   | Network communication errors                                                 |
| 2000   | Data formatting/processing errors                                            |
| 3000   | Authentication and/or data access permission errors                          |
| 4000   | Code execution exceptions                                                    |
| 5000   | Bad configuration or bad parameters errors                                   |
| 6000   | Semantic or inference errors (the model does not understand or hallucinates) |
