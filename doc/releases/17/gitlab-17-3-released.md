---
stage: Release Notes
group: Monthly Release
date: 2024-08-15
title: "GitLab 17.3 release notes"
description: "GitLab 17.3 released with Troubleshoot failed jobs with root cause analysis"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On August 15, 2024, GitLab 17.3 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Anton Kalmykov

Everyone can [nominate GitLab’s community contributors](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)!
Show your support for our active candidates or add a new nomination! 🙌

Anton Kalmykov is one of GitLab’s top contributors this year with 37 [merged contributions](https://gitlab.com/gitlab-org/gitlab/-/merge_requests?scope=all&state=merged&author_username=antonkalmykov)
since February and more in progress.
Anton is a Senior Frontend Engineer at [Yolo group (Bombay Games)](https://yolo.com/).

“Contributing to GitLab is one of the most challenging, ambitious, and exciting initiatives,” says Anton.
“I appreciate the opportunity to be involved in creating and improving such a great product.
Thanks to this chance, I have learned a lot of new things, and I still have a lot to do.
I am incredibly grateful to the GitLab team, especially those who have checked my MRs, guided me,
and helped me do things right.”

Anton was nominated by [Christina Lohr](https://gitlab.com/lohrc), Senior Product Manager at GitLab,
for helping out the Tenant Scale
group with several frontend issues.

“We have a lot of smaller UX improvements to work through for our basic workflows, and it is great
to get help from the community to complete these initiatives faster,” says Christina.
“All these improvements are helping to create a more cohesive user experience between groups and projects.
Thank you Anton.”

Many thanks to Anton and the rest of GitLab’s open source contributors for co-creating GitLab!

## Primary features

### Troubleshoot failed jobs with root cause analysis

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13080)

{{< /details >}}

Root cause analysis is now generally available. With root cause analysis, you can troubleshoot failed jobs in CI/CD pipelines faster. This AI-powered feature analyzes the failed job log, quickly determines the root cause of the job failure, and suggests a fix for you.

### Health check for GitLab Duo in beta

<!-- categories: Duo Chat -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../administration/gitlab_duo/configure/_index.md#run-a-health-check-for-gitlab-duo) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/14518)

{{< /details >}}

You can now troubleshoot the setup for GitLab Duo on your self-managed instance. In the **Admin** area, on the GitLab Duo page, select **Run health check**.
This health check performs a series of validations and suggests appropriate corrective actions to ensure GitLab Duo is operational.

The health check for GitLab Duo is available on Self-managed and GitLab Dedicated as a beta feature.

### Delete a pod from the GitLab UI

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/environments/kubernetes_dashboard.md#delete-a-pod) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/467653)

{{< /details >}}

Have you ever needed to restart or delete a failing pod in Kubernetes? Until now, you had to leave GitLab, use another tool to connect to the cluster, stop the pod, and wait for a new pod to start. GitLab now has built-in support for deleting pods, so you can smoothly troubleshoot your Kubernetes clusters.

You can stop a pod from a [dashboard for Kubernetes](../../ci/environments/kubernetes_dashboard.md), which lists all the pods across your cluster or namespace.

### Easily connect to a cluster from your local terminal

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/clusters/agent/user_access.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/463769)

{{< /details >}}

Do you want to connect to a Kubernetes cluster from your local terminal or using one of the desktop Kubernetes GUI tools?
GitLab allows you to connect to a terminal using the [user access feature of the agent for Kubernetes](../../user/clusters/agent/user_access.md).
Previously, finding commands required navigating out of GitLab to browse the documentation. Now, GitLab provides the connect command from the UI. GitLab can even help you configure user access!

To retrieve the connection command, either go to a [Kubernetes dashboard](../../ci/environments/kubernetes_dashboard.md), or to the [agent list](../../user/clusters/agent/work_with_agent.md#view-your-agents).

### Resolve a vulnerability with AI

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../user/application_security/vulnerabilities/_index.md#vulnerability-resolution) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10783)

{{< /details >}}

Vulnerability resolution uses AI to give specific code suggestions for users to fix vulnerabilities. With the click of a button you can open a merge request to get started resolving any SAST vulnerability from the [list of supported CWE identifiers](../../user/application_security/vulnerabilities/_index.md#supported-vulnerabilities-for-vulnerability-resolution).

### Add multiple compliance frameworks to a single project

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/working_with_projects.md#add-a-compliance-framework-to-a-project) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13294)

{{< /details >}}

You can create a compliance framework to identify that your project has certain compliance requirements or needs additional oversight.
The compliance framework can optionally enforce compliance pipeline configuration to the projects on which it is applied.

Previously, users could only apply one compliance framework to a project, which limited how many compliance requirements could be set on a project.
We have now provided the ability for a user to apply multiple compliance frameworks per project.
This will allow users to apply multiple different compliance frameworks onto a single project at a given time.
With this release, you can apply multiple compliance frameworks to a project. The project is then set with the compliance requirements of each framework.

### AI Impact analytics: Code Suggestions acceptance rate and GitLab Duo seats usage

<!-- categories: Value Stream Management, Code Suggestions -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../user/analytics/value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/471168)

{{< /details >}}

These two new metrics highlight the effectiveness and utilization of GitLab Duo, and are now included in the [AI Impact analytics in the Value Streams Dashboard](https://about.gitlab.com/blog/developing-gitlab-duo-ai-impact-analytics-dashboard-measures-the-roi-of-ai/), which helps organizations understand the impact of GitLab Duo on delivering business value.

The **Code Suggestions acceptance rate** metric indicates how frequently developers accept code suggestions made by GitLab Duo. This metric reflects both the effectiveness of these suggestions and the level of trust contributors have in AI capabilities. Specifically, the metric represents the percentage of code suggestions provided by GitLab Duo that have been accepted by code contributors in the last 30 days.

The **GitLab Duo seats assigned and used** metric shows the percentage of consumed licensed seats, helping organizations plan effectively for license utilization, resource allocation, and understanding of usage patterns. This metric tracks the ratio of assigned seats that have used at least one AI feature in the last 30 days.

With the addition of these new metrics, we have also introduced new overview tiles — a new visualization which provides a clear summary of the metrics, helping you quickly assess the current state of your AI features.

## Scale and Deployments

### Omnibus improvements

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

GitLab 17.3 includes packages for supporting [Raspberry Pi OS 12](https://www.raspberrypi.com/news/bookworm-the-new-version-of-raspberry-pi-os/).

Debian 10 has reached [EOL on June 30th, 2024](https://www.debian.org/releases/buster/). GitLab will remove support for Debian 10 in GitLab 17.6.

### Improved sorting and filtering for projects and groups in Your Work

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/working_with_projects.md#explore-all-projects-on-an-instance) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/25368)

{{< /details >}}

We have updated the sorting and filtering functionality of the project and group overview in **Your Work**.
Previously, in the **Your Work** page for projects, you could filter by name and language, and use a pre-defined set of sorting options. We have standardized the sorting options to include **Name**, **Created date**, **Updated date**, and **Stars**. We also added a navigation element to sort in ascending or descending order, and moved the language filter to the filter menu. Now you can find archived projects in the new **Inactive** tab. Additionally, we added a **Role** filter that allows you to search for projects you are the Owner of.

In the Your Work page for groups, we have standardized the sorting options to include **Name**, **Created date**, and **Updated date**, and added a navigation element to sort in ascending or descending order.

We welcome feedback about these changes in [#438322](https://gitlab.com/gitlab-org/gitlab/-/issues/438322).

### End-to-end instance indexing for advanced search

<!-- categories: Global Search -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../integration/advanced_search/elasticsearch.md#index-the-instance) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/271532)

{{< /details >}}

When you enable advanced search in GitLab, you can now select **Index the instance** to perform initial indexing or re-create an index from scratch. This setting achieves functional parity with the `gitlab:elastic:index` rake task by indexing all supported types of data into the integrated Elasticsearch or OpenSearch cluster.

**Index the instance** replaces the setting to index all projects, which was limited to the initial indexing only.

### Toggle inheriting settings for integrations by using the API

<!-- categories: Settings -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/integrations/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)

{{< /details >}}

Until now, you could only control whether a project inherited integration settings, or used its
own settings, using the UI.

In this milestone, we are introducing a new `use_inherited_settings` parameter to the REST API of all integrations. This parameter allows you to use the API to set
whether or not a project inherits integration settings. If not set, the default behavior is `false` (use the project’s own settings).

### List group or project webhook events with the API

<!-- categories: Notifications -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/project_webhooks.md#list-project-webhook-events) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/437188)

{{< /details >}}

Since GitLab 9.3 you can view project webhook request history in the UI, and since GitLab 15.3 you can also [view group webhook request history in the UI](../../user/project/integrations/webhooks.md#view-webhook-request-history).

In this release, that data is now exposed in the REST API, which can help you automate processes to discover and respond to webhook errors. You can get a list of events for a specific [project hook](../../api/project_webhooks.md#list-project-webhook-events) and [group hook](../../api/group_webhooks.md#list-all-group-hook-events) in the past 7 days.

Thanks to [Phawin](https://gitlab.com/lifez) for [this community contribution](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151048)!

### Find group settings by using the command palette

<!-- categories: Settings, Global Search -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/search/command_palette.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/448646)

{{< /details >}}

In 17.2, we added the ability to [search for project settings by using the command palette](https://about.gitlab.com/releases/2024/07/18/gitlab-17-2-released/#find-project-settings-by-using-the-command-palette). This change made it easier to quickly find the settings you need.

With 17.3, you can now search for group settings from the command palette as well. Try it out by visiting a group, selecting **Search or go to**, entering command mode with `>`, and typing the name of a settings section, like **Merge request approvals**. Select a result to jump right to the setting itself.

## Unified DevOps and Security

### Granular control of code suggestions by language in VS Code

<!-- categories: Editor Extensions -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/project/repository/code_suggestions/supported_extensions.md#manage-languages-for-code-suggestions) | [Related issue](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1388)

{{< /details >}}

Get more control over your coding experience in VS Code by enabling or disabling code suggestions for specific programming languages. This granular control allows you to customize your workflow, reducing irrelevant or intrusive suggestions while maintaining the benefits of code suggestions for your preferred languages.

### Improved TLS support in JetBrains IDEs

<!-- categories: Editor Extensions -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../editor_extensions/jetbrains_ide/jetbrains_troubleshooting.md#certificate-errors) | [Related issue](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/371)

{{< /details >}}

For tighter security in sensitive environments, you can now configure custom HTTP agent options, including client certificates and certificate authorities, directly in your JetBrains IDE settings.

### More easily remove content from repositories

<!-- categories: Source Code Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/repository/repository_size.md#remove-blobs)

{{< /details >}}

Currently, the process for removing content from a repository is complicated, and you might have to force push the project to GitLab.
This is prone to errors and can cause you to temporarily turn off protections to enable the push.
It can be even harder to delete files that use too much space within the repository.

You can now use the new repository maintenance option in project settings to remove blobs based on a list of object IDs.
With this new method, you can selectively remove content without the need to force push a project back to GitLab.

In the event that secrets or other content has been pushed that needs to be redacted from a project, we’re also introducing a new option to redact text.
Provide a string that GitLab will replace with `***REMOVED***` in files across the project.
After the text has been redacted, run housekeeping to remove old versions of the string.

This new UI streamlines the way you can manage your repositories when content needs to be removed.

### Audit event when agent for Kubernetes is created and deleted

<!-- categories: Audit Events -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/audit_event_types.md#deployment-management) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/462749)

{{< /details >}}

Because the agent for Kubernetes allows bi-directional data flow between a Kubernetes cluster and GitLab, it’s important to know when a component that can access your systems is added or removed.
In past releases, compliance teams had to use custom tooling or search for this data in GitLab directly. GitLab now provides the following audit events:

- `cluster_agent_created` records who registered a new agent for Kubernetes.
- `cluster_agent_create_failed` records who tried to register a new agent for Kubernetes but failed.
- `cluster_agent_deleted` records who removed an agent for Kubernetes registration.
- `cluster_agent_delete_failed` records who tried to remove an agent for Kubernetes registration but failed.

These audit events extend the `cluster_agent_token_created` and `cluster_agent_token_revoked` audit events to further improve the ability to audit your GitLab instance.

### Kubernetes 1.30 support

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/456929)

{{< /details >}}

This release adds full support for Kubernetes version 1.30, released in April 2024. If you deploy your apps to Kubernetes, you can now upgrade your connected clusters to the most recent version and take advantage of all its features.

You can read more about [our Kubernetes support policy and other supported Kubernetes versions](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features).

### Add authentication to merge request external status checks

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/merge_requests/status_checks.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/433035)

{{< /details >}}

External status checks can now be configured with HMAC (Hash-based Message Authentication Code) authentication. This will provide a more secure way to verify the authenticity of requests from GitLab to external services.

When enabled for your status check, a shared secret is used to generate a unique signature for each request. The signature is sent in the `X-Gitlab-Signature` header, using SHA256 as the hash algorithm.

- Improved Security: HMAC authentication prevents tampering with requests and ensures they come from a legitimate source.
- Compliance: This feature is particularly valuable for regulated industries, such as banking, where security is paramount.
- Backwards Compatibility: The feature will be optional and backwards compatible. Users can choose to enable HMAC authentication for new or existing checks, but existing external status checks will continue to function without changes.

In a [future iteration](https://gitlab.com/gitlab-org/gitlab/-/issues/476163), GitLab plans to add an option to also verify and block HTTP requests.

### Filter the member list in a group or project by role

<!-- categories: Permissions -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/members/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/431397)

{{< /details >}}

Users can now filter the Members page by role. Use the filter to find members with a specific role.

### View role details in the right drawer

<!-- categories: Permissions -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/custom_roles/_index.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/13061)

{{< /details >}}

Previously, if you wanted to view permissions for the custom roles of a user, you had to have the Owner role in the group. This requirement made it difficult to troubleshoot and understand what actions a user can perform when assigned a custom role. Now, any user can view the permissions of a user assigned a custom role in the Members page.

### LDAP group link support for custom roles

<!-- categories: Permissions -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/access_and_permissions.md#manage-group-memberships-with-ldap) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/435229)

{{< /details >}}

Organizations that use LDAP group links to manage user permissions for groups can already use default roles for membership.

In this release, we’re extending that support to [custom roles](../../user/custom_roles/_index.md). This configuration makes it easier to map access to a
large group of users.

### New permission for custom roles

<!-- categories: Permissions -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/custom_roles/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/391760)

{{< /details >}}

You can create custom roles with the following new permission:

- [Read Runners](../../user/custom_roles/abilities.md#runner)

With custom roles, you can reduce the number of users with the Owner role by creating users with equivalent permissions. This helps you define roles that are tailored to the needs of your group, and prevents users from being given more privileges than they need.

### Disable personal access tokens using Admin UI

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/profile/personal_access_tokens.md#view-token-usage-information) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/436991)

{{< /details >}}

Administrators can now disable or re-enable instance personal access tokens through the Admin UI. Previously, administrators had to use the application settings API or the GitLab Rails console to do this.

### Bluesky identifier in user profile

<!-- categories: User Profile -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/_index.md#add-external-accounts-to-your-user-profile-page) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/451690)

{{< /details >}}

You can now add your Bluesky did:plc identifier to your GitLab profile.

Thank you [Dominique](https://domi.zip/) for your contribution!

### Subdomain cookies preserved on sign out

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/active_sessions.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/471097)

{{< /details >}}

GitLab’s sign out process has been improved so that cookies from sibling subdomains are not deleted on sign out. Previously, these cookies were deleted, causing users to be signed out of other subdomain services on the same top-level domain as GitLab. For example, if a user has Kibana set up on `kibana.example.com` and GitLab set up on `gitlab.example.com`, signing out from GitLab will no longer sign the user out from Kibana.

Thank you [Guilherme C. Souza](https://gitlab.com/GCSBOSS) for your contribution!

### AI Impact analytics with enhanced sparklines trend visualization

<!-- categories: Value Stream Management, Code Suggestions -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../user/analytics/duo_and_sdlc_trends.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/464692)

{{< /details >}}

We are excited to announce a significant improvement to our [AI Impact analytics](https://about.gitlab.com/blog/developing-gitlab-duo-ai-impact-analytics-dashboard-measures-the-roi-of-ai/) with the introduction of sparklines. These small, simple graphs embedded in data tables enhance the readability and accessibility of AI Impact data. By transforming numerical values into visual representations, the new sparklines make it easier to identify trends over time, so you can spot upward or downward movements. This new visual approach also streamlines the process of comparing trends across multiple metrics, reducing the time and effort required when relying solely on numbers.

### Add merge requests to tasks

<!-- categories: Team Planning -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/tasks.md#add-a-merge-request-and-automatically-close-tasks) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/440851)

{{< /details >}}

Tasks are frequently used to break down issues into engineering implementation steps. Before this release, there was no way to connect a merge request to a task it implements. You can now use the same [closing pattern](../../user/project/issues/managing_issues.md#closing-issues-automatically) that you would when referencing issues from a merge request description to connect a merge request to a task. From the task view, connected merge requests are visible from the sidebar. If your project has the [auto-close setting enabled](../../user/project/issues/managing_issues.md#disable-automatic-issue-closing), the task will automatically close when the connected merge request is merged into your default branch.

### Set parent items for OKRs and tasks

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/okrs.md#set-an-objective-as-a-parent) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/11198)

{{< /details >}}

You can now effortlessly update parent assignments for [OKRs](../../user/okrs.md#set-an-objective-as-a-parent) and [tasks](../../user/tasks.md#set-an-issue-as-a-parent), directly from the child record, eliminating the need to navigate back and forth. This is a great step towards our goal of [improving efficiency with your workflows](https://gitlab.com/groups/gitlab-org/-/epics/10501).

### Report abuse for task, objective and key result items

<!-- categories: Team Planning -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/report_abuse.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/461848)

{{< /details >}}

You can now easily report abuse for work items directly from the **Actions** menu, just like you can with legacy issues. This new feature helps keep your workspace clean and safe by allowing you to quickly flag inappropriate content, ensuring a better collaborative environment for your team.

### Resolve threads in tasks, objectives, and key results

<!-- categories: Team Planning -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/discussions/_index.md#resolve-a-thread) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/458818)

{{< /details >}}

You can now resolve threads in tasks, objectives, and key results, making it easier to manage and track important conversations. Resolved threads are collapsed by default, helping you focus on active discussions and streamline your collaboration workflows.

### New Value Stream Analytics stage events for Cycle Time Reduction

<!-- categories: Value Stream Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/value_stream_analytics/_index.md#value-stream-stage-events) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/466383)

{{< /details >}}

To improve the tracking of merge request (MR) review time in GitLab, we added a new stage event to [Value Stream Analytics](https://about.gitlab.com/solutions/value-stream-management/): **MR first reviewer assigned**.
With this new event teams can identify where delays occur in the review process, find opportunities to improve collaboration, and encourage a culture of responsiveness and accountability among team members. Reducing the review time directly impacts the overall cycle time of development, [leading to faster software delivery](https://about.gitlab.com/blog/three-steps-to-optimize-software-value-streams/). For example, you can now add a new custom **Review Time to Merge (RTTM)** stage that starts with **MR first reviewer assigned** and ends with **MR merged**.

### Rust support for Dependency and License Scanning

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md#supported-languages-and-package-managers) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/13093)

{{< /details >}}

Composition Analysis has delivered Rust support for Dependency and License Scanning. Rust scanning supports the `Cargo.lock` file type.

To enable Rust scanning for your Project use the `cargo` template from the [Dependency Scanning CI/CD Component](https://gitlab.com/explore/catalog/components/dependency-scanning).

### Display SBOM ingestion errors in GitLab UI

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dependency_list/_index.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/14408)

{{< /details >}}

GitLab 15.3 added support for [ingesting CycloneDX SBOMs](../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx). While the SBOM reports are validated against the CycloneDX schema, any warnings and errors produced as part of validation were not displayed to the user.

In GitLab 17.3 these validation messages appear in the GitLab UI on the project-level Vulnerability Report and Dependency List pages.

Users will be able to view SBOM ingestion errors in the following areas of the GitLab UI: the project level vulnerability report and dependency list pages, the licenses and security tabs of the pipeline page.

### Enforce the ruleset used in SAST, IaC Scanning, and Secret Detection

<!-- categories: SAST, Secret Detection, Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/customize_rulesets.md#use-a-remote-ruleset-file)

{{< /details >}}

You can customize the rules used in [SAST](../../user/application_security/sast/customize_rulesets.md), [IaC Scanning](../../user/application_security/iac_scanning/_index.md#optimize-iac-scanning), and [Secret Detection](../../user/application_security/secret_detection/pipeline/configure.md#customize-analyzer-behavior) by creating a local configuration file committed in the repository or by setting a CI/CD variable to apply a shared configuration across multiple projects.

Previously, scanners preferred the local configuration file, even if you also set a shared ruleset reference.
This precedence order made it difficult to ensure that scans would use a known, trusted ruleset.

Now, we’ve added a new CI/CD variable, `SECURE_ENABLE_LOCAL_CONFIGURATION`, to control whether local configuration files are allowed.
It defaults to `true`, which keeps the existing behavior: local configuration files are allowed and are preferred over shared configurations.
If you set the value to `false` when you [enforce scan execution](../../user/application_security/policies/scan_execution_policies.md), you can be sure that scans use your shared ruleset, or the default ruleset, even if project developers add a local configuration file.

### Filter jobs by job name

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/jobs/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/387547)

{{< /details >}}

You can now quickly find a specific job by searching for a job name.

Previously, you could only filter the list of jobs by status, requiring manual scrolling to find a specific job. With this release, you can now enter a job name to filter the results. The results will only include jobs in pipelines that ran after the release of GitLab 17.3.

### Merge train visualization

<!-- categories: Merge Trains -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/pipelines/merge_trains.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13705)

{{< /details >}}

You can now visualize the merge train to gain better insight into the status and order of merge requests in the pipeline. With merge train visualization, you can identify conflicts earlier, take actions on merge requests directly in the merge train, and minimize the risk of breaking the default branch.

### GitLab Runner 17.3

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re releasing GitLab Runner 17.3 today! GitLab Runner is the lightweight, highly scalable agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### Bug fixes

- [Jobs appear to hang when canceled in the Kubernetes runner](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37780)
- [Log level not updated when not specified](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37490)
- [Job log adds extra newlines when using the runner Kubernetes executor](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27099)

For a list of all changes, see the GitLab Runner [changelog](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-3-stable/CHANGELOG.md).

### Improved performance for hosted runners on macOS

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../ci/runners/hosted_runners/macos.md) | [Related issue](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/job-images/-/issues/6)

{{< /details >}}

We have shipped performance improvements with the recent upgrade to macOS 14.5 and Xcode 15.4. With this change, Xcode build jobs are significantly faster compared to previous job executions.

### Description and type added to CI/CD catalog component input details

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../ci/components/_index.md#cicd-catalog) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/426870)

{{< /details >}}

The details page for a CI/CD component in the catalog provides useful information about the component. In this release we’ve added two more columns to the table that shows information about available inputs. The new **Description** and **Type** columns make it much easier to understand what an input is used for, and what type of value is expected.

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.3)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.3)
- [UI improvements](https://papercuts.gitlab.com/?milestone=17.3)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
