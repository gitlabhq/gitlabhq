---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Security considerations for using GitLab editor extensions and CLI tools with local agent execution.
title: Security considerations for editor extensions and CLI tools
---

GitLab editor extensions and CLI tools can run AI agents in your local environment.
Understand the security implications and follow best practices to protect your development environment.

## Local agent execution risks

When editor extensions and CLI tools execute agents locally, the agents run without container
isolation and have direct access to your system resources.

### File system access

Agents have different file access levels depending on the operation type.

#### File operations

Agents can perform file operations (read, write, edit, search, and list) on:

- Files located in the Git repository of your GitLab project.
- Files not excluded by `.gitignore` rules.
- Valid or resolvable symlinks that point to files inside the Git repository.

#### Shell operations on files

Shell commands executed by agents can access all files, including those outside of Git repositories
and those that match `.gitignore` patterns.

### Environment variable access

Agents have access to all environment variables in your shell session except for the following:

- `CI_JOB_TOKEN`
- `GITLAB_OAUTH_TOKEN`
- `DUO_WORKFLOW_SERVICE_TOKEN`

### System resources

Agents have access to the following system resources:

- Network requests: Agents can make network requests from your workstation.
- Process execution: Agents can execute commands in your shell environment.

### Security threats

Because isolation is not in place, the following threats are possible:

- Prompt injection: Malicious prompts manipulate agent behavior and execute unintended actions.
- Agent compromise: Compromised agents provide access to your workstation resources.
- Data exfiltration: Any data on your workstation, including sensitive data such as passwords,
  source code, and personal files, can be stolen.
- Lateral movement: Exposed credentials enable access to other systems and services.

## Recommended security practices

To protect your development environment, follow these security best practices.

### Review tool calls before approval

When agents request your approval to execute actions, carefully review each tool call before approving.

Verify that:

- Commands and file operations match your intended task.
- File paths are within expected directories, including symlink target files.
- Command arguments do not include unexpected flags or parameters.
- Sensitive file access and network requests are necessary for the task.

Your administrator can control whether you can approve tools once for a session, instead of approving each invocation. For more information, see
[tool approvals](../user/gitlab_duo_chat/agentic_chat.md#tool-approvals).

If you use the GitLab Duo CLI in headless mode, tool calls are approved automatically. Use headless
mode with caution and in a controlled sandbox environment, such as a development container.

### Verify MCP server sources and permissions

To use Model Context Protocol (MCP) servers securely with GitLab Duo:

- Enable MCP servers from trusted sources only.
- Review the permissions and capabilities that each MCP server requests.
- Review what data MCP servers can access before you enable them.
- Regularly audit which MCP servers are enabled in your environment.

### Use development containers for isolation

Use development containers to mitigate local execution risks.

For GitLab Duo CLI users, headless mode bypasses manual tool approvals, so development containers
are especially important.

Development containers provide:

- Process isolation: Run agents in an isolated container environment, not directly on your host machine.
- Limited file system access: Configure containers to restrict access to only necessary files.
- Credential isolation: Manage credentials separately and inject them into the container as needed.
- Network isolation: Restrict container networking to limit external access.

The GitLab for VS Code extension is compatible with VS Code Dev Containers. For more
information, see [use the extension in a Visual Studio Code Dev Container](visual_studio_code/setup.md#install-in-a-visual-studio-code-dev-container).
