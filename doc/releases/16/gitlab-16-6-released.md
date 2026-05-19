---
stage: Release Notes
group: Monthly Release
date: 2023-11-16
title: "GitLab 16.6 release notes"
description: "GitLab 16.6 released with GitLab Duo Chat available in Beta"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On November 16, 2023, GitLab 16.6 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Joe Snyder

Joe Snyder was awarded GitLab’s 16.6 MVP for consistent contributions across GitLab, including
recent merge requests to [allow admins to filter runners by version](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135025).

Joe was nominated by [Miguel Rincon](https://gitlab.com/mrincon), Staff Frontend Engineer at GitLab.
Miguel recognized Joe’s efforts through several required rewrites due to GitLab’s evolving architecture
and commented on Joe’s “thoughtful consideration of performance and usability.”

[Pedro Pombeiro](https://gitlab.com/pedropombeiro), Sr. Backend Engineer at GitLab, added that “Joe Snyder drove this change over the
finish line after taking over from a former colleague, requiring learning all the context around the problem.
He also proved very responsive and patient with our feedback in successive reviews.”

“Joe has been a pleasure to work with,” said [Terri Chu](https://gitlab.com/terrichu), Staff Backend Engineer at GitLab.
Terri highlighted Joe’s ongoing work on [`emails_enabled` changes](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127899)
over the last (and previous) milestone.

Joe Snyder is a Senior R&D Engineer at [Kitware](https://www.kitware.com/) and has been contributing to GitLab since 2021.
Our many thanks to Joe for continuing to improve GitLab!

## Primary features

### GitLab Duo Chat available in Beta

<!-- categories: Duo Chat -->

{{< details >}}

- Tier: Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/gitlab_duo_chat/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10550)

{{< /details >}}

Everyone involved in the software development process can spend a significant amount of time familiarizing themselves with code, epics, issues, and lengthy discussion threads. You can often find yourself slowed down by routine tasks like writing summaries, documentation, tests, or even code. Having an expert at your side that can answer DevSecOps questions without judgment and address follow-ups could help you accelerate the software development process.

GitLab Duo Chat aims to actively address these pain points and accelerate your workflows. Its capabilities include:

- Explain or summarize issues, epics, and code.
- Answer specific questions about these artifacts like “Collect all the arguments raised in comments regarding the solution proposed in this issue.”
- Generate code or content based the information in these artifacts. For instance, “Can you write documentation for this code?”
- Or simply get you started from scratch like “Create a .GitLab-ci.yml configuration file for testing and building a Ruby on Rails application in a GitLab CI/CD pipeline.”
- Answer all your DevSecOps related question, whether you are beginner or an expert. For example, “How can I set up Dynamic Application Security Testing for a REST API?”
- Answer follow-up questions so you can iteratively work through all the above scenarios.

GitLab Duo Chat is available on GitLab.com as a Beta feature. It is also integrated into our Web IDE and GitLab Workflow extension for VS Code as Experimental features.

You can also help us mature these features by providing feedback about your experiences with Duo Chat, either within the product or via our [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/430124).

### Automatic claims of enterprise users

<!-- categories: User Management -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/enterprise_user/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9675)

{{< /details >}}

When a GitLab.com user’s primary email address matches an existing verified domain, the user is automatically claimed as an enterprise user. This gives the group Owner more user management controls and visibility into the user’s account. After a user becomes an enterprise user, they can only change their primary email to an email their organization owns as per its verified domains.

### Minimal forking - only include the default branch

<!-- categories: Source Code Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/repository/forking_workflow.md#create-a-fork)

{{< /details >}}

In previous versions of GitLab, when forking a repository, the fork always included all branches within the repository.
Now you can create a fork with only the default branch, reducing complexity and storage space.
Create minimal forks if you don’t need the changes that are currently being worked on in other branches.

The default method of forking will not change and continue to include all branches within the repository.
The new option shows which branch is the default, so that you are aware of exactly which branch will be included in the new fork.

### Allow users to enforce MR approvals as a compliance policy

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#any_merge_request-rule-type) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9696)

{{< /details >}}

There is an increasing scrutiny on code changes that can potentially land in production applications and open businesses up to compliance risk and security vulnerability. With scan result policies, you can ensure unilateral changes cannot be made by enforcing two person approval on all merge requests.

Scan results policies have a new option to target `Any merge request` which can be paired with defining [role-based approvers](../../user/application_security/policies/merge_request_approval_policies.md#require_approval-action-type) to ensure each MR for the defined branches require approval by two (or more) users with a given role (Owner, Maintainer, or Developer).

Available in SaaS in 16.6. Available for Self-managed behind the feature flag `scan_result_any_merge_request` and will be enabled by default in 16.7.

### Switchboard portal for GitLab Dedicated is now generally available

<!-- categories: Switchboard, GitLab Dedicated -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../administration/dedicated/_index.md) | [Related issue](https://about.gitlab.com/dedicated/)

{{< /details >}}

Switchboard, a new self-service portal, is now available for customers and team members to onboard, configure and maintain their [GitLab Dedicated](https://about.gitlab.com/dedicated/) instances.

Using Switchboard, you can now make some [configuration changes](../../administration/dedicated/_index.md) to your GitLab Dedicated instance. This functionality will expand in future releases.

### CI/CD components Beta release

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../ci/components/_index.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/9897)

{{< /details >}}

In GitLab 16.1, we [announced](https://about.gitlab.com/blog/introducing-ci-components/) the release of an exciting experimental feature called CI/CD components. The component is a pipeline building block that can be listed in the upcoming CI/CD catalog.

Today we are excited to announce the Beta availability of CI/CD components. With this release, we have also improved the components folder structure from the initial experimental version. If you are already testing the experimental version of CI/CD components, it’s essential to migrate to the [new folder structure](../../ci/components/_index.md#directory-structure). You can see some examples [here](https://gitlab.com/gitlab-components/). The old folder structure is deprecated and we plan to remove it within the next couple of releases.

If you try out CI/CD components, you are also welcome to try the new CI/CD catalog, currently available as an experimental feature. You can search the [Global CI/CD catalog](../../ci/components/_index.md) for components that others have created and published for public use. Additionally, if you create your own components, you can choose to publish them in the catalog too!

### Improved UI for CI/CD variable management

<!-- categories: Secrets Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/418005)

{{< /details >}}

CI/CD variables are a fundamental part of GitLab CI/CD, and we felt that we could offer a better experience for working with variables from the settings UI. So in this release we’ve updated the UI to use a new drawer that improves the flow of adding and editing CI/CD variables.

For example, the masking validation used to only happen when you tried to save the CI/CD variable, and if it failed you’d have to restart from scratch. But now with the new drawer, you get real time validation so you can adjust on the fly without needed to redo anything!

Your [feedback for this change](https://gitlab.com/gitlab-org/gitlab/-/issues/428807) is always valued and appreciated.

### Runner Fleet Dashboard - Starter metrics (Beta)

<!-- categories: Fleet Visibility -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../ci/runners/runner_fleet_dashboard.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/424495)

{{< /details >}}

Operators of self-managed runner fleets need observability and the ability to quickly answer critical questions about their runner fleet infrastructure at a glance. Now, with the Runner Fleet Dashboard - Admin View (Beta), you have actionable insights to help you quickly answer critical fleet management and developer experience questions, starting with instance runners. These include answers to questions like which runners have errors, the performance of the runner queues for CI job execution, and which runners are most actively used. Ultimate customers can enable this feature independently, but are encouraged to participate in the [early adopter’s program](https://gitlab.com/groups/gitlab-org/-/epics/11180).

## Scale and Deployments

### Hide archived projects in search results by default

<!-- categories: Global Search -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/search/_index.md#include-archived-projects-in-search-results) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10957)

{{< /details >}}

Previously, users saw many archived projects in their project search results. This was problematic, especially when archived projects took up many of the top results. We now filter out archived projects by default, and users can select **Include archived** to see all projects.

### Private group names are hidden from unauthorized users

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/manage.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/415165)

{{< /details >}}

Previously, the names of private groups were visible to all users when accessing the **Groups** tab of a project’s or group’s members page. To enhance security, we are now masking private groups’ name and source from users who are not members of the shared group, shared project, or invited group. Instead, this information will be displayed as **Private**.

### Comprehensive list of items that failed to be imported

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/import/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/386138)

{{< /details >}}

Previously, when migrating GitLab projects and groups by direct transfer had completed and some items (such as a merge requests or issues) were not
successfully imported, you could select a **Details** button on the
[page listing imported groups and projects](../../user/group/import/_index.md) and see related errors there.

However, a list of errors is not helpful to understand how many items in total, and which items in particular, were not imported. Having this
information is crucial to understanding the results of the import process.

In this release, we replaced the **Details** button with a **See failures** link. Selecting the **See failures** link takes you to a new page listing all items that failed
to import for a given group or project. For each item that wasn’t imported, you can see:

- The type of the item. For example, merge request or issue.
- What kind of error occurred.
- The correlation ID, which is useful for debugging purposes.
- The URL of the item on the source instance, if available (items with `iid`).
- The title of the item on the source instance, if available. For example, the merge request title or the issue title.

### Consistent navigation experience for all users

<!-- categories: Navigation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../tutorials/left_sidebar/_index.md)

{{< /details >}}

The 16.0 release introduced a new navigation experience, which became the default for all users on June 2, 2023. In subsequent milestones, many improvements were made based on a wealth of user feedback. The ability to fall back to the old navigation has now been removed. More exciting changes are planned for the navigation, but for now, all users have a consistent navigation experience.

As a recap, with the new GitLab navigation, you can:

- Pin menu items to save your most-used project or group items at the top
- Hide and “peek” the navigation to expose a wider screen
- Easily search for menu items by using keyboard shortcuts
- Continue to use all the themes you had with the previous navigation
- Use better-organized sections that align with a DevOps workflow

### GitLab Silent Mode

<!-- categories: Disaster Recovery -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/silent_mode/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9826)

{{< /details >}}

When GitLab Silent Mode is enabled, it blocks all major outbound traffic such as notification emails, integrations, webhooks, and mirroring from a GitLab instance. This allows you to perform testing against a GitLab site without generating traffic towards users and other integrations. You can use Silent Mode to test a restored backup or a promoted Geo DR site without impacting your primary GitLab site or your end users.

## Unified DevOps and Security

### Real-time Kubernetes status updates in the GitLab UI

<!-- categories: Deployment Management, Environment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/environments/kubernetes_dashboard.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/422945)

{{< /details >}}

In GitLab 16.6, you can use the cluster UI integration on your environment page to determine the status of currently running applications without leaving GitLab. Previously, the status was updated by a one-time request when the UI loaded, which made tracking deployment progress unwieldy. The current version of GitLab upgrades the underlying connection to use the Kubernetes watch API for the Flux reconciliation and Pod statuses, and provides near real-time updates of the cluster state in the GitLab UI.

### Connect to Kubernetes clusters with the GitLab CLI

<!-- categories: GitLab CLI, Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/clusters/agent/user_access.md#access-a-cluster-with-the-kubernetes-api) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/11455)

{{< /details >}}

From GitLab version 16.4, you can connect to a Kubernetes cluster from a local terminal using the agent for Kubernetes and a personal access token. In the initial version, setting up the local cluster configuration required several commands and a long lived access token. In the past month, we worked to streamline and improve the security of the set up process by extending the GitLab CLI.

The GitLab CLI can now list the agent connections available from a GitLab project checkout directory or the specified project. You can set up the connection through a selected agent with a dedicated command. When `kubectl` or any other tool needs to authenticate with the cluster, the GitLab CLI generates a temporary, restricted token for the signed-in user.

### Allow compliance teams to prevent pushing and force pushing into protected branches

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9706)

{{< /details >}}

One of several new settings being added to scan result policies to aide in [compliance enforcement of security policies](https://gitlab.com/groups/gitlab-org/-/epics/9704), this control will limit the ability to leverage project-level settings to circumvent policies.

For each existing or new scan result policy, you can enable `Prevent pushing and force pushing` to take effect for the branches defined within the policy to prevent users from circumventing the merge request flow to push changes directly to a branch.

Available in SaaS in 16.6. Available for Self-managed behind the feature flag `scan_result_policies_block_force_push` and will be enabled by default in 16.7.

### Group-level audit event streaming to AWS S3

<!-- categories: Audit Events -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

Building on our integrations with external logging or data aggregation tools, you can now select AWS S3 as a destination for audit event streams
for top-level groups. This feature provides relevant information for an easier and more trouble-free integration.

Previously, you had to use custom HTTP headers to try to build a request that AWS S3 would accept. This method was prone to errors and could be difficult to troubleshoot.

### Improved handling of unresponsive external status checks

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/project/merge_requests/status_checks.md#status-checks-widget)

{{< /details >}}

Previously, external status checks on MRs continued to poll the external URL until they received either a successful or failed response.
This could result in some status checks seeming to hang in an unresponsive state.

Now, a 2 minute timeout has been incorporated so that you can manually retry the status check after 2 minutes if you are not getting any
response from the external system.

### Changes to the vulnerability report's Tool filter

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/vulnerability_report/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/11237)

{{< /details >}}

Previously, the vulnerability report allowed you to filter by a static list of GitLab-supported tool types, followed by a dynamic list of custom scanners. With this release, you can now select tool type grouped by analyzer.

### Service accounts have optional expiry dates

<!-- categories: User Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/personal_access_tokens.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/421420)

{{< /details >}}

GitLab administrators and group Owners can choose if they want to enforce an expiry date for service accounts. Previously, service account tokens had to expire within a year, in line with personal, project, and group access token expiration limits. This allows administrators and group Owners to choose the balance between security and ease of use that best aligns with their goals.

### Prevent duplicate NuGet packages

<!-- categories: Package Registry -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/packages/nuget_repository/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/293748)

{{< /details >}}

You can use the GitLab Package Registry to publish and download your project’s NuGet packages. By default, you can publish the same package name and version multiple times.

However, you might want to prevent duplicate uploads, especially for releases. In this release, GitLab has expanded the group setting for the Package Registry so you can allow or deny duplicate package uploads.

You can adjust this setting with the [GitLab API](../../api/graphql/reference/_index.md#packagesettings), or from the UI.

### Upload packages to the Maven repository with basic HTTP authentication

<!-- categories: Package Registry -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/packages/maven_repository/_index.md#basic-http-authentication) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/277385)

{{< /details >}}

The GitLab Package Registry now supports uploading Maven packages with basic HTTP authentication. Previously, you could use basic HTTP authentication only to download Maven packages. This inconsistency made it difficult for developers to configure and maintain authentication for their project.

Publishing artifacts with `sbt` is not supported, but [issue 408479](https://gitlab.com/gitlab-org/gitlab/-/issues/408479) proposes to add this feature.

### Container Scanning: Exclude findings which won't be fixed

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/container_scanning/_index.md#available-cicd-variables) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/6846)

{{< /details >}}

Container scanning results may include findings which the vendor has evaluated and decided to not fix. To allow
you to focus on actionable findings, you can now exclude such findings. For configuration options please refer to the GitLab documentation.

### Include CVSS Vectors in the vulnerability report export

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/vulnerability_report/_index.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/11213)

{{< /details >}}

When you export information from the vulnerability report, the CVSS Vector information is now included.
This additional data helps you analyze and triage vulnerabilities outside GitLab.

### Added support for SBT projects using Java 21

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/421174)

{{< /details >}}

Dependency Scanning and License Scanning now support SBT projects using Java 21.

### DAST analyzer updates

<!-- categories: DAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dast/browser/checks/_index.md#active-checks)

{{< /details >}}

During the 16.6 release milestone, we enabled the following active checks for browser-based DAST by default:

- Check 94.1 replaces ZAP check 90019 and identifies server-side code injection (PHP).
- Check 94.2 replaces ZAP check 90019 and identifies server-side code injection (Ruby).
- Check 94.3 replaces ZAP check 90019 and identifies server-side code injection (Python).
- Check 943.1 replaces ZAP check 40033 and identifies improper neutralization of special elements in data query logic.
- Check 74.1 replaces ZAP check 90017 and identifies XSLT injection.

### macOS 14 (Sonoma) and Xcode 15 image support

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../ci/runners/hosted_runners/macos.md#supported-macos-images) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/431424)

{{< /details >}}

Teams can now seamlessly create, test, and deploy applications for the Apple ecosystem on macOS 14 and Xcode 15.

SaaS runners on macOS allow you to increase your development teams’ velocity in building and deploying applications that require macOS in a secure, on-demand GitLab Runner build environment integrated with GitLab CI/CD.

Try it out today by using `macos-14-xcode-15` as the image in your .GitLab-ci.yml file.

### GitLab Runner 16.6

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 16.6 today! GitLab Runner is the lightweight, highly-scalable agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s new

- [GitLab Runner Fleeting plugin for GCP Compute Engine - Beta](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29409)
- [Implement graceful shutdown for Docker executor](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/6359)
- [Dynamically create PVC volumes with storage classes for Kubernetes](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27835)
- [Override the container entrypoint through `image.entrypoint` in the Kubernetes executor](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30713)

#### Bug Fixes

- [Pods keep restarting with a Liveness probe failed error after upgrade to GitLab Runner 16.5.0](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36959)
- [Debug terminal - variable contains content of file instead of file path](https://gitlab.com/gitlab-org/gitlab/-/issues/399770)
- [Job execution pods in Kubernetes does not handle signals](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28162)
- [Services in GitLab Runner Docker executor using Podman do not start](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29480)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-6-stable/CHANGELOG.md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.6)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.6)
- [UI improvements](https://papercuts.gitlab.com/?milestone=16.6)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
