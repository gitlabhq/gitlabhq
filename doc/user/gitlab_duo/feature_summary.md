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
| [GitLab Duo Chat (Classic)](../gitlab_duo_chat/_index.md) | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [Code Explanation](../gitlab_duo_chat/examples.md#explain-selected-code) in IDEs | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [Refactor Code](../gitlab_duo_chat/examples.md#refactor-code-in-the-ide) in IDEs | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [Fix Code](../gitlab_duo_chat/examples.md#fix-code-in-the-ide) in IDEs | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [Test Generation](../gitlab_duo_chat/examples.md#write-tests-in-the-ide) in IDEs | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [Code Explanation](../project/repository/code_explain.md) in GitLab UI | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [Discussion Summary](../discussions/_index.md#summarize-issue-discussions-with-duo-chat) | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [Code Review](../project/merge_requests/duo_in_merge_requests.md#have-gitlab-duo-review-your-code) | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes <sup>1</sup> |
| [Root Cause Analysis](../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [Vulnerability Explanation](../application_security/vulnerabilities/_index.md#vulnerability-explanation) <sup>3</sup> | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [Vulnerability Resolution](../application_security/vulnerabilities/_index.md#vulnerability-resolution) <sup>3</sup> | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [GitLab Duo and SDLC trends](../analytics/duo_and_sdlc_trends.md) <sup>3</sup> | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled">}} Yes |
| [Merge Commit Message Generation](../project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message) | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [GitLab Duo for the CLI](../../editor_extensions/gitlab_cli/_index.md#gitlab-duo-for-the-cli) | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes <sup>2</sup> |

**Footnotes**:

1. Amazon Q supports a different version of this feature.
   [View how to use Amazon Q to review code](../duo_amazon_q/_index.md#review-a-merge-request).
1. Amazon Q supports a different version of this feature.
   [View details](#amazon-q-developer-pro-included-with-gitlab-duo-with-amazon-q).
1. Requires an Ultimate tier subscription.

## Beta and experimental features

{{< history >}}

- GitLab Duo Agentic Chat added in GitLab 18.2.

{{< /history >}}

The following features are not generally available.

They require a Premium or Ultimate subscription and one of the available add-ons.

| Feature | GitLab Duo Core | GitLab Duo Pro | GitLab Duo Enterprise | GitLab Duo with Amazon Q | GitLab.com | GitLab Self-Managed | GitLab Dedicated | GitLab Duo Self-Hosted |
|---------|----------|---------|----------------|--------------------------|-----------|-------------|-----------|------------------------|
| [GitLab Duo Agent Platform](../duo_agent_platform/_index.md) | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="dash-circle" >}} No | Beta | Beta | Beta | {{< icon name="dash-circle" >}} No |
| [GitLab Duo Chat (Agentic)](../gitlab_duo_chat/agentic_chat.md) | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes <sup>1</sup> | Beta | Beta | Beta | {{< icon name="dash-circle" >}} No |
| [Merge Request Summary](../project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes) | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="dash-circle" >}} No | Beta | Beta | {{< icon name="dash-circle" >}} No | Beta |
| [Code Review Summary](../project/merge_requests/duo_in_merge_requests.md#summarize-a-code-review) | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="dash-circle" >}} No | Experiment | Experiment | Experiment | Experiment |
| [Issue Description Generation](../project/issues/managing_issues.md#populate-an-issue-with-issue-description-generation) | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="dash-circle" >}} No | Experiment | {{< icon name="dash-circle" >}} No | {{< icon name="dash-circle" >}} No | Not applicable |

**Footnotes**:

1. Amazon Q supports a different version of this feature.
   [View details](#amazon-q-developer-pro-included-with-gitlab-duo-with-amazon-q).

## Features available in GitLab Duo Self-Hosted

Your organization can use [GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md)
to self-host the AI gateway and language models if you:

- Have the GitLab Duo Enterprise add-on.
- Are a GitLab Self-Managed customer.

To check which GitLab Duo features are available for use with GitLab Duo Self-Hosted,
and the status of those features, see the
[supported GitLab Duo features for GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md#supported-gitlab-duo-features).

## Amazon Q Developer Pro included with GitLab Duo With Amazon Q

License credits for [Amazon Q Developer Pro](https://aws.amazon.com/q/developer/) are included
with a subscription to GitLab Duo with Amazon Q.

This subscription includes access to agentic chat and command-line tools, including:

- [Amazon Q Developer in the IDE](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/q-in-IDE.html), including Visual Studio, VS Code, JetBrains, and Eclipse.
- [Amazon Q Developer on the command line](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line.html).
- [Amazon Q Developer in the AWS Management Console](https://aws.amazon.com/q/developer/operate/).

For more information about the capabilities of Amazon Q Developer, see the [AWS website](https://aws.amazon.com/q/developer/).
