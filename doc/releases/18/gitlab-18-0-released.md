---
stage: Release Notes
group: Monthly Release
date: 2025-05-15
title: "GitLab 18.0 release notes"
description: "GitLab 18.0 released with GitLab Premium and Ultimate with Duo"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On May 15, 2025, GitLab 18.0 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Michael Hofer

Michael Hofer champions GitLab’s open source mission as both a top contributor and community leader.
With over [50 contributions](https://contributors.gitlab.com/users/karras?fromDate=2025-01-01&toDate=2025-05-12) this year,
his work strengthened GitLab’s Geo features and Secrets Manager, based on OpenBao.
He topped the [April Hackathon](https://contributors.gitlab.com/hackathon?hackathonName=2025_04) while supporting fellow contributors and leading community projects.

“I truly appreciate that everyone can contribute to GitLab!” says Michael.
“The team is great to work with, it’s a lot of fun, and everyone is super helpful, especially when we team up across open source initiatives like OpenBao and SLSA.”

Michael is the CTO at [Adfinis](https://adfinis.com/en/), an international IT service provider specializing in planning, building, and running mission critical open source workloads.
He is passionate about fostering collaboration and promoting open source solutions across organizations.

Recently, Adfinis participated in GitLab’s [Co-Create program](https://about.gitlab.com/community/co-create/), which pairs organizations with GitLab’s product and engineering teams
to build GitLab together.
“We highly recommend Co-Create to all organizations,” Michael says. “It led to a number of cool contributions, including rootless Podman builds, Glimmer syntax highlighting, and other improvements.”

“The Geo Team really appreciates and enjoys working with Michael,” says [Lucie Zhao](https://gitlab.com/luciezhao), Engineering Manager at GitLab, who nominated Michael for the award.
“With his excellent contributions over the last few milestones, he has become the most well-known community contributor within our team.”

GitLab team members [Lee Tickett](https://gitlab.com/leetickett-gitlab), [Chloe Fons](https://gitlab.com/c_fons), and [Alex Scheel](https://gitlab.com/cipherboy-gitlab) supported the nomination.
Alex adds, “Michael’s leadership in OpenBao has enabled us to effectively collaborate in bringing forward a secrets management solution for our customers, with the transparency that aligns with our GitLab values.”

Thanks to Michael and the Adfinis team for co-creating GitLab!

## Primary features

### GitLab Premium and Ultimate with Duo

<!-- categories: Code Suggestions, Duo Chat -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/gitlab_duo/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/538857)

{{< /details >}}

We’re excited to announce GitLab Premium with Duo and GitLab Ultimate with Duo. GitLab Premium and Ultimate now include AI-native features.

GitLab’s AI-native features include Code Suggestions and Chat within the IDE. Development teams can use these features to:

- Analyze, understand, and explain code
- Write secure code faster
- Quickly generate tests to maintain code quality
- Easily refactor code to improve performance or use specific libraries

### Repository X-Ray now available on GitLab Duo Self-Hosted

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../user/project/repository/code_suggestions/repository_xray.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/17756)

{{< /details >}}

You can now use Repository X-Ray with Code Suggestions on GitLab Duo Self-Hosted. This feature is in beta for GitLab Duo Self-Hosted, and is generally available on GitLab Self-Managed instances.

### Automatic reviews with Duo Code Review

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Add-ons: Duo Enterprise
- Links: [Documentation](../../user/project/merge_requests/duo_in_merge_requests.md)

{{< /details >}}

Duo Code Review provides valuable insights during the review process, but currently requires you to manually request reviews on each merge request.

You can now configure GitLab Duo Code Review to run automatically on merge requests by updating your project’s merge request settings. When enabled, Duo Code Review automatically reviews merge requests unless:

- The merge request is marked as draft.
- The merge request contains no changes.

Automatic reviews ensure that all code in your project receives a review, consistently improving code quality across your codebase.

### Code Suggestions prompt caching

<!-- categories: Code Suggestions -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/project/repository/code_suggestions/_index.md#prompt-caching) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/17489)

{{< /details >}}

Code Suggestions now includes prompt caching. Prompt caching significantly improves code completion latency by avoiding the re-processing of cached prompt and input data. The cached data is never logged to any persistent storage, and you can optionally disable prompt caching in the GitLab Duo settings.

### Improved Duo Code Review context

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Add-ons: Duo Enterprise
- Links: [Documentation](../../user/project/merge_requests/duo_in_merge_requests.md)

{{< /details >}}

Duo Code Review now provides more comprehensive context for improved analysis.
The key improvements are:

- Includes a merge request’s title and description to better understand the purpose of proposed changes.
- Examines all diffs simultaneously to recognize cross-file relationships and reduce false positives.
- Provides the full content of changed files to understand how modifications fit within existing code patterns.

These enhancements reduce inaccurate suggestions and deliver more relevant and higher quality
code reviews.

## Scale and Deployments

### List only Enterprise users for contributions reassignment on GitLab.com

<!-- categories: Importers -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/import/direct_transfer_migrations.md#user-membership-mapping) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/510673)

{{< /details >}}

In this release we’ve improved the placeholder users mapping experience by
narrowing down the user selection dropdown to only Enterprise users associated with the top-level group.
Previously, when reassigning users’ contributions after an import to GitLab.com, you would see in the dropdown list
all active users on the platform, making it difficult to identify the correct user, especially when SCIM provisioning
had modified usernames. Now, if your top-level group uses the Enterprise users feature, the dropdown list will display only
users claimed by your organization, significantly reducing the potential for errors during user reassignment.
The same scoping is also applied to CSV-based reassignment, preventing accidental assignment to users outside your organization.

### Support for multiple workspaces in the GitLab for Slack app

<!-- categories: Settings -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../administration/settings/slack_app.md#enable-support-for-multiple-workspaces) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/424190)

{{< /details >}}

The GitLab for Slack app now supports multiple workspaces for GitLab Self-Managed and GitLab Dedicated customers.
Enabling multiple workspaces allows organizations with federated Slack environments to maintain seamless GitLab integrations across all their workspaces.
To enable support for multiple workspaces, configure the GitLab for Slack app as an [unlisted distributed app](https://api.slack.com/distribution#unlisted-distributed-apps).

### Delete groups and placeholder users

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/import/mapping/post_migration_mapping.md#placeholder-user-deletion) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/473256)

{{< /details >}}

In GitLab 18.0, when you delete a top-level group, placeholder users associated with the group are deleted as well. If placeholder users are associated with other projects, they are only removed from the top-level group.
This way, unnecessary placeholder users are removed without disrupting the history or attributions of other projects.

### Internal releases available for GitLab Dedicated

<!-- categories: GitLab Dedicated -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](https://handbook.gitlab.com/handbook/engineering/releases/internal-releases/) | [Related epic](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/1201)

{{< /details >}}

GitLab Dedicated customers with strict security requirements and compliance obligations require the highest level of protection for their development environments.
Today, we’re introducing Internal Releases, a new private release that allows us to remediate GitLab Dedicated instances for critical vulnerabilities before public disclosure, ensuring GitLab Dedicated customers are never exposed to them.
This new capability delivers immediate protection for critical vulnerabilities found in GitLab parallel to response for GitLab.com. This new process does not require customer action.

### GitLab chart 9.0 released with breaking changes

<!-- categories: Cloud Native Installation, Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/charts/releases/9_0/) | [Related issue](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5927)

{{< /details >}}

- [Breaking change](../../update/deprecations.md#postgresql-14-and-15-no-longer-supported): Support for PostgreSQL 14 and 15 has been removed. Make sure you are running PostgreSQL 16 before upgrading.
- [Breaking change](../../update/deprecations.md#major-update-of-the-prometheus-subchart): The bundled Prometheus chart was updated from 15.3 to 27.11. Along with the Prometheus chart upgrade, the Prometheus version was updated from 2.38 to 3.0. Manual steps are required to perform the upgrade. If you have Alertmanager, Node Exporter, or Pushgateway enabled, you must also update your Helm values. For more information, see the [migration guide](https://docs.gitlab.com/charts/releases/9_0.html#prometheus-upgrade).
- [Breaking change](../../update/deprecations.md#fallback-support-for-gitlab-nginx-chart-controller-image-v131): The default NGINX controller image was updated from version 1.3.1 to 1.11.2. If you’re using the GitLab NGINX chart, and you have set your own NGINX RBAC rules, new RBAC rules must exist. For more information, see the [upgrade guide](https://docs.gitlab.com/charts/releases/8_0/#upgrade-to-86x-851-843-836) for more information.

### Event data collection

<!-- categories: Application Instrumentation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../administration/settings/event_data.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/510333)

{{< /details >}}

In GitLab 18.0, we are enabling event-level product usage data collection from GitLab Self-Managed and GitLab Dedicated instances. Unlike aggregated data, event-level data provides GitLab with deeper insights into usage, allowing us to improve user experience on the platform and increase feature adoption. For detailed instructions on how to adjust data sharing settings, please refer to our documentation.

### Deletion protection available for all users

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../administration/settings/visibility_and_access_controls.md#deletion-protection) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/17208) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/526405)

{{< /details >}}

Project and group delayed deletion is now available for all GitLab users, including those on our Free tier. This essential safety feature adds a grace period (7 days on GitLab.com) before deleted groups and projects are permanently removed. This feature allows recovery from accidental deletions without complex recovery operations.

By making data safety a core feature, GitLab can help better protect your work against data loss events.

### Delayed project deletion for user namespaces

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/project/working_with_projects.md#delete-a-project) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/536244)

{{< /details >}}

Delayed project deletion is now available for projects in user namespaces (personal projects). Previously, this safeguard against accidental data loss was only available for group namespaces. When you delete a project in your user namespace, it will now enter a “pending deletion” state for the duration configured in your instance settings (7 days on GitLab.com), rather than being immediately deleted. This creates a recovery window during which you can restore the project if needed.

We hope this enhancement provides greater peace of mind when managing your personal projects in GitLab.

### New `active` parameter for Groups and Projects REST APIs

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../api/projects.md#list-projects)

{{< /details >}}

We’ve added a new `active` parameter to our Groups and Projects REST APIs that simplifies filtering groups based on their status. When set to `true`, only non-archived groups or projects not marked for deletion are returned. When set to `false`, only archived groups or projects marked for deletion are returned. If the parameter is undefined, no filtering is applied. This enhancement helps you efficiently manage your workflows by targeting specific statuses through simple API calls.

Thank you [@dagaranupam](https://gitlab.com/dagaranupam) for adding this parameter to the Projects API.

### Rate limits for Groups, Projects, and Users API

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/gitlab_com/_index.md#rate-limits-on-gitlabcom) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/461316)

{{< /details >}}

We have added API rate limits for projects, groups, and users to improve platform stability and performance for all users. These changes are in response to increased API traffic that has been affecting our services.

The limits have been carefully set based on average usage patterns and should provide sufficient capacity for most use cases. If you exceed these limits, you’ll receive a “429 Too Many Requests” response.

For complete details about specific rate limits and implementation information, please [read the related blog post](https://about.gitlab.com/blog/rate-limitations-announced-for-projects-groups-and-users-apis/).

## Unified DevOps and Security

### Security scanners now support MR pipelines

<!-- categories: API Security, Container Scanning, DAST, Fuzz Testing, SAST, Secret Detection, Software Composition Analysis -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/detect/roll_out_security_scanning.md)

{{< /details >}}

You can now choose to run [Application Security Testing (AST) scanners](../../user/application_security/detect/_index.md) in [merge request (MR) pipelines](../../ci/pipelines/merge_request_pipelines.md).
To minimize the impact to your pipelines, this is as an opt-in behavior you can control.

Previously, the default behavior depended on whether you used the [Stable or Latest CI/CD template edition](../../user/application_security/detect/security_configuration.md#template-editions) to enable a scanner:

- In Stable templates, scan jobs ran in branch pipelines only. MR pipelines weren’t supported.
- In Latest templates, scan jobs ran in MR pipelines when an MR was open, and ran in branch pipelines if there was no associated MR. You couldn’t control this behavior.

Now, a new option, `AST_ENABLE_MR_PIPELINES`, allows you to control whether to run jobs in MR pipelines.
The default behavior for both Stable and Latest templates remains the same. Specifically:

- Stable templates continue to run scan jobs in branch pipelines by default, but you can set `AST_ENABLE_MR_PIPELINES: "true"` to use MR pipelines instead when an MR is open.
- Latest templates continue to run scan jobs in MR pipelines by default when an MR is open, but you can set `AST_ENABLE_MR_PIPELINES: "false"` to use branch pipelines instead.

This improvement affects all security scanning templates except for API Discovery (`API-Discovery.gitlab-ci.yml`), which currently defaults to MR pipelines.
We also changed the API Discovery template to align with other Stable templates in GitLab 18.0 and use branch pipeline by default.

### Display and filter archived projects in the compliance projects report

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate, Premium
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/compliance/compliance_center/compliance_projects_report.md#filter-the-compliance-projects-report) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/500520)

{{< /details >}}

In the compliance projects report, you can view the compliance frameworks applied to projects within a group or
subgroup.

However, the report lacked the ability to show whether a project is archived or not, which could be useful
information for managing compliance across active and archived projects.

As such, we’ve added an indicator to show whether a project is archived. This will provide you with better
visibility and context when reviewing compliance frameworks across both active and archived projects.

This feature includes:

- An archived status badge for each project in the compliance projects report to show whether a project is archived.
- A filter that allows you to toggle between archived, non-archived, or all projects.

### Create a workspace from merge requests

<!-- categories: Workspaces -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/workspace/configuration.md#create-a-workspace)

{{< /details >}}

You can now create a workspace directly from a merge request with the new **Open in Workspace** option. This feature automatically configures a workspace with the merge request’s branch and context, allowing you to:

- Review code changes in a fully configured environment.
- Run tests on the merge request branch to verify functionality.
- Make additional modifications to the merge request without local setup.

### View open merge requests targeting files

<!-- categories: Source Code Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/project/repository/files/_index.md#view-open-merge-requests-for-a-file) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/448868)

{{< /details >}}

Previously, when working on code files, you had no visibility into who else might be modifying
the same file in other branches. This lack of awareness led to merge conflicts, duplicated work,
and inefficient collaboration.

Now you can easily identify all open merge requests that modify the file you’re viewing in the
repository. This feature helps you:

- Identify potential merge conflicts before they happen.
- Avoid duplicating work that’s already in progress.
- Improve collaboration by providing visibility into in-flight changes.

A badge displays the number of open merge requests modifying the file, and hovering over it
reveals a popover with the list of these merge requests.

### Shared Kubernetes namespace for workspaces

<!-- categories: Workspaces -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/workspace/settings.md#shared_namespace)

{{< /details >}}

You can now create GitLab workspaces in a shared Kubernetes namespace. This removes the need to create
a new namespace for every workspace and eliminates the requirement to give elevated ClusterRole
permission to the agent. With this feature, you can more easily adopt workspaces in secure or
restricted environments, offering a simpler path to scale.

To enable shared namespaces, set the `shared_namespace` field in your agent configuration file to
specify the Kubernetes namespace you want to use for all workspaces.

Thank you to the half dozen community contributors who helped build this feature through
[GitLab’s Co-Create program](https://about.gitlab.com/community/co-create/)!

### Improved pod status visualizations in the dashboard for Kubernetes

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../ci/environments/kubernetes_dashboard.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/525081)

{{< /details >}}

You can use the dashboard for Kubernetes to monitor your deployed applications. Until now, pods with container errors like `CrashLoopBackOff` or `ImagePullBackOff` were displayed with a “Pending” or “Running” status, which makes it difficult to identify problematic deployments without using `kubectl`.

In GitLab 18.0, error states in the UI show a specific container’s status, similar to the `kubectl` output. Now, you can quickly identify and troubleshoot failing pods without leaving the GitLab interface.

### Exclude packages from license approval rules

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#license_finding-rule-type) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10203)

{{< /details >}}

In merge request approval policies, this new enhancement to license approval policies gives legal and compliance teams more control over which packages can use specific licenses. You can now create exceptions for pre-approved packages, even when they use licenses that would normally be blocked by your organization’s policies.

Previously, in license approval policies, if you blocked a license like AGPL-3.0, it was blocked for all packages across your organization. This created challenges when:

- Your legal team pre-approved specific packages with otherwise restricted licenses.
- You needed to use the same package across hundreds of projects.
- Different teams required different license exceptions.

With this release, you can maintain strict license governance while allowing necessary exceptions, significantly reducing approval bottlenecks and manual reviews. For example, you can:

- Define package-specific exceptions to your license approval rules using Package URL (PURL) format.
- Allow specific packages (or package versions) to use otherwise restricted licenses.
- Block specific packages (or package versions) from using generally allowed licenses.

To add exceptions, follow this workflow when you create or edit a license approval policy:

1. In your group, go to **Security & Compliance** > **Policies**
1. Create or edit a license approval policy.
1. Find the new package exception options in the visual editor or configure them in YAML mode.
1. Choose between allowlist or denylist mode for the licenses.
1. Add specific licenses to your policy.
1. For each license, define package exceptions in PURL format (for example, `pkg:npm/@angular/animation@12.3.1`).
1. Specify whether to include or exclude these packages from the license rule.

The policy then enforces your license rules while respecting the defined exceptions, giving you granular control over license compliance across your organization.

### Limit maximum user session length

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../administration/settings/account_and_limit_settings.md#set-sessions-to-expire-from-creation-date) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/395038)

{{< /details >}}

Administrators can now choose if the maximum length of a user session is computed from the initial sign-in or from the last activity. Users are notified that the session is ending, but cannot prevent the session from expiring or extend the session. This feature is disabled by default.

Thank you [John Parent](https://gitlab.kitware.com/john.parent) for your contribution!

### GitLab Query Language views enhancements

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/glql/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/15008)

{{< /details >}}

We’ve made significant improvements to GitLab Query Language (GLQL) views. These improvements include support for:

- The `>=` and `<=` operators for all date types
- The **View actions** dropdown in views
- The **Reload** action
- Field aliases
- Aliasing columns to a custom name in GLQL tables

We welcome your feedback on this enhancement, and on GLQL views in general, in [issue 509791](https://gitlab.com/gitlab-org/gitlab/-/issues/509791).

### Pages template improvements

<!-- categories: Pages -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/project/pages/getting_started/pages_new_project_template.md#project-templates)

{{< /details >}}

GitLab provides [templates for popular static site generators](https://gitlab.com/pages). We’ve taken a deep dive into available templates using a scoring framework, and refined the list to include only the most popular templates.

Refining templates available for GitLab Pages streamlines the website creation process. Use templates to launch professional-looking sites with minimal technical expertise. Enhanced templates also provide modern, responsive designs, eliminating the need for custom development work.

### Configure Jira issues from vulnerabilities using the Jira integration API

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../api/project_integrations.md#jira-issues) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/454574)

{{< /details >}}

Previously, you had to configure the integration to [create Jira issues from vulnerabilities](../../integration/jira/configure.md#create-a-jira-issue-for-a-vulnerability) from the **Project settings** page.

You can now configure this integration from the project integrations API, which allows you to automate the setup.

### Improved traceability of redetected vulnerabilities

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/vulnerabilities/_index.md#vulnerability-status-values) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/523452)

{{< /details >}}

Previously, when a resolved vulnerability was redetected and changed status, the vulnerability details did not provide information to indicate when and why the status change occurred.

GitLab now adds a system note to the vulnerability history when resolved vulnerabilities change status because they appeared in a new scan. This additional information helps users understand why vulnerabilities have changed status.

### Bulk add vulnerabilities to issues from the vulnerability report

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/vulnerability_report/_index.md#add-vulnerabilities-to-an-existing-issue) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13216)

{{< /details >}}

With this release you can now bulk add vulnerabilities to new or existing GitLab issues from the vulnerability report.
You may now associate multiple issues and vulnerabilities together. Additionally, related vulnerabilities are now listed within the issue page.

### Disable user invitations

<!-- categories: System Access -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../administration/settings/visibility_and_access_controls.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/19618)

{{< /details >}}

You can now remove the ability to invite members to groups or projects.

- On GitLab.com, this setting is configured by Owners of groups with enterprise users and applies to any sub-groups or projects within the top-level group. No user can send invites while this setting is enabled.
- On GitLab Self-Managed, this setting is by administrators and applies to the entire instance. Administrators can still invite users directly.

This feature helps organizations maintain strict control over membership access.

### LDAP authentication with GitLab username

<!-- categories: System Access -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/auth/ldap/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/215357)

{{< /details >}}

LDAP users can now authenticate requests with their GitLab username. Previously, if the GitLab username didn’t match their LDAP username, GitLab returned an authentication error. This change helps users maintain separate naming conventions in GitLab and LDAP systems without disrupting approval workflows.

### Support for SHA256 SAML certificates

<!-- categories: System Access -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../integration/saml.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/524624)

{{< /details >}}

GitLab now automatically detects and supports both SHA1 and SHA256 certificate fingerprints for Group SAML authentication. This maintains backward compatibility with existing SHA1 fingerprints while adding support for more secure SHA256 fingerprints. This upgrade is essential to prepare for the upcoming ruby-saml 2.x release that will make SHA256 the default.

### Granular permissions for job tokens in beta

<!-- categories: Permissions -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/jobs/fine_grained_permissions.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16199)

{{< /details >}}

Pipeline security just got more flexible. Job tokens are ephemeral credentials that provide access to resources in pipelines. Until now, these tokens inherited full permissions from the user, often resulting in unnecessarily broad access capabilities.

With our new [fine-grained permissions for job tokens](../../ci/jobs/fine_grained_permissions.md) beta feature, you can now precisely control which specific resources a job token can access within a project. This allows you to implement the principle of least privilege in your CI/CD workflows, granting only the minimal access necessary for each job to complete its tasks.

We’re actively seeking community feedback on this feature. If you have questions, want to share your implementation experience, or would like to engage directly with our team about potential improvements, please visit our [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/519575).

### New permissions for custom roles

<!-- categories: Permissions -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/custom_roles/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/14746)

{{< /details >}}

You can create custom roles with the [Manage protected environments](https://gitlab.com/gitlab-org/gitlab/-/issues/471385) permission.
Custom roles allow you to grant only the specific permissions users need to complete their tasks.
This helps you define roles that are tailored to the needs of your group, and can reduce the number of users who need the Maintainer or Owner role.

### New CI/CD analytics view for projects in limited availability

<!-- categories: Fleet Visibility -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../user/analytics/ci_cd_analytics.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/444468)

{{< /details >}}

The redesigned CI/CD analytics view transforms how your development teams analyze, monitor, and optimize pipeline performance
and reliability. Developers can access intuitive visualizations in the GitLab UI that reveal performance
trends and reliability metrics. Embedding these insights in your project repository eliminates context-switching
that disrupts developer flow. Teams can identify and address pipeline bottlenecks that drain productivity.
This enhancement leads to faster development cycles, improved collaboration, and data-driven confidence to optimize your
CI/CD workflows in GitLab.

### GitLab Runner 18.0

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 18.0 today! GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s new

- [Add `ConfigurationError` and `ExitCodeInvalidConfiguration` to the GitLab Runner build error classifications](https://gitlab.com/gitlab-org/gitlab/-/issues/514297)
- [Improve cloud provider error messages for failed cache uploads to cloud storage](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5527)

#### Bug Fixes

- [GitLab Runner can use cached images even when disallowed](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38706)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-0-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-0-stable/CHANGELOG.md).md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.0)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.0)
- [UI improvements](https://papercuts.gitlab.com/?milestone=18.0)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
