---
stage: AI-powered
group: Workflow Catalog
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Managing foundational agents
---

[Foundational agents](../../user/duo_agent_platform/agents/foundational_agents/_index.md) are specialized agents
that are created and maintained by GitLab, providing more accurate responses for specific use cases. These agents are
available by default on any place chat and duo chat are available, including groups, and are supported on Duo Self-hosted.

## Create a foundational agent

There are two ways of creating a foundational agent, using the AI Catalog or Duo Workflow Service. AI Catalog provides
a user-friendly interface, and it is the preferred approach, but writing a definition on Duo Workflow Service provides
more flexibility for complex cases.

### Using the AI catalog

1. Create your agent on the [AI Catalog](https://gitlab.com/explore/ai-catalog/agents/), and note its ID. Make sure the agent is set to
   public. Example: [Duo Planner](https://gitlab.com/explore/ai-catalog/agents/356/) has ID 356.

1. Agents created on the AI Catalog need to be bundled into Duo Workflow Service, so they can be available to self-hosted
   setups that do not have access to our SaaS. To achieve this, open an MR to Duo Workflow Service adding the ID of the
   agent:

   ```diff
   # https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/Dockerfile
   - RUN poetry run fetch-foundational-agents "https://gitlab.com" "$GITLAB_TOKEN" "348,356" \
   + RUN poetry run fetch-foundational-agents "https://gitlab.com" "$GITLAB_TOKEN" "348,356,<your-id-here>" \
   ```

   The command above can also be executed locally for testing purposes.

1. To make the agent be selectable, add it to the [`FoundationalChatAgentsDefinitions.rb`](https://gitlab.com/gitlab-org/gitlab/blob/master/ee/lib/ai/foundational_chat_agents_definitions.rb).
   The `reference` field must be the name of the agent lowercased and underscored, version must be `v1`. For example,
   a definition for an agent named `Test Agent` would be:

   ```ruby
   {
     id: 3,
     reference: 'test_agent',
     version: 'experimental',
     name: 'Test Agent',
     description: "An agent for testing"
   }
   ```

It is possible to test the setup locally. To do so, create the agent in your GDK. Then, on `$GDK/gitlab-ai-gateway`, run the following command:

```shell
poetry run fetch-foundational-agents "http://gdk.test:3000" "<TOKEN TO YOUR GDK>" \
  "<ID OF AGENT IN YOUR GDK>" \
  --output-path duo_workflow_service/agent_platform/experimental/flows/configs
```

With the changes to `FoundationalChatAgentsDefinitions.rb`, it is possible now to select your foundational agent in the web chat locally.

### Using Duo workflow service

1. Create a flow configuration file in `/duo_workflow_service/agent_platform/v1/flows/configs/` (located either on your GDK under `PATH-TO-YOUR-GDK/gdk/gitlab-ai-gateway` or on the [ai-assist repository](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/tree/main/duo_workflow_service/agent_platform/v1/flows/configs/)):

   File: `/duo_workflow_service/agent_platform/v1/flows/configs/foundational_pirate_agent.yml`

   ```yaml
   version: "v1"
   environment: chat-partial
   components:
     - name: "foundational_pirate_agent"
       type: AgentComponent
       prompt_id: "foundational_pirate_agent_prompt"
       inputs:
         - from: "context:goal"
           as: "goal"
         - from: "context:project_id"
           as: "project_id"
       toolset: []
       ui_log_events: []
   prompts:
     - name: Foundational Pirate Agent
       prompt_id: "foundational_pirate_agent_prompt"
       model:
         params:
           model_class_provider: anthropic
           max_tokens: 2_000
       prompt_template:
         system: |
           You are a seasoned pirate from the Golden Age of Piracy. You speak exclusively in pirate dialect, using nautical
           terms, pirate slang, and colorful seafaring expressions. Transform any input into authentic pirate speak while
           maintaining the original meaning. Use terms like 'ahoy', 'matey', 'ye', 'aye', 'landlubber', 'scallywag',
           'doubloons', 'plunder', etc. Add pirate exclamations like 'Arrr!', 'Shiver me timbers!', and 'Yo ho ho!' where
           appropriate. Refer to yourself in the first person as a pirate would.
         user: |
           {{goal}}
         placeholder: history
   routers: []
   flow:
     entry_point: "foundational_pirate_agent"
   ```

1. Add your agent definition to [FoundationalChatAgentsDefinitions.rb](https://gitlab.com/gitlab-org/gitlab/blob/master/ee/lib/ai/foundational_chat_agents_definitions.rb):

   ```ruby
   # frozen_string_literal: true

   module Ai
     module FoundationalChatAgentsDefinitions
       extend ActiveSupport::Concern

       ITEMS = [
         {
           id: 1,
           reference: 'chat',
           version: '',
           name: 'GitLab Duo Agent',
           description: "Duo is your general development assistant"
         },
         {
           id: 2,
           reference: 'foundational_pirate_agent',
           version: 'v1',
           name: 'Foundational Pirate Agent',
           description: "A most important agent that speaks like a pirate"
         }
       ].freeze
     end
   end
   ```

Tips:

1. You can use the AI Catalog to test foundational agents, even before you add them to the codebase.
   Create a new private agent in the AI Catalog with the same prompt and same tools, and enable it on your test project.
   Once results reach desired levels, add to Duo Workflow Service.
1. Add prompts to the Duo Workflow Service to enable testing the agent in your local GDK.
1. When using AI catalog, the version field of an agent in `FoundationalChatAgentsDefinitions.rb` should be `experimental`. 
   When creating the definition in Duo workflow service, the version should be `v1`.

## Use feature flags for releasing chat agents

Control the release of new foundational agents with feature flags:

```ruby
# ee/app/graphql/resolvers/ai/foundational_chat_agents_resolver.rb

  def resolve(*, project_id: nil, namespace_id: nil)
    project = GitlabSchema.find_by_gid(project_id)

    filtered_agents = []
    filtered_agents << 'foundational_pirate_agent' if Feature.disabled?(:my_feature_flag, project)
    # filtered_agents << 'foundational_pirate_agent' if Feature.disabled?(:my_feature_flag, current_user)

    ::Ai::FoundationalChatAgent
 .select {|agent| filtered_agents.exclude?(agent.reference) }
      .sort_by(&:id)
  end
```

This also allows making a foundational agent available to a specific tier.

## Scoping

Not every agent is useful in every area. For example, some agents operate in projects, while others are more useful or have more capabilities in groups. Scoping is not supported. See [issue 577395](https://gitlab.com/gitlab-org/gitlab/-/issues/577395).

## Triggers

Triggers are not supported for foundational chat agents by default, but if they are defined on AI Catalog, users can
still add it to their project at which point they can be used through triggers.

## Versioning

Versioning of agents is not yet supported. Consider potential breaking changes to older GitLab versions
before doing changes to an agent.
