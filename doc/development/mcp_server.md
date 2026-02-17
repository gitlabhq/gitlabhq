---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: MCP server development guidelines
---

This page includes information about developing and working with the GitLab MCP server.

## Set up your development environment

To set up your development environment:

1. [Enable and configure HTTPS in the GDK](https://gitlab-org.gitlab.io/gitlab-development-kit/howto/nginx/#update-gdkyml-for-https-optional).
1. Install `node` and install `mcp-remote` globally. GDK comes with Node.js but installed AI assistants cannot use the GDK version.
1. [Connect an AI assistant to the MCP server](../user/gitlab_duo/model_context_protocol/mcp_server.md#connect-cursor-to-the-gitlab-mcp-server).

## Debugging and troubleshooting

### Debug Cursor

Add `--debug` to the `mcp-remote` command for more detailed logging. View MCP server logs by opening the Output and selecting
`MCP:SERVERNAME`. For the example below, it would be `MCP:user-GitLab-GDK`

```json
{
  "mcpServers": {
    "GitLab-GDK": {
      "command": "npx",
      "args": [
        "mcp-remote",
        "https://gdk.test:3443/api/v4/mcp",
        "--debug"
      ],
      "env": {
        "NODE_TLS_REJECT_UNAUTHORIZED": "0"
      }
    }
  }
}
```

### Debug Claude Desktop

#### Check Node.js version

Claude Desktop uses an unsupported version of Node.js. Create a custom wrapper script that uses a specific version:

```shell
#!/bin/bash

# Force use of your Node.js version
NODE_BIN="/PATH_TO_NODE_INSTALL/node/22.17.0/bin/node"
MCP_REMOTE_BIN="/PATH_TO_NODE_INSTALL/node/22.17.0/bin/mcp-remote"

# Run mcp-remote with your Node.js
exec "$NODE_BIN" "$MCP_REMOTE_BIN" "$@"
```

Use the wrapper script in the Claude Desktop configuration.

```json
{
  "mcpServers": {
    "GitLab-GDK": {
      "command": "/PATH_TO_REMOTE_WRAPPER_SCRIPT/mcp-remote-wrapper",
      "args": [
        "https://gdk.test:3443/api/v4/mcp",
        "--debug"
      ],
      "env": {
        "NODE_TLS_REJECT_UNAUTHORIZED": "0"
      }
    }
  }
}
```

### Debug `mcp-remote`

Test the authentication from `mcp-remote` to GDK outside an AI assistant:

```shell
 NODE_TLS_REJECT_UNAUTHORIZED=0 npx mcp-remote https://gdk.test:3443/api/v4/mcp --debug
```

If you switch branches, you may experience authentication issues which can include `UNABLE_TO_VERIFY_LEAF_SIGNATURE`
errors in the logs. The untrusted certificate error in chain is specific to GDK instances that use TLS. The error is
caused by the https client used in Node.js and the `mcp-remote` library via npx. The https client doesn't trust
certificates signed outside a bundled certificate authorities list.

If encountering authentication issues clearing your `~/.mcp-auth` directory, as a last resort, resets stored
credentials for `mcp-remote`. When the AI Assistant reconnects to the MCP server, a browser window opens to prompt
for authorization.

```shell
rm -rf ~/.mcp-auth
```

### Debug with MCP Inspector

[MCP Inspector](https://modelcontextprotocol.io/legacy/tools/inspector) is an interactive developer tool for testing and debugging MCP servers.

The following command opens an intuitive Web UI for connecting to a server and listing and executing MCP tools:

```shell
npx -y @modelcontextprotocol/inspector npx
```

## Development workflow

### Helpful links

- [Model Context Protocol (MCP) tools specifications](https://modelcontextprotocol.io/specification/2025-06-18/server/tools)
- [mcp-remote documentation](https://www.npmjs.com/package/mcp-remote)

### Adding a new tool

#### The Tool Proposal process

Our current development guidelines remain in early development. As we continue establishing tool development standards - especially for custom and
aggregated tools - we've created an interim `mcp-tool-review-board` committee to evaluate proposed tools before implementation and guide teams planning new MCP tools.

To add a new tool, please create a [MCP Tool Proposal issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new?related_item_id=undefined&type=ISSUE&description_template=MCP%20Tool%20Proposal)
and follow the template instructions.

> [!note]
> Tool implementation location depends on GitLab resource interaction:
>
> - Tools that interact with GitLab resources should eventually live in MCP Server, but can be implemented in the Agent Platform for short-term or urgent needs.
> - Tools that don't interact with GitLab resources should be implemented in the Agent Platform.
>
> We are working to integrate MCP server functionality into the Agent Platform. You can track progress via [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/561296).
>
> We strongly encourage all engineers to follow the tool proposal process and provide clear explanations of their use cases.

#### Implement a tool from an API route

This [merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201838) defines a process for creating an MCP tool from an API route.

Adding the following `route_setting` to an API route definition:

```ruby
route_setting :mcp, tool_name: :get_merge_request, params: [:id, :merge_request_iid]
```

- Adds a `get_merge_request` tool to the list of tools and enables its execution
- The tool and parameters description is taken from the OpenAPI route definition
- The accepted parameters are filtered by the `params` argument. For example, only `id` and `merge_request_iid` are advertised and accepted
- When the tool is called, the route code is executed directly with the passed parameters

This [merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055) provides more examples.

#### Implement an aggregated API tool

Aggregated API tools combine multiple related API tools into a single unified interface, reducing
tool count and improving the user experience.
The [search tool](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208526) demonstrates
this pattern by consolidating global, group, and project search into one tool.

**When to use aggregated tools:**

Use aggregated tools when you have multiple API endpoints that serve similar purposes but operate at
different scopes (global, group, project). This reduces cognitive load on the LLM by presenting one
tool instead of three.

**Implementation steps:**

1. Create an aggregated service class that inherits from `Mcp::Tools::AggregatedService`:

```ruby
module Mcp
  module Tools
    class ExampleAggregatedService < AggregatedService
      include Gitlab::Utils::StrongMemoize
      extend ::Gitlab::Utils::Override

      register_version '0.1.0', {
        description: 'My example aggregated tool',
        input_schema: {
          type: 'object',
          properties: {},
          required: []
        }
      }

      override :tool_name
      def self.tool_name
        'new_tool'
      end

      override :select_tool
      def select_tool(args)
        tool_name = if args[:group_id]
                      :example_tool_for_group
                    elsif args[:project_id]
                      :example_tool_for_project
                    end

        tools.find { |tool| tool.name.to_sym == tool_name }
      end

      override :transform_arguments
      def transform_arguments(args)
        if args[:group_id]
          args.merge(id: args[:group_id])
        elsif args[:project_id]
          args.merge(id: args[:project_id])
        else
          args
        end
      end
    end
  end
end
```

1. Register the underlying API tools with the aggregator in their route definitions:

```ruby
route_setting :mcp, tool_name: :example_tool_for_group, params: [:id], aggregators: [::Mcp::Tools::ExampleAggregatedService]

route_setting :mcp, tool_name: :example_tool_for_project, params: [:id], aggregators: [::Mcp::Tools::ExampleAggregatedService]
```

1. The `Mcp::Tools::Manager` automatically discovers aggregated tools by scanning routes with
   `aggregators` specified and instantiates the aggregator class with the collected tools.

#### Implement a custom tool

For tools with distinct functionality that should remain separate from API exposure, you can define a standalone class (see [this example](https://gitlab.com/gitlab-org/gitlab/-/blob/5d394a38c3dc20a247473d5334d71dab15d26a4b/app/services/mcp/tools/manager.rb#L7) for reference).

#### Risks of tool proliferation in AI agent architecture

##### Key problems with adding too many tools

1. Performance degradation

- **Context Bloat:** Every tool definition (name, description, JSON schema) is added to the model's prompt context, increasing input token count
- **Increased Latency:** Larger prompts lead to slower response times
- **Higher Costs:** More tokens = higher API costs per request
- **Reduced Accuracy:** Research shows both more context and more tools degrade agent performance
- **Trajectory Degradation:** Agents requiring longer reasoning paths degrade more quickly with tool proliferation

1. Tool selection confusion

- **Decision Complexity:** More tools make it harder for the model to select the correct one
- **Parameter Design Issues:** Using internal IDs (like GitLab global IDs) instead of public-facing formats (project paths, IIDs) that LLMs are trained on reduces tool usage effectiveness
- **Ambiguity Between Similar Tools:** The model struggles to differentiate between tools with similar purposes (for example, local vs. remote file operations)

1. User experience impact

- **Tool Chaining Noise:** More tools lead to more tool calls in a single request, creating noise and distraction
- **Slower Responses:** Increased processing time affects user satisfaction
- **Incorrect Tool Selection:** Wrong tool choices lead to incorrect or irrelevant responses

##### Questions Developers Should Answer Before Adding Tools

1. **Necessity:** Is this truly a new capability, or could it be handled by an existing tool with parameter adjustments?
1. **Consolidation potential:** Can this functionality be merged with an existing tool using an enum or parameter?
1. **Parameter design:** Are you using publicly recognizable identifiers that align with the model's training data?
1. **Evaluation strategy:** How do you measure whether this tool improves or degrades overall agent performance?
1. **Context management:** How does this tool's definition impact the available context window for actual reasoning?
1. **Tool routing:** Should this tool be part of a specialized sub-agent rather than the main agent's toolset?
1. **Permission model:** How does this tool interact with your permission/pricing model? Does it create complexity?
1. **Semantic distinctness:** Is this tool clearly distinguishable from others in your toolset?

> [!warning]
> More tools aren't always better. The research shows that both context size and tool count have diminishing returns and
> eventually lead to performance degradation. Consider tool consolidation, specialized sub-agents, or dynamic tool routing
> instead of continuously expanding your toolset.

### Modifying an existing tool

MCP tools use semantic versioning to avoid breaking changes for consumers. When modifying a tool,
use the versioning system introduced
in [this merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205914).

**Why versioning matters:**

LLMs and AI agents cache tool schemas and build workflows around specific tool behaviors. Changes to
tool parameters, descriptions, or output formats can break existing integrations. Versioning allows
safe evolution while maintaining backward compatibility.

**Version registration pattern:**

For aggregated API, custom, and graphQL tools, register versions using `register_version`:

```ruby
module Mcp
  module Tools
    class GetServerVersionService < CustomService
      register_version '0.1.0', {
        description: 'Get the current version of MCP server.',
        input_schema: {
          type: 'object',
          properties: {},
          required: []
        }
      }

      def perform_0_1_0(_arguments = {})
        data = { version: Gitlab::VERSION, revision: Gitlab.revision }
        formatted_content = [{ type: 'text', text: data[:version] }]
        ::Mcp::Tools::Response.success(formatted_content, data)
      end

      override :perform_default
      def perform_default(arguments = {})
        perform_0_1_0(arguments)
      end
    end
  end
end
```

**Adding a new version:**

When you need to modify a tool's behavior:

1. Register the new version with updated metadata:

```ruby
register_version '0.2.0', {
  description: 'Get version with additional metadata.',
  input_schema: {
    type: 'object',
    properties: {
      include_metadata: {
        type: 'boolean',
        description: 'Include additional metadata'
      }
    },
    required: []
  }
}
```

1. Implement the version-specific method:

```ruby
def perform_0_2_0(arguments = {})
  data = {
    version: Gitlab::VERSION,
    revision: Gitlab.revision
  }

  if arguments[:include_metadata]
    data[:metadata] = { build_date: Time.current }
  end

  formatted_content = [{ type: 'text', text: data[:version] }]
  ::Mcp::Tools::Response.success(formatted_content, data)
end
```

1. Update `perform_default` to use the latest version:

```ruby
override :perform_default
def perform_default(arguments = {})
  perform_0_2_0(arguments)
end
```

**For API tools:**

API tools automatically default to version `0.1.0`. The version can be specified in the route
setting if needed:

```ruby
route_setting :mcp, tool_name: :get_merge_request,
  params: [:id, :merge_request_iid],
  version: '1.0.0'
```

Note: API tools from routes use a single version per tool. For tools requiring multiple
versions, consider implementing as a custom tool instead.

**Version support policy:**

The framework automatically uses the latest version when no version is specified. Consumers can
request specific versions during tool calls.
Follow [multi-version compatibility guidelines](multi_version_compatibility.md)
when deprecating versions.

### Renaming a tool

Renaming a tool requires using tool aliases to maintain backward compatibility. Connected clients
cache tool names and do not automatically refresh when tools are renamed. The alias system introduced
in [this merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214734) allows
graceful renames without breaking existing integrations.

**Why aliases are necessary:**

MCP clients cache the tool list from `tools/list` and don't automatically re-fetch when tools
change. Renaming a tool causes clients to call a non-existent tool name, resulting in errors
or indefinite hangs. The MCP specification supports `notifications/tools/list_changed` to notify
clients of changes, but GitLab MCP server doesn't implement this (tracked
in [this issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/582750)).

**Implementation steps:**

1. Override `tool_aliases` in your tool class to include the old name:

```ruby
module Mcp
  module Tools
    class RenamedService < AggregatedService
      override :tool_name
      def self.tool_name
        'new_name'
      end

      override :tool_aliases
      def self.tool_aliases
        ['old_name']
      end
    end
  end
end
```

1. Update all references to use the new tool name:
   - Route settings with `tool_name:`
   - Test files
   - Documentation
   - Any hardcoded tool name references

1. The `Mcp::Tools::Manager` automatically resolves aliases during `get_tool` calls, so clients
   using the old name continue to work.

**Important notes:**

- `list_tools` only returns the canonical tool name, not aliases
- Aliases work for all tool types: custom, GraphQL, API, and aggregated tools
- The alias resolution happens in `Manager#resolve_alias` which checks all tool registries
- Plan to remove aliases in a future release after sufficient time for clients to update

**Deprecation timeline:**

Release M: Add alias and rename tool
Release M+1: Remove alias (after clients have had time to refresh their tool lists)

This approach ensures zero downtime for connected clients during tool renames.
