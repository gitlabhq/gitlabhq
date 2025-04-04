---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: AI features based on 3rd-party integrations
---

GitLab Duo features are powered by AI models and integrations. This document provides an overview of developing with AI features in GitLab.

For detailed instructions on setting up GitLab Duo licensing in your development environment, see [GitLab Duo licensing for local development](ai_development_license.md).

## Instructions for setting up GitLab Duo features in the local development environment

For complete setup instructions, see [GitLab Duo licensing for local development](ai_development_license.md).

### Required: Install AI gateway

**Why:** Duo features (except for Duo Workflow) route LLM requests through the AI gateway.

**How:**
Follow [these instructions](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/gitlab_ai_gateway.md#install)
to install the AI gateway with GDK. We recommend this route for most users.

You can also install AI gateway by:

1. [Cloning the repository directly](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist).
1. [Running the server locally](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist#how-to-run-the-server-locally).

We only recommend this for users who have a specific reason for *not* running
the AI gateway through GDK.

### Set up and run GDK

For detailed instructions on setting up your GDK for GitLab Duo development, see [GitLab Duo licensing for local development](ai_development_license.md).

## Tips for local development

1. When responses are taking too long to appear in the user interface, consider
   restarting Sidekiq by running `gdk restart rails-background-jobs`. If that
   doesn't work, try `gdk kill` and then `gdk start`.
1. Alternatively, bypass Sidekiq entirely and run the service synchronously.
   This can help with debugging errors as GraphQL errors are now available in
  the network inspector instead of the Sidekiq logs. To do that, temporarily alter
  the `perform_for` method in `Llm::CompletionWorker` class by changing
  `perform_async` to `perform_inline`.

## Feature development (Abstraction Layer)

### Feature flags

Apply the following feature flags to any AI feature work:

- A general flag (`ai_duo_chat_switch`) that applies to all GitLab Duo Chat features. It's enabled by default.
- A general flag (`ai_global_switch`) that applies to all other AI features. It's enabled by default.
- A flag specific to that feature. The feature flag name [must be different](../feature_flags/_index.md#feature-flags-for-licensed-features) than the licensed feature name.

See the [feature flag tracker epic](https://gitlab.com/groups/gitlab-org/-/epics/10524) for the list of all feature flags and how to use them.

### Push feature flags to AI gateway

You can push [feature flags](../feature_flags/_index.md) to AI gateway. This is helpful to gradually rollout user-facing changes even if the feature resides in AI gateway.
See the following example:

```ruby
# Push a feature flag state to AI gateway.
Gitlab::AiGateway.push_feature_flag(:new_prompt_template, user)
```

Later, you can use the feature flag state in AI gateway in the following way:

```python
from ai_gateway.feature_flags import is_feature_enabled

# Check if the feature flag "new_prompt_template" is enabled.
if is_feature_enabled('new_prompt_template'):
  # Build a prompt from the new prompt template
else:
  # Build a prompt from the old prompt template
```

**IMPORTANT:** At the [cleaning up](../feature_flags/controls.md#cleaning-up) step, remove the feature flag in AI gateway repository **before** removing the flag in GitLab-Rails repository.
If you clean up the flag in GitLab-Rails repository at first, the feature flag in AI gateway will be disabled immediately as it's the default state, hence you might encounter a surprising behavior.

**IMPORTANT:** Cleaning up the feature flag in AI gateway will immediately distribute the change to all GitLab instances, including GitLab.com, GitLab Self-Managed, and GitLab Dedicated.

**Technical details:**

- When `push_feature_flag` runs on an enabled feature flag, the name of the flag is cached in the current context,
  which is later attached to the `x-gitlab-enabled-feature-flags` HTTP header when `GitLab-Sidekiq/Rails` sends requests to AI gateway.
- When frontend clients (for example, VS Code Extension or LSP) request a [User JWT](../cloud_connector/architecture.md#ai-gateway) (UJWT)
  for direct AI gateway communication, GitLab returns:

  - Public headers (including `x-gitlab-enabled-feature-flags`).
  - The generated UJWT (1-hour expiration).

Frontend clients must regenerate UJWT upon expiration. Backend changes such as feature flag updates through [ChatOps](../feature_flags/controls.md) render the header values to become stale. These header values are refreshed at the next UJWT generation.

Similarly, we also have [`push_frontend_feature_flag`](../feature_flags/_index.md) to push feature flags to frontend.

### GraphQL API

To connect to the AI provider API using the Abstraction Layer, use an extendable
GraphQL API called [`aiAction`](https://gitlab.com/gitlab-org/gitlab/blob/master/ee/app/graphql/mutations/ai/action.rb).
The `input` accepts key/value pairs, where the `key` is the action that needs to
be performed. We only allow one AI action per mutation request.

Example of a mutation:

```graphql
mutation {
  aiAction(input: {summarizeComments: {resourceId: "gid://gitlab/Issue/52"}}) {
    clientMutationId
  }
}
```

As an example, assume we want to build an "explain code" action. To do this, we extend the `input` with a new key,
`explainCode`. The mutation would look like this:

```graphql
mutation {
  aiAction(
    input: {
      explainCode: { resourceId: "gid://gitlab/MergeRequest/52", code: "foo() { console.log() }" }
    }
  ) {
    clientMutationId
  }
}
```

The GraphQL API then uses the [Anthropic Client](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/llm/anthropic/client.rb)
to send the response.

#### How to receive a response

The API requests to AI providers are handled in a background job. We therefore do not keep the request alive and the Frontend needs to match the request to the response from the subscription.

{{< alert type="warning" >}}

Determining the right response to a request can cause problems when only `userId` and `resourceId` are used. For example, when two AI features use the same `userId` and `resourceId` both subscriptions will receive the response from each other. To prevent this interference, we introduced the `clientSubscriptionId`.

{{< /alert >}}

To match a response on the `aiCompletionResponse` subscription, you can provide a `clientSubscriptionId` to the `aiAction` mutation.

- The `clientSubscriptionId` should be unique per feature and within a page to not interfere with other AI features. We recommend to use a `UUID`.
- Only when the `clientSubscriptionId` is provided as part of the `aiAction` mutation, it will be used for broadcasting the `aiCompletionResponse`.
- If the `clientSubscriptionId` is not provided, only `userId` and `resourceId` are used for the `aiCompletionResponse`.

As an example mutation for summarizing comments, we provide a `randomId` as part of the mutation:

```graphql
mutation {
  aiAction(
    input: {
      summarizeComments: { resourceId: "gid://gitlab/Issue/52" }
      clientSubscriptionId: "randomId"
    }
  ) {
    clientMutationId
  }
}
```

In our component, we then listen on the `aiCompletionResponse` using the `userId`, `resourceId` and `clientSubscriptionId` (`"randomId"`):

```graphql
subscription aiCompletionResponse(
  $userId: UserID
  $resourceId: AiModelID
  $clientSubscriptionId: String
) {
  aiCompletionResponse(
    userId: $userId
    resourceId: $resourceId
    clientSubscriptionId: $clientSubscriptionId
  ) {
    content
    errors
  }
}
```

The [subscription for Chat](duo_chat.md#graphql-subscription) behaves differently.

To not have many concurrent subscriptions, you should also only subscribe to the subscription once the mutation is sent by using [`skip()`](https://apollo.vuejs.org/guide-option/subscriptions.html#skipping-the-subscription).

##### Clarifying different ID parameters

When working with the `aiAction` mutation, several ID parameters are used for routing requests and responses correctly. Here's what each parameter does:

- **user_id** (required)
  - Purpose: Identifies and authenticates the requesting user
  - Used for: Permission checks, request attribution, and response routing
  - Example: `gid://gitlab/User/123`
  - Note: This ID is automatically included by the GraphQL API framework

- **client_subscription_id** (recommended for streaming or multiple features)
  - Client-generated UUID for tracking specific request/response pairs
  - Required when using streaming responses or when multiple AI features share the same page
  - Example: `"9f5dedb3-c58d-46e3-8197-73d653c71e69"`
  - Can be omitted for simple, isolated requests with no streaming

- **resource_id** (contextual - required for some features)
  - Purpose: References a specific GitLab entity (project, issue, MR) that provides context for the AI operation
  - Used for: Permission verification and contextual information gathering
  - Real example: `"gid://gitlab/Issue/164723626"`
  - Note: Some features may not require a specific resource

- **project_id** (contextual - required for some features)
  - Purpose: Identifies the project context for the AI operation
  - Used for: Project-specific permission checks and context
  - Real example: `"gid://gitlab/Project/278964"`
  - Note: Some features may not require a specific project

#### Current abstraction layer flow

The following graph uses VertexAI as an example. You can use different providers.

```mermaid
flowchart TD
A[GitLab frontend] -->B[AiAction GraphQL mutation]
B --> C[Llm::ExecuteMethodService]
C --> D[One of services, for example: Llm::GenerateSummaryService]
D -->|scheduled| E[AI worker:Llm::CompletionWorker]
E -->F[::Gitlab::Llm::Completions::Factory]
F -->G[`::Gitlab::Llm::VertexAi::Completions::...` class using `::Gitlab::Llm::Templates::...` class]
G -->|calling| H[Gitlab::Llm::VertexAi::Client]
H --> |response| I[::Gitlab::Llm::GraphqlSubscriptionResponseService]
I --> J[GraphqlTriggers.ai_completion_response]
J --> K[::GitlabSchema.subscriptions.trigger]
```

## Reuse the existing AI components for multiple models

We thrive optimizing AI components, such as prompt, input/output parser, tools/function-calling, for each LLM,
however, diverging the components for each model could increase the maintenance overhead.
Hence, it's generally advised to reuse the existing components for multiple models as long as it doesn't degrade a feature quality.
Here are the rules of thumbs:

1. Iterate on the existing prompt template for multiple models. Do _NOT_ introduce a new one unless it causes a quality degradation for a particular model.
1. Iterate on the existing input/output parsers and tools/functions-calling for multiple models. Do _NOT_ introduce a new one unless it causes a quality degradation for a particular model.
1. If a quality degradation is detected for a particular model, the shared component should be diverged for the particular model.

An [example](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/issues/713) of this case is that we can apply Claude specific CoT optimization to the other models such as Mixtral as long as it doesn't cause a quality degradation.

## Monitoring

- Error ratio and response latency apdex for each Ai action can be found on [Sidekiq Service dashboard](https://dashboards.gitlab.net/d/sidekiq-main/sidekiq-overview?orgId=1) under **SLI Detail: `llm_completion`**.
- Spent tokens, usage of each Ai feature and other statistics can be found on [periscope dashboard](https://app.periscopedata.com/app/gitlab/1137231/Ai-Features).
- [AI gateway logs](https://log.gprd.gitlab.net/app/r/s/zKEel).
- [AI gateway metrics](https://dashboards.gitlab.net/d/ai-gateway-main/ai-gateway3a-overview?orgId=1).
- [Feature usage dashboard via proxy](https://log.gprd.gitlab.net/app/r/s/egybF).

## Security

Refer to the [secure coding guidelines for Artificial Intelligence (AI) features](../secure_coding_guidelines.md#artificial-intelligence-ai-features).

## Help

- [Here's how to reach us!](https://handbook.gitlab.com/handbook/engineering/development/data-science/ai-powered/ai-framework/#-how-to-reach-us)
- View [guidelines](duo_chat.md) for working with GitLab Duo Chat.
