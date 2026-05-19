---
stage: Release Notes
group: Monthly Release
date: 2024-02-15
title: "GitLab 16.9 release notes"
description: "GitLab 16.9 released with GitLab Duo Chat Beta now available in Premium"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On February 15, 2024, GitLab 16.9 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor

Ravi is actively working with GitLab’s Vulnerability Research group
to address high false-positive results in [GitLab SAST.](https://gitlab.com/gitlab-org/security-products/sast-rules)

Ravi was nominated by [Rohan Shah](https://gitlab.com/rmsrohan), Customer Success Manager at GitLab, who noted
Ravi’s significant improvements to the [detection rules](../../user/application_security/sast/rules.md) used in GitLab SAST.
[Dinesh Bolkensteyn](https://gitlab.com/dbolkensteyn), Senior Vulnerability Researcher at GitLab, added
“Ravi’s feedback is spot on, directly actionable and enabled us to improve many of our SAST rules.”

Ravi Dharmawan a.k.a ravidhr works at GoTo Group as an Information Security Architect.
He works mostly on handling secure design review, source code review, and penetration testing.
Ravi is OSCP + eWPTXv2 certified.

Ian is the first GitLab MVP recognized for work [supporting users on the GitLab Forum.](https://forum.gitlab.com/u/iwalker/activity)[Michael Friedrich](https://gitlab.com/dnsmichi), Senior Developer Advocate at GitLab, and
[Fatima Sarah Khalid](https://gitlab.com/sugaroverflow), Developer Advocate at GitLab both nominated Ian
for continued efforts in helping make our forum a better place for the community by answering questions for users who are setting up and using GitLab.

Ian works at UpWare Sp. z o.o. as a System and Security Consultant, working mostly on Red Hat OpenShift and anything Linux-related.
He is Red Hat Certified RHCSA + RHCE and has been managing, maintaining and supporting his own self-hosted GitLab installation since 2017.
Ian has been regularly active on the GitLab forums for 3+ years with 2,600+ helpful responses, 480 helpful community moderation flags, and 240 solutions.

Thank you Ravi and Ian! 🙌

## Primary features

### GitLab Duo Chat Beta now available in Premium

<!-- categories: Duo Chat -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/gitlab_duo_chat/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/11251)

{{< /details >}}

In 16.8, we made GitLab Duo Chat available for self-managed instances. In 16.9, we are making Chat available to Premium customers while it is still in Beta.

GitLab Duo Chat can:

- Explain or summarize issues, epics, and code.
- Answer specific questions about these artifacts like “Collect all the arguments raised in comments regarding the solution proposed in this issue.”
- Generate code or content based on the information in these artifacts. For example, “Can you write documentation for this code?”
- Help you start a process. For example, “Create a .GitLab-ci.yml configuration file for testing and building a Ruby on Rails application in a GitLab CI/CD pipeline.”
- Answer all your DevSecOps related question, whether you are a beginner or an expert. For example, “How can I set up Dynamic Application Security Testing for a REST API?”
- Answer follow-up questions so you can iteratively work through all the previous scenarios.

GitLab Duo Chat is available as a Beta feature. It is also integrated into our Web IDE and GitLab Workflow extension for VS Code as Experimental features. In these IDEs, you can also use [predefined chat commands that help you do standard tasks more quickly](../../user/gitlab_duo_chat/examples.md) like writing tests.

You can help us mature these features by providing feedback about your experiences with GitLab Duo Chat, either within the product or through our [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/430124).

### Request changes on merge requests

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/project/merge_requests/reviews/_index.md#submit-a-review)

{{< /details >}}

The last part of reviewing a merge request is communicating the outcome. While approving was unambiguous, leaving comments was not. They required the author to read your comments, then determine if the comments were purely informational, or described needed changes. Now, when you complete your review, you can select from three options:

- **Comment**: Submit general feedback without explicitly approving.
- **Approve**: Submit feedback and approve the changes.
- **Request changes**: Submit feedback that should be addressed before merging.

The sidebar now shows the outcome of your review next to your name. Currently, ending your review with **Request changes** doesn’t block the merge request from being merged, but it provides extra context to other participants in the merge request.

You can leave feedback about the **Request changes** feature in our [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/438573).

### Improvements to the CI/CD variables user interface

<!-- categories: Secrets Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../ci/variables/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/418331)

{{< /details >}}

In GitLab 16.9, we have released a series of improvements to the CI/CD variables user experience. We have improved the variables creation flow through changes including:

- [Improved validation when variable values do not meet the requirements](https://gitlab.com/gitlab-org/gitlab/-/issues/365934).
- [Help text during variable creation](https://gitlab.com/gitlab-org/gitlab/-/issues/410220).
- [Allow resizing of the value field in the variables form](https://gitlab.com/gitlab-org/gitlab/-/issues/434667).

Other improvements include a new, [optional description field for group and project variables](https://gitlab.com/gitlab-org/gitlab/-/issues/378938) to assist with the management of variables. We have also made it easier to [add or edit multiple variables](https://gitlab.com/gitlab-org/gitlab/-/issues/434666), lowering the friction in the software development workflow and enabling developers to perform their job more efficiently.

Your [feedback for these changes](https://gitlab.com/gitlab-org/gitlab/-/issues/441177) is always valued and appreciated.

### Expanded options for auto-canceling pipelines

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../ci/yaml/_index.md#workflowauto_cancelon_new_commit) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/412473)

{{< /details >}}

Currently, to use the [auto-cancel redundant pipeline feature](../../ci/pipelines/settings.md#auto-cancel-redundant-pipelines), you must set jobs that can be cancelled as [`interruptible: true`](../../ci/yaml/_index.md#interruptible) to determine whether or not a pipeline can be cancelled. But this only applies to jobs that are actively running when GitLab tries to cancel the pipeline. Any jobs that have not yet started (are in “pending” status) are also considered safe to cancel, regardless of their `interruptible` configuration.

This lack of flexibility hinders users who want more control over which exact jobs can be cancelled by the auto-cancel pipeline feature. To address this limitation, we are pleased to announce the introduction of the `auto_cancel:on_new_commit` keywords with more granular control over job cancellation. If the legacy behavior did not work for you, you now have the option to configure the pipeline to only cancel jobs that are explicitly set with `interruptible: true`, even if they haven’t started yet. You can also set jobs to never be automatically cancelled.

## Scale and Deployments

### Limit concurrent code-indexing jobs for advanced search

<!-- categories: Global Search -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../integration/advanced_search/elasticsearch.md#advanced-search-configuration) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/435402)

{{< /details >}}

As a GitLab administrator, you can now set the maximum number of Elasticsearch code-indexing background jobs that can run concurrently. Previously, you could only limit the number of concurrent jobs by creating dedicated Sidekiq processes.

### Custom guidelines for managing group and project members

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/appearance.md#member-guidelines) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/433093)

{{< /details >}}

Administrators can now add text guidelines that are visible to users with permissions to manage members on the **Members** page of a group or project. Administrators can access these guidelines in the **Appearance** section of the **Admin Area** settings.

Guidelines are helpful for teams that use external tooling to manage members of groups or projects. For instance, the guideline can link to predefined groups that users should use instead of managing membership for individual members.

Thank you @bufferoverflow for this community contribution!

### Show import stats for direct transfer

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/import/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/437874)

{{< /details >}}

Completed migrations of GitLab groups and projects by direct transfer have displayed badges (**Complete**, **Partially completed**, and **Failed**)
to inform users about the general end result of the migration. Users could also access a list of items that were not imported, by clicking on the **See failures** link.

However, for a partially-imported project, there was no quick way to understand how many items of each type were successfully imported and how many were not.

In this release, we added import results statistics for groups and projects. To access the statistics, select the **Details** link on the direct transfer history page.

### Enable Jira issues at the group level

<!-- categories: Settings -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../integration/jira/configure.md#view-jira-issues) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/325715)

{{< /details >}}

With this release, you can enable Jira issues for all projects in a GitLab group. Previously, you could only enable Jira issues for each GitLab project individually.

### REST API support for the GitLab for Slack app

<!-- categories: Settings -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/group_integrations.md#gitlab-for-slack-app) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/364440)

{{< /details >}}

With this release, we’ve added REST API support for the GitLab for Slack app.

You cannot create a GitLab for Slack app from the API. Instead, you must [install the app](../../user/project/integrations/gitlab_slack_application.md#install-the-gitlab-for-slack-app) from the GitLab UI. You can then retrieve the integration settings and update or disable the app for a project.

### Access GitLab usage data through the REST API

<!-- categories: Application Instrumentation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../api/usage_data.md#export-service-ping-data) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/12251)

{{< /details >}}

Self-managed users can now seamlessly access Service Ping data through a REST API connection, facilitating direct integration with downstream systems. This represents a significant improvement over the previous method of file download. The new approach offers self-managed users a more efficient and real-time means of conducting customized analysis and deriving specific insights from their GitLab usage data.

## Unified DevOps and Security

### Authenticate and sign commits with SSH certificates

<!-- categories: Source Code Management -->

{{< details >}}

- Tier: Silver, Gold
- Links: [Documentation](../../user/group/ssh_certificates.md)

{{< /details >}}

Previously, Git access control options on GitLab.com relied on credentials set up in the user account. Now you can set up a process to make Git access possible using only SSH certificates. You can also use these certificates to sign commits.

### Limit workspaces per user on the GitLab agent

<!-- categories: Workspaces -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/workspace/gitlab_agent_configuration.md)

{{< /details >}}

In GitLab 16.8, we introduced settings for the GitLab agent for Kubernetes to limit the CPU and memory usage per workspace.

Now in 16.9, you can also limit the number of workspaces per user. With this new setting, you have even more control over your cloud resources and can prevent individual developers from inflating cloud spend.

### Allow users to cleanup partial resources from failed deployments

<!-- categories: Environment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/environments/_index.md#run-a-pipeline-job-when-environment-is-stopped) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/435128)

{{< /details >}}

The Environment [`auto_stop_in`](../../ci/yaml/_index.md#environmentauto_stop_in) functionality was updated to run the job from the last finished pipeline, instead of the last successful pipeline. This avoids edge cases where the auto stop job can not run because of not having any successful pipelines.

This behaviour might be considered a breaking change in some situations. The new behaviour is currently behind a feature flag, and will become the default in 17.0, and at the same time, we are going to deprecate the old behaviour to be removed from GitLab in 18.0. We recommend everyone to start transitioning or to configure the feature flag immediately to minimize the risks of the breaking change at the first 17.x upgrade.

### Kubernetes 1.29 support

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/clusters/agent/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/435293)

{{< /details >}}

This release adds full support for Kubernetes version 1.29, released in December 2023. If you deploy your apps to Kubernetes, you can now upgrade your connected clusters to the most recent version and take advantage of all its features.

You can read more about our Kubernetes support policy and other supported Kubernetes versions.

### Enterprise user email address accessible through UI and API

<!-- categories: User Management -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/enterprise_user/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/391453)

{{< /details >}}

Group Owners that have [enterprise users](../../user/enterprise_user/_index.md) can now use both the user management UI and the [group and project members API](../../api/group_members.md) to see those users’ email addresses. Previously, only provisioned users’ email addresses were returned.

### Add or remove service accounts from groups with LDAP group sync

<!-- categories: User Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/group/access_and_permissions.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/425947)

{{< /details >}}

Previously, if a group had LDAP sync enabled, administrators were not able to invite or remove any users from that group. Now, administrators can use the group and project members API to invite service account users to or remove those users from a group with LDAP sync. Administrators still cannot invite human users to or remove those users from a group with LDAP sync. This ensures that LDAP group sync is the single source of truth for human user account membership, while allowing the flexibility to use service accounts to add automations to LDAP-synced groups.

### Audit event for updating or deleting a custom role

<!-- categories: Permissions -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../administration/compliance/audit_event_reports.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/437672)

{{< /details >}}

GitLab now records an audit event when a custom role is updated or deleted. This event is important to identify if permissions have been added or changed in case of privilege escalation.

### Improved UX for expired SAML SSO sessions

<!-- categories: System Access -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/group/saml_sso/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/414475)

{{< /details >}}

If you belong to a group that requires SAML SSO authentication, but you do not have a valid session for that group, a banner is displayed that prompts you to refresh your session. Previously, issues and merge requests were not displayed when a session had expired, but this was not clear to the user. Now, it is clear to users when they must reauthenticate to see all of their work items.

### Standards Adherence Report Improvements

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/compliance_center/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/11053)

{{< /details >}}

The [standards adherence report](../../user/compliance/compliance_center/_index.md), within the
[compliance center](../../user/compliance/compliance_center/_index.md), is the destination for compliance teams to monitor their compliance posture.

In GitLab 16.5, we introduced the report with the GitLab Standard - a set of common compliance requirements all compliance teams should monitor. The standard helps
you understand which projects meet these requirements, which ones fall short, and how to bring them into compliance. Over time, we’ll be introducing more standards
into the reporting.

In this milestone, we’ve made some improvements which will make reporting more robust and actionable. These include:

- Grouping results by check
- Filtering by project, check, and standard
- Export to CSV (delivered via email)
- Improved pagination

### Rich text editor broader availability

<!-- categories: Team Planning, Portfolio Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/rich_text_editor.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/7098)

{{< /details >}}

In GitLab 16.2, [we released](https://about.gitlab.com/releases/2023/07/22/gitlab-16-2-released/) the rich text editor as an alternative to the plain text editor. The rich text editor provides a “what you see is what you get” editing interface, and an extensible foundation for additional development. Until this release, however, the rich text editor was available only in issues, epics, and merge requests.

With GitLab 16.9, the rich text editor is now available in:

- [Requirements descriptions](https://gitlab.com/gitlab-org/gitlab/-/issues/407493)
- [Vulnerability findings](https://gitlab.com/gitlab-org/gitlab/-/issues/407491)
- [Release descriptions](https://gitlab.com/gitlab-org/gitlab/-/issues/407494)
- [Design notes](https://gitlab.com/gitlab-org/gitlab/-/issues/407505)

With improved access to the rich text editor, you can collaborate more efficiently and without previous Markdown experience.

### Allow duplicate Terraform modules

<!-- categories: Package Registry -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/packages/terraform_module_registry/_index.md#allow-duplicate-terraform-modules) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/368040)

{{< /details >}}

You can use the GitLab package registry to publish and download Terraform modules. By default, you cannot publish the same module name and version more than once per project.

However, you might want to allow duplicate uploads, especially for releases. In this release, GitLab expands the group setting for the package registry so you can allow or deny duplicate modules.

### Validate Terraform modules from your group or subgroup

<!-- categories: Package Registry -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/packages/package_registry/_index.md#view-packages) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/352041)

{{< /details >}}

When using the GitLab Terraform registry, it is important to have a cross-project view of all your modules. Until recently, the user interface has been available only at the project level. If your group had a complex structure, you might have had difficulty finding and validating your modules.

From GitLab 16.9, you can view all of your group and subgroup modules in GitLab. The increased visibility provides a better understanding of your registry, and decreases the likelihood of name collisions.

### Boards work in progress line

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/project/issue_board.md#work-in-progress-limits) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/440540)

{{< /details >}}

You can now visualize your work in progress limits in a board list. When a limit has been exceeded, an indicator line will appear in the list to help you understand which items are over the limit and manage the list accordingly.

### New stage events for custom Value Stream Analytics

<!-- categories: Value Stream Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/value_stream_analytics/_index.md#value-stream-stage-events) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/431934)

{{< /details >}}

To improve the [tracking of development workflows in GitLab](https://about.gitlab.com/blog/value-stream-total-time-chart/), the Value Stream Analytics has been extended with a new stage event: `Issue first added to iteration`. You can use this event to detect problems caused by a lack of agility from teams planning too far ahead or execution challenges in teams that have issues rolling over from iteration to iteration. For example, you can now add a “Planned” stage that starts when `Issue first added to iteration` and ends when the `Issue first assigned`.

### Improvements to Operational Container Scanning

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/clusters/agent/vulnerabilities.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/11968)

{{< /details >}}

We’ve made reporting and stability improvements to Operational Container Scanning (OCS). Notably, the Trivy report size limit has been increased, which provides a more stable experience for users. Expanding the Trivy report size from 10MB to 100MB allows customers who were constrained by the report size limit to leverage OCS in securing container images in their cluster.

With this change to OCS, users who run `gitlab-agent` in FIPS mode cannot run Operational Container Scanning. For more details on this, see our documentation and please provide feedback in issue [#440849](https://gitlab.com/gitlab-org/gitlab/-/issues/440849).

### DAST analyzer updates

<!-- categories: DAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dast/browser/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/12685)

{{< /details >}}

We resolved the following bugs during the 16.9 release milestone:

- Browser-based DAST errors when attempting to get the response body for cached resources when the browser has transitioned to a new page. [See the issue](https://gitlab.com/gitlab-org/gitlab/-/issues/435175) for more details.
- Browser-based DAST crawl tasks are not running in parallel, causing performance degradation. [See the issue](https://gitlab.com/gitlab-org/gitlab/-/issues/435325) for more details.

### Updated SAST rules for higher-quality results

<!-- categories: SAST -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/rules.md#important-rule-changes) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10971)

{{< /details >}}

We’ve updated more than 40 default GitLab SAST rules to:

- Increase true-positive results (correctly identified vulnerabilities) and reduce false-negative results (incorrectly identified vulnerabilities) by updating the detection logic rules for C#, Go, Java, JavaScript, and Python.
- Add [OWASP mappings](https://gitlab.com/gitlab-org/gitlab/-/issues/438561) for C#, Go, Java, and Python rules.

The rule changes are included in updated versions of the Semgrep-based GitLab SAST [analyzer](../../user/application_security/sast/analyzers.md).
This update is automatically applied on GitLab 16.0 or newer unless you’ve [pinned SAST analyzers to a specific version](../../user/application_security/sast/_index.md).
We’re working on more SAST rule improvements in [epic 10907](https://gitlab.com/groups/gitlab-org/-/epics/10907).

### More detailed security findings in VS Code

<!-- categories: Editor Extensions, API Security, Container Scanning, DAST, Fuzz Testing, SAST, Secret Detection, Software Composition Analysis, Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../editor_extensions/visual_studio_code/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10996)

{{< /details >}}

We’ve improved how security findings are shown in the [GitLab Workflow extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#security-findings) for Visual Studio Code (VS Code).
You can now see more details of your security findings that weren’t previously shown, including:

- Full descriptions, with rich-text formatting.
- The solution to the vulnerability, if one is available.
- A link to the location where the problem occurs in your codebase.
- Links to more information about the type of vulnerability discovered.

We’ve also:

- Improved how the extension shows the status of security scans before results are ready.
- Made other usability improvements.

### Control which roles can cancel pipelines or jobs

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/pipelines/settings.md#restrict-roles-that-can-cancel-pipelines-or-jobs) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/410634)

{{< /details >}}

Organizations might want to control which user roles are able to cancel a pipeline. Previously, anyone who could run a pipeline could also cancel a pipeline. Now, a project Maintainer is able to update a setting which restricts pipeline and job cancellation to specific roles, or even prevents cancellation completely!

### Fleet Dashboard: Compute minutes used on instance runners per project metric card

<!-- categories: Fleet Visibility -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../ci/runners/runner_fleet_dashboard.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/421457)

{{< /details >}}

When managing a GitLab Runner Fleet at scale, you have told us that knowing which projects use the most compute minutes on the runners is critical. For you, this information is essential to help teams optimize CI/CD pipelines and also help you make the right decisions about fleet cost optimization.

Now, the runner compute usage by project metric card, a complement to the previously released CI/CD compute minutes export by CSV feature, is available in the Runner Fleet Dashboard. You can see the top projects that consume instance runner minutes, and the most used instance runners in your GitLab environment.

### GitLab Runner 16.9

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 16.9 today! GitLab Runner is the lightweight, highly-scalable agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s new

- [Make Kubernetes API retries configurable](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37349)

#### Bug Fixes

- [Random warning: failed to remove ***: Directory not empty](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/3185)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-9-stable/CHANGELOG.md).

### Show MR link for branch based pipelines

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/pipelines/_index.md#view-pipelines) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/416134)

{{< /details >}}

If you use branch pipelines, you can now quickly view and access the related merge requests from the pipeline details page.

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.9)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.9)
- [UI improvements](https://papercuts.gitlab.com/?milestone=16.9)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
