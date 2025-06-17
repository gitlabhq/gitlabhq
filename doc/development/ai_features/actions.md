---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: AI actions
---

This page includes how to implement actions and migrate them to the AI Gateway.

## How to implement a new action

Implementing a new AI action will require changes across different components.
We'll use the example of wanting to implement an action that allows users to rewrite issue descriptions according to
a given prompt.

### 1. Add your action to the Cloud Connector feature list

The Cloud Connector configuration stores the permissions needed to access your service, as well as additional metadata.
If there's no entry for your feature, [add the feature as a Cloud Connector unit primitive](../cloud_connector/_index.md#register-new-feature-for-gitlab-self-managed-dedicated-and-gitlabcom-customers):

For more information, see [Cloud Connector: Configuration](../cloud_connector/configuration.md).

### 2. Create a prompt definition in the AI gateway

In [the AI gateway project](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist), create a
new prompt definition under `ai_gateway/prompts/definitions` with the route `[ai-action]/base/[prompt-version].yml`
(see [Prompt versioning conventions](#appendix-a-prompt-versioning-conventions)).
Specify the model and provider you wish to use, and the prompts that
will be fed to the model. You can specify inputs to be plugged into the prompt by using `{}`.

```yaml
# ai_gateway/prompts/definitions/rewrite_description/base/1.0.0.yml

name: Description rewriter
model:
  config_file: conversation_performant
  params:
    model_class_provider: anthropic
prompt_template:
  system: |
    You are a helpful assistant that rewrites the description of resources. You'll be given the current description, and a prompt on how you should rewrite it. Reply only with your rewritten description.

    <description>{description}</description>

    <prompt>{prompt}</prompt>
```

When an AI action uses multiple prompts, the definitions can be organized in a tree structure in the form
`[ai-action]/[prompt-name]/base/[version].yaml`:

```yaml
# ai_gateway/prompts/definitions/code_suggestions/generations/base/1.0.0.yml

name: Code generations
model:
  config_file: conversation_performant
  params:
    model_class_provider: anthropic
...
```

To specify prompts for multiple models, use the name of the model in the path for the definition:

```yaml
# ai_gateway/prompts/definitions/code_suggestions/generations/mistral/1.0.0.yml

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
          extend ::Gitlab::Utils::Override

          override :inputs
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

### 6. Add a default prompt version query

Go to `Gitlab::Llm::PromptVersions` and add an entry for your AI action with a query that includes your desired prompt
version (for new features this will usually be `^1.0.0`, see [Prompt version resolution](#prompt-version-resolution)):

```ruby
class PromptVersions
  class << self
    VERSIONS = {
      # ...
      "rewrite_description/base": "^1.0.0"
```

## Updating an AI action

To make changes to the template, model, or parameters of an AI feature, create a new YAML version file in the AI Gateway:

```yaml
# ai_gateway/prompts/definitions/rewrite_description/base/1.0.1.yml

name: Description rewriter with Claude 3.5
model:
  name: claude-3-5-sonnet-20240620
  params:
    model_class_provider: anthropic
prompt_template:
  system: |
    You are a helpful assistant that rewrites the description of resources. You'll be given the current description, and a prompt on how you should rewrite it. Reply only with your rewritten description.

    <description>{description}</description>

    <prompt>{prompt}</prompt>
```

### Incremental rollout of prompt versions

Once a stable prompt version is added to the AI Gateway it should not be altered. You can create a mutable version of a
prompt by adding a pre-release suffix to the file name (for example, `1.0.1-dev.yml`). This will also prevent it from being
automatically served to clients. Then you can use a feature flag to control the rollout this new version. For GitLab
Duo Self-hosted, forced versions are ignored, and only versions defined in `PromptVersions` are used. This avoids
mistakenly enabling versions for models that don't have that specified version.

If your AI action is implemented as a subclass of `AiGateway::Completions::Base`, you can achieve this by overriding the prompt
version in your subclass:

```ruby
# ee/lib/gitlab/llm/ai_gateway/completions/rewrite_description.rb

module Gitlab
  module Llm
    module AiGateway
      module Completions
        class RewriteDescription < Base
          extend ::Gitlab::Utils::Override

          override :prompt_version
          def prompt_version
            '1.0.1-dev' if Feature.enabled?(:my_feature_flag) # You can also scope it to `user` or `resource`, as appropriate
          end

          # ...
```

Once you are ready to make this version stable and start auto-serving it to compatible clients, simply rename the YAML
definition file to remove the pre-release suffix, and remove the `prompt_version` override.

## How to migrate an existing action to the AI gateway

AI actions were initially implemented inside the GitLab monolith. As part of our
[AI gateway as the Sole Access Point for Monolith to Access Models Epic](https://gitlab.com/groups/gitlab-org/-/epics/13024)
we're migrating prompts, model selection and model parameters into the AI gateway. This will increase the speed at which
we can deliver improvements to users on GitLab Self-Managed, by decoupling prompt and model changes from monolith releases. To
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

{{< alert type="note" >}}

For more information, see [the GitLab AI gateway documentation](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/gitlab_ai_gateway.md#optional-enable-authentication-and-authorization-in-ai-gateway) about authentication and authorization in AI gateway.

{{< /alert >}}

If your Duo feature involves an autonomous agent, you should use
[composite identity](composite_identity.md) authorization.

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

- If the feature is not in any array, the check will return `true`. For example, the feature is generally available.

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

## Appendix A: Prompt versioning conventions

Prompt versions should adjust to [Semantic Versioning](https://semver.org/) standards: `MAJOR.MINOR.PATCH[-PRERELEASE]`.

- A change in the MAJOR component reflects changes will break with older versions of GitLab. For example, when the new
prompt must receive a new property that doesn't have a default, since if this change were applied to all GitLab versions,
requests made from older versions will throw an error since that property is not present.

- A change in the MINOR component reflects feature additions, but that are still backwards compatible. For example,
suppose we want to use a new more powerful model: requests of older versions of GitLab will still work.

- A change in the PATCH component reflects small bug fixes to prompts, like a typo.

The MAJOR component guarantees that older versions of GitLab will not break once a new change is added, without blocking
the evolution of our codebase. Changes in MINOR and PATCH are more subjective.

### Immutability of prompt versions

To guarantee traceability of changes, only prompts with a [pre-release version](https://semver.org/#spec-item-9) (eg `1.0.1-dev.yml`)
may be changed once committed. Prompts defining a stable version are immutable, and changing them will trigger a pipeline failure.

### Using partials

To better organize the prompts, it is possible to use partials to split a prompt into smaller parts. Partials must also be
versioned. For example:

```yaml
# ai_gateway/prompts/definitions/rewrite_description/base/1.0.0.yml

name: Description rewriter
model:
  config_file: conversation_performant
  params:
    model_class_provider: anthropic
prompt_template:
  system: |
    {% include 'rewrite_description/system/1.0.0.jinja' %}
  user: |
    {% include 'rewrite_description/user/1.0.0.jinja' %}
```

### Prompt version resolution

AI Gateway will fetch the latest stable version available that matches the prompt version query passed as argument.
Queries follow [Poetry's version constraint rules](https://python-poetry.org/docs/dependency-specification/#version-constraints).
For example, if prompt `foo/bar` has the following versions:

- `1.0.1.yml`
- `1.1.0.yml`
- `1.5.0-dev.yml`
- `2.0.1.yml`

Then, if `/v1/prompts/foo/bar` is called with

- `{'prompt_version': "^1.0.0"}`, prompt version `1.1.0.yml` will be selected.
- `{'prompt_version': "1.5.0-dev"}`, prompt version `1.5.0-dev.yml` will be selected.
- `{'prompt_version': "^2.0.0"}`, prompt version `2.0.1.yml` will be selected.
