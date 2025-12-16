---
stage: AI-powered
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Code Review Flow
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core or Pro
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< collapsible title="Model information" >}}

- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- Available on [GitLab Duo with self-hosted models](../../../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- Introduced as [a beta](../../../../policy/development_stages_support.md) in GitLab [18.6](https://gitlab.com/groups/gitlab-org/-/epics/18645) [with a flag](../../../../administration/feature_flags/_index.md) named `duo_code_review_on_agent_platform`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

The Code Review Flow helps you streamline code reviews with agentic AI.

This flow:

- Analyzes code changes, merge request comments, and linked issues.
- Provides enhanced contextual understanding of repository structure and cross-file dependencies.
- Delivers detailed review comments with actionable feedback.
- Supports custom review instructions tailored to your project.

This flow is available in the GitLab UI only.

The Code Review Flow is [different from classic GitLab Duo Code Review](#differences-from-classic-gitlab-duo-code-review).

## Use the flow

Prerequisites:

- Ensure you meet [the other prerequisites](../_index.md#prerequisites).

To trigger a Code Review Flow on a merge request:

1. On the left sidebar, select **Code** > **Merge requests** and find your merge request.
1. Use one of these methods to trigger the review:
   - Assign the review to `@GitLabDuo`
   - Mention `@GitLabDuo` in a comment

You can interact with GitLab Duo by:

- Replying to its review comments to ask for clarification or alternative approaches.
- Mentioning `@GitLabDuo` in any discussion thread to ask follow-up questions.

### Automatic code reviews

You can configure automatic code reviews for projects or groups to ensure all merge requests receive
an initial review by GitLab Duo. After you create a merge request, GitLab Duo reviews it unless:

- It's marked as draft. For GitLab Duo to review the merge request, mark it ready.
- It contains no changes. For GitLab Duo to review the merge request, add changes to it.

#### Enable automatic reviews for a project

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/506537) to a UI setting in GitLab 18.0.

{{< /history >}}

Prerequisites:

- You must have at least the [Maintainer role](../../../permissions.md) in a project.

To enable `@GitLabDuo` to automatically review merge requests:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Settings** > **Merge requests**.
1. In the **GitLab Duo Code Review** section, select **Enable automatic reviews by GitLab Duo**.
1. Select **Save changes**.

#### Enable automatic reviews for a group or application

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/554070) in GitLab 18.4 as a [beta](../../../../policy/development_stages_support.md) [with a flag](../../../../administration/feature_flags/_index.md) named `cascading_auto_duo_code_review_settings`. Disabled by default.
- Feature flag `cascading_auto_duo_code_review_settings` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213240) in GitLab 18.7.

{{< /history >}}

Use group or application settings to enable automatic reviews for multiple projects.

Prerequisites:

- To turn on automatic reviews for groups, have the Owner role for the group.
- To turn on automatic reviews for all projects, be an administrator.

To enable automatic reviews for groups:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
1. Expand the **Merge requests** section.
1. In the **GitLab Duo Code Review** section, select **Enable automatic reviews by GitLab Duo**.
1. Select **Save changes**.

To enable automatic reviews for all projects:

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **General**.
1. In the **GitLab Duo Code Review** section, select **Enable automatic reviews by GitLab Duo**.
1. Select **Save changes**.

Settings cascade from application to group to project. More specific settings override broader ones.

### Custom instructions

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/545136) in GitLab 18.2 as a [beta](../../../../policy/development_stages_support.md) [with a flag](../../../../administration/feature_flags/_index.md) named `duo_code_review_custom_instructions`. Disabled by default.
- Feature flag `duo_code_review_custom_instructions` [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199802) in GitLab 18.3.
- Feature flag `duo_code_review_custom_instructions` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202262) in GitLab 18.4.

{{< /history >}}

Customize the behavior of Code Review Flow with repository-specific review instructions. You can
guide the agent to:

- Focus on specific code quality aspects (such as security, performance, and maintainability).
- Enforce coding standards and best practices unique to your project.
- Target specific file patterns with tailored review criteria.
- Provide more detailed explanations for certain types of changes.

To configure custom instructions:

1. In the root of your repository, create a `.gitlab/duo` directory if it doesn't already exist.
1. In the `.gitlab/duo` directory, create a file named `mr-review-instructions.yaml`.
1. Add your custom instructions using this format:

   ```yaml
   instructions:
     - name: <instruction_group_name>
       fileFilters:
         - <glob_pattern_1>
         - <glob_pattern_2>
         - !<exclude_pattern>  # Exclude files matching this pattern
       instructions: |
         <your_custom_review_instructions>
   ```

   For example:

   ```yaml
   instructions:
     - name: Ruby Style Guide
       fileFilters:
         - "*.rb"           # Ruby files in the root directory
         - "lib/**/*.rb"    # Ruby files in lib and its subdirectories
         - "!spec/**/*.rb"  # Exclude test files
       instructions: |
         1. Ensure all methods have proper documentation
         2. Follow Ruby style guide conventions
         3. Prefer symbols over strings for hash keys

     - name: TypeScript Source Files
       fileFilters:
         - "**/*.ts"        # Typescript files in any directory
         - "!**/*.test.ts"  # Exclude test files
         - "!**/*.spec.ts"  # Exclude spec files
       instructions: |
         1. Ensure proper TypeScript types (avoid 'any')
         2. Follow naming conventions
         3. Document complex functions

     - name: All Files Except Tests
       fileFilters:
         - "!**/*.test.*"   # Exclude all test files
         - "!**/*.spec.*"   # Exclude all spec files
         - "!test/**/*"     # Exclude test directories
         - "!spec/**/*"     # Exclude spec directories
       instructions: |
         1. Follow consistent code style
         2. Add meaningful comments for complex logic
         3. Ensure proper error handling

     - name: Test Coverage
       fileFilters:
         - "spec/**/*_spec.rb" # Ruby test files in spec directory
       instructions: |
         1. Test both happy paths and edge cases
         2. Include error scenarios
         3. Use shared examples to reduce duplication
   ```

1. Optional: Add a [Code Owners](../../../project/codeowners/_index.md) entry to protect changes to
   the `mr-review-instructions.yaml` file.

   ```markdown
   [GitLab Duo]
   .gitlab/duo @default-owner @tech-lead
   ```

1. [Create a merge request](../../../project/merge_requests/creating_merge_requests.md) to review
   and merge the changes:

   - Code Review automatically applies your custom instructions when the file patterns match.
   - Multiple instruction groups can apply to a single file.
1. Optional:
   - Review the feedback and refine your instructions as needed.
   - Test the patterns to ensure they match the intended files.

## Differences from classic GitLab Duo Code Review

While the Code Review Flow provides the same core functionality as the classic
[GitLab Duo Code Review](../../../project/merge_requests/duo_in_merge_requests.md#have-gitlab-duo-review-your-code),
the GitLab Duo Agent Platform implementation offers:

- Improved context awareness: Better understanding of repository structure and cross-file dependencies.
- Agentic capabilities: Multi-step reasoning for more thorough analysis.
- Modern architecture: Built on the scalable GitLab Duo Agent Platform.

All existing features including custom instructions, automatic reviews, and interaction patterns
remain compatible.
