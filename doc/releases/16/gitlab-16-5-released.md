---
stage: Release Notes
group: Monthly Release
date: 2023-10-22
title: "GitLab 16.5 release notes"
description: "GitLab 16.5 released with Compliance standards adherence report"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On October 22, 2023, GitLab 16.5 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Thorben Westerhuys

Thorben was recognized for ongoing work on his merge request to [add a user preference to show
times in 24-hour format](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130789).
This feature is planned for 16.6 and will give users the choice between 12-hour and 24-hour time formats.

Magdalena Frankiewicz, Product Manager at GitLab, nominated Thorben and noted the issue
for this feature has been open for 7 years with over 190 upvotes. Peter Leitzen, Staff Backend
Engineer at GitLab, also highlighted Thorben’s work to [refactor backend code related to time
format](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130794).

Thorben is CTO of LUUCY, a 3D web platform bringing together high resolution geo data.
He is a former CTO of cividi, a geo spatial data consultancy for urban planning related topics.

Thank you to Thorben and the rest of the GitLab Community for contributing 🙌

## Primary features

### Compliance standards adherence report

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/compliance_center/_index.md)

{{< /details >}}

The Compliance Center now includes a new tab for the standards adherence report.
This report initially includes a GitLab best practices standard, showing when the
projects in your group are not meeting the requirements for the checks included in the standard. The
three checks shown initially are:

- Approval rule exists to require at least 2 approvers on MRs
- Approval rule exists to disallow the MR author to merge
- Approval rule exists to disallow committers to the MR to merge

The report contains details on the status of each check on a per project basis. It will
also show you when the check was last run, which standard the check applies to,
and how to fix any failures or problems that might be shown on the report. Future iterations
will add more checks and expand the scope to include more regulations and standards.
Additionally, we will be adding improvements to group and filter the report, so you
can focus on the projects or standards that matter most to your organization.

### Create rules to set target branches for merge requests

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/repository/branches/_index.md#configure-workflows-for-target-branches)

{{< /details >}}

Some projects use multiple long-term branches for development, like `develop` and `qa`. In these projects, you might want to keep `main` as the default branch since it represents the production state of the project. However, development work expects merge requests to target `develop` or `qa`. Target branch rules help ensure merge requests target the appropriate branch for your project and development workflow.

When you create a merge request, the rule checks the name of the branch. If the branch name matches the rule, the merge request pre-selects the branch you specified in the rule as the target. If the branch name does not match, the merge request targets the default branch of the project.

### Resolve an issue thread

<!-- categories: Team Planning -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/discussions/_index.md#resolve-a-thread) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/31114)

{{< /details >}}

Long-running issues with many threads can be challenging to read and track. You can now resolve a thread on an issue when the topic of discussion has concluded.

### Fast-forward merge trains with semi-linear history

<!-- categories: Merge Trains -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/pipelines/merge_trains.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/26996)

{{< /details >}}

In 16.4, we released [Fast-forward merge trains](https://about.gitlab.com/releases/2023/09/22/gitlab-16-4-released/#fast-forward-merge-support-for-merge-trains), and as a continuation, we want to ensure we support all [merge methods](../../user/project/merge_requests/methods/_index.md). Now, if you want to ensure your semi-linear commit history is maintained you can use semi-linear fast-forward merge trains.

## Scale and Deployments

### Find epics with advanced search

<!-- categories: Global Search -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/search/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/250699)

{{< /details >}}

The popularity of epics in GitLab continues to grow. Previously, finding epics was a little more difficult than other content types. With this release, you can now search and view results for epics when you use advanced search.

### Omnibus improvements

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- GitLab 16.5 `.deb` Linux packages have [switched from gzip to xz compression](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8197),
resulting in smaller package sizes. This change might result in slower unpacking times during installation.
- GitLab 16.5 includes [Mattermost 9.0](https://docs.mattermost.com/install/self-managed-changelog.html#release-v9-0-major-release).
This version removes the deprecated Insights feature, and
[Mattermost Boards and various plugins have transitioned to community support](https://forum.mattermost.com/t/upcoming-product-changes-to-boards-and-various-plugins/16669).
- GitLab 16.5 [moves the GitLab SELinux policy module](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/7165)
from `/opt/gitlab/embedded/selinux/rhel/7/` to `/opt/gitlab/embedded/selinux` to reflect that the module isn’t only for RHEL 7.

### Reviewer information for merge requests in the Jira development panel

<!-- categories: Settings -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../integration/jira/development_panel.md#information-displayed-in-the-development-panel) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/364273)

{{< /details >}}

With the [GitLab for Jira Cloud app](../../integration/jira/connect-app.md), you can connect GitLab and Jira Cloud to sync development information in real time. You can view this information in the Jira development panel.
Previously, when a reviewer was assigned to a merge request, the reviewer information was not displayed in the Jira development panel. With this release, the reviewer name, email, and approval status are displayed in the Jira development panel when you use the GitLab for Jira Cloud app.

### Changing context just got easier

<!-- categories: Navigation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../tutorials/left_sidebar/_index.md)

{{< /details >}}

We’ve heard your feedback that on the left sidebar, it can be hard to find the search button and to change between things like projects and preferences. In this release, we’ve made the button more prominent. This aids discoverability as well as streamlining workflows into a single touch point.

You can try it out by selecting the **Search or go to…** button or with a keyboard shortcut by typing / or s.

### Webhook now triggered when a release is deleted

<!-- categories: Notifications -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/integrations/webhook_events.md#release-events) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/418113)

{{< /details >}}

You can use release events to monitor release objects and react to changes. Previously, a webhook was only triggered when a release was created or updated. In heavily regulated industries, deleting releases is a crucial event that must be monitored and followed up.
With GitLab 16.5, a webhook is now also triggered when a release is deleted.

### Redesigned Service Desk issues list

<!-- categories: Service Desk -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/project/service_desk/using_service_desk.md)

{{< /details >}}

We’ve redesigned Service Desk issues list to load faster and more smoothly.
It now matches more closely the regular issues list. Available features include:

- The same sorting and ordering options as on the issue list.
- The same filters, including the OR operator and filtering by issue ID.

### Geo adds bulk resync and reverify buttons for all components

<!-- categories: Geo Replication, Disaster Recovery -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/geo/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/8212)

{{< /details >}}

You can now trigger bulk resync or reverify for any data component managed by Geo, through buttons in the Geo admin UI. Selecting the button will apply the operation to all data items related to the respective component. Before, this was only possible by logging into the Rails console. These actions are now more accessible, and the experience of troubleshooting and applying large scale changes that require a full resync or reverify of specific components, such as moving storage locations, is improved.

### Back up and restore repository data in the cloud

<!-- categories: Gitaly, Backup/Restore of GitLab instances -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/backup_restore/backup_gitlab.md#create-server-side-repository-backups) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10826)

{{< /details >}}

The GitLab backup and restore feature now supports storing repository data in object storage. This update improves performance by eliminating the intermediate steps used to create a large tarball, which needs to be manually stored in an appropriate location.

With this update, repository backups get stored in an object storage location of your choice (Amazon S3, Google Cloud Storage, Azure Cloud Data Storage, MinIO, etc.). This change eliminates the need to manually move data off of your Gitaly instance.

## Unified DevOps and Security

### Integrate deployment approval and approval rule changes into audit events

<!-- categories: Environment Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/audit_event_types.md#environment-management) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/415603)

{{< /details >}}

Deployments in regulated industries are a central topic of compliance. In previous releases, deployment approvals were not part of audited events, which made it difficult to tell when and how approval rules changed.

GitLab now ships with a new set of audit events for deployment approval and approval rule changes. These events fire when deployment approval rules change, or when approval rules for protected environments change.

### Use the API to delete a user's SAML and SCIM identities

<!-- categories: User Management -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../api/scim.md#delete-a-single-scim-identity) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/423592)

{{< /details >}}

Previously, group Owners had no way to programmatically delete SAML or SCIM identities. This made it difficult to troubleshoot issues with the user provisioning and sign-in processes. Now, group Owners can use new endpoints to delete these identities.

Thank you [jgao1025](https://gitlab.com/jgao1025) for your contribution!

### Export the compliance violations report

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/compliance_center/_index.md)

{{< /details >}}

The compliance violations report can contain a lot of information. Previously, you could only view the information in the GitLab UI. This was fine for individual issues, but
could be tricky if you needed to, for example:

- Create an artifact of the current compliance status for a release. For example, prove to an auditor that there were 0 violations.
- Aggregate the data with another data set or process it in another tool.

In GitLab 16.5, you can now export a list of the items included in the compliance violations report in CSV format.

### New customizable permissions

<!-- categories: User Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/custom_roles/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/17364)

{{< /details >}}

The permissions to manage group members and project access tokens have been added to the custom roles framework. You can add these permissions to any base role to create a custom role. By creating custom roles with only the permissions needed to accomplish a particular set of tasks, you do not have to unnecessarily assign highly privileged roles such as Maintainer and Owner to users.

### Instance-level audit event streaming to Google Cloud Logging

<!-- categories: Audit Events -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/compliance/audit_event_reports.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/11061)

{{< /details >}}

Previously, you could configure only top-level group streaming audit events for Google Cloud Logging.

With GitLab 16.5, we’ve extended support for Google Cloud Logging to instance-level streaming destinations.

### Configurable locked user policy

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../security/unlock_user.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/27048)

{{< /details >}}

Administrators can now configure a locked user policy for their instance by choosing the number of unsuccessful sign-in attempts, and how long the user is locked for. For example, five unsuccessful sign-in attempts would lock a user for 60 minutes. This allows administrators to define a locked user policy that meets their security and compliance needs. Previously, the number of sign-in attempts and locked user time period were not configurable.

### Activate and deactivate headers for streaming audit events

<!-- categories: Audit Events -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../administration/compliance/audit_event_reports.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/11109)

{{< /details >}}

Previously, you had to delete HTTP headers added to audit event streaming destinations, even if you only wanted to deactivate
them temporarily.

With GitLab 16.5, you can use the **Active** checkbox in the GitLab UI to toggle each header on and off individually. You can use this to:

- Test different headers.
- Temporarily deactivate a header.
- Switch between two versions of the same header.

### API to create PAT for currently authenticated user

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../api/users.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/425171)

{{< /details >}}

You can now use a new REST API endpoint at `user/personal_access_tokens` to create a new personal access token for the currently authenticated user. This token’s scope is limited to `k8s_proxy` for security reasons, so you can use it to only perform Kubernetes API calls using the agent for Kubernetes. Previously, only instance administrators could [create personal access tokens through the API](../../api/users.md).

### Vulnerability report grouping by status and severity

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/vulnerability_report/_index.md#group-vulnerabilities) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10164)

{{< /details >}}

As a user, you require the ability to group vulnerabilities so that you can more efficiently triage vulnerabilities. With this release, you are able to group by severity or status. This will help you better answer questions like how many confirmed vulnerabilities are in a group or project, or how many vulnerabilities still need to be triaged.

### Export individual wiki pages as PDF

<!-- categories: Wiki -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/wiki/_index.md#export-a-wiki-page) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/414691)

{{< /details >}}

From GitLab 16.5, you can export individual wiki pages as PDF files. Now, sharing team knowledge is even more seamless. Exporting a wiki to PDF can be used for a variety of use cases. For example, to provide a copy of technical documentation that is kept in a wiki or share information in a wiki with project status. Gone is the need to leverage alternative tools to convert Markdown files to PDF, since in some organizations, using these tools is prohibited, creating another challenge. Thank you to JiHu for contributing this feature!

### Add a child task, objective, or key result with a quick action

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/quick_actions.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/420797)

{{< /details >}}

You can now add a child item for a task, objective, or key result by using the `/add_child` quick action.

### Linked items widget in tasks, objectives, and key results

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/okrs.md#linked-items-in-okrs) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/416558)

{{< /details >}}

With this release, you can link [tasks](../../user/tasks.md#linked-items-in-tasks) and [OKRs](../../user/okrs.md#linked-items-in-okrs) as “related,” “blocked by,” or “blocking” to provide traceability between dependent and related work items.

When we migrate [epics](https://gitlab.com/groups/gitlab-org/-/epics/9290) and [issues](https://gitlab.com/groups/gitlab-org/-/epics/9584) to the work item framework, you will be able to link across all these types.

### Set a parent for a task, objective, or key result with a quick action

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/quick_actions.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/420798)

{{< /details >}}

You can now set a parent item for a task, objective, or key result by using the `/set_parent` quick action.

### DAST analyzer updates

<!-- categories: DAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dast/browser/checks/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/11426)

{{< /details >}}

During the 16.5 release milestone, we enabled the following active checks for browser-based DAST by default:

- Check 78.1 replaces ZAP check 90020 and identifies command injection, which can be exploited by executing arbitrary OS commands on the target application server. This is a critical vulnerability that can lead to a full system compromise.
- Check 611.1 replaces ZAP check 90023 and identifies External XML Entity Injection (XXE), which can be exploited by causing an application’s XML parser to include external resources.
- Check 94.4 replaces ZAP check 90019 and identifies “Server-side code injection (NodeJS)”, which can be exploited by injecting arbitrary JavaScript code to be executed on the server.
- Check 113.1 replaces ZAP check 40003 and identifies “Improper Neutralization of CRLF Sequences in HTTP Headers (‘HTTP Response Splitting’)”, which can be exploited by inserting Carriage Return / Line Feed (CRLF) characters to inject arbitrary data into HTTP responses.

### Make jobs API endpoint rate limit configurable

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../administration/settings/user_and_ip_rate_limits.md#maximum-authenticated-requests-to-projectidjobs-per-minute) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/395702)

{{< /details >}}

A rate limit for the `project/:id/jobs` API endpoint was added recently,
defaulting to 600 requests per minute per user. As a follow up iteration, we are making this limit
configurable, enabling instance administrators to set the limit that best matches their requirements.

### GitLab Runner 16.5

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 16.5 today! GitLab Runner is the lightweight, highly-scalable agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s new

- [GitLab Runner fleeting plugin for AWS EC2 instances - Beta](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29404)

#### Bug Fixes

- [Terminating a runner manager k8s pod results in orphaned worker pods](https://gitlab.com/gitlab-org/gitlab/-/issues/390645)
- [GitLab Runner 15.8.0 cannot checkout branches with special characters](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29606)
- [GitLab Runner pulls an x86-64 helper image, not the arm64 helper image, on an arm64 compute host](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27768)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-5-stable/CHANGELOG.md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.5)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.5)
- [UI improvements](https://papercuts.gitlab.com/?milestone=16.5)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
