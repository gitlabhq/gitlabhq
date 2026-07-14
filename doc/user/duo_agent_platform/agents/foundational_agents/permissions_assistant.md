---
stage: Agent Foundations
group: AI Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Permissions Assistant
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/592230) as a [beta](../../../../policy/development_stages_support.md#beta) feature in GitLab 18.11.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/596613) in GitLab 19.2.

{{< /history >}}

The Permissions Assistant is a GitLab Duo agent that helps you choose the right
[fine-grained permissions](../../../../auth/tokens/fine_grained_access_tokens.md) when creating a
personal access token.

Describe what you need the token to do, and the Permissions Assistant selects the appropriate
permissions on the creation form. You can ask follow-up questions or refine your request
until the selection matches your needs.

## Prerequisites

- Meet the [prerequisites for the GitLab Duo Agent Platform](../../_index.md#prerequisites).
- Have [foundational agents turned on](_index.md#turn-foundational-agents-on-or-off).
- Have fine-grained personal access tokens enabled. This feature is controlled by the
  `granular_personal_access_tokens` feature flag, which is enabled by default.

## Use the Permissions Assistant

The Permissions Assistant is available on the fine-grained personal access token creation page
in the GitLab UI.

To use the Permissions Assistant:

1. In the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. In the left sidebar, select **Access** > **Personal access tokens**.
1. From the **Generate token** dropdown list, select **Fine-grained token**.
1. Select **Add permissions with Duo**.

   A Duo Chat panel opens with the Permissions Assistant pre-selected.
1. Describe what you need the token to do, or select one of the suggested prompts.

   The Permissions Assistant selects the appropriate permissions on the form.
1. Review the selected permissions and refine your request if needed.
1. Complete the remaining token fields and select **Generate token**.

### Tips for best results

- Describe your use case specifically. For example, "I need to read issues and create merge
  requests in a single project" gives better results than "I need API access."
- If the initial selection is too broad or too narrow, ask for adjustments.
- Use the suggested prompts as a starting point if you are unsure how to describe your needs.
- Suggestions are applied to the relevant access level (Group and project, User, or Global),
  so the same permission can be added in more than one section when your request spans them.

## Example prompts

- "I want to read and write to repositories via the API."
- "I need to manage CI/CD pipelines and read job logs."
- "I want to automate issue and merge request management."
- "I need read-only access to projects and groups."
- "I want to read all snippets, not just my own."
