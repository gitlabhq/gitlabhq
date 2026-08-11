---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Code Review Flow
---

{{< details >}}

- Tier: [Free](../../../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Model information" >}}

- LLM: Anthropic Claude Sonnet 5 Vertex
- [Select a different model](../../../model_selection.md) using the **Agentic Code Review** setting.
- Available on [GitLab Duo with self-hosted models](../../../../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- Introduced as [a beta](../../../../../policy/development_stages_support.md) in GitLab [18.7](https://gitlab.com/groups/gitlab-org/-/epics/18645) [with a feature flag](../../../../../administration/feature_flags/_index.md) named `duo_code_review_on_agent_platform`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) in GitLab 18.8. Feature flag `duo_code_review_on_agent_platform` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217209).
- Available on the Free tier on GitLab.com with GitLab Credits in GitLab 18.10.
- LLM [updated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236876) to Claude Sonnet 4.6 Vertex in GitLab 19.1.
- LLM [updated](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/6422) to Claude Sonnet 5 Vertex in GitLab 19.3.

{{< /history >}}

> [!note]
> Depending on your add-on and group settings, GitLab runs one of two code review features:
>
> - Code Review Flow: the agentic version, part of GitLab Duo Agent Platform.
> - GitLab Duo Code Review: the non-agentic version, available only for users with the GitLab Duo Enterprise add-on.
>
> This page describes the agentic version.
>
> For more information about how the two features compare and how to turn on Code Review Flow for GitLab Duo Enterprise seats,
> see [use GitLab Duo to review your code.](../../../../project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code).

The Code Review Flow helps you streamline code reviews with agentic AI.

This flow:

- Analyzes code changes.
- Provides enhanced contextual understanding of repository structure and cross-file dependencies.
- Delivers detailed review comments with actionable feedback.
- Supports custom review instructions tailored to your project.

This flow is available in the GitLab UI only.

## Prerequisites

- Meet the [prerequisites for the GitLab Duo Agent Platform](../../../_index.md#prerequisites).
- Turn on **Allow foundational flows** and **Code Review** [for the top-level group](../_index.md#turn-foundational-flows-on-or-off).
- Have the Developer, Maintainer, or Owner role for the project.
- If you belong to multiple GitLab Duo namespaces, [set a default GitLab Duo namespace](../../../../profile/preferences.md#set-a-default-gitlab-duo-namespace).
- [Configure your own runners](../../execution/_index.md#configure-runners-to-execute-flows) with the `gitlab--duo` tag and
  an executor that supports Docker images, or turn on [GitLab hosted runners](../../../../../ci/runners/hosted_runners/_index.md)
  for your project. Code Review Flow runs as a CI/CD job and requires a runner to execute.

## Use the flow

{{< history >}}

- Using a flow in a GitLab Duo Agentic Chat conversation [introduced](https://gitlab.com/groups/gitlab-org/-/work_items/20484) in GitLab 19.2 [with a feature flag](../../../../../administration/feature_flags/_index.md) named `agentic_foundational_flow_tool`. Enabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

To use the Code Review Flow on a merge request:

1. In the left sidebar, select **Code** > **Merge requests** and find your merge request.
1. Use one of these methods to request a review:
   - Assign `@GitLabDuo` as a reviewer.
   - In a comment box, enter the quick action `/assign_reviewer @GitLabDuo`.
   - In a comment box, mention `@GitLabDuo` and ask for a review.
   - In the GitLab Duo sidebar, open a new or existing Agentic Chat conversation.
     Ask Agentic Chat to review the merge request.
1. To monitor progress, in the left sidebar, select **AI** > **Sessions**.

   If you are in Agentic Chat, you can also do the following:
   - See the progress in the Chat conversation.
   - Select **View Agent Session** in the conversation.

## Interact with GitLab Duo in reviews

{{< history >}}

- Comment interactions [updated](https://gitlab.com/gitlab-org/gitlab/-/work_items/601102) to use GitLab Duo Agent Platform in GitLab 19.1.

{{< /history >}}

In addition to assigning GitLab Duo as a reviewer, you can interact with GitLab Duo
by:

- Replying to review comments to ask for clarification or alternative approaches.
- Mentioning `@GitLabDuo` in any discussion thread to ask follow-up questions.

Discussions with GitLab Duo in comments use GitLab Duo Agent Platform and [consume credits](../../../../../subscriptions/gitlab_credits.md).

Feedback provided to GitLab Duo does not influence later reviews of other merge requests.
Adding this functionality is proposed in [issue 560116](https://gitlab.com/gitlab-org/gitlab/-/issues/560116).

## Contextual awareness

Code Review Flow runs in two stages:

1. Pre-scan: The flow inspects the merge request diffs and uses them to identify related
   context to fetch from the project repository. The pre-scan typically includes directory
   listings and the contents of related files, such as tests and dependencies referenced by the
   changes. The exact context fetched depends on the diff analysis.
1. Review: The flow runs the review with the following data in the large language model. The review stage cannot fetch additional context on demand.

   - Results from the pre-scan step.
   - Merge request title.
   - Merge request description.
   - Merge request diffs.
   - Original versions of the files.
   - Filenames.
   - Custom review instructions.

To specify content to exclude, see
[exclude context from GitLab Duo](../../../context.md#exclude-context-from-gitlab-duo).

### File and context limits

Code Review Flow applies two limits to keep the prompt within a workable size:

- For files longer than 10,000 lines, only the diff is sent to the model. The full file contents are not included.
- The total context that the pre-scan gathers is capped at approximately 1 MiB. When the cap is
  exceeded, the context is truncated to approximately 800 KiB before the review stage runs.

These limits apply to the data the flow gathers and are separate from the
[selected model's](../../../model_selection.md) context window.

For very large merge requests, the review might miss context that was truncated. To reduce the
risk:

- Split the merge request into smaller merge requests.
- [Exclude context](../../../context.md#exclude-context-from-gitlab-duo) for files that are not
  relevant to the review.

## Custom code review instructions

Customize the behavior of Code Review Flow with an `mr-review-instructions.yaml` file.

You can guide GitLab Duo with repository-specific review instructions:

- Focus on specific code quality aspects (such as security, performance, and maintainability).
- Enforce coding standards and best practices unique to your project.
- Target specific file patterns with tailored review criteria.
- Provide more detailed explanations for certain types of changes.

Code Review Flow does not reference `AGENTS.md` and `SKILL.md` files.

To configure custom instructions, see [customize review instructions for GitLab Duo](../../../customize/review_instructions.md).

## Automatic reviews

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/506537) automatic reviews for projects to a UI setting in GitLab 18.0.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/554070) automatic reviews for groups and instances in GitLab 18.4 as a [beta](../../../../../policy/development_stages_support.md#beta) [with a feature flag](../../../../../administration/feature_flags/_index.md) named `cascading_auto_duo_code_review_settings`. Disabled by default.
- Feature flag `cascading_auto_duo_code_review_settings` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213240) in GitLab 18.7.
- Automatic reviews for groups and applications [turned on by default](https://gitlab.com/gitlab-org/gitlab/-/work_items/592822) for new GitLab Duo trials on GitLab.com in GitLab 19.1.

{{< /history >}}

Automatic reviews from GitLab Duo ensure that all merge requests in your project, group, or instance
receive an initial review.

When a user creates a merge request, GitLab Duo automatically reviews it unless:

- It's marked as draft. For GitLab Duo to review the merge request, mark it ready.
- It contains no changes. For GitLab Duo to review the merge request, add changes to it.
- It matches one or more exclusion rules you set. For GitLab Duo to review the merge request,
  manually request a review.

For new GitLab Duo trials on GitLab.com in GitLab 19.1 and later, automatic reviews for groups are turned on by
default.

{{< tabs >}}

{{< tab title="Project" >}}

Prerequisites:

- The Maintainer or Owner role for the project.

To turn on automatic reviews for a project:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Settings** > **Merge requests**.
1. In the **GitLab Duo Code Review** section, select **Enable automatic reviews by GitLab Duo**.
1. Select **Save changes**.

{{< /tab >}}

{{< tab title="Group" >}}

Prerequisites:

- The Owner role for the group.

To turn on automatic reviews for a group:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Settings** > **General**.
1. Expand the **Merge requests** section.
1. In the **GitLab Duo Code Review** section, select **Enable automatic reviews by GitLab Duo**.
1. Select **Save changes**.

Settings cascade from group to project. More specific settings override broader ones.

{{< /tab >}}

{{< tab title="Instance" >}}

Prerequisites:

- Administrator access

To turn on automatic reviews for an instance:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. In the **GitLab Duo Code Review** section, select **Enable automatic reviews by GitLab Duo**.
1. Select **Save changes**.

Settings cascade from instance to group to project. More specific settings override broader ones.

{{< /tab >}}

{{< /tabs >}}

After you enable automatic reviews, you can specify rules to exclude specific merge requests.

For information on how credit usage is attributed for automatic reviews, see
[determine which code review feature runs](../../../../project/merge_requests/duo_in_merge_requests.md#determine-which-review-feature-runs).

### Exclude merge requests for a project

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240236) in GitLab 19.2 as a [beta](../../../../../policy/development_stages_support.md#beta) [with a flag](../../../../../administration/feature_flags/_index.md) named `duo_code_review_automated_rules`. Enabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/245852) in GitLab 19.3. Feature flag `duo_code_review_automated_rules` removed.

{{< /history >}}

When automatic reviews are turned on for a project,
GitLab Duo reviews every eligible merge request.
To exclude specific merge requests, define exclusion rules in a
`.gitlab/duo/mr-review-automated-rules.yaml` file.

Exclusion rules only prevent automatic reviews.
You can still request a review manually for any excluded merge request.

To define exclusion rules:

1. In the root of your repository, create a `.gitlab/duo` directory if one doesn't already exist.
1. In the `.gitlab/duo` directory, create a file named `mr-review-automated-rules.yaml`.
1. Add exclusion rules using the following format:

   ```yaml
   exclude:
     target_branches:
       - <pattern>
     source_branches:
       - <pattern>
     authors:
       - <pattern>
   ```

   Each key is optional.
   GitLab Duo skips the automatic review when a merge request matches any pattern in any category:

   - `target_branches`: Matches the target branch name of the merge request.
   - `source_branches`: Matches the source branch name of the merge request.
   - `authors`: Matches the username of the merge request author.

   Patterns support wildcard (glob) matching.
   For example, `dependabot/*` matches any source branch that starts with `dependabot/`.

   For example, to skip automatic reviews for merge requests that target a release branch or
   that a bot account creates:

   ```yaml
   exclude:
     target_branches:
       - "release/*"
     authors:
       - "*-bot"
   ```

1. Commit the file to the default branch of your repository.

GitLab Duo reads the exclusion rules from the default branch of your repository.
GitLab Duo does not apply rules on other branches.

### Exclude merge requests for a group

To define exclusion rules for all projects in a group and its subgroups, specify a project to use
as a template.
The template project must contain a `.gitlab/duo/mr-review-automated-rules.yaml` file.

GitLab Duo combines the exclusion rules from the group template project with the rules defined
in the individual project.
If the same category is defined at both levels, the project's rules take
precedence.
When a group and its subgroups each set a template project, GitLab Duo combines the rules from
every level.

> [!note]
> If you already configured a project to store [custom review instructions](../../../customize/review_instructions.md#configure-custom-review-instructions-for-a-group)
> for your group, store your `mr-review-automated-rules.yaml` in the same project.
> You can only specify a single project to customize code review for a group, so GitLab automatically
> checks that project for exclusion rules as well. You do not need to follow the steps below again.

Prerequisites:

- The Owner role for the group.
- A project in the group contains the exclusion rules that you want to set.

To configure exclusion rules for a group:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Settings** > **General** > **GitLab Duo features**.
1. Under **Customize code review**, select the project that contains the
   `.gitlab/duo/mr-review-automated-rules.yaml` file.
1. Select **Save changes**.

## Troubleshooting

When working with Code Review Flow, you might encounter issues.

For information on how to resolve these issues, see [troubleshooting](troubleshooting.md).

## Related topics

- [GitLab Duo in merge requests](../../../../project/merge_requests/duo_in_merge_requests.md)
- [Agent Platform AI models](../../../model_selection.md)
- [Turn on Code Review Flow for GitLab Duo Enterprise seats](../../../../project/merge_requests/duo_in_merge_requests.md#turn-on-code-review-flow-for-gitlab-duo-enterprise-seats).
