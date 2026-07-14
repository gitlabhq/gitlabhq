---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Project onboarding for GitLab Duo Agent Platform
---

{{< details >}}

- Tier: [Free](../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Initialize project context [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/229847) as a [beta](../../policy/development_stages_support.md) in GitLab 19.0
  [with a feature flag](../../administration/feature_flags/_index.md) named `duo_agent_onboarding`. Disabled by default.
- Improve CI setup [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234426) as a [beta](../../policy/development_stages_support.md) in GitLab 19.1
  [with a feature flag](../../administration/feature_flags/_index.md) named `duo_agent_onboarding`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

The **Onboarding** page helps you set up your project for use with GitLab Duo Agent Platform.
From this page you can initialize project context and improve your CI/CD setup using AI agents.

## Prerequisites

- The Developer, Maintainer, or Owner role for the project.
- The [prerequisites for the GitLab Duo Agent Platform](_index.md#prerequisites).
- For the **Improve CI setup** task, a `.gitlab-ci.yml` file in your project.

## Initialize project context

The **Initialize project context** task analyzes your repository to create an `AGENTS.md` file for your project.

This file follows the [`AGENTS.md` specification](https://agents.md/) and documents your project conventions, such as test commands, linting rules, commit format, and coding patterns. Agent Platform features use it for context when working in your repository.

To initialize project context:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Automate** > **Onboarding**.
1. Select **Initialize project context**. If `AGENTS.md` or `.ai/AGENTS.md` already exists on your default branch, this option is not available.

GitLab starts a `developer/v1` agent session that analyzes your repository and opens
a draft merge request to add an `AGENTS.md` file.
A link to the agent session appears so you can track progress.

## Improve CI/CD setup

The **Improve CI setup** task launches an agent that analyzes your existing CI/CD configuration
and suggests improvements.

To improve your CI/CD setup:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Automate** > **Onboarding**.
1. Select **Improve CI setup**. If `.gitlab-ci.yml` doesn't exist on your default branch, this option is not available.

GitLab starts an agent session that analyzes your `.gitlab-ci.yml` and opens a draft merge
request with suggested improvements.
A link to the agent session appears so you can track progress.

## Related topics

- [AGENTS.md customization files](customize/agents_md.md)
- [Developer Flow](flows/foundational_flows/developer.md)
- [Fix CI/CD Pipeline Flow](flows/foundational_flows/fix_pipeline.md)
