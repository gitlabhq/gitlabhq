---
stage: AI-powered
group: Workflow Catalog
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Managing foundational agents
---

Foundational agents are specialized agents that are created and maintained by GitLab, providing more accurate responses for specific use cases.
You can select a foundational agent when you start a chat.

## Create a foundational agent

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

Triggers are not supported for foundational agents. See [issue 577394](https://gitlab.com/gitlab-org/gitlab/-/issues/577394)
