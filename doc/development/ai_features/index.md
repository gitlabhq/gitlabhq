---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# AI features based on 3rd-party integrations

## Local setup

### Access

Access to both Google Cloud Vertex and Anthropic are recommended for setup. 

#### Google Cloud Vertex

To obtain a Google Cloud service key for local development, follow the steps below:

1. Set up a Google Cloud project
   1. Option 1 (recommended for GitLab team members): request access to our
      existing group Google Cloud project (`ai-enablement-dev-69497ba7`) by using
      [this template](https://gitlab.com/gitlab-com/it/infra/issue-tracker/-/issues/new?issuable_template=gcp_group_account_iam_update_request)
      This project has Vertex APIs and Vertex AI Search (for Duo Chat
      documentaton questions) already enabled
   1. Option 2: Create a sandbox Google Cloud project by following the instructions
      in [the handbook](https://handbook.gitlab.com/handbook/infrastructure-standards/#individual-environment).
      If you are using an individual Google Cloud project, you may also need to
      enable the Vertex AI API:
      1. Visit [welcome page](https://console.cloud.google.com/welcome), choose
         your project (for example: `jdoe-5d23dpe`).
      1. Go to **APIs & Services > Enabled APIs & services**.
      1. Select **Enable APIs and Services**.
      1. Search for `Vertex AI API`.
      1. Select **Vertex AI API**, then select **Enable**.
1. Install the [`gcloud` CLI](https://cloud.google.com/sdk/docs/install)
   1. If you already use [`asdf`](https://asdf-vm.com/) for runtime version
    management, you can install `gcloud` with the
    [`asdf gcloud` plugin](https://github.com/jthegedus/asdf-gcloud)
1. Authenticate locally with Google Cloud using the
  [`gcloud auth application-default login`](https://cloud.google.com/sdk/gcloud/reference/auth/application-default/login)
  command.
1. Open a Rails console. Update the settings to:

   ```ruby
   # PROJECT_ID = "ai-enablement-dev-69497ba7" for GitLab team members with access
   # to the group using the access request method described above

   # PROJECT_ID = "your-google-cloud-project-name" for those with their own sandbox
   # Google Cloud project.

   Gitlab::CurrentSettings.update!(vertex_ai_project: "PROJECT_ID")
   ```

#### Anthropic

After filling out an
[access request](https://gitlab.com/gitlab-com/team-member-epics/access-requests/-/issues/new?issuable_template=AI_Access_Request),
you can sign up for an Anthropic account and [create an API key](https://docs.anthropic.com/en/docs/getting-access-to-claude).

Run the following in a Rails console locally:

```ruby
Gitlab::CurrentSettings.update!(anthropic_api_key: "<insert API key>")
```

### Configure GDK

#### Licenses and feature flags

1. Follow [the process to obtain an EE license](https://handbook.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee-developer-licenses)
   for your local instance and [upload the license](../../administration/license_file.md).
   1. To verify that the license is applied go to **Admin Area** > **Subscription**
      and check the subscription plan.
1. Enable all AI-related feature flags:

   ```shell
   rake gitlab:duo:enable_feature_flags
   ```

1. If you are running GDK in SaaS mode (recommended), you need to enable Duo
   features for at least one group. To do this, run:

   ```shell
    GITLAB_SIMULATE_SAAS=1 RAILS_ENV=development bundle exec rake 'gitlab:duo:setup[<test-group-name>]'
   ```

   Replace `<test-group-name>` with the name of any top-level group. If the
   group doesn't exist, it creates a new one. You might need to
   re-run the script multiple times; it prints error messages with links
   on how to resolve the error.
   Membership to a group with Duo features enabled is what enables many AI
   features. To enable AI feature access locally, make sure that your test user is
   a member of the group with Duo features enabled.

#### Set up the AI Gateway

To develop AI features that are compatible with all GitLab instances,
the feature must proxy requests through the [AI Gateway](../../architecture/blueprints/ai_gateway/index.md).

1. [Install it with GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/gitlab_ai_gateway.md).
1. Verify that it is working by calling the following in the rails console:

   ```ruby
   Gitlab::Llm::Chain::Requests::AiGateway.new(User.first).request(prompt: [{role: "user", content: "Hi, how are you?"}])
   ```

#### Environment variables

The following variables should be set in the `env.runit` file in your GDK root:

```shell
# <GDK-root>/env.runit

# for running in SaaS mode so that you can skip CustomersDot local setup
# if you need to test something specific to self-managed, unset this and follow the
# section below on CustomersDot setup
export GITLAB_SIMULATE_SAAS=1

# point your GDK-hosed GitLab Rails to your GDK-hosted AI Gateway
AI_GATEWAY_URL=http://0.0.0.0:5052
```

The following variables should be set in the `.env` file in your AI Gateway
directory:

```shell
# <GDK-root>/gitlab-ai-gateway/.env

# for AI Gateway requests to Anthropic
ANTHROPIC_API_KEY=$SEKRET_KEY

# for AI Gateway documentation search
# You must have access to this Google Cloud project to perform documentation
# search questions locally
# Issue for documenting how to set up Vertex AI search for a different project:
# https://gitlab.com/gitlab-org/gitlab/-/issues/461393#note_1935931455
AIGW_VERTEX_SEARCH__PROJECT="ai-enablement-dev-69497ba7"

# skip OIDC auth for AI Gateway
AIGW_AUTH__BYPASS_EXTERNAL=true
```

### Optional: Test with OIDC authentication

In the production environment, AI Gateway verifies that the JWT sent by client
request is signed by the authentic OIDC provider. To test this authentication
and authorization flow with scopes/unit-primitives, you can take the following
optional step.

Assuming that you are running the [AI Gateway with GDK](#set-up-the-ai-gateway),
apply the following configuration to GDK:

```shell
# <GDK-root>/env.runit
export AIGW_AUTH__BYPASS_EXTERNAL=false
export AIGW_GITLAB_URL=<your-gdk-url>
export GITLAB_SIMULATE_SAAS=1
```

and `gdk restart`.

Try requests from GitLab-Rails to AI Gateway. Example:

```ruby
gdk rails console

# allow the local requests since your AI Gateway is running in localhost.
Gitlab::CurrentSettings.update(allow_local_requests_from_web_hooks_and_services: true)

Gitlab::Llm::VertexAi::Client.new(User.first, unit_primitive: 'explain_vulnerability').chat(content: "Hi, how are you?")
Gitlab::Llm::VertexAi::Client.new(User.first, unit_primitive: 'explain_vulnerability').messages_chat(content: [{"author": "user", "content": "Hi, how are you?"}])
Gitlab::Llm::VertexAi::Client.new(User.first, unit_primitive: 'explain_vulnerability').code_completion(content: {"prefix": "print('Hello", "suffix": ""})
```

Here is the underlying process happening per request:

1. GitLab-Rails generates a new JWT with a given scope (e.g. `duo_chat`).
1. GitLab-Rails requets to AI Gateway with the JWT (bearer token in `Authorization` HTTP header).
1. AI Gateway decodes the JWT with the JWKS issued by the GitLab-Rails. If it's successful, the request is authenticated.
1. AI Gateway verifies if the `scopes` claim in the JWT satisfies the target endpoint's scope requirement.
   Required scope varies per endpoint (e.g. `/v1/chat/agent` requires `duo_chat`, `/v2/code/suggestions` requires `code_suggestions`).

If you want to test OIDC auth as a self-managed GitLab instance, you need to set
up CustomerDot as described below.

### Optional: Set up CustomersDot

CustomersDot setup is helpful when you want to test or update functionality
related to [cloud licensing](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/)
or if you are running GDK in non-SaaS mode.
Otherwise, it can be skipped as long as your GDK has
`AIGW_AUTH__BYPASS_EXTERNAL=true` set so that auth checks are skipped locally.

[Internal video tutorial](https://youtu.be/rudS6KeQHcA)

1. Follow [Instruct your local CustomersDot instance to use the GitLab application](https://gitlab.com/gitlab-org/customers-gitlab-com/-/blob/main/doc/setup/installation_steps.md#instruct-your-local-customersdot-instance-to-use-the-gitlab-application).
1. Activate GitLab Enterprise license
   1. To test Self Managed instances, follow
      [Cloud Activation steps](../../administration/license.md#activate-gitlab-ee)
      using the cloud activation code you received earlier.
   1. To test SaaS, follow
      [Activate GitLab Enterprise license](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/index.md#use-gitlab-enterprise-features)
      with your license file.

### Help

- [Here's how to reach us!](https://handbook.gitlab.com/handbook/engineering/development/data-science/ai-powered/ai-framework/#-how-to-reach-us)
- View [guidelines](duo_chat.md) for working with GitLab Duo Chat.

## Tips for local development

1. When responses are taking too long to appear in the user interface, consider
   restarting Sidekiq by running `gdk restart rails-background-jobs`. If that
   doesn't work, try `gdk kill` and then `gdk start`.
1. Alternatively, bypass Sidekiq entirely and run the service synchronously.
   This can help with debugging errors as GraphQL errors are now available in
  the network inspector instead of the Sidekiq logs. To do that temporary alter
  `perform_for` method in `Llm::CompletionWorker` class by changing
  `perform_async` to `perform_inline`.

## Feature development (Abstraction Layer)

### Feature flags

Apply the following feature flags to any AI feature work:

- A general flag (`ai_duo_chat_switch`) that applies to all GitLab Duo Chat features. It's enabled by default.
- A general flag (`ai_global_switch`) that applies to all other AI features. It's enabled by default.
- A flag specific to that feature. The feature flag name [must be different](../feature_flags/index.md#feature-flags-for-licensed-features) than the licensed feature name.

See the [feature flag tracker epic](https://gitlab.com/groups/gitlab-org/-/epics/10524) for the list of all feature flags and how to use them.

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
  aiAction(input: {explainCode: {resourceId: "gid://gitlab/MergeRequest/52", code: "foo() { console.log() }" }}) {
    clientMutationId
  }
}
```

The GraphQL API then uses the [Anthropic Client](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/llm/anthropic/client.rb)
to send the response.

#### How to receive a response

The API requests to AI providers are handled in a background job. We therefore do not keep the request alive and the Frontend needs to match the request to the response from the subscription.

WARNING:
Determining the right response to a request can cause problems when only `userId` and `resourceId` are used. For example, when two AI features use the same `userId` and `resourceId` both subscriptions will receive the response from each other. To prevent this interference, we introduced the `clientSubscriptionId`.

To match a response on the `aiCompletionResponse` subscription, you can provide a `clientSubscriptionId` to the `aiAction` mutation.

- The `clientSubscriptionId` should be unique per feature and within a page to not interfere with other AI features. We recommend to use a `UUID`.
- Only when the `clientSubscriptionId` is provided as part of the `aiAction` mutation, it will be used for broadcasting the `aiCompletionResponse`.
- If the `clientSubscriptionId` is not provided, only `userId` and `resourceId` are used for the `aiCompletionResponse`.

As an example mutation for summarizing comments, we provide a `randomId` as part of the mutation:

```graphql
mutation {
  aiAction(input: {summarizeComments: {resourceId: "gid://gitlab/Issue/52"}, clientSubscriptionId: "randomId"}) {
    clientMutationId
  }
}
```

In our component, we then listen on the `aiCompletionResponse` using the `userId`, `resourceId` and `clientSubscriptionId` (`"randomId"`):

```graphql
subscription aiCompletionResponse($userId: UserID, $resourceId: AiModelID, $clientSubscriptionId: String) {
  aiCompletionResponse(userId: $userId, resourceId: $resourceId, clientSubscriptionId: $clientSubscriptionId) {
    content
    errors
  }
}
```

The [subscription for chat](duo_chat.md#graphql-subscription) behaves differently.

To not have many concurrent subscriptions, you should also only subscribe to the subscription once the mutation is sent by using [`skip()`](https://apollo.vuejs.org/guide-option/subscriptions.html#skipping-the-subscription).

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

## How to implement a new action

### Register a new method

Go to the `Llm::ExecuteMethodService` and add a new method with the new service class you will create.

```ruby
class ExecuteMethodService < BaseService
  METHODS = {
    # ...
    amazing_new_ai_feature: Llm::AmazingNewAiFeatureService
  }.freeze
```

### Create a Service

1. Create a new service under `ee/app/services/llm/` and inherit it from the `BaseService`.
1. The `resource` is the object we want to act on. It can be any object that includes the `Ai::Model` concern. For example it could be a `Project`, `MergeRequest`, or `Issue`.

```ruby
# ee/app/services/llm/amazing_new_ai_feature_service.rb

module Llm
  class AmazingNewAiFeatureService < BaseService
    private

    def perform
      ::Llm::CompletionWorker.perform_async(user.id, resource.id, resource.class.name, :amazing_new_ai_feature)
      success
    end

    def valid?
      super && Ability.allowed?(user, :amazing_new_ai_feature, resource)
    end
  end
end
```

### Authorization

We recommend to use [policies](../policies.md) to deal with authorization for a feature. Currently we need to make sure to cover the following checks:

1. For GitLab Duo Chat feature, `ai_duo_chat_switch` is enabled
1. For other general AI features, `ai_global_switch` is enabled
1. Feature specific feature flag is enabled
1. The namespace has the required license for the feature
1. User is a member of the group/project
1. `experiment_features_enabled` settings are set on the `Namespace`

For our example, we need to implement the `allowed?(:amazing_new_ai_feature)` call. As an example, you can look at the [Issue Policy for the summarize comments feature](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/policies/ee/issue_policy.rb). In our example case, we want to implement the feature for Issues as well:

```ruby
# ee/app/policies/ee/issue_policy.rb

module EE
  module IssuePolicy
    extend ActiveSupport::Concern
    prepended do
      with_scope :global
      condition(:ai_available) do
        ::Feature.enabled?(:ai_global_switch, type: :ops)
      end

      with_scope :subject
      condition(:amazing_new_ai_feature_enabled) do
        ::Feature.enabled?(:amazing_new_ai_feature, subject_container) &&
          subject_container.licensed_feature_available?(:amazing_new_ai_feature)
      end

      rule do
        ai_available & amazing_new_ai_feature_enabled & is_project_member
      end.enable :amazing_new_ai_feature
    end
  end
end
```

### Pairing requests with responses

Because multiple users' requests can be processed in parallel, when receiving responses,
it can be difficult to pair a response with its original request. The `requestId`
field can be used for this purpose, because both the request and response are assured
to have the same `requestId` UUID.

### Caching

AI requests and responses can be cached. Cached conversation is being used to
display user interaction with AI features. In the current implementation, this cache
is not used to skip consecutive calls to the AI service when a user repeats
their requests.

```graphql
query {
  aiMessages {
    nodes {
      id
      requestId
      content
      role
      errors
      timestamp
    }
  }
}
```

This cache is especially useful for chat functionality. For other services,
caching is disabled. (It can be enabled for a service by using `cache_response: true`
option.)

Caching has following limitations:

- Messages are stored in Redis stream.
- There is a single stream of messages per user. This means that all services
  currently share the same cache. If needed, this could be extended to multiple
  streams per user (after checking with the infrastructure team that Redis can handle
  the estimated amount of messages).
- Only the last 50 messages (requests + responses) are kept.
- Expiration time of the stream is 3 days since adding last message.
- User can access only their own messages. There is no authorization on the caching
  level, and any authorization (if accessed by not current user) is expected on
  the service layer.

### Check if feature is allowed for this resource based on namespace settings

There is one setting allowed on root namespace level that restrict the use of AI features:

- `experiment_features_enabled`

To check if that feature is allowed for a given namespace, call:

```ruby
Gitlab::Llm::StageCheck.available?(namespace, :name_of_the_feature)
```

Add the name of the feature to the `Gitlab::Llm::StageCheck` class. There are
arrays there that differentiate between experimental and beta features.

This way we are ready for the following different cases:

- If the feature is not in any array, the check will return `true`. For example, the feature was moved to GA.

To move the feature from the experimental phase to the beta phase, move the name of the feature from the `EXPERIMENTAL_FEATURES` array to the `BETA_FEATURES` array.

### Implement calls to AI APIs and the prompts

The `CompletionWorker` will call the `Completions::Factory` which will initialize the Service and execute the actual call to the API.
In our example, we will use VertexAI and implement two new classes:

```ruby
# /ee/lib/gitlab/llm/vertex_ai/completions/amazing_new_ai_feature.rb

module Gitlab
  module Llm
    module VertexAi
      module Completions
        class AmazingNewAiFeature < Gitlab::Llm::Completions::Base
          def execute
            prompt = ai_prompt_class.new(options[:user_input]).to_prompt

            response = Gitlab::Llm::VertexAi::Client.new(user).text(content: prompt)

            response_modifier = ::Gitlab::Llm::VertexAi::ResponseModifiers::Predictions.new(response)

            ::Gitlab::Llm::GraphqlSubscriptionResponseService.new(
              user, nil, response_modifier, options: response_options
            ).execute
          end
        end
      end
    end
  end
end
```

```ruby
# /ee/lib/gitlab/llm/vertex_ai/templates/amazing_new_ai_feature.rb

module Gitlab
  module Llm
    module VertexAi
      module Templates
        class AmazingNewAiFeature
          def initialize(user_input)
            @user_input = user_input
          end

          def to_prompt
            <<~PROMPT
            You are an assistant that writes code for the following context:

            context: #{user_input}
            PROMPT
          end
        end
      end
    end
  end
end
```

Because we support multiple AI providers, you may also use those providers for the same example:

```ruby
Gitlab::Llm::VertexAi::Client.new(user)
Gitlab::Llm::Anthropic::Client.new(user)
```

### Add AI Action to GraphQL

TODO

## Monitoring

- Error ratio and response latency apdex for each Ai action can be found on [Sidekiq Service dashboard](https://dashboards.gitlab.net/d/sidekiq-main/sidekiq-overview?orgId=1) under **SLI Detail: `llm_completion`**.
- Spent tokens, usage of each Ai feature and other statistics can be found on [periscope dashboard](https://app.periscopedata.com/app/gitlab/1137231/Ai-Features).

## Security

Refer to the [secure coding guidelines for Artificial Intelligence (AI) features](../secure_coding_guidelines.md#artificial-intelligence-ai-features).
