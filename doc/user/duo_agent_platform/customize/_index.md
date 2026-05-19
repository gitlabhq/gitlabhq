---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Customize GitLab Duo Agent Platform behavior to match your workflow, coding standards, and project requirements.
title: Customize GitLab Duo Agent Platform
---

You can customize the Agent Platform to match your workflow, coding standards, or project requirements.

## Customization options

| Method | AI features <sup>1</sup> | Use cases | Supported in |
|--------|--------------------------|-----------|--------------|
| [Use custom rules](custom_rules.md) to provide instructions. | - GitLab Duo Chat<br>- Agents<br>- Flows, excluding Code Review Flow | - Apply personal preferences.<br>- Enforce team standards. | - GitLab UI<br>- Editor extensions<br>- GitLab Duo CLI |
| [Create an AGENTS.md file](agents_md.md) to provide instructions. | - GitLab Duo Chat<br>- Flows, excluding Code Review Flow | - Account for project-specific context.<br>- Organize a monorepo.<br>- Enforce directory-specific conventions. | - GitLab UI<br>- Editor extensions<br>- GitLab Duo CLI<br>- Non-GitLab AI coding tools |
| [Create MR review instructions](review_instructions.md) to ensure consistent and specific code review standards in your project. | - Code Review Flow | Apply:<br>- Language-specific review rules.<br>- Security standards.<br>- Code quality requirements.<br>- File-specific guidelines. | - GitLab UI |
| [Create Agent Skills](agent_skills.md) to provide skills. | - GitLab Duo Chat<br>- Flows, excluding Code Review Flow | - Provide shareable skills<br>- Add custom slash commands | - GitLab UI<br>- Editor extensions<br>- GitLab Duo CLI<br>- Non-GitLab AI coding tools |

**Footnotes**:

1. Support varies by where you use these features.
   For more information, see the documentation for each customization method.

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
  |- skills/<skill-name>/
     |─ SKILL.md                       # Applies to multiple Duo features
  |─ .gitlab/duo/
     |─ chat-rules.md                  # Custom Chat-specific rules
     |─ mr-review-instructions.yaml    # Custom code review standards
     |─ ...                            # Other configuration as needed
  ```

  You can include other configuration files in the `.gitlab/duo/` folder, such as
  [custom flow definitions](../flows/custom.md), or an
  [MCP server configuration](../../gitlab_duo/model_context_protocol/mcp_server.md) file.
- Document your choices in comments to explain why certain instructions exist.
- Protect customization files with [Code Owners](../../project/codeowners/_index.md) to manage changes.
