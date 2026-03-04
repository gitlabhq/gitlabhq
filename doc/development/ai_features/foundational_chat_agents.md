---
stage: AI-powered
group: Workflow Catalog
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Managing foundational agents
---

[Foundational agents](../../user/duo_agent_platform/agents/foundational_agents/_index.md) are specialized agents
that are created and maintained by GitLab, providing more accurate responses for specific use cases. These agents are
available by default on any place chat and GitLab Duo chat are available, including groups, and are supported on GitLab Duo Self-Hosted.

## Create a foundational agent

There are two ways of creating a foundational agent, using the AI Catalog or GitLab Duo Workflow Service. AI Catalog provides
a user-friendly interface, and it is the preferred approach, but writing a definition on GitLab Duo Workflow Service provides
more flexibility for complex cases.

### Using the AI catalog

1. Create your agent on the [AI Catalog](https://gitlab.com/explore/ai-catalog/agents/), and note its ID. Make sure the agent is set to
   public. Example: [Planner Agent](https://gitlab.com/explore/ai-catalog/agents/348/) has ID 348.

1. Agents created on the AI Catalog need to be bundled into GitLab Duo Workflow Service, so they can be available to self-hosted
   setups that do not have access to our SaaS. To achieve this, open an MR to GitLab Duo Workflow Service adding the ID of the
   agent:

   ```diff
   # https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/Dockerfile
   - RUN poetry run fetch-foundational-agents "https://gitlab.com" "$GITLAB_TOKEN" "348" \
   + RUN poetry run fetch-foundational-agents "https://gitlab.com" "$GITLAB_TOKEN" "duo_planner:348,<agent-reference>:<agent-catalog-id>" \
   ```

   The command above can also be executed locally for testing purposes. Agent reference must be lowercase without spaces (example: 'test_agent').

1. To make the agent be selectable, add it to the [`FoundationalChatAgentsDefinitions.rb`](https://gitlab.com/gitlab-org/gitlab/blob/master/ee/lib/ai/foundational_chat_agents_definitions.rb).
   Use the reference used in the Dockerfile:

   ```ruby
   {
     id: 3,
     reference: '<agent-reference>',
     version: 'experimental',
     name: 'Test Agent',
     description: "An agent for testing"
   }
   ```

1. Update [user facing documentation](../../user/duo_agent_platform/agents/foundational_agents/_index.md).

### Using GitLab Duo Workflow Service

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
           description: "GitLab Duo is your general development assistant"
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

1. Update [user facing documentation](../../user/duo_agent_platform/agents/foundational_agents/_index.md).

Tips:

1. You can use the AI Catalog to test foundational agents, even before you add them to the codebase.
   Create a new private agent in the AI Catalog with the same prompt and same tools, and enable it on your test project.
   Once results reach desired levels, add to GitLab Duo Workflow Service.
1. Add prompts to the GitLab Duo Workflow Service to enable testing the agent in your local GDK.
1. When using AI catalog, the version field of an agent in `FoundationalChatAgentsDefinitions.rb` should be `experimental`.
   When creating the definition in GitLab Duo Workflow Service, the version should be `v1`.

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

Triggers are not supported for foundational chat agents. However, if they are defined on AI Catalog, users can
still add it to their project at which point they can be used through triggers.

## Versioning

Versioning of agents is not yet supported. Consider potential breaking changes to older GitLab versions
before doing changes to an agent.

## Developing foundational agents locally

  For AI catalog created agents, you need to sync the agents locally. To do so, either create the agent in the local AI Catalog or on GitLab.com AI Catalog.

1. **Fetch agents from GitLab.com**

   On `$GDK/gitlab-ai-gateway`, run the following command:

   ```shell
   poetry run fetch-foundational-agents "http://gdk.test:3000 or https://gitlab.com" "<token-to-your-local-gdk>" \
    "<agent-reference>:<agent-id-in-local-catalog>" --flow-registry-version v1
   ```

   An example pulling `duo_planner` and `security_analyst_agent` from GitLab.com would look like this:

   ```shell
   poetry run fetch-foundational-agents "https://gitlab.com" "<token-to-your-local-gdk>" \
    "duo_planner:348,security_analyst_agent:356" --flow-registry-version v1
   ```

   Where:

   - `348` is the GitLab Duo Planner catalog ID on GitLab.com
   - `356` is the Security Analyst Agent catalog ID on GitLab.com

   After fetching the configurations, restart the service:

   ```shell
   gdk restart duo-workflow-service
   ```

1. **Verify the setup**

   Foundational agents are saved in `$GDK/gitlab-ai-gateway/duo_workflow_service/agent_platform/v1/flows/configs/` as `.yml` files.

   For example if you used the above `poetry` command to pull `duo_planner` and `security_analyst_agent`, you can run the following:

   ```shell
   ls duo_workflow_service/agent_platform/v1/flows/configs/ | grep -e "duo_planner" -e "security_analyst"
   ```

   You then should see the following output:

   ```shell
   duo_planner.yml
   security_analyst_agent.yml
   ```

   Alternatively to check in the GDK UI:

   1. With the changes to `FoundationalChatAgentsDefinitions.rb`, you can now select your foundational agent in the web chat locally.
   1. Verify that you can see and interact with the foundational agents
   1. Test sending a message to confirm the agents respond correctly

### Troubleshooting

- Agents don't appear in chat: Verify the configuration files were created in your GitLab-ai-gateway directory and the service restarted successfully
- Permission errors: Ensure your GitLab.com API token has the API scope
- Flow registry version errors: Confirm you're using `--flow-registry-version v1`

## Testing foundational agent synchronization pipeline

This section describes how to test the pipeline used to sync foundational agents in your local GDK. For developing the foundational flows or pulling the latest flows refer to the [Developing foundational agents locally](#developing-foundational-agents-locally) section above.

### Prerequisites

- A running GDK instance
- A GitLab API token with `api` scope (`$GDK_PAT_WITH_API_SCOPE`)
- Access to the `gitlab-ai-gateway` repository in your GDK

### Step 1: Check existing foundational agents

First, identify which foundational agents are defined in the monolith but missing from your local AI Catalog:

1. Check the foundational agents definitions:

   ```shell
   # In your GDK's gitlab directory
   cat ee/lib/ai/foundational_chat_agents_definitions.rb
   ```

1. List existing agents in your local AI Catalog:

   ```shell
   curl --header "Authorization: Bearer $GDK_PAT_WITH_API_SCOPE" \
     --header "Content-Type: application/json" \
     "http://gdk.test:3000/api/graphql" \
     --data '{"query": "query { aiCatalogItems { nodes { id name description } } }"}'
   ```

1. Compare the results to identify missing foundational agents (typically `duo_planner` and `security_analyst_agent`).

### Step 2: Create missing foundational agents

If foundational agents are missing from your local AI Catalog, create them programmatically:

1. Get a project ID for hosting the agents:

   If you've run the duo setup script with `bundle exec rake gitlab:duo:setup`, you can use the project with ID `1000000` as the foundational agents owning project. If not, you can pick any Premium or Ultimate project in your GDK and use that project's ID.

   ```shell
   # If you haven't run the duo setup script, get any project ID
   curl --header "Authorization: Bearer $GDK_PAT_WITH_API_SCOPE" \
     "http://gdk.test:3000/api/v4/projects" | jq '.[0].id'
   ```

1. Create the Planner agent:

   ```shell
   curl --header "Authorization: Bearer $GDK_PAT_WITH_API_SCOPE" \
     --header "Content-Type: application/json" \
     "http://gdk.test:3000/api/graphql" \
     --data '{
       "query": "mutation { aiCatalogAgentCreate(input: { projectId: \"gid://gitlab/Project/YOUR_PROJECT_ID\", name: \"Planner\", description: \"Get help with planning and workflow management. Organize, edit, create, and track work more effectively in GitLab.\", public: true, systemPrompt: \"You are a helpful planning assistant that helps users organize, edit, create, and track work more effectively in GitLab.\" }) { item { id name } errors } }"
     }'
   ```

1. Create the Security Analyst agent:

   ```shell
   curl --header "Authorization: Bearer $GDK_PAT_WITH_API_SCOPE" \
     --header "Content-Type: application/json" \
     "http://gdk.test:3000/api/graphql" \
     --data '{
       "query": "mutation { aiCatalogAgentCreate(input: { projectId: \"gid://gitlab/Project/YOUR_PROJECT_ID\", name: \"Security Analyst\", description: \"Automate vulnerability management and security workflows. The Security Analyst Agent acts as an AI team member that can autonomously analyze, triage, and remediate security vulnerabilities.\", public: true, systemPrompt: \"You are a security analyst AI that helps with vulnerability management and security workflows. You can analyze, triage, and help remediate security vulnerabilities.\" }) { item { id name } errors } }"
     }'
   ```

   Replace `YOUR_PROJECT_ID` with the actual project ID from step 1.

### Step 3: Get the local agent IDs

After creating the agents, get their local catalog IDs:

```shell
# Get Planner agent ID
curl --header "Authorization: Bearer $GDK_PAT_WITH_API_SCOPE" \
  --header "Content-Type: application/json" \
  "http://gdk.test:3000/api/graphql" \
  --data '{"query": "query { aiCatalogItems(search: \"Planner\") { nodes { id name } } }"}'

# Get Security Analyst agent ID
curl --header "Authorization: Bearer $GDK_PAT_WITH_API_SCOPE" \
  --header "Content-Type: application/json" \
  "http://gdk.test:3000/api/graphql" \
  --data '{"query": "query { aiCatalogItems(search: \"Security Analyst\") { nodes { id name } } }"}'
```

Note the numeric IDs from the responses (for example, `10` and `11`).

### Step 4: Fetch foundational agent configurations

In your `gitlab-ai-gateway` directory, fetch the agent configurations using the local IDs:

```shell
# For v1 flow registry (recommended)
poetry run fetch-foundational-agents "http://gdk.test:3000" "$GDK_PAT_WITH_API_SCOPE" \
  "duo_planner:10,security_analyst_agent:11" \
  --flow-registry-version v1

# For experimental flow registry (alternative)
poetry run fetch-foundational-agents "http://gdk.test:3000" "$GDK_PAT_WITH_API_SCOPE" \
  "duo_planner:10,security_analyst_agent:11" \
  --flow-registry-version experimental \
  --output-path duo_workflow_service/agent_platform/experimental/flows/configs
```

Replace `10` and `11` with the actual agent IDs from step 3.

### Step 5: Restart GitLab Duo Workflow Service

```shell
gdk restart duo-workflow-service
```

### Step 6: Verify the setup

With the changes to `FoundationalChatAgentsDefinitions.rb` and the fetched configurations, you can now select your foundational agents in the web chat locally.

### Troubleshooting

- **Missing agents**: If agents don't appear in chat after following these steps, verify:
  - The agents exist in your local AI Catalog (check with the GraphQL query from Step 3)
  - The flow configuration files were created in the correct directory after running `fetch-foundational-agents`
  - The GitLab Duo Workflow Service was restarted successfully
- **Flow registry version**: Use `v1` for production-like behavior, `experimental` for testing new features
- **Permission errors**: Ensure your API token has the `api` scope and sufficient project permissions
- **GraphQL errors**: Check the exact mutation parameters using GraphQL introspection:

  ```shell
  curl --header "Authorization: Bearer $GDK_PAT_WITH_API_SCOPE" \
    --header "Content-Type: application/json" \
    "http://gdk.test:3000/api/graphql" \
    --data '{"query": "query { __type(name: \"AiCatalogAgentCreatePayload\") { fields { name type { name } } } }"}'
  ```

## Architecture design

[Foundational Chat Agents](../../development/ai_features/glossary.md#agent-types) are developed by GitLab and must be available to all GitLab deployments (GitLab.com, Self-Managed, and Dedicated).

The architecture of how Foundational Agents are made available avoids connecting to AI Catalog to fetch definitions at runtime and allows GitLab engineering teams full control over when they are released.

This design could also be extended to support
[Foundational flows](../../development/ai_features/glossary.md#flow-types).

### Foundational Agents in Monolith

Defining foundational agents in the monolith serves two purposes: backwards compatibility support and release control.

With [`FoundationalChatAgentsDefinitions`](https://gitlab.com/gitlab-org/gitlab/blob/master/ee/lib/ai/foundational_chat_agents_definitions.rb)
The [`FoundationalChatAgentsDefinitions`](https://gitlab.com/gitlab-org/gitlab/blob/master/ee/lib/ai/foundational_chat_agents_definitions.rb)
module manages agent versioning based on the GitLab instance version.
affecting older GitLab versions, similar to [prompt versioning](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/prompts_migration/#versioning).

Additionally, on [`FoundationalChatAgentsResolver`](https://gitlab.com/gitlab-org/gitlab/blob/master/ee/app/graphql/resolvers/ai/foundational_chat_agents_resolver.rb),
teams are able to select which conditions can make a foundational chat agent available, for situations like:

- does the user have Ultimate,
- is the feature flag enabled,
- is the agent SaaS exclusive

If we relied exclusively on AI Catalog or Duo Workflow Service, such flexibility wouldn't be possible

#### Version resolution

Agent versions are resolved based on the `version` field in `FoundationalChatAgentsDefinitions.rb`,
which maps to a
folder in GitLab Duo Workflow Service (for example, `v1`, `experimental`).

In the future, [version resolution will be based on semantic versioning](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/issues/1577).
This will allow:

- **Patch and minor updates** (bug fixes, performance improvements, prompt refinements) to be shipped to existing
  GitLab versions without requiring a GitLab instance update
- **Major version releases** for breaking changes that require new GitLab features (such as new tools, API changes,
  or schema modifications) to be shipped only to compatible GitLab versions

This approach ensures backward compatibility while enabling continuous improvement of foundational agents.

### Bundling into GitLab Duo Workflow Service

Bundling agents into GitLab Duo Workflow Service makes agents defined in AI Catalog available on all deployments,
including self-hosted setups.
[With semantic versioning support](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/issues/1577),
the latest version of each major release will be bundled,
along with specific pinned versions of each foundational
agent.

The alternative to this would be to ship the YAML definitions themselves as part of GitLab monolith,
but that comes with
the downside of not being able to quickly ship fixes to cloud-connected self-managed instances.

Eventually, if labels are implemented on AI Catalog,
teams wouldn't need to add their entries to the Dockerfile, versions
could be fetched by the correct labels.

### Creation flow

```mermaid
%%{init: {"sequence": {"actorMargin": 50}}}%%
sequenceDiagram
    accTitle: Foundational agent creation flow
    accDescr: Sequence diagram showing the process of creating a foundational agent from AI Catalog through to GitLab monolith
    participant Team
    participant AI Catalog
    participant DWS Repo as DWS Repository
    participant CI
    participant Monolith

    Team->>AI Catalog: Create foundational agent
    Team->>DWS Repo: Add agent ID to Dockerfile
    DWS Repo->>CI: Trigger build
    CI->>AI Catalog: Pull agent definitions
    AI Catalog->>CI: Returns all required versions
    CI->>CI: Store definitions in DWS image
    CI->>CI: Ships images with definitions
    Team->>Monolith: Add agent to FoundationalChatAgentsDefinitions.rb
```

### Usage flow

```mermaid
%%{init: {"sequence": {"actorMargin": 50}}}%%
sequenceDiagram
    accTitle: Foundational agent usage flow
    accDescr: Sequence diagram showing how users interact with foundational agents through GitLab monolith and Duo Workflow Service
    participant User
    participant Monolith
    participant DWS as GitLab Duo Workflow Service

    User->>Monolith: Request to foundational agent
    Monolith->>DWS: Request specific agent version
    DWS->>DWS: Resolve agent version
    DWS->>DWS: Process request
    DWS->>Monolith: Return response
    Monolith->>User: Return response
```

The execution flows are the same whether the user is using a local monolith, GitLab SaaS,
the cloud-connected DWS or a
local installation of DWS.
