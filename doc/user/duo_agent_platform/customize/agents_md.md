---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: AGENTS.md customization files
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Support for `AGENTS.md` in GitLab Duo Chat [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/2597) in GitLab 18.7.
- Support for `AGENTS.md` in agentic flows [introduced](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/issues/1509) in GitLab 18.8.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) in GitLab 18.8.

{{< /history >}}

GitLab Duo supports the [`AGENTS.md` specification](https://agents.md/), an emerging standard for
providing context and instructions to AI coding assistants.

Use `AGENTS.md` files to document your repository structure, coding conventions, style guidelines,
build and testing instructions, and project context. When you specify an `AGENTS.md` file, these
details are available for GitLab Duo Agent Platform and any other AI tool that supports the specification.

Specify `AGENTS.md` files for GitLab Duo to use with:

- GitLab Duo Chat in your IDE.
- Foundational and custom flows.

## How GitLab Duo uses `AGENTS.md` files

You can create `AGENTS.md` files at multiple levels:

- User-level: Apply to all of your projects and workspaces.
- Workspace-level: Apply only to a specific project or workspace.
- Subdirectory-level: Apply only to a specific project within a monorepo
  or within a project with distinct components.

GitLab Duo Chat combines available instructions from user-level and workspace-level `AGENTS.md`
files for all conversations. If a task requires working with files in a directory that contains an
additional `AGENTS.md` file, Chat applies those instructions as well.

## Use `AGENTS.md` with GitLab Duo

> [!note]
> Only new conversations and flows created after you add or update `AGENTS.md` files follow the new
instructions. Previously existing conversations do not.

### Prerequisites

- Meet the [Agent Platform prerequisites](../_index.md#prerequisites).
- For GitLab Duo Chat in your IDE, install the supported extensions:

  - For VS Code, [install and configure the GitLab Workflow extension for VS Code](../../../editor_extensions/visual_studio_code/setup.md) 6.60 or later.
  - For a JetBrains IDE, [install and configure the GitLab plugin for JetBrains](../../../editor_extensions/jetbrains_ide/setup.md) 3.26.0 or later.

- For custom flows, update the flow's configuration file to access the `user_rule` context passed
  from the executor:

  ```yaml
  components:
  - name: "my_agent"
     type: AgentComponent
     prompt_id: "my_prompt"
     inputs:
     - from: "context:inputs.user_rule"
        as: "agents_dot_md"
      optional: true
  ```

  By setting `optional: true`, the flow gracefully handles cases where no `AGENTS.md` file exists.
  The agent works with or without additional context.

### Create user-level `AGENTS.md` files

User-level `AGENTS.md` files apply to all of your projects and workspaces.

1. Create an `AGENTS.md` file in your home directory:
   - On Linux or macOS, create the file at `~/.gitlab/duo/AGENTS.md`.
   - On Windows, create the file at `%APPDATA%\GitLab\duo\AGENTS.md`.

1. Add instructions to the file. For example:

   {{< tabs >}}

   {{< tab title="Personal preferences" >}}

   ```markdown
   # My personal coding preferences

   - Always explain code changes in simple terms for beginners
   - Use descriptive variable names
   - Add comments for complex logic
   - Prefer functional programming patterns when appropriate
   ```

   {{< /tab >}}

   {{< tab title="Team standards" >}}

   ```markdown
   # Team coding standards

   - Follow our company's style guide for all code
   - Use TypeScript strict mode
   - Write unit tests for all new functions
   - Document all public APIs with JSDoc
   ```

   {{< /tab >}}

   {{< tab title="Monorepo context" >}}

   ```markdown
   # Monorepo context

   - This is a monorepo with multiple services
   - Frontend code is in /apps/web
   - Backend services are in /services
   - Shared libraries are in /packages
   - Follow the architecture decision records in /docs/adr
   ```

   {{< /tab >}}

   {{< tab title="Security guidelines" >}}

   ```markdown
   # Security review guidelines

   - Always validate user input
   - Use parameterized queries for database operations
   - Implement proper authentication and authorization
   - Follow OWASP security best practices
   - Never log sensitive information
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. Save the file.
1. To apply the instructions, start a new conversation or flow. You must do this every time you
   change the `AGENTS.md` file.

If you have set a specific environment variable, then you create the
`AGENTS.md` file in a different location:

- If you have set the `GLAB_CONFIG_DIR` environment variable, create the file at
  `$GLAB_CONFIG_DIR/AGENTS.md`.
- If you have set the `XDG_CONFIG_HOME` environment variable, create the file at
  `$XDG_CONFIG_HOME/gitlab/duo/AGENTS.md`.

### Create workspace-level `AGENTS.md` files

Workspace-level `AGENTS.md` files apply only to a specific project or workspace.

1. In the root of your project workspace, create an `AGENTS.md` file.
1. Add instructions to the file. For example:

   ```markdown
   # Project-specific guidelines

   - This project uses React with TypeScript
   - Follow the component structure in /src/components
   - Use our custom hooks from /src/hooks
   - State management uses Redux Toolkit
   ```

1. Save the file.
1. To apply the instructions, start a new conversation or flow. You must do this every time you
   change the `AGENTS.md` file.

### Create `AGENTS.md` files in monorepos and subdirectories

For monorepos or projects with distinct components, you can place `AGENTS.md` files in
subdirectories to provide context-specific instructions for different parts of your codebase.

When GitLab Duo Chat discovers additional `AGENTS.md` files in subdirectories, it reads the relevant
file before editing files in that directory. For example:

```plaintext
/my-project
  AGENTS.md              # Root instructions (included in all conversations)
  /frontend
    AGENTS.md            # Frontend-specific instructions
  /backend
    AGENTS.md            # Backend-specific instructions
```

In this example:

- The root `AGENTS.md` is always included in conversations.
- When GitLab Duo edits files in `/frontend`, it reads `/frontend/AGENTS.md` first.
- When GitLab Duo edits files in `/backend`, it reads `/backend/AGENTS.md` first.

This approach helps ensure GitLab Duo follows the appropriate conventions for each part of your
project.

To use `AGENTS.md` in a subdirectory:

1. In a subdirectory of your project, create an `AGENTS.md` file.
1. Add instructions specific to that directory. For example, for a backend service:

   ```markdown
   # Backend service guidelines

   - This service uses Node.js with Express
   - Follow RESTful API conventions
   - Use async/await for asynchronous operations
   - Validate all inputs with Joi schemas
   ```

1. Save the file.
1. To apply the instructions, start a new conversation that involves files in that directory. You
   must do this every time you change the `AGENTS.md` file.

## Related topics

- [Custom rules](custom_rules.md)
