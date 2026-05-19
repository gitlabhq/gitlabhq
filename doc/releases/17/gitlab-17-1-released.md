---
stage: Release Notes
group: Monthly Release
date: 2024-06-20
title: "GitLab 17.1 release notes"
description: "GitLab 17.1 released with Model registry available in beta"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On June 20, 2024, GitLab 17.1 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor

Everyone can [nominate GitLab’s community contributors](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)!
Show your support for our active candidates or add a new nomination! 🙌

Shubham Kumar [completed 7 issues during 17.1](https://gitlab.com/dashboard/issues?sort=due_date_desc&state=closed&assignee_username%5B%5D=imskr&milestone_title=17.1)
and has been consistently contributing to GitLab since 2021.
He has now reached over 50 merged contributions!
Shubham is a [GitLab Hero](https://contributors.gitlab.com/docs/previous-heroes) and a former Google Summer of Code contributor.

Shubham was nominated by [Christina Lohr](https://gitlab.com/lohrc), Senior Product Manager at GitLab.
“Shubham has helped with a lot of issues over the past weeks and months, specifically with closing gaps in our API offering,” says Christina.
“I cannot write release posts fast enough for all the additions that Shubham is pushing through!”

“The open-source community is amazing,” says Shubham.
“I am grateful for the opportunity and recognition, and I look forward to continuing my contributions to the GitLab platform.”

Joe Snyder was nominated by [Kai Armstrong](https://gitlab.com/phikai), Principal Product Manager at GitLab,
for building a much requested feature for [restricting diffs from being included in emails](https://gitlab.com/gitlab-org/gitlab/-/issues/24733).
This contribution took more than 10 merge requests going back to GitLab 15.3.
“This is a massive feature that’s taken many milestones, complicated migrations, and changes to the product to enable it’s support,” says Kai.
“Joe worked tirelessly with many maintainers and collaborators over the milestones to get this work done.”

[Jocelyn Eillis](https://gitlab.com/jocelynjane), Product Manager at GitLab, supported Joe’s nomination
by highlighting additional work to fix a bug where [nested variables in `build:resource_group` are not expanded](https://gitlab.com/gitlab-org/gitlab/-/issues/361438).
“This bug had 23 upvotes in addition to documented customer demand in the issue itself,” says Jocelyn.
“The quick turnaround on reviewer feedback means we were able to get this into GitLab 17.1!”

This is Joe’s second GitLab MVP after previously being awarded in [GitLab 16.6](https://about.gitlab.com/releases/2023/11/16/gitlab-16-6-released/#mvp).
Joe is a Senior R&D Engineer at [Kitware](https://www.kitware.com/) and has been contributing to GitLab since 2021.

## Primary features

### Model registry available in beta

<!-- categories: MLOps -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/ml/model_registry/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9423)

{{< /details >}}

GitLab now officially supports model registry in beta as a first-class concept. You can add and edit models directly via the UI, or use the MLflow integration to use GitLab as a model registry backend.

A model registry is a hub that helps data science teams manage machine learning models and their related metadata. It serves as a centralized location for organizations to store, version, document, and discover trained machine learning models. It ensures better collaboration, reproducibility, and governance over the entire model lifecycle.

We think of the model registry as a cornerstone concept that enables teams to collaborate, deploy, monitor, and continuously train models, and are very interested in your feedback. Please feel free to drop us a note in our [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/465405) and we’ll get back in touch!

### See multiple GitLab Duo Code Suggestions in VS Code

<!-- categories: Editor Extensions, Code Suggestions -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/repository/code_suggestions/_index.md#view-multiple-code-suggestions) | [Related issue](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1325)

{{< /details >}}

GitLab Duo Code Suggestions in VS Code will now show you if there are multiple suggestions available. Simply hover over the suggestion and use the arrows or keyboard shortcut to cycle through the suggestions.

### Secret Push Protection available in beta

<!-- categories: Secret Detection -->

{{< details >}}

- Tier: Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/application_security/secret_detection/secret_push_protection/_index.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/12729)

{{< /details >}}

If a secret, like a key or an API token, is accidentally committed to a Git repository, anyone with repository access can impersonate the user of the secret for malicious purposes. To address this risk, most organizations require exposed secrets to be revoked and replaced, but you can save remediation time and reduce risk by preventing secrets from being pushed in the first place.

Secret push protection checks the content of each commit pushed to GitLab. [If any secrets are detected](../../user/application_security/secret_detection/secret_push_protection/_index.md#detected-secrets), the push is blocked and displays information about the commit, including:

- The commit ID that contains the secret.
- The filename and line number that contains the secret.
- The type of secret.

Need to bypass secret push protection for testing? When you skip secret push detection, GitLab logs an audit event so you can investigate.

Secret push protection is available on GitLab.com and for Dedicated customers as a Beta feature and can be enabled on a [per project basis](../../user/application_security/secret_detection/secret_push_protection/_index.md#enable-secret-push-protection-in-a-project). You can help us improve secret push protection by providing feedback in [issue 467408](https://gitlab.com/gitlab-org/gitlab/-/issues/467408).

### GitLab Runner Autoscaler is generally available

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner/runner_autoscale/) | [Related issue](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29221)

{{< /details >}}

In earlier versions of GitLab, some customers needed an autoscaling solution for GitLab Runner on virtual machine instances on public cloud platforms. These customers had to rely on the legacy [Docker Machine executor](https://docs.gitlab.com/runner/configuration/autoscale.html) or custom solutions stitched together by using cloud provider technologies.

Today, we’re pleased to announce the general availability of the GitLab Runner Autoscaler. The GitLab Runner Autoscaler is composed of GitLab-developed taskscaler and [fleeting](https://docs.gitlab.com/runner/fleet_scaling/fleeting.html) technologies and the cloud provider plugin for Google Compute Engine.

### GitLab connector application now available on the Snowflake Marketplace

<!-- categories: Audit Events, Compliance Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../integration/snowflake.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13004)

{{< /details >}}

Audit events are created and stored in GitLab. Before this release, audit events could only be accessed from in GitLab, with results reviewed using the GitLab UI or set a streaming destination to receive all audit events as structured JSON.

However, customers also wanted the ability to have audit events in third-party destinations (such as SIEM solutions like Snowflake) to make it easier to:

- See, combine, manipulate, and report on all of the audit event data from an organization’s multiple systems, including GitLab.
- Look only at specific audit events that they care about so that they can quickly answer the questions they are interested in.
- Have a full picture of what goes on inside GitLab, and be able to review it after the fact.

To help customers with these tasks, we have created a GitLab connector application for the [Snowflake Marketplace](https://app.snowflake.com/marketplace/listing/GZTYZXESENG/gitlab-gitlab-data-connector), which uses the Audit events API.
To make use of this functionality, customers must deploy and manage the application using the Snowflake Marketplace.

### Improved wiki user experience

<!-- categories: Wiki -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/wiki/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/452225)

{{< /details >}}

The wiki feature in GitLab 17.1 provides a more unified and efficient workflow:

- [Easier and quicker cloning](https://gitlab.com/gitlab-org/gitlab/-/issues/281830) with a new repository clone button. This improves collaboration, and speeds up access to the wiki content for editing or viewing.
- [A more obvious delete option](https://gitlab.com/gitlab-org/gitlab/-/issues/335169) in a more discoverable location. This reduces the time spent searching for it, and minimizes potential errors or confusion when managing wiki pages.
- [Allowing empty pages to be valid](https://gitlab.com/gitlab-org/gitlab/-/issues/221061), improving flexibility. Create empty placeholders when you need them. Focus on better planning and organization of wiki content, and fill in the empty pages later.

These enhancements improve ease of use, discoverability, and content management in your wiki’s workflow. We want your wiki experience to be efficient and user-friendly. By making cloning repositories more accessible, relocating key options for better visibility, and allowing for the creation of empty placeholders, we’re refining our platform to better meet your users’ needs.

### New Value Stream Management report generator tool

<!-- categories: Value Stream Management, DORA Metrics -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/analytics/value_streams_dashboard.md#schedule-reports) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/10880)

{{< /details >}}

With the addition of the new Reports Generation Tool for Value Stream Management, we empower decision-makers to be more efficient and effective in the software development life cycle (SDLC) optimization.

You can now schedule [DevSecOps comparison metrics reports](https://gitlab.com/components/vsd-reports-generator#example-for-monthly-executive-value-streams-report) or the [AI Impact analytics](https://about.gitlab.com/releases/2024/05/16/gitlab-17-0-released/#ai-impact-analytics-in-the-value-streams-dashboard) report to be delivered automatically, proactively, and with relevant information in GitLab issues. With scheduled reports, managers can focus on analyzing insights and making informed decisions, rather than spending time manually searching for the right dashboard with the required data.

You can access the scheduled reports tool using the [CI/CD Catalog](https://gitlab.com/explore/catalog).

### Container images linked to signatures

<!-- categories: Container Registry -->

{{< details >}}

- Tier: Free, Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/packages/container_registry/_index.md#container-image-signatures) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/7856)

{{< /details >}}

The GitLab container registry now associates signed container images with their signatures. With this improvement, users can more easily:

- Identify which images are signed and which are not.
- Find and validate the signatures that are associated with a container image.

This improvement is generally available only on GitLab.com. Self-managed support is in beta and requires users to enable the
[next-generation container registry](../../administration/packages/container_registry_metadata_database.md), which is also in beta.

### Require confirmation for manual jobs

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/jobs/job_control.md#require-confirmation-for-manual-jobs) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/18906)

{{< /details >}}

Manual jobs can be used to trigger highly critical operations in your CI pipeline, such as deploying to production. With this release, you can now configure a manual job to require confirmation before it runs. Use `manual_confirmation` with `when: manual` to display a confirmation dialog in the UI when a job is run manually. Requiring confirmation for manual jobs provides an additional layer of security and control.

Special thanks to [Phawin](https://gitlab.com/lifez) for this community contribution!

### Runner fleet dashboard for groups

<!-- categories: Fleet Visibility -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/runners/runner_fleet_dashboard_groups.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/424789)

{{< /details >}}

Operators of self-managed runner fleets at the group level need observability and the ability to quickly answer critical questions about their runner fleet infrastructure at a glance. With the runner fleet dashboard for groups, you directly have runner fleet observability and actionable insights in the GitLab UI. You can now quickly determine the runner health, and gain insights into runner usage metrics as well as CI/CD job queue service capabilities, in your organization’s target service-level objectives.

Customers on GitLab.com can use all of the fleet dashboard metrics available for groups today. Self-managed customers can use most of the fleet dashboard metrics, but must configure the ClickHouse analytics database to use the **Runner usage** and **Wait time to pick a job** metrics.

## Scale and Deployments

### Omnibus improvements

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

GitLab 17.1 includes packages for supporting [Ubuntu Noble 24.04](../../install/package/_index.md).

### New GraphQL API argument `markedForDeletionOn` for groups and projects

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/graphql/reference/_index.md#querygroups) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/463809)

{{< /details >}}

You can now use the new GraphQL API argument `markedForDeletionOn` to list the groups or projects that were marked for deletion at a specific date.

Thank you [@imskr](https://gitlab.com/imskr) for this community contribution!

### New placeholders for group and project badges

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/badges.md#placeholders) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/22278)

{{< /details >}}

You can now create badge links and image URLs using four new placeholders:

- `%{project_namespace}` - referencing the full path of a project namespace
- `%{group_name}` - referencing the group name
- `%{gitlab_server}` - referencing the group’s or project’s server name
- `%{gitlab_pages_domain}` - referencing the group’s or project’s domain name

Thank you [@TamsilAmani](https://gitlab.com/TamsilAmani) for this community contribution!

### New `%{latest_tag}` placeholder for badges

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/badges.md#placeholders) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/26420)

{{< /details >}}

You can now create badge links and image URLs using a `%{latest_tag}` placeholder. This placeholder references the latest tag that was published for a repository.

Thank you [@TamsilAmani](https://gitlab.com/TamsilAmani) for this community contribution!

### Filter groups by `marked_for_deletion_on` date with the Groups API

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/groups.md#list-groups) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/429315)

{{< /details >}}

You can now filter responses in the Groups API using the attribute `marked_for_deletion_on`, which returns groups that were marked for deletion at a specific date.

Thank you [@imskr](https://gitlab.com/imskr) for this community contribution!

### List contributed projects of a user with GraphQL API

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/graphql/reference/_index.md#usercontributedprojects) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/450191)

{{< /details >}}

You can now use the new GraphQL API field `User.contributedProjects` to list the projects a user has contributed to.

Thank you [@yasuk](https://gitlab.com/yasuk) for this community contribution!

### Add members by username with the Members API

<!-- categories: User Management, Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/group_members.md#add-a-group-member) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/28208)

{{< /details >}}

Previously, when using the Members API, you could add members to groups and projects only by their user ID. With this release, you can now add members also by their username.

Thank you [@imskr](https://gitlab.com/imskr) for this community contribution!

### Updated sorting and filtering functionality in Explore

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/working_with_projects.md#explore-all-projects-on-an-instance)

{{< /details >}}

We have updated the sorting and filtering functionality of the group and project Explore pages. The filtering bar is now wider for better readability.

In the Explore page for projects, you can now use standardized sorting options that include **Name**, **Created date**, **Updated date**, and **Stars**, and a navigation element to sort in ascending or descending order. The language filter has moved to the filter menu. A new **Inactive** tab displays archived projects for a more focused search. Additionally, you can use a **Role** filter to search for projects you are the Owner of.

In the Explore page for groups, we have standardized the sorting options to include **Name**, **Created date**, and **Updated date**, and added a navigation element to sort in ascending or descending order.

We welcome feedback about these changes in [issue 438322](https://gitlab.com/gitlab-org/gitlab/-/issues/438322).

### Improved visibility level selection

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/public_access.md#change-group-visibility) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/455668)

{{< /details >}}

Previously, a group’s or project’s general settings displayed only permitted visibility levels. This view often confused users who tried to understand why the other options were not available, and could lead to information being displayed incorrectly. The new view shows all visibility levels, greying out the options that are not available for selection. In addition, a popover gives further context about why an option is not available. For example, a visibility level could be unavailable because an administrator restricted it, or it would cause a conflict with a project’s or parent group’s visibility setting.

We hope these changes help you resolve the conflicts in selecting your desired visibility option. Thank you [@gerardo-navarro](https://gitlab.com/gerardo-navarro) for this community contribution!

### Filter projects by `marked_for_deletion_on` date with the Projects API

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/projects.md#list-all-projects) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/463939)

{{< /details >}}

You can now filter responses in the Projects API using the attribute `marked_for_deletion_on`, which returns projects that were marked for deletion at a specific date.

Thank you [@imskr](https://gitlab.com/imskr) for this community contribution!

### Audit event on webhook creation

<!-- categories: Notifications, Audit Events -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/audit_event_types.md#webhooks) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/8068)

{{< /details >}}

Audit events make a record of important actions that are performed in GitLab. Until now, no audit event was created when a system, group, or
project webhook was added by a user.

In this release, we’ve added an audit event for when a user creates a system, group, or project webhook.

### Use REST API to cancel a running direct transfer migration

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/bulk_imports.md#cancel-a-migration) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/438281)

{{< /details >}}

Until now cancelling a running direct transfer migration
[required access to a Rails console](../../user/group/import/direct_transfer_migrations.md#cancel-a-running-migration).

In this release, we’ve added the ability for Administrators to cancel a migration by using the REST API.

### Test group hooks with the REST API

<!-- categories: Notifications -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/group_webhooks.md#trigger-a-test-group-hook) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/455589)

{{< /details >}}

Previously, you could test only project hooks with the REST API. With this release, you can also trigger test hooks for specified groups.

This endpoint has a special rate limit of three requests per minute per group hook. To disable this limit on self-managed GitLab and GitLab Dedicated, an administrator can disable the `web_hook_test_api_endpoint_rate_limit` feature flag.

Thanks to [Phawin](https://gitlab.com/lifez) for [this community contribution](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150486)!

### Re-import a chosen project relation by using the API

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/project_import_export.md#import-project-resources) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/455889)

{{< /details >}}

When importing projects from export files with many items of the same type (for example, merge requests or pipelines), sometimes some of those items aren’t imported.

In this release, we’ve added an API endpoint that re-imports a named relation, skipping items that have already been imported. The API requires both:

- A project export archive.
- A type. Either issues, merge requests, pipelines, or milestones.

### Keep inherited membership structure when importing by direct transfer

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/import/direct_transfer_migrations.md#user-membership-mapping) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/458834)

{{< /details >}}

Until now, [inherited memberships](../../user/project/members/_index.md#membership-types) were not imported reliably when migrating
by direct transfer. This meant that inherited members of projects were imported as direct members.

From this release, GitLab now first migrates group membership before migrating project memberships. This replicates the inherited memberships on
the source GitLab instance.

### Use the REST API to set custom webhook headers

<!-- categories: Source Code Management, Notifications -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/project_webhooks.md#set-a-custom-header) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/455528)

{{< /details >}}

In GitLab 16.11, we introduced the ability to
[add custom headers when you create or edit a webhook](https://about.gitlab.com/releases/2024/04/18/gitlab-16-11-released/#custom-webhook-headers).

With this release, you can now use the GitLab REST API to set custom webhook headers.

Thanks to [Niklas](https://gitlab.com/Taucher2003) for [this community contribution](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153768)!

### Backups include external merge request diffs stored on disk

<!-- categories: Backup/Restore of GitLab instances -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/backup_restore/backup_gitlab.md#backup-command)

{{< /details >}}

The `gitlab-backup` tool now supports backing up [external merge request diffs](../../administration/merge_request_diffs.md) stored on local disk. Note, the `gitlab-backup` tool does not backup files stored on object storage. Therefore, if external merge diffs are stored on object storage they will need to be backed up manually.

The `backup-utility` for Cloud Native Hybrid environments already supported backing up external merge request diffs and this functionality remains unchanged.

## Unified DevOps and Security

### Disable diff previews in code review emails

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/group/manage.md#disable-diff-previews-in-email-notifications)

{{< /details >}}

When you review code in a merge request and comment on a line of code, GitLab includes a few lines of the diff in the email notification to participants. Some organizational policies treat email as a less secure system, or might not control their own infrastructure for email. This can present risks to IP or access control of source code.

New settings are available in groups and projects to enable organizations to remove diff previews from merge request emails. This can help ensure that sensitive information isn’t available outside of GitLab.

A gigantic thank you to [Joe Snyder](https://gitlab.com/joe-snyder) for contributing this!

### Administrators can search users by partial email address

<!-- categories: User Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/admin_area.md#administering-users) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/20381)

{{< /details >}}

Administrators can now search users by partial email address in the User overview of the Admin Area. For instance, you can filter users by a specific email domain to find all users from a distinct institution. This feature is limited to administrators to prevent unprivileged users from accessing email addresses of other accounts.

Thanks [@zzaakiirr](https://gitlab.com/zzaakiirr) for this community contribution!

### Show Release RSS icon on Releases page

<!-- categories: Release Orchestration -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/releases/_index.md#track-releases-with-an-rss-feed) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/30988)

{{< /details >}}

Do you need to be notified when a new release is posted? GitLab now provides an RSS feed for releases. You can subscribe to a release feed with the RSS icon on the project release page.

Thanks to [Martin Schurz](https://gitlab.com/schurzi) for the contribution!

### New permissions for custom roles

<!-- categories: Permissions -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/custom_roles/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/391760)

{{< /details >}}

In GitLab 17.1, you can create custom roles with the following new permissions:

- [Manage merge request settings](../../user/custom_roles/abilities.md#code-review-workflow)
- [Manage integrations](../../user/custom_roles/abilities.md#integrations)
- [Manage deploy tokens](../../user/custom_roles/abilities.md#continuous-delivery)
- [Read CRM Contacts](../../user/custom_roles/abilities.md#team-planning)

With custom roles, you can reduce the number of users with the Owner role by creating users with equivalent permissions. This helps you define roles that are tailored specifically to the needs of your group, and prevents unnecessary privilege escalation.

### Merge request approval policies fail open/closed (Policy editor)

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#fallback_behavior) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13227)

{{< /details >}}

Building on the previous [iteration](https://gitlab.com/groups/gitlab-org/-/epics/10816), we are introducing a new option within the policy editor allowing users to toggle security policies to fail open or fail closed. This enhancement extends the YAML support to allow for simpler configuration within the policy editor view.

For example, a merge request policy configured to fail open allows a merge request to merge if there is not enough evidence to evaluate the criteria. The lack of evidence might be because an analyzer is not enabled for the project, or the analyzer failed to produce results for the policy to evaluate. This approach allows for progressive rollout of policies as teams work to ensure proper scan execution and enforcement.

### Project Owners receive expiring access token notifications

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../security/tokens/_index.md#project-access-tokens) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/460818)

{{< /details >}}

Both project Owners and Maintainers with direct membership now receive email notifications when their project access tokens are close to expiring. Previously, only project Maintainers received this notification. This helps keep more people informed about upcoming token expiration.

Thank you [Jacob Henner](https://gitlab.com/arcesium-henner) for your contribution!

### Downscale pasted images on image upload

<!-- categories: Team Planning, Portfolio Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/markdown.md#change-image-or-video-dimensions) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/419913)

{{< /details >}}

GitLab 17.1 enhances the handling of high-resolution images, enabling them to be downscaled during upload. Previously, images displayed in their original size, resulting in suboptimal display quality. This improvement ensures large images don’t break the visual flow of the pages they are included in.

### Draggable media in the rich text editor

<!-- categories: Team Planning -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/rich_text_editor.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/452233)

{{< /details >}}

Previously, moving media in the rich text editor required you to copy and paste each item manually. This often slowed down the inclusion of media in issues, epics, and wikis. In GitLab 17.1, you can now drag and drop media in the rich text editor, significantly enhancing efficiency during editing.

### Pages support for mutual TLS in GitLab API calls

<!-- categories: Pages -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/pages/_index.md#support-mutual-tls-when-calling-the-gitlab-api) | [Related issue](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/548)

{{< /details >}}

GitLab can be configured to [enforce client authentication with SSL certificates](https://docs.gitlab.com/omnibus/settings/ssl/#enable-2-way-ssl-client-authentication). However, the GitLab Pages service was incompatible with that feature, because it couldn’t be configured to use client certificates, and calls to the internal API were rejected.

From GitLab 17.1, you can configure a client certificate for GitLab Pages. This allows you to enable client authentication with the GitLab API, strengthening the security of your GitLab instance.

### Redirect wiki pages to new URL when renamed

<!-- categories: Wiki -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/wiki/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/257892)

{{< /details >}}

GitLab 17.1 introduces a significant enhancement to wiki page redirects. When you rename a wiki page, anyone trying to access the old page is automatically redirected to the new page, ensuring all existing links remain functional. This improvement streamlines the workflow for managing page name changes and enhances the overall knowledge management experience.

### Updated Pages UI

<!-- categories: Pages -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/pages/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153250)

{{< /details >}}

In GitLab 17.1 we’ve improved the Pages user interface. Improvements include more efficient use of screen space. These UI improvements are focused on improving user experience and efficiency when managing Pages.

### Display the last published date for container images

<!-- categories: Container Registry -->

{{< details >}}

- Tier: Free, Silver, Gold
- Links: [Documentation](../../user/packages/container_registry/_index.md#view-the-container-registry) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/290949)

{{< /details >}}

Previously, the published timestamp was often incorrect in the container registry user interface. This meant that you couldn’t rely on this important data to find and validate your container images.

In GitLab 17.1, we’ve updated the UI to include accurate `last_published_at` timestamps. You can find this information by navigating to **Deploy > Container Registry** and selecting a tag to view more details. The last published date is available at the top of the page.

This improvement is generally available only on GitLab.com. Self-managed support is in beta and available only on instances that have enabled the beta [next-generation container registry](../../administration/packages/container_registry_metadata_database.md).

### Sort container registry tags by publish date

<!-- categories: Container Registry -->

{{< details >}}

- Tier: Free, Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/packages/container_registry/_index.md#view-the-container-registry) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/7856)

{{< /details >}}

You use the GitLab container registry to view, push, and pull Docker or OCI images alongside your source code as well as pipelines. After a container image has been built, you often need to find and validate that it has been built correctly. For many customers, finding the correct container image using the user interface can be challenging.

You can now sort the container registry tags list by publish date. You can use this feature to quickly find and validate the most recently published container image.

This improvement is generally available only on GitLab.com. Self-managed support is in Beta because it requires the next-generation container registry, which is also in Beta. To learn more, see the [container registry metadata database documentation](../../administration/packages/container_registry_metadata_database.md).

### Real-time board updates for a smoother workflow

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/issue_board.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/468187)

{{< /details >}}

You’ll now notice a smoother experience when updating issues on [boards](../../user/project/issue_board.md)! Changes you make in the sidebar will instantly appear on the board itself, no more refreshing required. This reactive boards experience streamlines your workflow, allowing you to quickly make updates while seeing them reflected in real-time.

### Track time on tasks

<!-- categories: Team Planning -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/time_tracking.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/438577)

{{< /details >}}

With this release, you can now set time estimates and record time spent on tasks with a [quick action](../../user/project/quick_actions.md) or in the time tracking widget in the task’s sidebar. Time spent on a task can be viewed with the task’s time tracking report.

### Understand an epic's progress percentage

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/epics/manage_epics.md#manage-issues-assigned-to-an-epic) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/5163)

{{< /details >}}

You can now easily see the overall progress of an epic based on the weight completion of its child items. This new progress rollup in the hierarchy widget makes it easier to understand the full scope of work for an epic and track progress as you go.

### API Security Testing analyzer updates

<!-- categories: API Security -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/api_security_testing/configuration/variables.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/14170)

{{< /details >}}

GitLab 17.1 adds the following configuration variables for API Security Testing:

1. `APISEC_SUCCESS_STATUS_CODES` creates a comma-separated list of HTTP success status codes that define whether an API security testing scanning job has passed.
1. `APISEC_TARGET_CHECK_DISABLED` disables waiting for the target API to become available before scanning begins.
1. `APISEC_TARGET_CHECK_STATUS_CODE` specifies the expected status code for the API target availability check. If not provided, any non-500 status code is acceptable to the scanner.

These new variables provide greater customization and flexibility to ensure scans run successfully.

DAST API was renamed API Security Testing in 16.10. Variable names now begin with the prefix `APISEC`. Previously, they began with `DAST_API`. Variables prefixed with `DAST_API` will be supported until 18.0 (May 2025). To ensure your configurations work as expected, you should update your variable names as soon as possible.

### Container Scanning for Registry

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/container_scanning/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/2340)

{{< /details >}}

GitLab Composition Analysis now supports Container Scanning for Registry.

If Container Scanning for Registry has been enabled on a project, and a container image is pushed to the container registry in your project, GitLab checks its tag and scan limit.

If the tag is `latest`, and the number of scans is under the limit (50 scans/day), then GitLab creates a new pipeline that runs a `container_scanning` job on the image. The pipeline is associated with the user who pushed the image to the registry.

The scan job generates a CycloneDX SBOM that is uploaded to GitLab. The Continuous Vulnerability Scanning features are activated and scan the packages detected in the SBOM.

Note: a vulnerability scan is only perfomed when a new advisory is published. This occurs when the [package metadata is synchronized](../../administration/settings/security_and_compliance.md).

As always, we appreciate feedback on our newly released features. To provide feedback, please comment on this [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/466117).

### Fuzz Testing analyzer updates

<!-- categories: Fuzz Testing -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/api_fuzzing/configuration/variables.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/442699)

{{< /details >}}

GitLab 17.1 adds the following configuration variables for Fuzz Testing:

1. `FUZZAPI_SUCCESS_STATUS_CODES` creates a comma-separated list of HTTP success status codes that define whether a Fuzz Testing job has passed.
1. `FUZZAPI_TARGET_CHECK_SKIP` disables waiting for the target API to become available before scanning begins.
1. `FUZZAPI_TARGET_CHECK_STATUS_CODE` specifies the expected status code for the API target availability check. If not provided, any non-500 status code is acceptable to the scanner.

These new variables provide greater customization and flexibility for ensuring scans run.

### Enhanced control over who can override user-defined variables

<!-- categories: Secrets Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/variables/_index.md#restrict-pipeline-variables) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/440338)

{{< /details >}}

To better control who can override user-defined variables, we are introducing the `ci_pipeline_variables_minimum_role` project setting. This new setting provides greater flexibility than the existing [`restrict_user_defined_variables`](../../ci/variables/_index.md#restrict-pipeline-variables) setting. You can now restrict override permissions to no users, or only users with at least the Developer, Maintainer, or Owner roles.

### GitLab Runner 17.1 released

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner) | [Related issue](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36942)

{{< /details >}}

Today we’re releasing GitLab Runner 17.1! GitLab Runner is the lightweight, highly scalable agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s new

- [GitLab Runner fleeting plugin for GCP Compute Engine](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29221)

#### Bug Fixes

- [Runner helper images missing the entry point](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37689)

The list of all changes is in the GitLab Runner [change log](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-1-stable/CHANGELOG.md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.1)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.1)
- [UI improvements](https://papercuts.gitlab.com/?milestone=17.1)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
