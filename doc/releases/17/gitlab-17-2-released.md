---
stage: Release Notes
group: Monthly Release
date: 2024-07-18
title: "GitLab 17.2 release notes"
description: "GitLab 17.2 released with Log streaming for Kubernetes pods and containers"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On July 18, 2024, GitLab 17.2 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Phawin Khongkhasawan

Everyone can [nominate GitLab’s community contributors](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)!
Show your support for our active candidates or add a new nomination! 🙌

Phawin Khongkhasawan is a Tech Lead at [Jitta](https://www.jitta.com/) and started contributing
to GitLab in February of 2024.
In just a few months, Phawin has merged over 20 contributions and his contributions have also been
featured in [16.11](https://about.gitlab.com/releases/2024/04/18/gitlab-16-11-released/#test-project-hooks-with-the-rest-api),
[17.0](https://about.gitlab.com/releases/2024/05/16/gitlab-17-0-released/#customize-avatars-for-users),
and [17.1](https://about.gitlab.com/releases/2024/06/20/gitlab-17-1-released/#require-confirmation-for-manual-jobs).

Phawin was first nominated by [Magdalena Frankiewicz](https://gitlab.com/m_frankiewicz), Product Manager at GitLab,
for improving Webhook related features like the request to [Allow triggering of project test webhooks via the API](https://gitlab.com/gitlab-org/gitlab/-/issues/455589).
GitLab engineers [Marc Shaw](https://gitlab.com/marc_shaw) and [Jose Ivan Vargas](https://gitlab.com/jivanvl),
and GitLab Product Manager [Rutvik Shah](https://gitlab.com/rutshah), highlighted Phawin’s patience
in collaboration and iteration, two of [GitLab’s core values](https://handbook.gitlab.com/handbook/values/).

“I really appreciate Phawin’s work, patience and perseverance on pushing the feature to [Add order by merged_at](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147052)
to the finish line,” says [Patrick Bajao](https://gitlab.com/patrickbajao), Staff Backend Engineer at GitLab.
“It took a couple of milestones before it got merged and deployed, but he didn’t stop and he continued
to collaborate with us.”

A big thank you to Phawin for showing how new contributors can make an immediate impact and help
co-create GitLab.

## Primary features

### Log streaming for Kubernetes pods and containers

<!-- categories: Environment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/environments/kubernetes_dashboard.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13793)

{{< /details >}}

In GitLab 16.1, we introduced the Kubernetes pod list and detail views. However, you still had to use third-party tools for an in-depth analysis of your workloads.
GitLab now ships with a log streaming view for pods and containers, so you can quickly check and troubleshoot issues across your environments without leaving your application delivery tool.

### GitLab Duo disabling input and output logging by default.

<!-- categories: Duo Chat -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: GitLab Duo Pro, GitLab Duo Enterprise
- Links: [Documentation](../../user/gitlab_duo/data_usage.md#data-retention) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13401)

{{< /details >}}

GitLab is now disabling AI input and output logging for GitLab Duo by default.

At GitLab, we aim to ensure that customers have sovereignty over their data.
We’ve now disabled input and output logging by default and will only log inputs and outputs with customers’ explicit
consent via a GitLab Support ticket.

### Block a merge request by requesting changes

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/merge_requests/reviews/_index.md#prevent-merge-when-you-request-changes)

{{< /details >}}

When you perform a review, you can complete it by choosing whether to `approve`, `comment`, or `request changes` ([released in GitLab 16.9](https://about.gitlab.com/releases/2024/02/15/gitlab-16-9-released/#request-changes-on-merge-requests)). While reviewing, you might find changes that should prevent a merge request from merging until they’re resolved, and so you complete your review with `request changes`.

When requesting changes, GitLab now adds a merge check that prevents merging until the request for changes has been resolved. The request for changes can be resolved when the original user who requested changes re-reviews the merge request and subsequently approves the merge request. If the user who originally requested changes is unable to approve, the request for changes can be **Bypassed** by anyone with merge permissions, so development can continue.

Leave us feedback about this new feature in [issue 455339](https://gitlab.com/gitlab-org/gitlab/-/issues/455339).

### Vulnerability Explanation

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../user/application_security/analyze/duo.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10642)

{{< /details >}}

Vulnerability Explanation is now a part of GitLab Duo Chat and is generally available. With Vulnerability Explanation, you can open chat from any SAST vulnerability to better understand the vulnerability, see how it could be exploited, and review a potential fix.

### OAuth 2.0 device authorization grant support

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/oauth2.md#device-authorization-grant-flow) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/332682)

{{< /details >}}

GitLab now supports the [OAuth 2.0 device authorization grant flow](https://datatracker.ietf.org/doc/html/rfc8628). This flow makes it possible to securely authenticate your GitLab identity from input constrained devices where browser interactions are not an option.
This makes the device authorization grant flow ideal for users attempting to use GitLab services from headless servers or other devices with no, or limited, UI.
Thank you [John Parent](https://kitware.com/) for your contribution!

### Pipeline execution policy type

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/pipeline_execution_policies.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13266)

{{< /details >}}

The pipeline execution policy type is a new type of [security policy](../../user/application_security/policies/_index.md) that allows users to support enforcement of generic CI jobs, scripts, and instructions.

The pipeline execution policy type enables security and compliance teams to enforce customized [GitLab security scanning templates](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Jobs), [GitLab or partner-supported CI templates](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates), 3rd party security scanning templates, custom reporting rules through CI jobs, or custom scripts/rules through GitLab CI.

The pipeline execution policy has two modes: inject and override. The *inject* mode injects jobs into the project’s CI/CD pipeline. The *override* mode replaces the project’s CI/CD pipeline configuration.

As with all GitLab policies, enforcement can be managed centrally by designated security and compliance team members who create and manage the policies. [Learn how to get started by creating your first pipeline execution policy](../../user/application_security/policies/pipeline_execution_policies.md)!

### Expanded support of custom rulesets in pipeline secret detection

<!-- categories: Secret Detection -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/secret_detection/pipeline/configure.md#customize-analyzer-rulesets) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/336395)

{{< /details >}}

We have expanded support of custom rulesets in pipeline secret detection.

You can use two new types of passthroughs, `git` and `url`, to configure remote rulesets. This makes it easier to manage workflows such as sharing ruleset configurations across multiple projects.

You can also extend the default configuration with a remote ruleset by using one of those new types of passthroughs.

The analyzer also now supports:

- Chaining up to 20 passthroughs into a single configuration to replace predefined rules.
- Including environment variables in passthroughs.
- Setting a timeout when loading a passthrough.
- Validating TOML syntax in ruleset configuration.

### GitLab Duo Chat and Code Suggestions available in workspaces

<!-- categories: Workspaces, Duo Chat, Code Suggestions -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/gitlab_duo/_index.md)

{{< /details >}}

[GitLab Duo Chat](../../user/gitlab_duo_chat/_index.md) and [Code Suggestions](../../user/project/repository/code_suggestions/_index.md) are now available in workspaces! Whether you’re seeking quick answers or efficient code improvements, Duo Chat and Code Suggestions are designed to boost productivity and streamline your workflow, making remote development in workspaces more efficient and effective than ever.

## Scale and Deployments

### Improved sorting and filtering in group overview

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/_index.md#view-a-group) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/437013)

{{< /details >}}

We have updated the sorting and filtering functionality of the group overview page. The search element now stretches across the whole page, allowing you to see your search strings better. We have standardized the sorting options to `Name`, `Created date`, `Updated date`, and `Stars`.

We welcome feedback about these changes in [issue 438322](https://gitlab.com/gitlab-org/gitlab/-/issues/438322).

### List groups that a group was invited to using the Groups API

<!-- categories: Source Code Management, Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/groups.md#list-shared-groups) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/424959)

{{< /details >}}

We added a new endpoint to the Groups API to list the groups a group has been invited to.
This functionality complements the [endpoint to list the projects that a group has been invited to](../../api/groups.md#list-shared-projects), so you can now get a complete overview of all the groups and projects that your group has been added to.
The endpoint is rate-limited to 60 requests per minute per user.

Thank you [@imskr](https://gitlab.com/imskr) for this community contribution!

### Resolve to-do items, one discussion at a time

<!-- categories: Notifications -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/todos.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/461111)

{{< /details >}}

Discussions on GitLab issues can get busy. GitLab helps you manage these conversations by raising a to-do item for comments that are relevant to you, and automatically resolves the item when you take an action on the issue.

Previously, when you took action on a thread in the issue, all to-do items were resolved, even if you were mentioned in several different threads. Now, GitLab resolves only the to-do item for the thread you interacted with.

### Indicate imported items in UI

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/import/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13825)

{{< /details >}}

You can import projects to GitLab from [other SCM solutions](../../user/import/_index.md). However, it was difficult to know
if project items were imported or created on the GitLab instance.

With this release, we’ve added visual indicators to items imported from GitHub, Gitea, Bitbucket Server, and Bitbucket Cloud where the creator is identified as a specific
user. For example, merge requests, issues, and notes.

### Deleted branches are removed from Jira development panel

<!-- categories: Settings -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../integration/jira/development_panel.md#feature-availability) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/351625)

{{< /details >}}

Previously, when using [GitLab for Jira Cloud app](../../integration/jira/connect-app.md), if you deleted a branch in GitLab, that branch still
appeared in Jira development panel. Selecting that branch caused a `404` error on GitLab.

From this release, branches deleted in GitLab are removed from the Jira development panel.

### Find project settings by using the command palette

<!-- categories: Settings, Global Search -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/search/command_palette.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/448637)

{{< /details >}}

GitLab offers many settings across projects, groups, the instance, and for yourself personally. To find the setting you’re looking for, you often have to spend time clicking through many different areas of the UI.

With this release, you can now search for project settings from the command palette. Try it out by visiting a project, selecting **Search or go to…**, entering command mode with `>`, and typing the name of a settings section, like **Protected tags**. Select a result to jump right to the setting itself.

## Unified DevOps and Security

### Merge commit message generation now GA

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message)

{{< /details >}}

Crafting commit messages is an important part of ensuring that future users understand what and why changes were made to the codebase. It’s challenging to come up with a message that communicates your changes effectively and takes into account everything you might have changed.

Generation of merge commits with GitLab Duo is now Generally Available to help ensure every merge request has quality commit messages. Before you merge, select **Edit commit message** in the merge widget, then use the **Generate commit message** option to have a commit message drafted.

This new GitLab Duo capability is a great way to make sure your project’s commit history is a valuable resource for future developers.

### GitLab Duo for the CLI now GA

<!-- categories: GitLab CLI -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](https://docs.gitlab.com/cli/)

{{< /details >}}

GitLab Duo for the CLI is now generally available for all users. You can now `ask` GitLab Duo to help you with finding the right `git` command for your need.

Use `glab duo ask <git question>` to have GitLab Duo provide you with formatted `git` commands to achieve your goals. The GitLab CLI then provides additional details on the commands and what they will do, including information on any flags being passed. You’re then able to run the commands and get their output directly in your workflow.

The `ask` command for the GitLab CLI is a great way to speed up your workflow with `git` commands you need a little extra help remembering.

### Pure SSH transfer protocol for LFS

<!-- categories: Source Code Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../administration/lfs/_index.md#pure-ssh-transfer-protocol) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/11872)

{{< /details >}}

Back in September 2021, [`git-lfs` 3.0.0](https://github.com/git-lfs/git-lfs/blob/main/CHANGELOG.md#300-24-sep-2021)
released support for using SSH as the transfer protocol instead of HTTP.
Prior to `git-lfs` 3.0.0, HTTP was the only supported transfer protocol
which meant using `git-lfs` at GitLab was not possible for some users.
With this release, we’re very excited to offer the ability to
enable support for SSH over HTTP as the transfer protocol for `git-lfs`.

Thank you to [Kyle Edwards](https://gitlab.com/KyleFromKitware) and
[Joe Snyder](https://gitlab.com/joe-snyder) for this contribution!

### Deployments and approvals to protected environments trigger an audit event

<!-- categories: Continuous Delivery -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/audit_event_types.md#continuous-delivery) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/456687)

{{< /details >}}

An accessible record of deployment events, like deployment approvals, is essential for compliance management. Until now, GitLab did not provide deployment-related audit events, so compliance managers had to use custom tooling or search for this data in GitLab directly. GitLab now provides three audit events:

- `deployment_started` records who started a deployment job, and when it was started.
- `deployment_approved` records who approved a deployment job, and when it was approved.
- `deployment_rejected` records who rejected a deployment job, and when it was rejected.

### Assigning frameworks at subgroup compliance center

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate, Premium
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/compliance_center/compliance_projects_report.md) | [Related epic](https://gitlab.com/gitlab-org/gitlab/-/issues/469004)

{{< /details >}}

The compliance center is the central location for compliance teams to
manage their compliance standards adherence reporting, violations reporting,
and compliance frameworks for their group.

Previously, all of the associated features of the compliance center were only available for top-level groups.
This meant that for subgroups, owners didn’t have access to any of the functionality provided by the compliance center on the top-level group.

To help address these key pain points, we’ve added the ability to assign and unassign compliance frameworks for subgroups. Now, group owners can
visualize their compliance posture at the subgroup level in addition to the full top-group-level compliance centre dashboard that was already available.

### Expand "Scan Execution Policies" to run `latest` templates for each GitLab analyzer

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/scan_execution_policies.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/415427)

{{< /details >}}

[Scan execution policies](../../user/application_security/policies/scan_execution_policies.md) have been expanded to allow you to choose between `default` and `latest` GitLab templates when defining the policy rules. While `default` reflects the current behavior, you may update your policy to `latest` to use features available only in the latest template of the given security analyzer.

By utilizing the `latest` template, you may now ensure scans are enforced on merge request pipelines, along with any other rules enabled in the `latest` template. Previously this was limited to branch pipelines or a specified schedule.

Note: Be sure to review all changes between `default` and `latest` templates before modifying the policy to ensure this suits your needs!

### Identify dates when multiple access tokens expire

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../security/tokens/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/467313)

{{< /details >}}

Administrators can now run a script that identifies dates when multiple access tokens expire. You can use this script in combination with other scripts on the [token troubleshooting page](../../security/tokens/token_troubleshooting.md) to identify and extend large batches of tokens that might be approaching their expiration date, if token rotation has not yet been implemented.

### OAuth authorization screen improvements

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../integration/oauth_provider.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/462655)

{{< /details >}}

The OAuth authorization screen now more clearly describes the authorization you are granting. It also includes a “verified by GitLab” section for applications that are provided by GitLab. Previously, the user experience was the same, regardless of whether an application was provided by GitLab or not. This new functionality provides an extra layer of trust.

### Streamlined instance administrator setup

<!-- categories: User Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/458985)

{{< /details >}}

The administrator setup experience for a new install of GitLab has been streamlined and made more secure. The initial administrator root email address is now randomzied, and administrators are forced to change this email address to an account that they can access. Previously, this step could have been delayed, and an administrator might forget to change the email address.

### User API added to the Snowflake Data Connector

<!-- categories: Audit Events, Compliance Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../integration/snowflake.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13004)

{{< /details >}}

In GitLab 17.2, we’ve added support for the [Users API](../../api/users.md#list-all-users) to the [GitLab Data Connector](https://app.snowflake.com/marketplace/listing/GZTYZXESENG/gitlab-gitlab-data-connector),
which is available in the Snowflake Marketplace app. You can now stream user data from self-managed GitLab instances to Snowflake using the Users API.

### Simplified setup for Google Cloud integration

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../tutorials/set_up_gitlab_google_integration/_index.md#secure-your-usage-with-google-cloud-identity-and-access-management-iam) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/454343)

{{< /details >}}

Google Cloud CLI commands are now natively available when setting up workload identity federation for the Google Cloud IAM integration. Previously, the guided setup used a script downloaded through cURL commands. Also, help text has been added to better describe the setup process. These improvements help group owners set up the Google Cloud IAM integration more quickly.

### Separate wiki page title and path fields

<!-- categories: Wiki -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/wiki/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/30758)

{{< /details >}}

In GitLab 17.2, wiki page titles are separate from their paths. In previous releases, if a page title changed, the path would also change, which could cause links to the page to break. Now, if a wiki page’s title changes, the path remains unchanged. Even if a wiki page path changes, an automatic redirect is set up to prevent broken links.

### Improvements to the wiki sidebar

<!-- categories: Wiki -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/wiki/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/281570)

{{< /details >}}

GitLab 17.2 adds several enhancements to how wikis display the sidebar. Now, a wiki displays all pages in the sidebar (up to 5000 pages), displays a table of contents (TOC), and provides a search bar to quickly find pages.

Previously, the sidebar lacked a TOC, making it challenging to navigate to sections of a page. The new TOC feature helps to see the page structure clearly, as well as navigate quickly to different sections, greatly improving usability.

The addition of a search bar makes discovering content easier. And because the sidebar now displays all pages, you can seamlessly browse an entire wiki.

### Document modules in the Terraform module registry

<!-- categories: Package Registry -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/packages/terraform_module_registry/_index.md#view-terraform-modules) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/451054)

{{< /details >}}

The Terraform module registry now displays Readme files! With this highly requested feature, you can transparently document the purpose, configuration, and requirements of each module.

Previously, you had to search other sources for this critical information, which made it difficult to properly evaluate and use modules. Now, with the module documentation readily available, you can quickly understand a module’s capabilities before you use it. This accessibility empowers you to confidently share and reuse Terraform code across your organization.

### Add type attribute to issues events webhook

<!-- categories: Team Planning, Notifications, Incident Management, Service Desk -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/integrations/webhook_events.md#work-item-events) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/467415)

{{< /details >}}

Issues, tasks, incidents, requirements, objectives, and key results
all trigger payloads under the **Issues Events** webhook category. Until now, there has been no way to quickly determine the type of object that triggered the webhook within the event payload. This release introduces an `object_attributes.type` attribute available on payloads within the **Issues events**, **Comments**, **Confidential issues events**, and **Emoji events** triggers.

### GitLab Advanced SAST available in Beta for Go, Java, and Python

<!-- categories: SAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/gitlab_advanced_sast.md)

{{< /details >}}

GitLab Advanced SAST is now available as a Beta feature for Ultimate customers.
Advanced SAST uses cross-file, cross-function analysis to deliver higher-quality results.
It now supports Go, Java, and Python.

During the Beta phase, we recommend running Advanced SAST in test projects, not replacing existing SAST analyzers.
To enable Advanced SAST, see the [instructions](../../user/application_security/sast/gitlab_advanced_sast.md#turn-on-gitlab-advanced-sast).
Starting in GitLab 17.2, Advanced SAST is included in the [`SAST.latest` CI/CD template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.latest.gitlab-ci.yml).

This is part of our iterative [integration of Oxeye technology](https://about.gitlab.com/blog/oxeye-joins-gitlab-to-advance-application-security-capabilities/).
In upcoming releases, we plan to move Advanced SAST to General Availability, add support for [other languages](https://gitlab.com/groups/gitlab-org/-/epics/14312), and introduce new UI elements to trace how vulnerabilities flow.
We welcome any testing feedback in [issue 466322](https://gitlab.com/gitlab-org/gitlab/-/issues/466322).

### API Security Testing now supports signed authentication requests

<!-- categories: API Security -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/api_security_testing/configuration/variables.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/458825)

{{< /details >}}

API Security already has support for “overrides” which can modify the requests sent by the scanner. However these overrides must be set ahead of time and cannot change based on the request itself. GitLab 17.2 adds a “per-request script” (`APISEC_PER_REQUEST_SCRIPT`), which allows a user to provide a C# script that is called prior to sending each request. This provides support for “signing” the request with a secret as a form of authentication.

### Container Scanning: Continuous Vulnerability Scanning OS support

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/container_scanning/continuous_container_scanning/_index.md#supported-package-types) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/10174)

{{< /details >}}

As a follow up to the Continuous Vulnerability Scanning for Container scanning MVC, during 17.2 we added support for APK and RPM operating system package versions.

This enhancement allows our analyzer to fully support Continuous Vulnerability Scans for Container Scanning advisories by comparing the package versions for [APK](https://gitlab.com/gitlab-org/gitlab/-/issues/428703) and [RPM](https://gitlab.com/gitlab-org/gitlab/-/issues/428941) operating system purl types.

As a note, RPM versions containing a caret (`^`) are not supported. Work to support these versions is being tracked in this [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/459969).

### DAST analyzer updates

<!-- categories: DAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dast/browser/checks/_index.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/13411)

{{< /details >}}

During the 17.2 release milestone, we published the following updates.

1. We added three new checks:

- Check 506.1 is a passive check that identifies request URLs that are likely compromised by the Polyfill.io CDN takeover.
- Check 384.1 is a passive check that identifies session fixation weaknesses, which could allow a valid session identifier to be reused by malicious actors.
- Check 16.11 is an active check that identifies when the TRACE HTTP debugging method is enabled on a production server, which could inadvertently expose sensitive information.

1. We addressed the following bugs to reduce false positives:

- DAST checks 614.1 (Sensitive cookie without Secure attribute) and 1004.1 (Sensitive cookie without HttpOnly attribute) no longer create findings when a site has cleared a cookie by setting an expiry date in the past.
- DAST check 1336.1 (Server-Side Template Injection) no longer relies on a 500 HTTP response status code to determine attack success.

1. We added the following enhancements:

- All response headers are now presented as evidence in a DAST vulnerability finding. This additional context reduces time spent on triaging findings.
- Sitemap.xml files are now crawled for additional URLs, leading to better coverage of target websites.

### API Fuzz Testing now supports signed authentication requests

<!-- categories: Fuzz Testing -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/api_fuzzing/configuration/variables.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/458825)

{{< /details >}}

API Fuzzing already has support for “overrides” which can modify the requests sent by the scanner. However these overrides must be set ahead of time and cannot change based on the request itself. GitLab 17.2 adds a “per-request script” (`FUZZAPI_PER_REQUEST_SCRIPT`), which allows a user to provide a C# script that is called prior to sending each request. This provides support for “signing” the request with a secret as a form of authentication.

### Secret push protection now available for Self-Managed, and improved warnings of potential leaks

<!-- categories: Secret Detection -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/secret_detection/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13107)

{{< /details >}}

During the 17.2 release milestone, we published the following updates:

- Secret Push Protection beta is now available for self-managed customers. After an administrator [enables the feature instance-wide](../../user/application_security/secret_detection/secret_push_protection/_index.md#allow-the-use-of-secret-push-protection-in-your-gitlab-instance), follow our documentation to [enable push protection](../../user/application_security/secret_detection/secret_push_protection/_index.md#enable-secret-push-protection-in-a-project) on your projects.
- [Warnings for potential leaks in text content](../../user/application_security/secret_detection/client/_index.md) have been enriched with more detail, making it easier to understand which type of secret is about to be leaked in a description or comment in either an issue, epic, or MR.

### Sort options for pipeline schedules

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/pipelines/schedules.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/37246)

{{< /details >}}

You can now sort the pipeline schedules list by description, ref, next run, created date, and updated date.

### `rules:changes:compare_to` now supports CI/CD variables

<!-- categories: Pipeline Composition, Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/yaml/_index.md#ruleschangescompare_to) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/369916)

{{< /details >}}

In GitLab 15.3 we introduced the [`compare_to` keyword](../../ci/yaml/_index.md#ruleschangescompare_to) for `rules:change`. This made it possible to define the exact ref to compare against. Beginning in GitLab 17.2, you can now use CI/CD variables with this keyword, making it easier to define and reuse `compare_to` values in multiple jobs.

### GitLab Runner 17.2

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re releasing GitLab Runner 17.2 today! GitLab Runner is the lightweight, highly scalable agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s new

- [GitLab Runner fleeting plugin for AWS EC2 instances (GA)](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29222)
- [Permit configuration of Runner `livenessProbe` and `readinessProbe`](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/issues/545)
- [Ability to enable and disable the `umask 0000` command for the Kubernetes executor](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28867)
- [Support for Red Hat OpenShift 4.16 for the GitLab Runner Operator](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/203)

#### Bug Fixes

- [GitLab Runner upgrade removes all cache volumes](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30876)

For a list of all changes, see the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-2-stable/CHANGELOG.md).

### New agent authorization strategy for workspaces

<!-- categories: Workspaces -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/workspace/gitlab_agent_configuration.md)

{{< /details >}}

With this release, we’ve implemented a new authorization strategy for workspaces to address the limitations of the legacy strategy while providing group owners and administrators more control and flexibility. With the new authorization strategy, group owners and administrators can control which cluster agents to use for hosting workspaces.

To ensure a smooth transition, users on the legacy authorization strategy are migrated automatically to the new strategy. Existing agents that support workspaces are allowed automatically in the root group where these agents are located. This migration also occurs even if these agents have been allowed in different groups in a root group.

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.2)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.2)
- [UI improvements](https://papercuts.gitlab.com/?milestone=17.2)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
