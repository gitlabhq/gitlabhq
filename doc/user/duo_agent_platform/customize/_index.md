---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Customize GitLab Duo Agent Platform
---

You can customize the Agent Platform to match your workflow, coding standards, or project requirements.

## Customization options

| Method    | AI feature | Use cases    |
|-----------|------------|--------------|
| [Use custom rules](custom_rules.md) to provide instructions. | - GitLab Duo Chat<br>- Agents<br>- Flows | - Apply personal preferences.<br>- Enforce team standards. |
| [Create an AGENTS.md file](agents_md.md) to provide instructions. | - GitLab Duo Chat<br>- Flows<br>- Other non-GitLab AI coding tools | - Account for project-specific context.<br>- Organize a monorepo.<br>- Enforce directory-specific conventions. |
| [Create MR review instructions](review_instructions.md) to ensure consistent and specific code review standards in your project. | - Code Review Flow | Apply:<br>- Language-specific review rules.<br>- Security standards.<br>- Code quality requirements.<br>- File-specific guidelines. |

## Best practices

When you customize the Agent Platform, apply the following best practices:

- Start with minimal, clear, and simple instructions, and add more as needed.
  Keep the instruction file as short as possible.
- Make sure the instructions are specific and actionable. Provide examples as
  needed.
- Choose the method that matches your use case.
- Combine multiple methods to tailor and control how GitLab Duo behaves.
- If you use multiple methods, consider the following file structure for your project:

  ```plaintext
  Project root directory
  |─ AGENTS.md                         # Applies to multiple Duo features
  |─ .gitlab/duo/
     |─ chat-rules.md                  # Custom Chat-specific rules
     |─ mr-review-instructions.yaml    # Custom code review standards
     |─ ...                            # Other configuration as needed
  ```

  You can include other configuration files in the `.gitlab/duo/` folder, such as
  [custom flow definitions](../../duo_agent_platform/flows/custom.md), or an
  [MCP server configuration](../../gitlab_duo/model_context_protocol/mcp_server.md) file.
- Document your choices in comments to explain why certain instructions exist.
- Protect customization files with [Code Owners](../../project/codeowners/_index.md) to manage changes.
