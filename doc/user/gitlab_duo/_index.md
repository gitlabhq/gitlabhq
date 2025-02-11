---
stage: AI-powered
group: AI Framework
description: AI-powered features and functionality.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo
---

> - [First GitLab Duo features introduced](https://about.gitlab.com/blog/2023/05/03/gitlab-ai-assisted-features/) in GitLab 16.0.
> - [Removed third-party AI setting](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136144) in GitLab 16.6.
> - [Removed support for OpenAI from all GitLab Duo features](https://gitlab.com/groups/gitlab-org/-/epics/10964) in GitLab 16.6.

GitLab Duo is a suite of AI-powered features that assist you while you work in GitLab.
These features aim to help increase velocity and solve key pain points across the software development lifecycle.

GitLab Duo features are available in [IDE extensions](../../editor_extensions/_index.md) and the GitLab UI.
Some features are also available as part of [GitLab Duo Chat](../gitlab_duo_chat_examples.md).

- [Get started with GitLab Duo](../get_started/getting_started_gitlab_duo.md).
- [View a walkthrough of GitLab Duo Enterprise features](https://gitlab.navattic.com/duo-enterprise).

GitLab is [transparent](https://handbook.gitlab.com/handbook/values/#transparency).
As GitLab Duo features mature, the documentation will be updated to clearly state
how and where you can access these features.

## Working across the entire software development lifecycle

To improve your workflow across the entire software development lifecycle, try these features:

- [GitLab Duo Chat](../gitlab_duo_chat/_index.md): Write and understand code, get up to speed on the status of projects,
  and learn about GitLab by asking your questions in a chat window.
  <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=ZQBAuf-CTAY)
- [Self-Hosted Models](../../administration/gitlab_duo_self_hosted/_index.md): Host the language models that power AI features in GitLab.
  Code Suggestions and Chat are supported. Use GitLab model vendors or self-host a supported language model.
- [GitLab Duo Workflow](../duo_workflow/_index.md): Automate tasks and help increase productivity in your development workflow.
- [AI Impact Dashboard](../analytics/ai_impact_analytics.md): Measure the AI effectiveness and impact on SDLC metrics.

## Planning work

To improve your workflow while planning work, try these features:

- [Issue Description Generation](../project/issues/managing_issues.md#populate-an-issue-with-issue-description-generation): Generate a more in-depth issue description based on a short summary.
  <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=-BWBQat7p5M)
  <!-- Video published on 2024-12-18 -->
- [Discussion Summary](../discussions/_index.md#summarize-issue-discussions-with-duo-chat): Summarize lengthy conversations in an issue.
  <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=IcdxLfTIUgc)
  <!-- Video published on 2024-03-28 -->

## Authoring code

To improve your workflow while authoring code, try these features:

- [Code Suggestions](../project/repository/code_suggestions/_index.md): Generate code and show suggestions as you type.
  <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://youtu.be/ds7SG1wgcVM)
- Code Explanation: Have code explained. View docs for explaining code in:

  - [The IDE](../gitlab_duo_chat/examples.md#explain-selected-code).
  - [A file](../project/repository/code_explain.md).
  - [A merge request](../project/merge_requests/changes.md#explain-code-in-a-merge-request).
  - <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://youtu.be/1izKaLmmaCA?si=O2HDokLLujRro_3O)
    <!-- Video published on 2023-11-18 -->
- [Test Generation](../gitlab_duo_chat/examples.md#write-tests-in-the-ide): Test your code by generating tests.
  <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=zWhwuixUkYU)
- [Refactor Code](../gitlab_duo_chat/examples.md#refactor-code-in-the-ide): Improve or refactor the selected code.
  <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=zWhwuixUkYU)
- [Fix Code](../gitlab_duo_chat/examples.md#fix-code-in-the-ide): Fix quality problems, like bugs or typos, in the selected code.
  <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=zWhwuixUkYU)
- [GitLab Duo for the CLI](../../editor_extensions/gitlab_cli/_index.md#gitlab-duo-for-the-cli): Discover or recall `git` commands.

## Reviewing code

To improve your workflow while reviewing code in merge requests, try these features:

- [Merge Request Summary](../project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes): Generate a description based on the code changes.
  <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=CKjkVsfyFd8&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW)
- [Code Review](../project/merge_requests/duo_in_merge_requests.md#have-gitlab-duo-review-your-code): Review proposed code changes.
- [Code Review Summary](../project/merge_requests/duo_in_merge_requests.md#summarize-a-code-review): Summarize all the comments in a review.
  <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=Bx6Zajyuy9k)
- [Merge Commit Message Generation](../project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message): Generate commit messages.
  <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=fUHPNT4uByQ)

## Testing and deploying code

To improve your testing and deployment workflow, try these features:

- [Root Cause Analysis](../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis): Research the root cause for a CI/CD job failure by analyzing the logs.
  <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=MLjhVbMjFAY&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW)

## Securing code

To improve your security, try these features:

- [Vulnerability Explanation](../application_security/vulnerabilities/_index.md#explaining-a-vulnerability): Learn more about vulnerabilities, how they can be exploited, and how to fix them.
  <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=MMVFvGrmMzw&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW)
- [Vulnerability Resolution](../application_security/vulnerabilities/_index.md#vulnerability-resolution): Generate a merge request that addresses a vulnerability.
  <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=VJmsw_C125E&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW)

## Summary of all GitLab Duo features

| Feature | Tier | Add-on | Offering | Status |
| ------- | ---- | ------ | -------- | ------ |
| [GitLab Duo Chat](../gitlab_duo_chat/_index.md) | Premium, Ultimate | GitLab Duo Pro or Enterprise | GitLab.com, Self-managed, GitLab Dedicated | General availability |
| [Self-Hosted Models](../../administration/gitlab_duo_self_hosted/_index.md) | Ultimate | GitLab Duo Enterprise | Self-managed | Beta |
| [GitLab Duo Workflow](../duo_workflow/_index.md) | Ultimate | - | GitLab.com | Experiment |
| [Issue Description Generation](../project/issues/managing_issues.md#populate-an-issue-with-issue-description-generation) | Ultimate | GitLab Duo Enterprise | GitLab.com | Experiment |
| [Discussion Summary](../discussions/_index.md#summarize-issue-discussions-with-duo-chat) | Ultimate | GitLab Duo Enterprise | GitLab.com, Self-managed, GitLab Dedicated | General availability |
| [Code Suggestions](../project/repository/code_suggestions/_index.md) | Premium, Ultimate | GitLab Duo Pro or Enterprise | GitLab.com, Self-managed, GitLab Dedicated | General availability |
| [Code Explanation](../project/repository/code_explain.md) | Premium, Ultimate | GitLab Duo Pro or Enterprise | GitLab.com, Self-managed, GitLab Dedicated | General availability |
| [Test Generation](../gitlab_duo_chat/examples.md#write-tests-in-the-ide) | Premium, Ultimate | GitLab Duo Pro or Enterprise | GitLab.com, Self-managed, GitLab Dedicated | General availability |
| [Refactor Code](../gitlab_duo_chat/examples.md#refactor-code-in-the-ide) | Premium, Ultimate | GitLab Duo Pro or Enterprise | GitLab.com, Self-managed, GitLab Dedicated | General availability |
| [Fix Code](../gitlab_duo_chat/examples.md#fix-code-in-the-ide) | Premium, Ultimate | GitLab Duo Pro or Enterprise | GitLab.com, Self-managed, GitLab Dedicated | General availability |
| [GitLab Duo for the CLI](../../editor_extensions/gitlab_cli/_index.md#gitlab-duo-for-the-cli) | Ultimate | GitLab Duo Enterprise | GitLab.com, Self-managed, GitLab Dedicated | General availability |
| [Merge Request Summary](../project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes) | Ultimate | GitLab Duo Enterprise | GitLab.com | Beta |
| [Code Review](../project/merge_requests/duo_in_merge_requests.md#have-gitlab-duo-review-your-code) | Ultimate | GitLab Duo Enterprise | GitLab.com | Experiment |
| [Code Review Summary](../project/merge_requests/duo_in_merge_requests.md#summarize-a-code-review) | Ultimate | GitLab Duo Enterprise | GitLab.com | Experiment |
| [Merge Commit Message Generation](../project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message) | Ultimate | GitLab Duo Enterprise | GitLab.com, Self-managed, GitLab Dedicated | General availability |
| [Root Cause Analysis](../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) | Ultimate | GitLab Duo Enterprise | GitLab.com, Self-managed, GitLab Dedicated | General availability |
| [Vulnerability Explanation](../application_security/vulnerabilities/_index.md#explaining-a-vulnerability) | Ultimate | GitLab Duo Enterprise | GitLab.com, Self-managed, GitLab Dedicated | General availability |
| [Vulnerability Resolution](../application_security/vulnerabilities/_index.md#vulnerability-resolution) | Ultimate | GitLab Duo Enterprise | GitLab.com, Self-managed, GitLab Dedicated | General availability |
| [AI Impact Dashboard](../analytics/ai_impact_analytics.md) | Ultimate | GitLab Duo Enterprise | GitLab.com, Self-managed | General availability |
