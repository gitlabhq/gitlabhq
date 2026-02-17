---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Security considerations for using GitLab editor extensions with local agent execution.
title: Security considerations for editor extensions
---

When you use GitLab editor extensions that run agents locally (such as the Software Development Flow), understand the security implications and follow best practices to protect your development environment.

## Local agent execution risks

GitLab editor extensions can execute agents locally on your developer workstation. These agents run without container isolation, which gives them direct access to your system resources.

### File system access

Agents have different file access levels depending on the operation type.

#### File operations

Agents can perform file operations (read, write, edit, search, and list) on:

- Files located in the Git repository of your GitLab project.
- Files not excluded by `.gitignore` rules.
- Valid or resolvable symlinks that point to files inside the Git repository.

#### Shell operations on files

Shell commands executed by agents can access all files, including those outside of Git repositories and those that match `.gitignore` patterns.

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
- Data exfiltration: Any data on your workstation, including sensitive data such as passwords, source code, and personal files, can be stolen.
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

### Verify MCP server sources and permissions

To use Model Context Protocol (MCP) servers securely with GitLab Duo:

- Enable MCP servers from trusted sources only.
- Review the permissions and capabilities that each MCP server requests.
- Review what data MCP servers can access before you enable them.
- Regularly audit which MCP servers are enabled in your environment.

### Use development containers for isolation

Use development containers to mitigate local execution risks.

Development containers provide:

- Process isolation: Run agents in an isolated container environment, not directly on your host machine.
- Limited file system access: Configure containers to restrict access to only necessary files.
- Credential isolation: Manage credentials separately and inject them into the container as needed.
- Network isolation: Restrict container networking to limit external access.

The GitLab Workflow extension for VS Code is compatible with VS Code Dev Containers. For more
information, see [use the extension in a Visual Studio Code Dev Container](visual_studio_code/setup.md#use-the-extension-in-a-visual-studio-code-dev-container).
