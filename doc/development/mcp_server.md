---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: MCP server development guidelines
---

This page includes information about developing and working with the GitLab MCP server.

## Set up your development environment

To set up your development environment:

1. [Enable and configure HTTPS in the GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/nginx.md#update-gdkyml-for-https-optional).
1. Install `node` and install `mcp-remote` globally. GDK comes with Node.js but installed AI assistants cannot use the GDK version.
1. [Connect an AI assistant to the MCP server](../user/gitlab_duo/model_context_protocol/mcp_server.md#connect-cursor-to-a-gitlab-mcp-server).

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

{{< alert type="warning" >}}

More tools aren't always better. The research shows that both context size and tool count have diminishing returns and
eventually lead to performance degradation. Consider tool consolidation, specialized sub-agents, or dynamic tool routing
instead of continuously expanding your toolset.

{{< /alert >}}
