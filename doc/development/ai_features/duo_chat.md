---
stage: AI-powered
group: Duo Chat
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: GitLab Duo Chat
---

GitLab Duo Chat aims to assist users with AI in ideation and creation tasks as
well as in learning tasks across the entire Software Development Lifecycle
(SDLC) to make them faster and more efficient.

[Chat](../../user/gitlab_duo_chat/_index.md) is a part of the [GitLab Duo](../../user/ai_features.md)
offering.

Chat can answer different questions and perform certain tasks. It's done with
the help of [prompts](glossary.md) and [tools](#adding-a-new-tool).

To answer a user's question asked in the Chat interface, GitLab sends a
[GraphQL request](https://gitlab.com/gitlab-org/gitlab/-/blob/4cfd0af35be922045499edb8114652ba96fcba63/ee/app/graphql/mutations/ai/action.rb)
to the Rails backend. Rails backend sends then instructions to the Large
Language Model (LLM) through the [AI gateway](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/ai_gateway/).

## Which use cases lend themselves most to contributing to Chat?

We aim to employ the Chat for all use cases and workflows that can benefit from a **conversational** interaction **between** **a user** and **an AI** that is driven by a large language model (LLM). Typically, these are:

- **Creation and ideation** task as well as **Learning** tasks that are more effectively and more efficiently solved through iteration than through a one-shot interaction.
- **Tasks** that are typically satisfiable with one-shot interactions but **that might need refinement or could turn into a conversation**.
- Among the latter are tasks where the **AI may not get it right the first time but** where **users can easily course correct** by telling the AI more precisely what they need. For instance, "Explain this code" is a common question that most of the time would result in a satisfying answer, but sometimes the user may have additional questions.
- **Tasks that benefit from the history of a conversation**, so neither the user nor the AI need to repeat themselves.

Chat aims to be context aware and ultimately have access to all the resources in GitLab that the user has access to. Initially, this context was limited to the content of individual issues and epics, as well as GitLab documentation. Since then additional contexts have been added, such as code selection and code files. Currently, work is underway contributing vulnerability context and pipeline job context, so that users can ask questions about these contexts.

To scale the context awareness and hence to scale creation, ideation, and learning use cases across the entire DevSecOps domain, the Duo Chat team welcomes contributions to the Chat platform from other GitLab teams and the wider community. They are the experts for the use cases and workflows to accelerate.

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

That said, it does not mean that Chat can't write commit messages, nor that it would be prevented from doing so. If Chat has the commit context (which may be added at some point for reasons other than commit message writing), the user can certainly ask to do anything with this commit content, including writing a commit message. But users are certainly unlikely to do that with Chat as they would only loose time. Note: the resulting commit messages may be different if created from Chat with a prompt written by the user vs. a static prompt behind a purpose-built commit message creation.

## Set up GitLab Duo Chat

To set up Duo Chat locally, go through the
[general setup instructions for AI features](_index.md).

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
| Chat replies with "Forbidden by auth provider" error.                 | Backend can't access LLMs. Make sure your [AI gateway](_index.md#required-install-ai-gateway) is set up correctly.                                                                                                                                                                                      |
| Requests take too long to appear in UI                               | Consider restarting Sidekiq by running `gdk restart rails-background-jobs`. If that doesn't work, try `gdk kill` and then `gdk start`. Alternatively, you can bypass Sidekiq entirely. To do that temporary alter `Llm::CompletionWorker.perform_async` statements with `Llm::CompletionWorker.perform_inline` |
| There is no Chat button in GitLab UI when GDK is running on non-SaaS mode | You do not have cloud connector access token record or seat assigned. To create cloud connector access record, in rails console put following code: `CloudConnector::Access.new(data: { available_services: [{ name: "duo_chat", serviceStartTime: ":date_in_the_future" }] }).save`. |

For more information, see [interpreting GitLab Duo Chat error codes](#interpreting-gitlab-duo-chat-error-codes).
that Chat sends to assist troubleshooting.

## Contributing to GitLab Duo Chat

From the code perspective, Chat is implemented in the similar fashion as other
AI features. Read more about GitLab [AI Abstraction layer](_index.md#feature-development-abstraction-layer).

The Chat feature uses a [zero-shot agent](https://gitlab.com/gitlab-org/gitlab/blob/master/ee/lib/gitlab/duo/chat/react_executor.rb)
that sends user question and relevant context to the [AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist)
which construct a prompt and sends the request to the large language model.

Large language model decides if it can answer directly or if it needs to use
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

To add a new tool you need to add changes both to [AI gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist)
and Rails Monolith. The main chat prompt is stored and assembled on AI gateway. Rails side is responsible for assembling
required parameters of the prompt and sending them to AI gateway. AI gateway is responsible for assembling Chat prompt and
selecting Chat tools that are available for user based on their subscription and addon.

When LLM selects the tool to use, this tool is executed on the Rails side. Tools use different endpoint to make
a request to AI gateway. When you add a new tool, take into account that AI gateway works with different clients
and GitLab applications that have different versions. That means that old versions of GitLab won't know about a new tool.
If you want to add a new tool, contact the Duo Chat team. We're working on long-term solution for this [problem](https://gitlab.com/gitlab-org/gitlab/-/issues/466247).

#### Changes in AI gateway

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
- GitLab [guide](ai_feature_development_playbook.md) on working with prompts.

The key things to keep in mind are properly instructing the large language model through prompts and tool descriptions,
keeping tools self-sufficient, and returning responses to the zero-shot agent. With some trial and error on prompts,
adding new tools can expand the capabilities of the Chat feature.

There are available short [videos](https://www.youtube.com/playlist?list=PL05JrBw4t0KoOK-bm_bwfHaOv-1cveh8i) covering this topic.

### Working with multi-thread conversation

If you're building features that interact with Duo Chat conversations, you need to understand how threads work.

Duo Chat supports multiple conversations. Each conversation is represented by a thread, which contains multiple messages. The important attributes of a thread are:

- `id`: The `id` is required when replying to a thread.
- `conversation_type`: This allows for distinguishing between the different available Duo Chat conversation types. See the [thread conversation types list](../../api/graphql/reference/_index.md#aiconversationsthreadsconversationtype).
  - If your feature needs its own conversation type, contact the Duo Chat team.

If your feature requires calling GraphQL API directly, the following queries and mutations are available, for which you **must** specify the `conversation_type`.

- [Query.aiConversationThreads](../../api/graphql/reference/_index.md#queryaiconversationthreads): lists threads
- [Query.aiMessages](../../api/graphql/reference/_index.md#queryaimessages): lists one thread's messages. **Must** specify `threadId`.
- [Mutation.aiAction](../../api/graphql/reference/_index.md#mutationaiaction): creates one message. If `threadId` is specified the message is appended into that thread.

All chat conversations have a retention period, controlled by the admin. The default retention period is 30 days after last reply.

- [Configure Duo Chat Conversation Expiration](../../user/gitlab_duo_chat/_index.md#configure-chat-conversation-expiration)

### Developer Resources

- [Example GraphQL Queries](#duo-chat-conversation-threads-graphql-queries) - See examples below in this document

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

![LangSmith UI](img/langsmith_v16_10.png)

Tracing is especially useful for evaluation that runs GitLab Duo Chat against large dataset.
LangSmith integration works with any tools, including [Prompt Library](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library).

### Use tracing with LangSmith

{{< alert type="note" >}}

Tracing is available in Development and Testing environment only.
It's not available in Production environment.

{{< /alert >}}

1. Access [LangSmith](https://smith.langchain.com/) and create an account
   1. Optional: [Create an Access Request](https://gitlab.com/gitlab-com/team-member-epics/access-requests/-/issues/new?issuable_template=Individual_Bulk_Access_Request) to be added to the GitLab organization in LangSmith.
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
1. Ask any question to Chat.
1. Observe project in the LangSmith [page](https://smith.langchain.com/) > Projects > \[Project name\]. 'Runs' tab should contain
   your last requests.

## Evaluate your merge request in one click

To evaluate your merge request with [Central Evaluation Framework](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library) (a.k.a. CEF),
you can use [Evaluation Runner](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/evaluation-runner) (internal only).
Follow [run evaluation on your merge request](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/evaluation-runner#run-evaluation-on-your-merge-request) instruction.

### Prevent regressions in your merge request

When you make a change to Duo Chat or related components,
you should run the [regression evaluator](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library/-/blob/main/doc/eli5/duo_chat/regression_evaluator.md)
to detect quality degradation and bugs in the merge request.
It covers any Duo Chat execution patterns, including tool execution and slash commands.

To run the regression evaluator, [run evaluation on your merge request](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/evaluation-runner#run-evaluation-on-your-merge-request) and click a play button for the regression evaluator.
Later, you can [compare the evaluation result of the merge request against master](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/evaluation-runner#compare-the-evaluation-result-of-your-merge-request-against-master).
Make sure that there are no quality degradation and bugs in the [LangSmith's comparison page](https://docs.smith.langchain.com/evaluation/how_to_guides/compare_experiment_results).

While there are no strict guidelines for interpreting the comparison results, here are some helpful tips to consider:

- If the number of degraded scores exceeds the number of improved scores, it may indicate that the merge request has introduced a quality degradation.
- If any examples encounter errors during evaluation, it could suggest a potential bug in the merge request.

In either of these scenarios, we recommend further investigation:

1. Compare your results with [the daily evaluation results](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/evaluation-runner#view-daily-evaluation-result-on-master). For instance, look at the daily evaluations from yesterday and the day before.
1. If you observe similar patterns in these daily evaluations, it's likely that your merge request is safe to merge. However, if the patterns differ, it may indicate that your merge request has introduced unexpected changes.

We strongly recommend running the regression evaluator in at least the following environments:

| Environment                                                                 | Evaluation pipeline name                                  |
| -----------                                                                 | ------------------------                                  |
| GitLab Self-Managed and a custom model that is widely adopted               | `duo-chat regression sm: [bedrock_mistral_8x7b_instruct]` |
| GitLab.com and GitLab Duo Enterprise add-on                                 | `duo-chat regression .com: [duo_enterprise]`              |
| GitLab.com and GitLab Duo Pro add-on                                        | `duo-chat regression .com: [duo_pro]`                     |

Additionally, you can run other evaluators, such as `gitlab-docs`, which has a more comprehensive dataset for specific scopes.
See [available evaluation pipelines](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/evaluation-runner#evaluation-pipelines) for more information.

### Add an example to the regression dataset

When you introduce a new feature or received a regression report from users, you should add a new example to the regression dataset for expanding the coverage.
To add an example to the regression dataset, follow [this section](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library/-/blob/main/doc/eli5/duo_chat/regression_evaluator.md#guideline).

For more information, see [the guideline of the regression evaluator](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library/-/blob/main/doc/eli5/duo_chat/regression_evaluator.md#guideline).

## GitLab Duo Chat Self-managed End-to-End Tests

In MRs, the end-to-end tests exercise the Duo Chat functionality of GitLab Self-Managed instances by using an instance of the GitLab Linux package
integrated with the `latest` version of AI gateway. The instance of AI gateway is configured to return [mock responses](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist#mocking-ai-model-responses).
To view the results of these tests, open the `e2e:test-on-omnibus-ee` child pipeline and view the `ai-gateway` job.

The `ai-gateway` job activates a cloud license and then assigns a Duo Pro seat to a test user, before the tests are run.

For more information, see [AiGateway Scenarios](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/what_tests_can_be_run.md#aigateway-scenarios).

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

Keep in mind that the `clientSubscriptionId` must be unique for every request. Reusing a `clientSubscriptionId` will cause several unwanted side effects in the subscription responses.

### Duo Chat GraphQL queries

1. [Set up GitLab Duo Chat](#set-up-gitlab-duo-chat)
1. Visit [GraphQL explorer](../../api/graphql/_index.md#interactive-graphql-explorer).
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

### Duo Chat Conversation Threads GraphQL queries

#### Querying messages in a conversation thread

To retrieve messages from a specific thread, use the `aiMessages` query with a thread ID:

```graphql
query {
  aiMessages(threadId: "gid://gitlab/Ai::Conversation::Thread/1") {
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

#### Starting a new conversation thread

If you don't include a threadId in your aiAction mutation, a new thread will be created:

```graphql
mutation {
  aiAction(input: {
    chat: {
      content: "This will create a new conversation thread"
    },
    conversationType: DUO_CHAT
  })
  {
    requestId
    errors
    threadId  # This will contain the ID of the newly created thread
  }
}
```

#### Creating a new message in an existing conversation thread

To add a message to an existing thread, include the threadId in your aiAction mutation:

```graphql
mutation {
  aiAction(input: {
    chat: {
      content: "this is another message in the same thread"
    },
    conversationType: DUO_CHAT,
    threadId: "gid://gitlab/Ai::Conversation::Thread/1",
  })
  {
    requestId
    errors
    threadId
  }
}
```

## Testing GitLab Duo Chat in production-like environments

GitLab Duo Chat is enabled in the [Staging](https://staging.gitlab.com/users/sign_in) and
[Staging Ref](https://staging-ref.gitlab.com/) GitLab environments.

Because GitLab Duo Chat is currently only available to members of groups in the
Premium and Ultimate tiers, Staging Ref may be an easier place to test changes as a GitLab
team member because
[you can make yourself an instance Admin in Staging Ref](https://handbook.gitlab.com/handbook/engineering/infrastructure/environments/staging-ref/#admin-access)
and, as an Admin, easily create licensed groups for testing.

### Important Testing Considerations

**Note**: A user who has a seat in multiple groups with different tiers of Duo add-on gets the highest tier experience across the entire instance.

It's not possible to test feature separation between different Duo add-ons if your test account has a seat in a higher tier add-on.
To properly test different tiers, create a separate test account for each tier you need to test.

### Staging testing groups

To simplify testing on [staging](https://staging.gitlab.com), several pre-configured groups have been created with the appropriate licenses and add-ons:

| Group | Duo Add-on | GitLab license |
| --- | --- | --- |
| [`duo_pro_gitlab_premium`](https://staging.gitlab.com/groups/duo_pro_gitlab_premium) | Pro | Premium |
| [`duo_pro_gitlab_ultimate`](https://staging.gitlab.com/groups/duo_pro_gitlab_ultimate) | Pro | Ultimate |
| [`duo_enterprise_gitlab_ultimate`](https://staging.gitlab.com/groups/duo_enterprise_gitlab_ultimate) | Enterprise | Ultimate |

Ask in the `#g_duo_chat` channel on Slack to be added as an Owner to these groups.
Once added as an Owner, you can add your secondary accounts to the group with a role Developer and assign them a seat in the Duo add-on.
Then you can sign in as your Developer user and test access control to Duo Chat.

### GitLab Duo Chat End-to-End Tests in live environments

Duo Chat end-to-end tests run continuously against [Staging](https://staging.gitlab.com/users/sign_in) and [Production](https://gitlab.com/) GitLab environments.

These tests run in scheduled pipelines and ensure the end-to-end user experiences are functioning correctly.
Results can be viewed in the `#e2e-run-staging` and `#e2e-run-production` Slack channels. The pipelines can be found below, access can be requested in `#s_developer_experience`:

- [Staging-canary pipelines](https://ops.gitlab.net/gitlab-org/quality/staging-canary/-/pipelines)
- [Staging pipelines](https://ops.gitlab.net/gitlab-org/quality/staging/-/pipelines)
- [Canary pipelines](https://ops.gitlab.net/gitlab-org/quality/canary/-/pipelines)
- [Production pipelines](https://ops.gitlab.net/gitlab-org/quality/production/-/pipelines)

## Product Analysis

To better understand how the feature is used, each production user input message is analyzed using LLM and Ruby,
and the analysis is tracked as a Snowplow event.

The analysis can contain any of the attributes defined in the latest [iglu schema](https://gitlab.com/gitlab-org/iglu/-/blob/master/public/schemas/com.gitlab/ai_question_category/jsonschema).

- The categories and detailed categories have been predefined by the product manager and the product designer, as we are not allowed to look at the actual questions from users. If there is reason to believe that there are missing or confusing categories, they can be changed. To edit the definitions, update `categories.xml` in both [AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/ai_gateway/prompts/definitions/categorize_question/categories.xml) and [monolith](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/llm/fixtures/categories.xml).
- The list of attributes captured can be found in [labesl.xml](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/ai_gateway/prompts/definitions/categorize_question/labels.xml).
  - The following is yet to be implemented:
    - `is_proper_sentence`
  - The following are deprecated:
    - `number_of_questions_in_history`
    - `length_of_questions_in_history`
    - `time_since_first_question`

The request count and the user count for each question category and detail category can be reviewed in [this Tableau dashboard](https://10az.online.tableau.com/#/site/gitlab/views/DuoCategoriesofQuestions/DuoCategories) (GitLab team members only).

## How `access_duo_chat` policy works

This table describes the requirements for the `access_duo_chat` policy to
return `true` in different contexts.

| | GitLab.com | Dedicated or GitLab Self-Managed | All instances |
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

See the video ([internal link](https://drive.google.com/file/d/1X6CARf0gebFYX4Rc9ULhcfq9LLLnJ_O-)) that covers the full setup.

### (Deprecated) Issue and epic experiments

{{< alert type="note" >}}

This section is deprecated in favor of the [development seed file](testing_and_validation.md#seed-project-and-group-resources-for-testing-and-evaluation).

{{< /alert >}}

If you would like to use the evaluation framework (as described [here](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library/-/blob/main/doc/how-to/run_duo_chat_eval.md?ref_type=heads#evaluation-on-issueepic))
you can import the required groups and projects using this Rake task:

```shell
GITLAB_SIMULATE_SAAS=1 bundle exec 'rake gitlab:duo:setup_evaluation[<test-group-name>]'
```

Since we use the `Setup` class (under `ee/lib/gitlab/duo/developments/setup.rb`)
that requires "saas" mode to create a group (necessary for importing subgroups),
you need to set `GITLAB_SIMULATE_SAAS=1`. This is just to complete the import
successfully, and then you can switch back to `GITLAB_SIMULATE_SAAS=0` if
desired.

#### (Deprecated) Epic and issue fixtures

{{< alert type="note" >}}

This section is deprecated in favor of the [development seed file](testing_and_validation.md#seed-project-and-group-resources-for-testing-and-evaluation).

{{< /alert >}}

The fixtures are the replicas of the _public_ issues and epics from projects and groups _owned by_ GitLab.
The internal notes were excluded when they were sampled. The fixtures have been committed into the canonical `gitlab` repository.
See [the snippet](https://gitlab.com/gitlab-org/gitlab/-/snippets/3613745) used to create the fixtures.

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
1. `Gitlab::Llm::Completions::Chat#execute` calls `Gitlab::Duo::Chat::ReactExecutor`.
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/30817374f2feecdaedbd3a0efaad93feaed5e0a0/ee/lib/gitlab/llm/completions/chat.rb#L122-L130))
1. `Gitlab::Duo::Chat::ReactExecutor#execute` calls `#step_forward` which calls `Gitlab::Duo::Chat::StepExecutor#step`
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/30817374f2feecdaedbd3a0efaad93feaed5e0a0/ee/lib/gitlab/duo/chat/react_executor.rb#L235)).
1. `Gitlab::Duo::Chat::StepExecutor#step` calls `Gitlab::Duo::Chat::StepExecutor#perform_agent_request`, which sends a request to the AI Gateway `/v2/chat/agent/` endpoint
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/30817374f2feecdaedbd3a0efaad93feaed5e0a0/ee/lib/gitlab/duo/chat/step_executor.rb#L69)).
1. The AI Gateway `/v2/chat/agent` endpoint receives the request on the `api.v2.agent.chat.agent.chat` function
   ([code](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/989ead63fae493efab255180a51786b69a403b49/ai_gateway/api/v2/chat/agent.py#L133))
1. `api.v2.agent.chat.agent.chat` creates the `GLAgentRemoteExecutor` through the `gl_agent_remote_executor_factory` ([code](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/989ead63fae493efab255180a51786b69a403b49/ai_gateway/api/v2/chat/agent.py#L166)).

      Upon creation of the `GLAgentRemoteExecutor`, the following parameters are passed:
      - `tools_registry` - the registry of all available tools; this is passed through the factory ([code](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/989ead63fae493efab255180a51786b69a403b49/ai_gateway/chat/container.py#L35))
      - `agent` - `ReActAgent` object that wraps the prompt information, including the chosen LLM model, prompt template, etc

1. `api.v2.agent.chat.agent.chat` calls the `GLAgentRemoteExecutor.on_behalf`, which gets the user tools early to raise an exception as soon as possible if an error occurs ([code](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/989ead63fae493efab255180a51786b69a403b49/ai_gateway/chat/executor.py#L56)).
1. `api.v2.agent.chat.agent.chat` calls the `GLAgentRemoteExecutor.stream` ([code](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/989ead63fae493efab255180a51786b69a403b49/ai_gateway/chat/executor.py#L81)).
1. `GLAgentRemoteExecutor.stream` calls `astream` on `agent` (an instance of `ReActAgent`) with inputs such as the messages and the list of available tools ([code](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/989ead63fae493efab255180a51786b69a403b49/ai_gateway/chat/executor.py#L92)).
1. The `ReActAgent` builds the prompts, with the available tools inserted into the system prompt template
   ([code](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/989ead63fae493efab255180a51786b69a403b49/ai_gateway/prompts/definitions/chat/react/system/1.0.0.jinja)).
1. `ReActAgent.astream` sends a call to the LLM model ([code](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/989ead63fae493efab255180a51786b69a403b49/ai_gateway/chat/agents/react.py#L216))
1. The LLM response is returned to Rails
   (code path: [`ReActAgent.astream`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/989ead63fae493efab255180a51786b69a403b49/ai_gateway/chat/agents/react.py#L209)
   -> [`GLAgentRemoteExecutor.stream`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/989ead63fae493efab255180a51786b69a403b49/ai_gateway/chat/executor.py#L81)
   -> [`api.v2.agent.chat.agent.chat`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/989ead63fae493efab255180a51786b69a403b49/ai_gateway/api/v2/chat/agent.py#L133)
   -> Rails)
1. We've now made our first request to the AI gateway. If the LLM says that the answer to the first request is final,
   Rails [parses the answer](https://gitlab.com/gitlab-org/gitlab/-/blob/30817374f2feecdaedbd3a0efaad93feaed5e0a0/ee/lib/gitlab/duo/chat/react_executor.rb#L56) and [returns it](https://gitlab.com/gitlab-org/gitlab/-/blob/30817374f2feecdaedbd3a0efaad93feaed5e0a0/ee/lib/gitlab/duo/chat/react_executor.rb#L63) for further response handling by [`Gitlab::Llm::Completions::Chat`](https://gitlab.com/gitlab-org/gitlab/-/blob/30817374f2feecdaedbd3a0efaad93feaed5e0a0/ee/lib/gitlab/llm/completions/chat.rb#L66).
1. If the answer is not final, the "thoughts" and "picked tools" from the first LLM request are parsed and then the relevant tool class is called.
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/30817374f2feecdaedbd3a0efaad93feaed5e0a0/ee/lib/gitlab/duo/chat/react_executor.rb#L207)
   | [example tool class](https://gitlab.com/gitlab-org/gitlab/-/blob/971d07aa37d9f300b108ed66304505f2d7022841/ee/lib/gitlab/llm/chain/tools/identifier.rb))
      1. The tool executor classes include `Concerns::AiDependent` and use its `request` method.
      ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/30817374f2feecdaedbd3a0efaad93feaed5e0a0/ee/lib/gitlab/llm/chain/concerns/ai_dependent.rb#L14))
      1. The `request` method uses the `ai_request` instance
         that was injected into the `context` in `Llm::Completions::Chat`. For Chat,
         this is `Gitlab::Llm::Chain::Requests::AiGateway`. ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/971d07aa37d9f300b108ed66304505f2d7022841/ee/lib/gitlab/llm/completions/chat.rb#L42)).
      1. The tool indicates that `use_ai_gateway_agent_prompt=true` ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/30817374f2feecdaedbd3a0efaad93feaed5e0a0/ee/lib/gitlab/llm/chain/tools/issue_reader/executor.rb#L121)).

         This tells the `ai_request` to send the prompt to the `/v1/prompts/chat` endpoint ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/30817374f2feecdaedbd3a0efaad93feaed5e0a0/ee/lib/gitlab/llm/chain/requests/ai_gateway.rb#L87)).

      1. AI Gateway `/v1/prompts/chat` endpoint receives the request on `api.v1.prompts.invoke`
      ([code](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/989ead63fae493efab255180a51786b69a403b49/ai_gateway/api/v1/prompts/invoke.py#L41)).
      1. `api.v1.prompts.invoke` gets the correct tool prompt from the tool prompt registry ([code](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/989ead63fae493efab255180a51786b69a403b49/ai_gateway/api/v1/prompts/invoke.py#L49)).
      1. The prompt is called either as a [stream](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/989ead63fae493efab255180a51786b69a403b49/ai_gateway/api/v1/prompts/invoke.py#L86) or as a [non-streamed invocation](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/989ead63fae493efab255180a51786b69a403b49/ai_gateway/api/v1/prompts/invoke.py#L96).
      1. If the tool answer is not final, the response is added to agent_scratchpad and the loop in `Gitlab::Duo::Chat::ReactExecutor` starts again, adding the additional context to the request. It loops to up to 10 times until a final answer is reached. ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/30817374f2feecdaedbd3a0efaad93feaed5e0a0/ee/lib/gitlab/duo/chat/react_executor.rb#L44))

## Interpreting GitLab Duo Chat error codes

GitLab Duo Chat has error codes with specified meanings to assist in debugging.

See the [GitLab Duo Chat troubleshooting documentation](../../user/gitlab_duo_chat/troubleshooting.md) for a list of all GitLab Duo Chat error codes.

When developing for GitLab Duo Chat, include these error codes when returning an error and [document them](../../user/gitlab_duo_chat/troubleshooting.md), especially for user-facing errors.

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
| G    | AI gateway      |
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
