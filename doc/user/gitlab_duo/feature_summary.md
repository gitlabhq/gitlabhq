---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: AI-native features and functionality.
title: Summary of GitLab Duo features
---

{{< history >}}

- [First GitLab Duo features introduced](https://about.gitlab.com/blog/2023/05/03/gitlab-ai-assisted-features/) in GitLab 16.0.
- [Removed third-party AI setting](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136144) in GitLab 16.6.
- [Removed support for OpenAI from all GitLab Duo features](https://gitlab.com/groups/gitlab-org/-/epics/10964) in GitLab 16.6.

{{< /history >}}

The following features are generally available on GitLab.com, GitLab Self-Managed, and GitLab Dedicated.
They require a Premium or Ultimate subscription and one of the available add-ons.

The GitLab Duo with Amazon Q features are available as a separate add-on, and
are available on GitLab Self-Managed only.

| Feature | GitLab Duo Core | GitLab Duo Pro | GitLab Duo Enterprise | GitLab Duo with Amazon Q |
|---------|----------|---------|----------------|--------------------------|
| [Code Suggestions](../project/repository/code_suggestions/_index.md) | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [GitLab Duo Chat](../gitlab_duo_chat/_index.md) in IDEs | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [Code Explanation](../gitlab_duo_chat/examples.md#explain-selected-code) in IDEs | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [Refactor Code](../gitlab_duo_chat/examples.md#refactor-code-in-the-ide) in IDEs | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [Fix Code](../gitlab_duo_chat/examples.md#fix-code-in-the-ide) in IDEs | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [Test Generation](../gitlab_duo_chat/examples.md#write-tests-in-the-ide) in IDEs | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [GitLab Duo Chat](../gitlab_duo_chat/_index.md) in GitLab UI | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [Code Explanation](../project/repository/code_explain.md) in GitLab UI | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [Code Review](../project/merge_requests/duo_in_merge_requests.md#have-gitlab-duo-review-your-code) | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [Discussion Summary](../discussions/_index.md#summarize-issue-discussions-with-duo-chat) | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [Root Cause Analysis](../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [Vulnerability Explanation](../application_security/vulnerabilities/_index.md#vulnerability-explanation) | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [Vulnerability Resolution](../application_security/vulnerabilities/_index.md#vulnerability-resolution) | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [GitLab Duo for the CLI](../../editor_extensions/gitlab_cli/_index.md#gitlab-duo-for-the-cli) | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="dash-circle" >}} No |
| [Merge Commit Message Generation](../project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message) | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="dash-circle" >}} No |
| [AI Impact Dashboard](../analytics/ai_impact_analytics.md) | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="dash-circle" >}} No |

## Features available in GitLab Duo Self-Hosted

Your organization can use [GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md)
to self-host the AI gateway and language models if you:

- Have the GitLab Duo Enterprise add-on.
- Are a GitLab Self-Managed customer.

To check which GitLab Duo features are available for use with GitLab Duo Self-Hosted,
and the status of those features, see the
[supported GitLab Duo features for GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md#supported-gitlab-duo-features).

## Beta and experimental features

{{< history >}}

- GitLab Duo Agentic Chat added in GitLab 18.2.

{{< /history >}}

The following features are not generally available.

They require a Premium or Ultimate subscription and one of the available add-ons.

| Feature | GitLab Duo Core | GitLab Duo Pro | GitLab Duo Enterprise | GitLab Duo with Amazon Q | GitLab.com | GitLab Self-Managed | GitLab Dedicated | GitLab Duo Self-Hosted |
|---------|----------|---------|----------------|--------------------------|-----------|-------------|-----------|------------------------|
| [Code Review Summary](../project/merge_requests/duo_in_merge_requests.md#summarize-a-code-review) | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="dash-circle" >}} No | Experiment | Experiment | {{< icon name="dash-circle" >}} No | Experiment |
| [Issue Description Generation](../project/issues/managing_issues.md#populate-an-issue-with-issue-description-generation) | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="dash-circle" >}} No | Experiment | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | Not applicable |
| [Merge Request Summary](../project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes) | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="dash-circle" >}} No | Beta | Beta | {{< icon name="dash-circle" >}} No | Beta |
| [GitLab Duo Agentic Chat](../gitlab_duo_chat/agentic_chat.md) | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="dash-circle" >}} No | Experiment | Experiment | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No |

[GitLab Duo Agent Platform](../duo_agent_platform/_index.md) is in private beta, does not require an add-on, and is not supported for GitLab Duo Self-Hosted.
