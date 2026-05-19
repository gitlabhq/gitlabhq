---
stage: Release Notes
group: Monthly Release
date: 2025-03-20
title: "GitLab 17.10 release notes"
description: "GitLab 17.10 released with Duo Code Review available in beta"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On March 20, 2025, GitLab 17.10 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Alexey Butkeev

Everyone can [nominate GitLab’s community contributors](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)!
Show your support for our active candidates or add a new nomination! 🙌

[Alexey Butkeev](https://gitlab.com/abutkeev) is a valued community contributor whose contributions enhance our global reach and user experience. His impactful localization and translation contributions exemplify our Diversity, Inclusion, and Belonging value.

“I’m honored to be selected as the 17.10 MVP and to contribute to making GitLab more accessible and inclusive,” says Alexey.
“Localization is a team effort, and I’m grateful to be part of such a supportive community.”

In addition to his code contributions, Alexey took the initiative to find, document, and fix translation errors via GitLab and Crowdin. His thorough research and problem solving make him our 17.10 MVP.

Alexey was nominated by [Oleksandr Pysaryuk](https://gitlab.com/opysaryuk), Senior Manager, Globalization Technology at GitLab, and supported by [Daniel Sullivan](https://gitlab.com/djsulliv), Director of Globalization & Localization at GitLab.
“We appreciate your work and support here at GitLab so much,” says Daniel.
“Thank you for your part in helping us become a more globally supported company!”

Thank you Alexey for making GitLab more inclusive and transparent!

## Primary features

### Duo Code Review available in beta

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../user/project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code)

{{< /details >}}

Code review is an essential activity of software development. It ensures that contributions to a project maintain and improve code quality and security, and is an avenue of mentorship and feedback for engineers. It’s also one of the most time-consuming activities in the software development process.

Duo Code Review is the next evolution of the code review process.

Duo Code Review can accelerate your development process. When it performs an initial review on your merge request, it can help identify potential bugs and suggest further improvements - some of which you can apply directly from your browser. Use it to iterate on and improve your changes before you add another human to the loop.

**Try it out:**

- To start a code review immediately, add `@GitLabDuo` as a reviewer to your merge request.
- To refine feedback on your changes, mention `@GitLabDuo` in a comment.

You can track future progress for Duo Code Review in epic [13008](https://gitlab.com/groups/gitlab-org/-/epics/13008) and related child epics. Feedback can be provided in issue [517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386).

### Root Cause Analysis available on GitLab Duo Self-Hosted

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/_index.md#feature-versions-and-status) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13759)

{{< /details >}}

You can now use [GitLab Duo Root Cause Analysis](https://about.gitlab.com/blog/developing-gitlab-duo-blending-ai-and-root-cause-analysis-to-fix-ci-cd/) on GitLab Duo Self-Hosted. This feature is in beta for GitLab Self-Managed instances using GitLab Duo Self-Hosted, with support for Mistral, Anthropic, and OpenAI GPT model families.

With Root Cause Analysis on GitLab Duo Self-Hosted, you can troubleshoot failed jobs in CI/CD pipelines faster without compromising data sovereignty. Root Cause Analysis analyzes the failed job log, quickly determines the root cause of the job failure, and suggests a fix for you.

Note: This feature currently has limited functionality, and full functionality is planned for 17.11.
Additional information is available in
[troubleshooting documentation](../../administration/gitlab_duo_self_hosted/troubleshooting.md#feature-not-accessible-or-feature-button-not-visible)
and in issue [527128](https://gitlab.com/gitlab-org/gitlab/-/issues/527128).

Please leave feedback on Root Cause Analysis for GitLab Duo Self-Hosted in [issue 523912](https://gitlab.com/gitlab-org/gitlab/-/issues/523912).

### Expanded AWS Regions available for GitLab Dedicated failover instances

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- Tier: Gold
- Links: [Documentation](../../administration/dedicated/create_instance/data_residency_high_availability.md)

{{< /details >}}

GitLab Dedicated customers can now select from an expanded list of AWS regions when choosing where to host their failover instance for [disaster recovery](../../administration/dedicated/disaster_recovery.md).

Expanding failover support to additional regions enables GitLab Dedicated customers to fully use the disaster recovery functionality of GitLab Dedicated regardless of which AWS region they need to use to satisfy their data residency needs.

These newly available regions are only available for hosting failover instances as they do not fully support certain AWS features that GitLab Dedicated relies on.

### GitLab Query Language views Beta

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/glql/_index.md#embedded-views) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/14938)

{{< /details >}}

Tracking and understanding work in progress across GitLab previously required navigating multiple locations, reducing team efficiency and consuming valuable time.

This release introduces GitLab Query Language (GLQL) views Beta so you can create dynamic, real-time work tracking directly in your existing workflows.

GLQL views embed live data queries in Markdown code blocks throughout Wiki pages, epic descriptions, issue comments, and merge requests.

Previously available as an experiment, GLQL views now enter beta with support for sophisticated filtering using logical expressions and operators across key fields, including assignee, author, label, and milestone. You can customize your view’s presentation as tables or lists, control which fields appear, and set result limits to create focused, actionable insights for your team.

Teams can now maintain context while accessing the information they need, creating shared understanding, and improving collaboration — all without leaving their current workflow.

[We welcome your feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/509791) on GLQL views as we continue to enhance this feature.

### Enhanced Markdown experience

<!-- categories: Markdown -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/markdown.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/7654)

{{< /details >}}

GitLab Flavored Markdown has been enhanced with several powerful improvements:

- **Improved math and image handling**:
  - Disable [math rendering](../../user/markdown.md#math-equations) limits in your group or self-hosted instance to handle more complex mathematical expressions.
  - Control [image dimensions](../../user/markdown.md#change-image-or-video-dimensions) precisely using pixel values or percentages to better manage content layout.
- **Enhanced editor experience**:
  - Continue lists automatically when pressing Enter/Return.
  - Shift text left or right using keyboard shortcuts.
  - Create clear term-definition pairs using description list syntax.
  - Adjust video widths flexibly.
- **Better content organization**:
  - Navigate content more easily with auto-expanding [summary quick views](../../user/markdown.md#show-item-summary) (add `+s` to URLs).
  - See referenced [issue titles](../../user/markdown.md#show-item-title) render automatically (add `+` to URLs).
  - Organize content modularly using [`include` syntax](../../user/markdown.md#includes).
  - Create visually distinct callouts and warnings using [alert boxes](../../user/markdown.md#alerts).

These improvements make GitLab Flavored Markdown more powerful for teams creating and maintaining documentation while offering greater flexibility in how content is presented and organized.

### New visualization of DevOps performance with DORA metrics across projects

<!-- categories: Value Stream Management, DORA Metrics -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/analytics/value_streams_dashboard.md#projects-by-dora-metric) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/408516)

{{< /details >}}

We are excited to introduce the **Projects by DORA metric** panel, a new addition to the [Value Streams Dashboard](https://www.youtube.com/watch?v=EA9Sbks27g4). This table lists all projects in the top-level group, with breakdown into the [four DORA metrics](https://about.gitlab.com/solutions/value-stream-management/dora/#overview). Managers can use this table to identify high, medium, and low-performing projects. This information can also help make data-driven decisions, allocate resources effectively, and focus on initiatives that enhance software delivery speed, stability, and reliability.

The [DORA metrics](../../user/analytics/dora_metrics.md) are available out-of-the-box in GitLab, and now together with the [**DORA Performers score** panel](https://about.gitlab.com/blog/inside-dora-performers-score-in-gitlab-value-streams-dashboard/) executives have a complete view into their organization’s DevOps health top to bottom.

### New issues look now in beta

<!-- categories: Team Planning -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/issues/_index.md)

{{< /details >}}

Issues now share a common framework with epics and tasks, featuring real-time updates and workflow improvements:

- **Drawer view:** Open items from lists or boards in a drawer for quick viewing without leaving your current context. A button at the top lets you expand to full page view.
- **Change type:** Convert types between epics, issues, and tasks using the “Change type” action (replaces “Promote to epic”)
- **Start date:** Issues now support start dates, aligning their functionality with epics and tasks.
- **Ancestry:** The complete hierarchy is above the title and the Parent field in the sidebar. To manage relationships, use the new [quick action](../../user/project/quick_actions.md) commands `/set_parent`, `/remove_parent`, `/add_child`, and `/remove_child`.
- **Controls:** All actions are now accessible from the top menu (vertical ellipsis), which remains visible in the sticky header when scrolling.
- **Development:** All development items (merge requests, branches, and feature flags) related to an issue or task are now consolidated in a single, convenient list.
- **Layout:** UI improvements create a more seamless experience between issues, epics, tasks, and merge requests, helping you navigate your workflow more efficiently.
- **Linked items:** Create relationships between tasks, issues, and epics with improved linking options. Drag and drop to change link types and toggle the visibility of labels and closed items.

### Description templates for epics, issues, tasks, objectives and key results

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/description_templates.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16088)

{{< /details >}}

You can now streamline your workflow and maintain consistency across your projects with description templates for work items (epics, tasks, objectives, and key results).

This powerful addition allows you to create standardized templates, saving you time and ensuring all crucial information is included every time you create a new work item.

### Change the severity of a vulnerability

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/vulnerability_report/_index.md#change-or-override-vulnerability-severity) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/16157)

{{< /details >}}

When triaging vulnerabilities, you need the flexibility to adjust severity levels based on your organization’s unique security context and risk tolerance. Until now, you had to rely on the default severity levels assigned by security scanners, which might not accurately reflect the risk level for your specific environment.

Now you can manually change the severity of specific vulnerability occurrences to better align with your organization’s security needs. This allows you to:

- Adjust the severity level of any vulnerability to **Critical**, **High**, **Medium**, **Low**, **Info**, or **Unknown**.
- Change multiple vulnerabilities’ severity at once from the vulnerability report.
- Easily identify which vulnerabilities have custom severity levels through visual indicators.

All severity changes are tracked in the vulnerability history and audit events and can only be overridden by your team members who have at least the Maintainer role for the project, or a custom role with the `admin_vulnerability` permission. This feature gives security teams more flexibility and control over vulnerability prioritization.

## Agentic Core

### GitLab Duo Chat is now resizable

<!-- categories: Duo Chat -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/gitlab_duo_chat/_index.md#use-gitlab-duo-chat-in-the-gitlab-ui) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/499849)

{{< /details >}}

In the GitLab UI, you can now resize the Duo Chat drawer. This makes it easier to view code outputs, or keep Chat open whilst working with GitLab in the background.

### Manage multiple conversations in GitLab Duo Chat

<!-- categories: Duo Chat -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/gitlab_duo_chat/_index.md#have-multiple-conversations) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16108)

{{< /details >}}

Maintaining context across different topics in GitLab Duo Chat is now easier with multiple conversations. You can create new conversations, browse your conversation history, and switch between conversations.

Previously, starting a new conversation meant losing the context of your existing chat. Now, you can manage multiple conversations on different topics. Each conversation maintains its own context, so for example, you can ask follow-up questions about code explanations in one conversation, whilst preparing a work-plan in another conversation.

When you need to revisit previous discussions, select the new chat history icon to see all your recent conversations. Conversations are automatically organized by most recent activity, making it easy to pick up where you left off.

For your privacy, conversations with no activity for 30 days are automatically deleted, and you can manually delete any conversation at any time.

This feature is currently available only on GitLab.com in the web UI. It is not available in GitLab Self-Managed instances, nor in IDE integrations.

Share your experience with us in [issue 526013](https://gitlab.com/gitlab-org/gitlab/-/issues/526013).

### Select models for AI-powered features on GitLab Duo Self-Hosted

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#select-a-self-hosted-model-for-a-feature) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/524174)

{{< /details >}}

On GitLab Duo Self-Hosted, you can now select individual supported models for each GitLab Duo Chat sub-feature on your self-managed instance. Model selection and configuration for Chat sub-features is now in beta.

To leave feedback, go to [issue 524175](https://gitlab.com/gitlab-org/gitlab/-/issues/524175).

### AI Impact Dashboard available on GitLab Duo Self-Hosted Code Suggestions

<!-- categories: Self-Hosted Models, Value Stream Management, DORA Metrics -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/analytics/duo_and_sdlc_trends.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/523807)

{{< /details >}}

You can now use the AI Impact Dashboard with GitLab Duo Self-Hosted Code Suggestions on your self-managed instance to help you understand the impact of GitLab Duo on your productivity. The AI Impact Dashboard is in beta with GitLab Duo Self-Hosted, and you can use this feature with your self-managed instance and Visual Studio Code, Microsoft Visual Studio, JetBrains, and Neovim IDEs.

Use the AI Impact Dashboard to compare AI usage trends with metrics like lead time, cycle time, DORA, and vulnerabilities. This allows you to measure how much time is saved in your end-to-end workstream using GitLab Duo Self-Hosted, whilst staying focused on business outcomes rather than developer activity.

Please leave feedback on the AI Impact Dashboard in [issue 456105](https://gitlab.com/gitlab-org/gitlab/-/issues/456105).

### Meta Llama 3 models available for GitLab Duo Self-Hosted Code Suggestions and Chat

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/523917)

{{< /details >}}

You can now use select Meta Llama 3 models with GitLab Duo Self-Hosted. These models are in beta for GitLab Duo Self-Hosted to support GitLab Duo Chat and Code Suggestions.

Please leave feedback on using these models with GitLab Duo Self-Hosted in [issue 523912](https://gitlab.com/gitlab-org/gitlab/-/issues/523917).

## Scale and Deployments

### Timestamps of when placeholder users were created

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/import/mapping/post_migration_mapping.md#placeholder-user-attributes) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/507297)

{{< /details >}}

Previously, when you imported groups or projects, you could not see when [placeholder users](../../user/import/mapping/post_migration_mapping.md#placeholder-users) were created.
With this release, we’ve added timestamps so you can track the progress of your migration and troubleshoot any issues as they occur.

### Bulk edit to-do items

<!-- categories: Notifications -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/todos.md#bulk-edit-to-do-items) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/16564)

{{< /details >}}

You can now efficiently manage your To-Do List with our improved bulk editing feature. Select multiple to-do items and mark them as done or snooze them in one go, giving you more control over your tasks and helping you stay organized with less effort.

### Snooze to-do items

<!-- categories: Notifications -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/todos.md#snooze-to-do-items) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/17712)

{{< /details >}}

You can now snooze notifications in your To-Do List, allowing you to temporarily hide items and focus on what’s most important right now. Whether you need an hour to concentrate or want to revisit a task tomorrow, you’ll have fine-grained control over when notifications reappear, helping you manage your workflow more effectively.

### Request reassignment by using a CSV file

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/import/mapping/reassignment.md#request-reassignment-by-using-a-csv-file) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16765)

{{< /details >}}

With this release, user contribution mapping now supports bulk reassignment by using a CSV file.
If you have a large user base with many placeholder users, group members with the Owner role can:

1. Download a prefilled CSV template.
1. Add GitLab usernames or public emails from the destination instance.
1. Upload the completed file to reassign all contributions at once.

This method eliminates tedious manual reassignment through the UI.
To further streamline large-scale migrations, API support for CSV-based reassignment is now also available.

### New navigation experience for projects in Your Work

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/working_with_projects.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/465889)

{{< /details >}}

We’re excited to announce significant improvements to the project overview in **Your Work**, designed to streamline how you discover and access your projects. This update introduces a more intuitive tab-based navigation system that better reflects how users interact with their projects.

- The new **Contributed** tab (previously **Yours**) now displays all projects you’ve contributed to, including your personal projects, making it easier to track your development activity.
- Find your individual projects faster with the **Personal** tab, now prominently featured in the main navigation.
- Access team projects through the **Member** tab (formerly **All**), showing all projects where you have membership.
- The **Inactive** tab (previously **Pending deletion**) now provides a comprehensive view of both archived projects and those pending deletion.

Further, if you have the appropriate permissions, you can now edit or delete a project directly from the **Your Work** projects overview.
These changes reflect our commitment to creating a more efficient and user-friendly GitLab experience. The new layout helps you focus on the projects that matter most to your work, reducing the time spent navigating between different project categories.

We value your feedback on this update! Join the discussion in [epic 16662](https://gitlab.com/groups/gitlab-org/-/epics/16662) to share your experience with the new navigation system.

### Improved project creation permission settings

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../administration/settings/visibility_and_access_controls.md#define-which-roles-can-create-projects) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/507410)

{{< /details >}}

We’ve improved the project creation permission settings to make them more clear, intuitive, and aligned with our security principles. The improved settings include:

- Renamed the “Default project creation protection” dropdown to “Minimum role required for project creation” to clearly reflect the setting’s purpose.
- Renamed the “Developers + Maintainers” dropdown option to “Developers” for consistency across the platform.
- Reordered the dropdown options from most restrictive to least restrictive access level.

These changes make it easier to understand and configure which roles can create projects within your groups, helping administrators enforce appropriate access controls more confidently.

Thank you [@yasuk](https://gitlab.com/yasuk) for this community contribution!

## Unified DevOps and Security

### Dependency Scanning support for pub (Dart) package manager

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#supported-languages-and-package-managers) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/342468)

{{< /details >}}

Dependency Scanning has added support for pub, the official package manager for Dart. Support for this has been added to our Dependency Scanning [latest template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.latest.gitlab-ci.yml) and [CI/CD component](https://gitlab.com/explore/catalog/components/dependency-scanning).

This addition was a community contribution from one of our users, Alexandre Laroche. The GitLab Composition Analysis team appreciates this contribution to improve our product, many thanks, Alexandre. If you are interested in learning more about contributing to GitLab please check out our [Community Contribution program](https://about.gitlab.com/community/contribute/).

### Select a compliance framework as default from the dropdown list on the Frameworks page

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate, Premium
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/compliance_center/compliance_frameworks_report.md#set-and-remove-a-compliance-framework-as-default) | [Related epic](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181500)

{{< /details >}}

Users can set a default compliance framework in the GitLab compliance centre, which is applied to all new and
imported projects that are created in that group. A default compliance framework has a **default** label to help
users identify it.

To make it easier to set a compliance framework as default, we are introducing the ability for users
to set a framework as default by using the framework dropdown list on the list frameworks page in the compliance
center of a top-level group. This feature isn’t available in the compliance center of subgroups nor projects.

### Ignore specific revisions in Git blame

<!-- categories: Source Code Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/repository/files/git_blame.md#ignore-specific-revisions)

{{< /details >}}

When browsing the history of a repository, there might be commits that aren’t relevant to otherwise meaningful changes in the project. This can happen during:

- Refactors where you change from one library to another without changing functionality.
- Implementation of code formatters or linters that require standardizing the entire codebase.

When you look through the history of a project with `blame`, these kinds of commits make it difficult to understand the changes that occurred. Git supports identifying these commits with a `.git-blame-ignore-revs` file in your project. GitLab now allows you to toggle the blame view to show or hide these specific revisions in the “Blame preferences” dropdown list, making it easier to understand the history of your project.

### Path exclusions for CODEOWNERS

<!-- categories: Source Code Management, Code Review Workflow -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/codeowners/reference.md#exclusion-patterns)

{{< /details >}}

When teams configure a `CODEOWNERS` file, it’s common to include broad matching patterns for paths
and file types. These broad configurations can be problematic if your documentation, automated
build files, or other patterns don’t require a specified Code Owner.

You can now configure the `CODEOWNERS` file with path exclusions to ignore certain paths. This is helpful
when you want to exclude specific files, or paths from requiring a Code Owner approval.

### Configurable squash settings in branch rules

<!-- categories: Source Code Management, Code Review Workflow -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/repository/branches/branch_rules.md#edit-squash-commits-option)

{{< /details >}}

Different Git workflows require different strategies for handling commits when merging between branches. In previous versions of GitLab, you could only set a single strategy for whether commits should be squashed when merging and how strongly that should be enforced. This setup could be error-prone or require developers to make specific choices to follow the project convention for different branch targets.

You can now configure squash settings for each protected branch through branch rules. For example, you can:

- Require squashing when merging from your `feature` branch to the `develop` branch to keep history clean.
- Disable squashing when merging from the `develop` branch to `main` branch when you want the commit history to remain intact.

This flexibility ensures consistent commit history across your project while respecting the unique needs of each branch in your workflow, all without requiring manual developer intervention.

### Wider distribution for token expiration notifications

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/manage.md#expiry-emails-for-group-and-project-access-tokens) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/463016)

{{< /details >}}

Previously, access token expiry notification emails were only sent to direct members of the group and project in which the token was expiring. Now, these notifications are also sent to inherited group and project members, if the setting is enabled. This wider distribution makes it easier to manage the token before expiry.

### Handling of `needs` statements in pipeline execution policies for compliance

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/pipeline_execution_policies.md#pipeline_execution_policy-schema) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/469256)

{{< /details >}}

To strengthen your control over pipeline execution, jobs enforced in the `.pipeline-policy-pre` reserved stage are now required to complete before jobs in subsequent stages can begin, regardless of whether the job defines any `needs` statements. Previously, jobs defined in the `.pipeline-policy-pre` stage and jobs in subsequent pipelines with a `needs` statement both started as soon as the pipeline executed. With this enhancement, jobs in subsequent stages must wait for the `.pipeline-policy-pre` to complete before starting any other jobs without dependencies, helping you enforce ordered execution and ensuring compliance within the security policies.

Our customers rely on reserved stages to enforce compliance and security checks before developer jobs run. A common use case is to enforce a security or compliance check that fails the entire pipeline if the check does not pass. Allowing jobs to run out of order could bypass this enforcement and weaken policy intent. This improvement provides you with a more consistent approach to compliance enforcement.

To inject jobs at the beginning of the pipeline without overriding `needs` behavior, configure the jobs to use a custom stage with the new custom stages feature that we introduced in 17.9.

### Authenticate to private Pages with an access token

<!-- categories: Pages -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/pages/pages_access_control.md#authenticate-with-an-access-token)

{{< /details >}}

You can now authenticate to private GitLab Pages sites programmatically using access tokens, making it easier to automate interactions with your Pages content. Previously, accessing restricted Pages sites required interactive authentication through the GitLab UI.

This powerful enhancement increases productivity while maintaining security, giving developers more flexibility in how they interact with and distribute private Pages content.

### New insights into GitLab Duo Code Suggestions and GitLab Duo Chat trends

<!-- categories: Value Stream Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../user/analytics/duo_and_sdlc_trends.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/477246)

{{< /details >}}

The AI comparison metrics panel on the AI Impact Dashboard now provides month-over-month (MoM) tracking for GitLab Duo Code Suggestions acceptance rate and GitLab Duo Chat usage (MoM%). These new trend-based insights complement the existing Duo Code Suggestions and Duo Chat tiles, which provide a 30-day snapshot of these metrics.
With these additional metrics, managers can better measure the AI impact on their software development processes and identify patterns, by comparing Code Suggestions acceptance rate and Duo Chat usage with other SDLC metrics over time.

### Docker Hub authentication for the dependency proxy

<!-- categories: Container Registry -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/packages/dependency_proxy/_index.md#authenticate-with-docker-hub) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/331741)

{{< /details >}}

The GitLab Dependency Proxy for container images now supports authentication with Docker Hub, helping you avoid pipeline failures due to rate limits and giving you access to private images.

Starting April 1, 2025, Docker Hub will enforce stricter pull limits (100 per 6-hour window per IPv4 address or IPv6 /64 subnet) for unauthenticated users. Without authentication, your pipelines might fail once these limits are reached.

With this release, you can configure Docker Hub authentication through the GraphQL API using your Docker Hub credentials, [personal access token](https://docs.docker.com/security/for-developers/access-tokens/), or [organization access tokens](https://docs.docker.com/security/for-admins/access-tokens/). Support for UI configuration will be available in GitLab 17.11.

### Package registry adds audit events

<!-- categories: Package Registry -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/audit_event_types.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/329588)

{{< /details >}}

Package registry operations are now logged as audit events so teams can track when packages are published or deleted to meet compliance requirements.

Before this release, there was no built-in way to track who published or made changes to packages. Teams had to create their own tracking systems or manually document package changes to maintain logs of these activities. Now, each audit event shows who made a change, when it happened, how they were authenticated, and exactly what changed in the package.

Audit events for projects are stored either in a group namespace or the project itself for individual project Owners. Groups can turn off audit events to manage storage needs.

### Sort access tokens in Credentials Inventory

<!-- categories: System Access -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../administration/credentials_inventory.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/513181)

{{< /details >}}

You can now sort personal, project, and group access tokens in the Credentials Inventory by owner, created date, and last used date. This helps you to locate and identify your access tokens more quickly.
Thank you [Chaitanya Sonwane](https://gitlab.com/chaitanyason9) for your contribution!

### Identify and revoke tokens with token information API

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../api/admin/token.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/15777)

{{< /details >}}

GitLab administrators can now use a unified API to identify and revoke tokens. Previously, administrators had to use endpoints related to the specific type of token. This API allows revocation regardless of the type. For a list of supported token types, see the [Token information API](../../api/admin/token.md).

Thank you [Nicholas Wittstruck](https://gitlab.com/nwittstruck) and the team from Siemens for your contribution!

### Configurable token duration with GitLab OIDC provider

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/auth/oidc.md#configure-a-custom-duration-for-id-tokens) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/377654)

{{< /details >}}

When using GitLab as an OpenID Connect (OIDC) provider, you can now configure the duration of ID tokens with the `id_token_expiration` attribute. Previously, ID tokens had a fixed expiration time of 120 seconds.

Thank you [Henry Sachs](https://gitlab.com/DerAstronaut) for your contribution!

### Map OmniAuth profile attributes to user

<!-- categories: User Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../integration/omniauth.md#keep-omniauth-user-profiles-up-to-date) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/505575)

{{< /details >}}

You can now map the Organization and Title profile attributes from an OmniAuth identity provider (IdP) to a user’s GitLab profile. This allows the IdP to be the single source of truth for these attributes, and users can no longer change them.

### Extended webhook triggers for expiring tokens

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/manage.md#add-additional-webhook-triggers-for-group-access-token-expiration) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/499732)

{{< /details >}}

You can now trigger webhook events 60 and 30 days before a project or group access token expires. Previously, these webhook events only triggered 7 days before expiry. This is an optional setting that matches the existing email notification schedule for expiring tokens.

### GitLab Runner 17.10

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 17.10 today! GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s new

- [Perform Autoscaler executor health check before instance usage](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38271)
- [Expand Docker executor volumes](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38249)
- [Add Docker excecutor configuration for device addition for services](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/6208)

#### Bug Fixes

- [The Windows `gitlab-runner-helper` image fails due to invalid volume specification for the `/opt/step-runner’ path](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38632)
- [Repository mirroring for RPM packages is not working properly in GitLab Runner 17.7.0 and later](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38409)
- [Running `git submodule update --remote` in GitLab CI/CD returns an error](https://gitlab.com/gitlab-org/gitlab/-/issues/359825)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-10-stable/CHANGELOG.md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.10)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.10)
- [UI improvements](https://papercuts.gitlab.com/?milestone=17.10)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
