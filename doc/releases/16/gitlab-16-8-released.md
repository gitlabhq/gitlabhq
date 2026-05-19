---
stage: Release Notes
group: Monthly Release
date: 2024-01-18
title: "GitLab 16.8 release notes"
description: "GitLab 16.8 released with Static Analysis Findings in Merge request changes view"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On January 18, 2024, GitLab 16.8 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor

Ted has made significant contributions [removing old and unused code](https://gitlab.com/gitlab-org/gitlab/-/issues/420057)
from our helper files and addressing other maintenance tasks.
He was nominated by [Kerri Miller](https://gitlab.com/kerrizor), Staff Engineer at GitLab, who said,
“It’s not always glamorous work, but it’s important work”.

Ted is a freelance software engineer, avid climber, and cat enthusiast based in Orange County.

Martin was nominated by [Viktor Nagy](https://gitlab.com/nagyv-gitlab), Product Manager at GitLab, who said,
“He added many missing tests to the Auto Deploy jobs template and improved the [agentk Helm chart documentation](../../user/clusters/agent/install/_index.md#customize-the-helm-installation)”.

[Lee Tickett](https://gitlab.com/leetickett-gitlab), Engineer at GitLab, added that he
“has been joining community pairing sessions on [Discord](https://discord.gg/gitlab) and collaborating
closely with team members to contribute a heavily requested [search enhancement](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002) for merge requests”.

Martin is an IT Architect at Deutsche Telekom MMS GmbH based in Dresden, Germany.

Helio was nominated by [Hannah Sutor](https://gitlab.com/hsutor), Principal Product Manager at GitLab, who said,
“he has pushed our entire team forward by proposing the [ability to sign in using passkeys](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135324).
Helio’s MR was closed, but his contribution was deep, thought provoking, and his questions and open discussion will make our Passwordless implementation better”.

Helio is a software engineer with passion for Ruby and OSS.

Thank you Ted, Martin, and Helio! 🙌

## Primary features

### Static Analysis Findings in Merge request changes view

<!-- categories: SAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/_index.md#merge-request-changes-view) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10959)

{{< /details >}}

Static Analysis now supports displaying the findings in the Merge request changes view.
No need to navigate elsewhere – it’s all consolidated in one place. The UI is refined for a more straightforward encounter. For specifics, just open the drawer. Learn more from the linked documentation, demo video and rollout issue.

### Google Cloud Secret Manager support

<!-- categories: Secrets Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/secrets/gcp_secret_manager.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/11739)

{{< /details >}}

Secrets stored in Google Cloud Secret Manager can now be easily retrieved and used in CI/CD jobs. Our new integration simplifies the process of interacting with Google Cloud Secret Manager through GitLab CI/CD, helping you streamline your build and deploy processes! This is just one of the many ways [GitLab and Google Cloud are better together](https://about.gitlab.com/blog/gitlab-google-partnership-s3c/)!

### Workspaces are now generally available

<!-- categories: Workspaces -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/workspace/_index.md)

{{< /details >}}

We’re thrilled to share that Workspaces are now generally available and ready to improve your developer efficiency!

By creating secure, on-demand remote development environments, you can reduce the time you spend managing dependencies and onboarding new developers and focus on delivering value faster. With our platform-agnostic approach, you can use your existing cloud infrastructure to host your workspaces and keep your data private and secure.

Since their introduction in GitLab 16.0, workspaces have received improvements to error handling and reconciliation, support for private projects and SSH connections, additional configuration options, and a new administrator interface. These improvements mean that workspaces are now more flexible, more resilient, and more easily managed at scale.

### Enforce 2FA for GitLab administrators

<!-- categories: User Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../security/two_factor_authentication.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/427549)

{{< /details >}}

You can now enforce whether GitLab administrators are required to use two-factor authentication (2FA) in their self-managed instance. It is good security practice to use 2FA for all accounts, especially for privileged accounts like administrators. If this setting is enforced, and an administrator does not already use 2FA, they must set up 2FA on their next sign-in.

### Speed up your builds with the Maven dependency proxy

<!-- categories: Dependency Management, Package Registry -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/packages/package_registry/dependency_proxy/_index.md)

{{< /details >}}

A typical software project relies on a variety of dependencies, which we call packages. Packages can be internally built and maintained, or sourced from a public repository. Based on our user research, we’ve learned that most projects use a 50/50 mix of public and private packages. Package installation order is very important, as using an incorrect package version can introduce breaking changes and security vulnerabilities into your pipelines.

Now you can add one external Java repository to your GitLab project. After adding it, when you install a package using the dependency proxy, GitLab first checks for the package in the project. If it’s not found, GitLab then attempts to pull the package from the external repository.

When a package is pulled from the external repository, it’s imported into the GitLab project. The next time that particular package is pulled, it’s pulled from GitLab and not the external repository. Even if the external repository is having connectivity issues and the package is present in the dependency proxy, pulling the package still works, making your pipelines faster and more reliable.

If the package changes in the external repository (for example, a user deletes a version and publishes a new one with different files) the dependency proxy detects it. It invalidates the package, so GitLab pulls the newer one. This ensures the correct packages are downloaded, and helps reduce security vulnerabilities.

### Deeper insights into velocity in the Issue Analytics report

<!-- categories: Value Stream Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/issues_analytics/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/233905)

{{< /details >}}

The **Issue Analytics** report now contains information on the number of closed issues in a month to allow for a detailed velocity analysis. With this valuable addition, GitLab users can now gain insights into trends associated with their projects, and improve the overall turn-around time and value delivered to their customers. The **Issue Analytics** visualization contains a bar chart with the number of issues for each month, with a default time span of 13 months. You can access this chart from the drill-down in the [Value Streams Dashboard](../../user/analytics/value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports).

### New organization-level DevOps view with DORA-based industry benchmarks

<!-- categories: Value Stream Management, DORA Metrics -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/analytics/value_streams_dashboard.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/426516)

{{< /details >}}

We added a new **DORA Performers score** panel to the [Value Streams Dashboard](https://www.youtube.com/watch?v=EA9Sbks27g4) to visualize the status of the organization’s DevOps performance across different projects. This new visualization displays a breakdown of the DORA score (high, medium, or low) so that executives can understand the organization’s DevOps health top to bottom.

The [four DORA metrics](https://about.gitlab.com/solutions/value-stream-management/dora/#overview) are available out-of-the-box in GitLab, and now with the new DORA scores organizations can compare their DevOps performance against [industry benchmarks](https://dora.dev/) or peers. This benchmarking helps executives understand where they stand in relation to others, and identify best practices or areas where they might be lagging behind.

To help us improve the Value Streams Dashboard, please share feedback about your experience in this [survey](https://gitlab.fra1.qualtrics.com/jfe/form/SV_50guMGNU2HhLeT4).

## Scale and Deployments

### Omnibus improvements

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

From GitLab 16.8, you can specify commands to generate configurations for the following services in the
`gitlab.rb` file so that plaintext passwords are not exposed:

- GitLab Kubernetes Agent Server
- GitLab Workhorse
- GitLab Exporter

This means plaintext passwords for Redis no longer need to be stored in `gitlab.rb`.

## Unified DevOps and Security

### Smarter approval resets with `patch-id` support

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/project/merge_requests/approvals/settings.md#remove-all-approvals-when-commits-are-added-to-the-source-branch)

{{< /details >}}

To ensure all changes are reviewed and approved, it’s common to remove all approvals when new commits are added to a merge request. However, rebases also unnecessarily invalidated existing approvals, even if the rebase introduced no new changes, requiring authors to seek re-approval.

Merge request approvals now align to a [`git-patch-id`](https://git-scm.com/docs/git-patch-id). It’s a reasonably stable and reasonably unique identifier that enables smarter decisions about resetting approvals. By comparing the `patch-id` before and after the rebase, we can determine if new changes were introduced that should reset approvals and require a review.

If you have feedback about your experiences with resets now, let us know in [issue #435870](https://gitlab.com/gitlab-org/gitlab/-/issues/435870).

### View blame information directly in the file page

<!-- categories: Source Code Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/project/repository/files/git_blame.md#view-blame-for-a-file)

{{< /details >}}

In previous versions of GitLab, viewing file blame required you to access a different page. Now you can view the file blame information directly from the file page.

### Set CPU and memory usage per workspace

<!-- categories: Workspaces -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/workspace/gitlab_agent_configuration.md)

{{< /details >}}

Improved developer experience, onboarding, and security are driving more development toward cloud IDEs and on-demand development environments. However, these environments might contribute to increased infrastructure costs. You can already configure CPU and memory usage per project in your [devfile](../../user/workspace/_index.md#devfile).

Now you can also set CPU and memory usage per workspace. By configuring requests and limits at the GitLab agent level, you can prevent individual developers from using an excessive amount of cloud resources.

### Kubernetes 1.28 support

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/clusters/agent/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/432070)

{{< /details >}}

This release adds full support for Kubernetes version 1.28, released in August 2023. If you deploy your apps to Kubernetes, you can now upgrade your connected clusters to the most recent version and take advantage of all its features.

You can read more about our Kubernetes support policy and other supported Kubernetes versions.

### New customizable permissions

<!-- categories: Permissions -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/custom_roles/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/391760)

{{< /details >}}

There are five new abilities available you can use to create custom roles:

- Manage project access tokens.
- Manage group access tokens.
- Manage group members.
- Ability to archive a project.
- Ability to delete a project.

Add these abilities, along with other pre-existing custom abilities, to any base role to create a custom role. Custom roles allow you to define granular roles that only give a user the abilities they need to do their jobs, and reduce unnecessary privilege escalation.

### Assign a custom role with SAML SSO

<!-- categories: Permissions -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/saml_sso/_index.md#configure-gitlab) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/417285)

{{< /details >}}

Users can be assigned a custom role as the default role they are created with when they are provisioned with SAML SSO. Previously, only static roles could be chosen as the default. This allows automatically provisioned users to be assigned a role that best aligns with the principle of least privilege.

### Filter streaming audit events by sub group/project at group level

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../administration/compliance/audit_event_reports.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/11384)

{{< /details >}}

Streaming audit events have been extended to support filtering by sub-group or project at the group level, in addition to the existing support for event type filtering.

This additional filter will allow you to separate out events in your streams to send to different destinations, or to exclude irrelevant sub-groups/projects, ensuring you have the most actionable events for your team to monitor.

### Compliance framework management improvements

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/compliance_frameworks/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/11240)

{{< /details >}}

Our compliance center is becoming the central destination for understanding
compliance posture and managing compliance frameworks. We’re moving framework
management into a new tab in the compliance center, as well as adding more exciting
capabilities:

- View frameworks in a list view in the **Frameworks** tab.
- Search and filter to find specific frameworks.
- Use the new compliance framework sidebar to explore more details for each framework.
- Edit your framework to view all settings, including managing name, description, linked projects, and more.
- Create a quick report of your frameworks with an export to CSV.

### Instance-level audit event streaming to AWS S3

<!-- categories: Audit Events -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

Previously, you could configure only top-level group streaming audit events for AWS S3.

With GitLab 16.8, we’ve extended support for AWS S3 to instance-level streaming destinations.

### Enforce policy to prevent branches being deleted or unprotected

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9705)

{{< /details >}}

One of several new settings added to scan result policies to aide in [compliance enforcement of security policies](https://gitlab.com/groups/gitlab-org/-/epics/9704), branch modification controls will limit the ability to circumvent policies by changing project-level settings.

For each existing or new scan result policy, you can enable `Prevent branch modification` to take effect for the branches defined within the policy to prevent users from deleting or unprotecting those branches.

### SAML Group Sync for custom roles

<!-- categories: Permissions -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/saml_sso/group_sync.md#configure-saml-group-links) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/417201)

{{< /details >}}

You can now use SAML Group Sync to map custom roles to groups of users. Previously, you could only map SAML groups to GitLab’s static roles. This gives more flexibility to customers who use SAML Group Links to manage group membership and member roles.

### SAML SSO authentication for merge request approval

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/merge_requests/approvals/settings.md#require-user-re-authentication-to-approve) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/11084)

{{< /details >}}

For those using SAML SSO and SCIM for user account management in GitLab, you can now use SSO to meet the merge request authentication requirement
over password-based authentication for approving merge requests.

This method ensures only authenticated users can approve a merge request for security and compliance, without having to use a separate
password-based solution.

### Introduce group-level landing page for Analytics Dashboards

<!-- categories: Value Stream Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/analytics/value_streams_dashboard.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/433420)

{{< /details >}}

We are introducing a new landing page for the group-level analytics dashboard. This enhancement ensures a more consistent and user-friendly navigation experience. In the first phase this page includes the [Value Streams Dashboard](https://www.youtube.com/watch?v=8pLEucNUlWI), but it also sets the groundwork for future features, allowing you to personalize your dashboards. These improvements aim to streamline your experience, and provide more flexibility in managing and interpreting your data.

### View all ancestor items of a task or OKR

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/tasks.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/11197)

{{< /details >}}

With this release, you can now view the entire hierarchy lineage of a work item instead of just the immediate parent.

Work items include:

- Tasks, in all tiers.
- [Objectives and key results](../../user/okrs.md), in the Ultimate tier and behind a feature flag.

### Runner Fleet Dashboard: CSV export of compute minutes used by instance runners

<!-- categories: Fleet Visibility -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../ci/runners/runner_fleet_dashboard.md#export-compute-minutes-used-by-instance-runners) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/425853)

{{< /details >}}

You might need to run a report of CI/CD compute minutes used by projects on instance runners for various reasons. However, there wasn’t a simple to use mechanism in GitLab for you to generate a CI/CD compute minutes usage report. With this feature, you can export a report of CI/CD compute minutes used by each project on shared runners as a CSV file.

### GitLab Runner 16.8

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 16.8 today! GitLab Runner is the lightweight, highly-scalable agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s new

- [Overwrite generated Kubernetes pod specifications - Beta](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29659)

#### Bug Fixes

- [GitLab Runner authentication token exposed in the runner log file](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37224)
- [Registering multiple autoscaling runners results in a partial config.toml file](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37197)
- [Interrupt of the restore_cache helper task corrupts the cache](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36988)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-8-stable/CHANGELOG.md).

### Predefined variables for merge request description

<!-- categories: Secrets Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/variables/predefined_variables.md#predefined-variables-for-merge-request-pipelines) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/432846)

{{< /details >}}

If you use automation to work with merge requests in CI/CD pipelines, you might have wanted an easier way to fetch a merge request’s description without an API call. In GitLab 16.7 we introduced the `CI_MERGE_REQUEST_DESCRIPTION` predefined variable, making the description easily accessible in all jobs. In GitLab 16.8 we tweaked the behavior to truncate `CI_MERGE_REQUEST_DESCRIPTION` at 2700 characters, because very large descriptions can cause runner errors. You can check if the description was truncated with the newly introduced `CI_MERGE_REQUEST_DESCRIPTION_IS_TRUNCATED` predefined variable, which is set to `true` when the description was truncated.

### Windows 2022 support for SaaS runners on Windows

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Tier: Free, Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../ci/runners/hosted_runners/windows.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/438554)

{{< /details >}}

Teams can now build, test, and deploy applications on Windows Server 2022.

SaaS runners on Windows allow you to increase your development teams’ velocity in building and deploying applications that require Windows in a secure, on-demand GitLab Runner build environment integrated with GitLab CI/CD.

Try it out today by using `saas-windows-medium-amd64` as the tag in your .GitLab-ci.yml file.

### CI/CD Components Catalog section for your internal components

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../ci/components/_index.md#cicd-catalog) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/437768)

{{< /details >}}

As the number of items in the CI/CD catalog continues to expand, it is increasingly challenging for you to locate the CI/CD components released by your teams and available to you. In this release, we are introducing a dedicated **Your groups** tab, empowering you to effortlessly filter and identify the components associated with your organization. This simplified search process enhances efficiency, as you can more quickly find and use released CI/CD components.

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.8)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.8)
- [UI improvements](https://papercuts.gitlab.com/?milestone=16.8)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
