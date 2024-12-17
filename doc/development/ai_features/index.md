---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# AI features based on 3rd-party integrations

## Instructions for setting up GitLab Duo features in the local development environment

### Required: Install AI gateway

**Why:** All Duo features route LLM requests through the AI gateway.

**How:**
Follow [these instructions](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/gitlab_ai_gateway.md#install)
to install the AI gateway with GDK. We recommend this route for most users.

You can also install AI gateway by:

1. [Cloning the repository directly](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist).
1. [Running the server locally](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist#how-to-run-the-server-locally).

We only recommend this for users who have a specific reason for *not* running
the AI gateway through GDK.

### Required: Setup Licenses in GitLab-Rails

**Why:** GitLab Duo is available to Premium and Ultimate customers only. You
likely want an Ultimate license for your GDK. Ultimate gets you access to
all GitLab Duo features.

**How:**

Follow [the process to obtain an EE license](https://handbook.gitlab.com/handbook/engineering/developer-onboarding/#working-on-gitlab-ee-developer-licenses)
for your local instance and [upload the license](../../administration/license_file.md).

To verify that the license is applied, go to **Admin area** > **Subscription**
and check the subscription plan.

### Set up and run GDK

#### Option A: in SaaS (GitLab.com) Mode

**Why:** Most Duo features are available on GitLab.com first, so running in SaaS
mode will ensure that you can access most features.

**How:**

Run the Rake task to set up Duo features for a group:

```shell
GITLAB_SIMULATE_SAAS=1 bundle exec 'rake gitlab:duo:setup[test-group-name]'
```

```shell
gdk restart
```

Replace `test-group-name` with the name of any top-level group. Duo will
be configured for that group. If the group doesn't exist, it creates a new
one.

Make sure the script succeeds. It prints error messages with links on how
to resolve any errors. You can re-run the script until it succeeds.

In SaaS mode, membership to a group with Duo features enabled is what enables
many AI features. Make sure that your test user is a member of the group with
Duo features enabled (`test-group-name`).

This Rake task creates Duo Enterprise add-on attached to that group.

In case you need Duo Pro add-on attached, please use:

```shell
GITLAB_SIMULATE_SAAS=1 bundle exec 'rake gitlab:duo:setup[test-group-name,duo_pro]'
```

Duo Pro add-on serves smaller scope of features. Usage of add-on depends on what features you want to use.

#### Option B: in Self-managed Mode

**Why:** If you want to test something specific to self-managed, such as Custom
Models.

**How:**

Run the Rake task to set up Duo features for the instance:

```shell
GITLAB_SIMULATE_SAAS=0 bundle exec 'rake gitlab:duo:setup_instance'
```

```shell
gdk restart
```

This Rake task creates Duo Enterprise add-on attached to your instance.

In case you need Duo Pro add-on attached, please use:

```shell
GITLAB_SIMULATE_SAAS=0 bundle exec 'rake gitlab:duo:setup_instance[duo_pro]'
```

Duo Pro add-on serves smaller scope of features. Usage of add-on depends on what features you want to use.

### Recommended: Set `CLOUD_CONNECTOR_SELF_SIGN_TOKENS` environment variable

**Why:** Setting this environment variable will allow the local GitLab instance to
issue tokens itself, without syncing with CustomersDot first.
With this set, you can skip the
[CustomersDot setup](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/gitlab_ai_gateway.md#option-2-use-your-customersdot-instance-as-a-provider).

**How:** The following should be set in the `env.runit` file in your GDK root:

```shell
# <GDK-root>/env.runit

export CLOUD_CONNECTOR_SELF_SIGN_TOKENS=1
```

You need to restart GDK to apply the change.

If you use `CLOUD_CONNECTOR_SELF_SIGN_TOKENS=1`, th `root`/`admin` user must
have a [seat assigned](../../subscriptions/subscription-add-ons.md#for-gitlabcom)
to receive a "Code completion test was successful" notification from the health check
on the `http://localhost:3000/admin/code_suggestions` page.

Our customers (production environment) do not need to do that to run a Code
Suggestions health check.

### Recommended: Test clients in Rails console

**Why:** you've completed all of the setup steps, now it's time to confirm that
GitLab Duo is actually working.

**How:**

After the setup is complete, you can test clients in GitLab-Rails to see if it can
correctly reach to AI gateway:

1. Run `gdk start`.
1. Login to Rails console with `gdk rails console`.
1. Talk to a model:

   ```ruby
   # Talk to Anthropic model
   Gitlab::Llm::Anthropic::Client.new(User.first, unit_primitive: 'duo_chat').complete(prompt: "\n\nHuman: Hi, How are you?\n\nAssistant:")

   # Talk to Vertex AI model
   Gitlab::Llm::VertexAi::Client.new(User.first, unit_primitive: 'documentation_search').text_embeddings(content: "How can I create an issue?")

   # Test `/v1/chat/agent` endpoint
   Gitlab::Llm::Chain::Requests::AiGateway.new(User.first).request({prompt: [{role: "user", content: "Hi, how are you?"}]})
   ```

NOTE:
See [this doc](../cloud_connector/index.md) for registering unit primitives in Cloud Connector.

### Optional: Enable authentication and authorization in AI gateway

**Why:** The AI gateway has [authentication and authorization](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/auth.md)
flow to verify if clients have permission to access the features. Auth is
enforced in any live environments hosted by GitLab infra team. You may want to
test this flow in your local development environment.

NOTE:
In development environments (for example: GDK), this process is disabled by default.

To enable authorization checks, set `AIGW_AUTH__BYPASS_EXTERNAL` to `false` in the
[application setting file](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/application_settings.md)
(`<GDK-root>/gitlab-ai-gateway/.env`) in AI gateway.

#### Option 1: Use your GitLab instance as a provider

**Why:** this is the simplest method of testing authentication and reflects our setup on GitLab.com.

**How:**
Assuming that you are running the [AI gateway with GDK](#required-install-ai-gateway),
apply the following configuration to GDK:

```shell
# <GDK-root>/env.runit

export GITLAB_SIMULATE_SAAS=1
```

Update the [application settings file](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/application_settings.md) in AI gateway:

```shell
# <GDK-root>/gitlab-ai-gateway/.env

AIGW_AUTH__BYPASS_EXTERNAL=false
AIGW_GITLAB_URL=<your-gdk-url>
```

and `gdk restart`.

#### Option 2: Use your customersDot instance as a provider

**Why**: CustomersDot setup is required when you want to test or update functionality
related to [cloud licensing](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/)
or if you are running GDK in non-SaaS mode.

NOTE:
This setup is challenging. There is [an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/463341)
for discussing how to make it easier to test the customersDot integration locally.
Until that is addressed, this setup process is time consuming and should be
avoided if possible.

If you need to get customersDot working for your local GitLab Rails instance for
any reason, reach out to `#s_fulfillment_engineering` in Slack. For questions around the integration of CDot with other systems to deliver AI use cases, reach out to `#g_cloud_connector`.
assistance.

### Help

- [Here's how to reach us!](https://handbook.gitlab.com/handbook/engineering/development/data-science/ai-powered/ai-framework/#-how-to-reach-us)
- View [guidelines](duo_chat.md) for working with GitLab Duo Chat.

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
- A flag specific to that feature. The feature flag name [must be different](../feature_flags/index.md#feature-flags-for-licensed-features) than the licensed feature name.

See the [feature flag tracker epic](https://gitlab.com/groups/gitlab-org/-/epics/10524) for the list of all feature flags and how to use them.

### Push feature flags to AI gateway

You can push [feature flags](../feature_flags/index.md) to AI gateway. This is helpful to gradually rollout user-facing changes even if the feature resides in AI gateway.
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

**IMPORTANT:** Cleaning up the feature flag in AI gateway will immediately distribute the change to all GitLab instances, including GitLab.com, Self-managed GitLab, and Dedicated.

**Technical details:**

- When `push_feature_flag` runs on an enabled feature flag, the name of the flag is cached in the current context,
  which is later attached to the `x-gitlab-enabled-feature-flags` HTTP header when `GitLab-Sidekiq/Rails` sends requests to AI gateway.
- When frontend clients (for example, VS Code Extension or LSP) request a [User JWT](../cloud_connector/architecture.md#ai-gateway) (UJWT)
  for direct AI gateway communication, GitLab returns:

  - Public headers (including `x-gitlab-enabled-feature-flags`).
  - The generated UJWT (1-hour expiration).

Frontend clients must regenerate UJWT upon expiration. Backend changes such as feature flag updates through [ChatOps](../feature_flags/controls.md) render the header values to become stale. These header values are refreshed at the next UJWT generation.

Similarly, we also have [`push_frontend_feature_flag`](../feature_flags/index.md) to push feature flags to frontend.

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

WARNING:
Determining the right response to a request can cause problems when only `userId` and `resourceId` are used. For example, when two AI features use the same `userId` and `resourceId` both subscriptions will receive the response from each other. To prevent this interference, we introduced the `clientSubscriptionId`.

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

Implementing a new AI action will require changes across different components.
We'll use the example of wanting to implement an action that allows users to rewrite issue descriptions according to
a given prompt.

### 1. Add your action to the Cloud Connector feature list

The Cloud Connector configuration stores the permissions needed to access your service, as well as additional metadata.
If there's still not an entry for your feature, you'll need to add one in two places:

- In the GitLab monolith:

```yaml
# ee/config/cloud_connector/access_data.yml

services:
  # ...
  rewrite_description:
    backend: 'gitlab-ai-gateway'
    bundled_with:
      duo_enterprise:
        unit_primitives:
          - rewrite_issue_description
```

- In [`customers-gitlab-com`](https://gitlab.com/gitlab-org/customers-gitlab-com):

```yaml
# config/cloud_connector.yml

services:
  # ...
  rewrite_description:
    backend: 'gitlab-ai-gateway'
    bundled_with:
      duo_enterprise:
        unit_primitives:
          - rewrite_issue_description
```

For more information, see [Cloud Connector: Configuration](../cloud_connector/configuration.md).

### 2. Create a prompt definition in the AI gateway

In [the AI gateway project](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist), create a
new prompt definition under `ai_gateway/prompts/definitions`. Create a new subfolder corresponding to the name of your
AI action, and a new YAML file for your prompt. Specify the model and provider you wish to use, and the prompts that
will be fed to the model. You can specify inputs to be plugged into the prompt by using `{}`.

```yaml
# ai_gateway/prompts/definitions/rewrite_description/base.yml

name: Description rewriter
model:
  name: claude-3-sonnet-20240229
  params:
    model_class_provider: anthropic
prompt_template:
  system: |
    You are a helpful assistant that rewrites the description of resources. You'll be given the current description, and a prompt on how you should rewrite it. Reply only with your rewritten description.

    <description>{description}</description>

    <prompt>{prompt}</prompt>
```

If your AI action is part of a broader feature, the definitions can be organized in a tree structure:

```yaml
# ai_gateway/prompts/definitions/code_suggestions/generations/base.yml

name: Code generations
model:
  name: claude-3-sonnet-20240229
  params:
    model_class_provider: anthropic
...
```

To specify prompts for multiple models, use the name of the model as the filename for the definition:

```yaml
# ai_gateway/prompts/definitions/code_suggestions/generations/mistral.yml

name: Code generations
model:
  name: mistral
  params:
    model_class_provider: litellm
...
```

### 3. Create a Completion class

1. Create a new completion under `ee/lib/gitlab/llm/ai_gateway/completions/` and inherit it from the `Base`
AI gateway Completion.

```ruby
# ee/lib/gitlab/llm/ai_gateway/completions/rewrite_description.rb

module Gitlab
  module Llm
    module AiGateway
      module Completions
        class RewriteDescription < Base
          def inputs
            { description: resource.description, prompt: prompt_message.content }
          end
        end
      end
    end
  end
end
```

### 4. Create a Service

1. Create a new service under `ee/app/services/llm/` and inherit it from the `BaseService`.
1. The `resource` is the object we want to act on. It can be any object that includes the `Ai::Model` concern. For example it could be a `Project`, `MergeRequest`, or `Issue`.

```ruby
# ee/app/services/llm/rewrite_description_service.rb

module Llm
  class RewriteDescriptionService < BaseService
    extend ::Gitlab::Utils::Override

    override :valid
    def valid?
      super &&
        # You can restrict which type of resources your service applies to
        resource.to_ability_name == "issue" &&
        # Always check that the user is allowed to perform this action on the resource
        Ability.allowed?(user, :rewrite_description, resource)
    end

    private

    def perform
      schedule_completion_worker
    end
  end
end
```

### 5. Register the feature in the catalogue

Go to `Gitlab::Llm::Utils::AiFeaturesCatalogue` and add a new entry for your AI action.

```ruby
class AiFeaturesCatalogue
  LIST = {
    # ...
    rewrite_description: {
      service_class: ::Gitlab::Llm::AiGateway::Completions::RewriteDescription,
      feature_category: :ai_abstraction_layer,
      execute_method: ::Llm::RewriteDescriptionService,
      maturity: :experimental,
      self_managed: false,
      internal: false
    }
  }.freeze
```

## Reuse the existing AI components for multiple models

We thrive optimizing AI components, such as prompt, input/output parser, tools/function-calling, for each LLM,
however, diverging the components for each model could increase the maintenance overhead.
Hence, it's generally advised to reuse the existing components for multiple models as long as it doesn't degrade a feature quality.
Here are the rules of thumbs:

1. Iterate on the existing prompt template for multiple models. Do _NOT_ introduce a new one unless it causes a quality degredation for a particular model.
1. Iterate on the existing input/output parsers and tools/functions-calling for multiple models. Do _NOT_ introduce a new one unless it causes a quality degredation for a particular model.
1. If a quality degredation is detected for a particular model, the shared component should be diverged for the particular model.

An [example](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/issues/713) of this case is that we can apply Claude specific CoT optimization to the other models such as Mixtral as long as it doesn't cause a quality degredation.

## How to migrate an existing action to the AI gateway

AI actions were initially implemented inside the GitLab monolith. As part of our
[AI gateway as the Sole Access Point for Monolith to Access Models Epic](https://gitlab.com/groups/gitlab-org/-/epics/13024)
we're migrating prompts, model selection and model parameters into the AI gateway. This will increase the speed at which
we can deliver improvements to self-managed users, by decoupling prompt and model changes from monolith releases. To
migrate an existing action:

1. Follow steps 1 through 3 on [How to implement a new action](#how-to-implement-a-new-action).
1. Modify the entry for your AI action in the catalogue to list the new completion class as the `aigw_service_class`.

```ruby
class AiFeaturesCatalogue
  LIST = {
    # ...
    generate_description: {
      service_class: ::Gitlab::Llm::Anthropic::Completions::GenerateDescription,
      aigw_service_class: ::Gitlab::Llm::AiGateway::Completions::GenerateDescription,
      prompt_class: ::Gitlab::Llm::Templates::GenerateDescription,
      feature_category: :ai_abstraction_layer,
      execute_method: ::Llm::GenerateDescriptionService,
      maturity: :experimental,
      self_managed: false,
      internal: false
    },
    # ...
  }.freeze
```

1. Create `prompt_migration_#{feature_name}` feature flag (e.g `prompt_migration_generate_description`)

When the feature flag is enabled, the `aigw_service_class` will be used to process the AI action.
Once you've validated the correct functioning of your action, you can remove the `aigw_service_class` key and replace
the `service_class` with the new `AiGateway::Completions` class to make it the permanent provider.

For a complete example of the changes needed to migrate an AI action, see the following MRs:

- [Changes to the GitLab Rails monolith](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152429)
- [Changes to the AI gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/921)

### Authorization in GitLab-Rails

We recommend to use [policies](../policies.md) to deal with authorization for a feature. Currently we need to make sure to cover the following checks:

Some basic authorization is included in the Abstraction Layer classes that are base classes for more specialized classes.

What needs to be included in the code:

1. Check for feature flag compatibility: `Gitlab::Llm::Utils::FlagChecker.flag_enabled_for_feature?(ai_action)` - included in the `Llm::BaseService` class.
1. Check if resource is authorized: `Gitlab::Llm::Utils::Authorizer.resource(resource: resource, user: user).allowed?` - also included in the `Llm::BaseService` class.
1. Both of those checks are included in the `::Gitlab::Llm::FeatureAuthorizer.new(container: subject_container, feature_name: action_name).allowed?`
1. Access to AI features depend on several factors, such as: their maturity, if they are enabled on self-managed, if they are bundled within an add-on etc.
   - [Example](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/policies/ee/global_policy.rb#L222-222) of policy not connected to the particular resource.
   - [Example](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/policies/ee/issue_policy.rb#L25-25) of policy connected to the particular resource.

NOTE:
For more information, see [the GitLab AI gateway documentation](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/gitlab_ai_gateway.md#optional-enable-authentication-and-authorization-in-ai-gateway) about authentication and authorization in AI gateway.

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

This cache is used for chat functionality. For other services, caching is
disabled. You can enable this for a service by using the `cache_response: true`
option.

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
# /ee/lib/gitlab/llm/vertex_ai/completions/rewrite_description.rb

module Gitlab
  module Llm
    module VertexAi
      module Completions
        class AmazingNewAiFeature < Gitlab::Llm::Completions::Base
          def execute
            prompt = ai_prompt_class.new(options[:user_input]).to_prompt

            response = Gitlab::Llm::VertexAi::Client.new(user, unit_primitive: 'amazing_feature').text(content: prompt)

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
# /ee/lib/gitlab/llm/vertex_ai/templates/rewrite_description.rb

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

Because we support multiple AI providers, you may also use those providers for
the same example:

```ruby
Gitlab::Llm::VertexAi::Client.new(user, unit_primitive: 'your_feature')
Gitlab::Llm::Anthropic::Client.new(user, unit_primitive: 'your_feature')
```

## Monitoring

- Error ratio and response latency apdex for each Ai action can be found on [Sidekiq Service dashboard](https://dashboards.gitlab.net/d/sidekiq-main/sidekiq-overview?orgId=1) under **SLI Detail: `llm_completion`**.
- Spent tokens, usage of each Ai feature and other statistics can be found on [periscope dashboard](https://app.periscopedata.com/app/gitlab/1137231/Ai-Features).
- [AI gateway logs](https://log.gprd.gitlab.net/app/r/s/zKEel).
- [AI gateway metrics](https://dashboards.gitlab.net/d/ai-gateway-main/ai-gateway3a-overview?orgId=1).
- [Feature usage dashboard via proxy](https://log.gprd.gitlab.net/app/r/s/egybF).

## Logs

### Overview

In addition to standard logging in the GitLab Rails Monolith instance, specialized logging is available for features based on large language models (LLMs).

### Logged events

Currently logged events are documented [here](logged_events.md).

### Implementation

#### Logger Class

To implement LLM-specific logging, use the `Gitlab::Llm::Logger` class.

#### Privacy Considerations

**Important**: User inputs and complete prompts containing user data must not be logged unless explicitly permitted.

### Feature Flag

A feature flag named `expanded_ai_logging` controls the logging of sensitive data.
Use the `conditional_info` helper method for conditional logging based on the feature flag status:

- If the feature flag is enabled for the current user, it logs the information on `info` level (logs are accessible in Kibana).
- If the feature flag is disabled for the current user, it logs the information on `info` level, but without optional parameters (logs are accessible in Kibana, but only obligatory fields).

### Best Practices

When implementing logging for LLM features, consider the following:

- Identify critical information for debugging purposes.
- Ensure compliance with privacy requirements by not logging sensitive user data without proper authorization.
- Use the `conditional_info` helper method to respect the `expanded_ai_logging` feature flag.
- Structure your logs to provide meaningful insights for troubleshooting and analysis.

### Example Usage

```ruby
# including concern that handles logging
include Gitlab::Llm::Concerns::Logger

# Logging potentially sensitive information
log_conditional_info(user, message:"User prompt processed", event_name: 'ai_event', ai_component: 'abstraction_layer', prompt: sanitized_prompt)

# Logging application error information
log_error(user, message: "System application error", event_name: 'ai_event', ai_component: 'abstraction_layer', error_message: sanitized_error_message)
```

**Important**: Please familiarize yourself with our [Data Retention Policy](../../user/gitlab_duo/data_usage.md#data-retention) and remember
to make sure we are not logging user input and LLM-generated output.

## Security

Refer to the [secure coding guidelines for Artificial Intelligence (AI) features](../secure_coding_guidelines.md#artificial-intelligence-ai-features).

## Model Migration Process

### Introduction

LLM models are constantly evolving, and GitLab needs to regularly update our AI features to support newer models. This guide provides a structured approach for migrating AI features to new models while maintaining stability and reliability.

### Purpose

Provide a comprehensive guide for migrating AI models within GitLab.

#### Expected Duration

Model migrations typically follow these general timelines:

- **Simple Model Updates (Same Provider):** 2-3 weeks
  - Example: Upgrading from Claude Sonnet 3.5 to 3.6
  - Involves model validation, testing, and staged rollout
  - Primary focus on maintaining stability and performance
  - Can sometimes be expedited when urgent, but 2 weeks is standard

- **Complex Migrations:** 1-2 months (full milestone or longer)
  - Example: Adding support for a new provider like AWS Bedrock
  - Example: Major version upgrades with breaking changes (e.g., Claude 2 to 3)
  - Requires significant API integration work
  - May need infrastructure changes
  - Extensive testing and validation required

#### Timeline Factors

Several factors can impact migration timelines:

- Current system stability and recent incidents
- Resource availability and competing priorities
- Complexity of behavioral changes in new model
- Scale of testing required
- Feature flag rollout strategy

#### Best Practices

- Always err on the side of caution with initial timeline estimates
- Use feature flags for gradual rollouts to minimize risk
- Plan for buffer time to handle unexpected issues
- Communicate conservative timelines externally while working to deliver faster
- Prioritize system stability over speed of deployment

NOTE:
While some migrations can technically be completed quickly, we typically plan for longer timelines to ensure proper testing and staged rollouts. This approach helps maintain system stability and reliability.

### Scope

Applicable to all AI model-related teams at GitLab. We currently only support using Anthropic and Google Vertex models, with plans to support AWS Bedrock models in the [future](https://gitlab.com/gitlab-org/gitlab/-/issues/498119).

### Prerequisites

Before starting a model migration:

- Create an issue under the [AI Model Version Migration Initiative epic](https://gitlab.com/groups/gitlab-org/-/epics/15650) with the following:
  - Label with `group::ai framework`
  - Document any known behavioral changes or improvements in the new model
  - Include any breaking changes or compatibility issues
  - Reference any model provider documentation about the changes

- Verify the new model is supported in our current AI-Gateway API specification by:
  
  - Check model definitions in AI gateway:
    - For LiteLLM models: `ai_gateway/models/v2/container.py`
    - For Anthropic models: `ai_gateway/models/anthropic.py`
    - For new providers: Create a new model definition file in `ai_gateway/models/`
  - Verify model configurations:
    - Model enum definitions
    - Stop tokens
    - Timeout settings
    - Completion type (text or chat)
    - Max token limits
  - Testing the model locally in AI gateway:
    - Set up the [AI gateway development environment](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist#how-to-run-the-server-locally)
    - Configure the necessary API keys in your `.env` file
    - Test the model using the Swagger UI at `http://localhost:5052/docs`
  - If the model isn't supported, create an issue in the [AI gateway repository](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist) to add support
  - Review the provider's API documentation for any breaking changes:
    - [Anthropic API Documentation](https://docs.anthropic.com/claude/reference/versions)
    - [Google Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs/reference)

- Ensure you have access to testing environments and monitoring tools
- Complete model evaluation using the [Prompt Library](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library/-/blob/main/doc/how-to/run_duo_chat_eval.md)

NOTE:
Documentation of model changes is crucial for tracking the impact of migrations and helping with future troubleshooting. Always create an issue to track these changes before beginning the migration process.

### Migration Tasks

#### Migration Tasks for Anthropic Model

- **Optional** - Investigate if the new model is supported within our current AI-Gateway API specification. This step can usually be skipped. However, sometimes to support a newer model, we may need to accommodate a new API format.
- Add the new model to our [available models list](https://gitlab.com/gitlab-org/gitlab/-/blob/32fa9eaa3c8589ee7f448ae683710ec7bd82f36c/ee/lib/gitlab/llm/concerns/available_models.rb#L5-10).
- Change the default model in our [AI-Gateway client](https://gitlab.com/gitlab-org/gitlab/-/blob/41361629b302f2c55e35701d2c0a73cff32f9013/ee/lib/gitlab/llm/chain/requests/ai_gateway.rb#L63-67). Please place the change around a feature flag. We may need to quickly rollback the change.
- Update the model definitions in AI gateway following the [prompt definition guidelines](#2-create-a-prompt-definition-in-the-ai-gateway)
Note: While we're moving toward AI gateway holding the prompts, feature flag implementation still requires a GitLab release.

#### Migration Tasks for Vertex Models

**Work in Progress**

### Feature Flag Process

#### Implementation Steps

For implementing feature flags, refer to our [Feature Flags Development Guidelines](../feature_flags/index.md).

NOTE:
Feature flag implementations will affect self-hosted cloud-connected customers. These customers won't receive the model upgrade until the feature flag is removed from the AI gateway codebase, as they won't have access to the new GitLab release.

#### Model Selection Implementation

The model selection logic should be implemented in:

- AI gateway client (`ee/lib/gitlab/llm/chain/requests/ai_gateway.rb`)
- Model definitions in AI gateway
- Any custom implementations in specific features that override the default model

#### Rollout Strategy

- Enable the feature flag for a small percentage of users/groups initially
- Monitor performance metrics and error rates using:
  - [Sidekiq Service dashboard](https://dashboards.gitlab.net/d/sidekiq-main/sidekiq-overview) for error ratios and response latency
  - [AI gateway metrics dashboard](https://dashboards.gitlab.net/d/ai-gateway-main/ai-gateway3a-overview?orgId=1) for gateway-specific metrics
  - [AI gateway logs](https://log.gprd.gitlab.net/app/r/s/zKEel) for detailed error investigation
  - [Feature usage dashboard](https://log.gprd.gitlab.net/app/r/s/egybF) for adoption metrics
  - [Periscope dashboard](https://app.periscopedata.com/app/gitlab/1137231/Ai-Features) for token usage and feature statistics
- Gradually increase the rollout percentage
- If issues arise, quickly disable the feature flag to rollback to the previous model
- Once stability is confirmed, remove the feature flag and make the migration permanent

For more details on monitoring during migrations, see the [Monitoring and Metrics](#monitoring-and-metrics) section below.

### Scope of Work

#### AI Features to Migrate

- **Duo Chat Tools:**
  - `ci_editor_assistant/prompts/anthropic.rb` - CI Editor
  - `gitlab_documentation/executor.rb` - GitLab Documentation
  - `epic_reader/prompts/anthropic.rb` - Epic Reader
  - `issue_reader/prompts/anthropic.rb` - Issue Reader
  - `merge_request_reader/prompts/anthropic.rb` - Merge Request Reader
- **Chat Slash Commands:**
  - `refactor_code/prompts/anthropic.rb` - Refactor
  - `write_tests/prompts/anthropic.rb` - Write Tests
  - `explain_code/prompts/anthropic.rb` - Explain Code
  - `explain_vulnerability/executor.rb` - Explain Vulnerability
- **Experimental Tools:**
  - Summarize Comments Chat
  - Fill MR Description

### Testing and Validation

#### Model Evaluation

The `ai-model-validation` team created the following library to evaluate the performance of prompt changes as well as model changes. The [Prompt Library README.MD](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library/-/blob/main/doc/how-to/run_duo_chat_eval.md) provides details on how to evaluate the performance of AI features.

> Another use-case for running chat evaluation is during feature development cycle. The purpose is to verify how the changes to the code base and prompts affect the quality of chat responses before the code reaches the production environment.

For evaluation in merge request pipelines, we use:

- One click [Duo Chat evaluation](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/evaluation-runner)
- Automated evaluation in [merge request pipelines](https://gitlab.com/gitlab-org/gitlab/-/issues/495410)

#### Seed project and group resources for testing and evaluation

To seed project and group resources for testing and evaluation, run the following command:

```shell
SEED_GITLAB_DUO=1 FILTER=gitlab_duo bundle exec rake db:seed_fu
```

This command executes the [development seed file](../development_seed_files.md) for GitLab Duo, which creates `gitlab-duo` group in your GDK.

This command is responsible for seeding group and project resources for testing GitLab Duo features.
It's mainly used by the following scenarios:

- Developers or UX designers have a local GDK but don't know how to set up the group and project resources to test a feature in UI.
- Evaluators (e.g. CEF) have input dataset that refers to a group or project resource e.g. (`Summarize issue #123` requires a corresponding issue record in PosstgreSQL)

Currently, the input dataset of evaluators and this development seed file are managed seaprately.
To ensure that the integration keeps working, this seeder has to create the **same** group/project resources every time.
For example, ID and IID of the inserted PostgreSQL records must be the same every time we run this seeding process.

These fixtures are depended by the following projects:

- [Central Evaluation Framework](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library)
- [Evaluation Runner](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/evaluation-runner)

See [this architecture doc](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/evaluation-runner/-/blob/main/docs/architecture.md) for more information.

#### Local Development

A valuable tool for local development to ensure the changes are correct outside of unit tests is to use [LangSmith](duo_chat.md#tracing-with-langsmith) for tracing. The tool allows you to trace LLM calls within Duo Chat to verify the LLM tool is using the correct model.

To prevent regressions, we also have CI jobs to make sure our tools are working correctly. For more details, see the [Duo Chat testing section](duo_chat.md#gitlab-duo-chat-qa-evaluation-test).

### Monitoring and Metrics

Monitor the following during migration:

- **Performance Metrics:**
  - Error ratio and response latency apdex for each AI action on [Sidekiq Service dashboard](https://dashboards.gitlab.net/d/sidekiq-main/sidekiq-overview)
  - Spent tokens, usage of each AI feature and other statistics on [periscope dashboard](https://app.periscopedata.com/app/gitlab/1137231/Ai-Features)
  - [AI gateway logs](https://log.gprd.gitlab.net/app/r/s/zKEel)
  - [AI gateway metrics](https://dashboards.gitlab.net/d/ai-gateway-main/ai-gateway3a-overview?orgId=1)
  - [Feature usage dashboard via proxy](https://log.gprd.gitlab.net/app/r/s/egybF)
