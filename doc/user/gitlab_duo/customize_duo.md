---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Customize GitLab Duo
---

You can customize GitLab Duo to match your workflow, coding standards, or project requirements.

## Customization options

| Method    | AI feature | Use cases    |
|-----------|------------|--------------|
| [Use custom rules](../gitlab_duo_chat/agentic_chat.md#create-custom-rules) to provide instructions. | - GitLab Duo Chat | - Apply personal preferences.<br>- Enforce team standards. |
| [Create an AGENTS.md file](../gitlab_duo_chat/agentic_chat.md#create-agentsmd-instruction-files) to provide instructions. | - GitLab Duo Chat<br>- Other non-GitLab AI coding tools | - Account for project-specific context.<br>- Organize a monorepo.<br>- Enforce directory-specific conventions. |
| [Create MR review instructions](../project/merge_requests/duo_in_merge_requests.md#customize-instructions-for-gitlab-duo-code-review) to ensure consistent and specific code review standards in your project. | - GitLab Duo Code Review | Apply:<br>- Language-specific review rules.<br>- Security standards.<br>- Code quality requirements.<br>- File-specific guidelines. |

## Best practices

When you customize GitLab Duo, apply the following best practices:

- Start with minimal, clear, and simple instructions, and add more as needed.
  Keep the instruction file as short as possible.
- Make sure the instructions are specific and actionable. Provide examples as
  needed.
- Choose the method that matches your use case.
- Combine multiple methods to tailor and control how GitLab Duo behaves.
- Document your choices in comments to explain why certain instructions exist.
- Protect customization files with [Code Owners](../project/codeowners/_index.md) to manage changes.
