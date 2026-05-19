---
stage: Release Notes
group: Monthly Release
date: 2023-06-22
title: "GitLab 16.1 release notes"
description: "GitLab 16.1 released with All new navigation experience"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On June 22, 2023, GitLab 16.1 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor

Gerardo has been consistently iterating over multiple releases to deliver
the [REST API endpoints for job token scope](https://gitlab.com/gitlab-org/gitlab/-/issues/351740).
Iteration is one of our [core values](https://handbook.gitlab.com/handbook/values/#iteration)
at GitLab, and Gerardo has exemplified that with his multiple contributions to deliver the feature.

Due to the change in [default `CI_JOB_TOKEN` behavior](../../update/deprecations.md),
users who automate creation of projects cannot also automate adding the projects allowed to use
a `CI_JOB_TOKEN` with the project. This REST API endpoint enables our customers to automate this
process again and drive increased adoption of a more secure `CI_JOB_TOKEN` workflow.

Thanks to Gerardo and the rest of the crew from Siemens!

Yuri picked up an [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/18287) that
was logged 6 years ago, took a [bias for action](https://handbook.gitlab.com/handbook/values/#bias-for-action)
(one of our GitLab values) and contributed a fix.

This was a popular feature that a number of customers were interested in. This enhancement
allows the system admin to skip specific projects during backup and restore, based on a comma-separated list of group
or project paths. With this feature, system admins can skip over stale
or archived projects during their backup run, save storage space and speed up the backup.
They can also exclude specific projects when restoring from backup using the same option.

Thanks to Yuri for his valuable contribution!

## Primary features

### All new navigation experience

<!-- categories: Navigation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../tutorials/left_sidebar/_index.md)

{{< /details >}}

GitLab 16.1 features an all-new navigation experience! We’ve defaulted this experience to on for all users. To get started, go to your avatar in the top right of the UI and turn on the **New navigation** toggle.

The new navigation was designed to solve three key areas of feedback: navigating GitLab can be overwhelming, it can be hard to pick up where you left off, and you can’t customize the navigation.

The new navigation includes a streamlined and improved left sidebar, where you can:

- Pin 📌 frequently accessed items.
- Completely hide the sidebar and “peek” it back into view.
- Easily switch contexts, search, and view subsets of data with the new **Your Work** and **Explore** options.
- Scan more quickly because of fewer top-level menu items.

We are proud of the new navigation and can’t wait to see what you think. Review a [list of what’s changed](https://gitlab.com/groups/gitlab-org/-/epics/9044#whats-different) and read our blog posts about the navigation [vision](https://about.gitlab.com/blog/gitlab-product-navigation/) and [design](https://about.gitlab.com/blog/overhauling-the-navigation-is-like-building-a-dream-home/).

Please try the new navigation and let us know about your experience in [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/409005). We are already [addressing](https://gitlab.com/gitlab-org/gitlab/-/issues/409005#actions-we-are-taking-from-the-feedback) the feedback and will eventually remove the toggle.

### Visualize Kubernetes resources in GitLab

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/environments/kubernetes_dashboard.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390769)

{{< /details >}}

How do you check the status of the applications running in your clusters? The pipeline status and environment pages provide insights about the latest deployment runs. However, previous versions of GitLab lacked insights about the state of your deployments. In GitLab 16.1, you can see an overview of the primary resources in your Kubernetes deployments.

This feature works with every connected Kubernetes cluster. It doesn’t matter if you deploy your workloads with the CI/CD integration or GitOps. To further improve the feature for Flux users, support for showing the synchronization status of an environment is proposed in [issue 391581](https://gitlab.com/gitlab-org/gitlab/-/issues/391581).

### Authenticate with service accounts

<!-- categories: System Access -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/groups.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/6777)

{{< /details >}}

There are many use cases for which a non-human user might need to authenticate. Previously, depending on the desired scope, users could use personal, project, or group access tokens to meet this need. These tokens were not ideal, due to still being either tied to a human (for personal access tokens), or an unnecessarily privileged role (for group and project access tokens).

Service accounts are not tied to a human user, and are more granular in scope. Service account creation and management is API-only. Support for a UI option is proposed in [issue 9965](https://gitlab.com/groups/gitlab-org/-/epics/9965).

### GitLab Dedicated is now generally available

<!-- categories: GitLab Dedicated -->

{{< details >}}

- Tier: Gold
- Offering: GitLab.com
- Links: [Documentation](../../subscriptions/gitlab_dedicated/_index.md) | [Related issue](https://about.gitlab.com/dedicated/)

{{< /details >}}

GitLab Dedicated is a fully managed, single-tenant SaaS deployment of our comprehensive DevSecOps platform designed to address the needs of customers with stringent compliance requirements.

Customers in highly-regulated industries are unable to adopt multi-tenant SaaS offerings due to strict compliance requirements like data isolation. With GitLab Dedicated, organizations can access all of the benefits of the DevSecOps platform – including faster releases, better security, and more productive developers – while satisfying compliance requirements such as data residency, isolation, and private networking.

[Learn more](https://about.gitlab.com/dedicated/) about GitLab Dedicated today.

### Manage job artifacts through the Artifacts page

<!-- categories: Job Artifacts -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/jobs/job_artifacts.md#view-all-job-artifacts-in-a-project)

{{< /details >}}

Previously, if you wanted to view or manage job artifacts, you had to go to each job’s detail page, or use the API. Now, you can view and manage job artifacts through the **Artifacts** page accessed at **Build > Artifacts**.

Users with at least the Maintainer role can use this new interface to delete artifacts too. You can delete individual artifacts, or bulk delete up to 100 artifacts at a time through either manual selection or checking the **Select all** option at the top of the page.

Please use the survey at the top of the Artifacts page to share any feedback you have about this new functionality. To view additional UI features under consideration, you can check out the [Build Artifacts page enhancements epic](https://gitlab.com/groups/gitlab-org/-/epics/8311).

### Improved CI/CD variables list view

<!-- categories: Secrets Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/410383)

{{< /details >}}

CI/CD variables are a key part of all pipelines and can be defined in multiple places, including in the project and group settings. To prepare for making bigger improvements that will help users intuitively navigate between variables at different hierarchy, we are starting out with improving the usability and layout of the variable list.

In GitLab 16.1, you will see the first iteration of these improvements. We have merged the “Type” and “Options” columns into a new **Attributes** column, which better represents these related attributes. We appreciate your feedback on how we can continue to improve the CI/CD variable experience, you are welcome to comment in our [variables improvement epic](https://gitlab.com/groups/gitlab-org/-/epics/10506).

## Scale and Deployments

### GitLab chart improvements

<!-- categories: Cloud Native Installation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/charts/)

{{< /details >}}

- GitLab 16.1 replaces `busybox` Docker image with `gitlab-base` Docker image to share layers with other GitLab
Docker images. This implementation treats `gitlab-base` as a helper image (like `kubectl` and `certificates`),
with optional local overrides.

### Omnibus improvements

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- GitLab 16.1 adds support for building and releasing packages on
[Debian 12 `Bookworm`](https://www.debian.org/releases/bookworm/) that released on June 10, 2023.

### Improved domain verification

<!-- categories: User Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/enterprise_user/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/375492)

{{< /details >}}

Domain verification serves multiple purposes across GitLab. Previously, in order to verify a domain, you had to complete the [GitLab Pages](../../user/project/pages/_index.md) wizard, even if you were verifying a domain for a purpose outside of GitLab Pages.

Now, domain verification lives at the group level, and has been streamlined. This makes it easier to verify your domains.

### View Vulnerability Report as Customizable Permission

<!-- categories: System Access -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/permissions.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/10160)

{{< /details >}}

The ability to view the vulnerability report is now split into a separate permission, enabling GitLab administrators and group owners to create a custom role with this permission. Previously, viewing the vulnerability report was limited to the Developer role and above. Now, any user can view the vulnerability report, as long as they are assigned a custom role that has the permission.

### Password reset email sent to any verified email address

<!-- categories: User Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/user_passwords.md#change-your-password) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/16311)

{{< /details >}}

If you forget your GitLab password, you can now reset it by email with any verified email address. Previously, only the primary email address was used for reset requests. This made it difficult to complete the password reset process if the primary email inbox was inaccessible.

### SCIM identities included in users API response

<!-- categories: System Access, Source Code Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/users.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/324247)

{{< /details >}}

The users API now returns the SCIM identities for a user. Previously, this information was included in the UI but not the API.

### Reintroduction of OmniAuth Shibboleth support

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../integration/shibboleth.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/393065)

{{< /details >}}

Shibboleth OmniAuth support has been re-introduced to GitLab. It was previously [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/388959) in GitLab 15.9 due to lack of upstream support. Thanks to a generous community contribution by [lukaskoenen](https://gitlab.com/lukaskoenen), who took on upstream support, `omniauth-shibboleth-redux` is now supported in self-managed GitLab.

### Select administrator access for personal access tokens in Admin Mode

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/profile/personal_access_tokens.md#personal-access-token-scopes) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/42692)

{{< /details >}}

GitLab administrators can use Admin Mode to work as a non-administrator user, and turn on administrator access when needed. Previously, an administrator’s personal access token (PAT) always had permissions to perform API actions as an administrator. Now, when adding a PAT, an administrator can decide if that PAT has administrator access to perform API actions or not, by selecting the Admin Mode scope. An administrator must enable Admin Mode for the instance to use this feature.

Thank you [Jonas Wälter](https://gitlab.com/wwwjon), [Diego Louzán](https://gitlab.com/dlouzan), and [Andreas Deicha](https://gitlab.com/TrueKalix) for contributing!

### Prevent user from deleting account

<!-- categories: User Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/settings/account_and_limit_settings.md#prevent-users-from-deleting-their-accounts) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/26053)

{{< /details >}}

Administrators can prevent users from deleting their account with a new user restrictions configuration setting. If this setting is enabled, users will no longer be able to delete their accounts, preserving auditable account information.

### Personal access token `last_used` value updated more frequently

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/personal_access_tokens.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/410168)

{{< /details >}}

The `last_used` value for personal access tokens (PAT) was previously updated every 24 hours. It is now updated every 10 minutes. This increases visibility of PAT usage and, in the case of PAT compromise, reduces risk because it takes less time before malicious activity is noticed.

Thank you [Jacob Torrey](https://thinkst.com/) for your contribution!

### More detail in completed GitHub project import summary

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/import/github.md#check-status-of-imports) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/386748)

{{< /details >}}

When a GitHub project finished importing, GitLab showed a simple summary of imported entities. However, GitLab didn’t show exactly which GitHub
entities failed to import nor the errors that caused the import failures. This made it difficult to decide if import results were satisfactory or not.

In this release, we have extended the import summary to include a list of GitHub entities that weren’t imported and, if possible, provide
a direct link to these entities on GitHub. GitLab now also shows an error for each failure. This helps you understand how well the import worked
and helps you troubleshoot problems.

### Show external user as a comment author in Service Desk issues

<!-- categories: Service Desk -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/project/service_desk/_index.md)

{{< /details >}}

When a requester replies to a Service Desk email, it is useful to the Service Desk agent to know who made the comment. But because the requester can be an external user with no GitLab account or access to the GitLab project, these comments were previously attributed to the GitLab Support Bot. From now on, email replies from requesters will be attributed to the external users, making it more clear who made the comments in the GitLab issue.

### Issue URL placeholder in Service Desk emails

<!-- categories: Service Desk -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/project/service_desk/_index.md)

{{< /details >}}

For Service Desk requesters, it can be helpful to access the Service Desk issue directly rather than interact with the Service Desk request only via email. We are introducing a new placeholder `%{ISSUE_URL}`, that you can use in your email templates (for example, the “thank you” email) to link requesters directly to the Service Desk issue.

### Backup adds the ability to skip projects

<!-- categories: Backup/Restore of GitLab instances -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/18287)

{{< /details >}}

The built-in backup and restore tool adds the ability to skip specific repositories. The Rake task now accepts a list of comma-separated group or project paths to be skipped during the backup or restore by using the new `SKIP_REPOSITORIES_PATHS` environment variable. This will allow you to skip, for example, stale or archived projects which do not change over time, saving you a) time by speeding up the backup run, and b) space by not including this data in the backup file.
Thanks to [Yuri Konotopov](https://gitlab.com/nE0sIghT) for this [community contribution](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121865)!

### Geo adds filtering by replication status to all components

<!-- categories: Geo Replication, Disaster Recovery -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/geo/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/411981)

{{< /details >}}

Geo adds filtering by replication status to all components managed by the [self-service framework](../../development/geo/framework.md). Now you can filter items in the replication details views by “In progress”, “Failed”, and “Synced” status making it easier and faster to locate data that is failing to synchronize.

### Geo verifies Design repositories

<!-- categories: Geo Replication, Disaster Recovery -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/geo/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/355660)

{{< /details >}}

When you add a design to an issue, a design Git repository is created or updated, and an LFS object and an upload (for the thumbnails) are created. Geo already verifies LFS objects and uploads, and now it also verifies the design repositories as well. Now that all underlying data of [Design Management](../../user/project/issues/design_management.md) is verified, your design data is ensured to not be corrupted in transfer or at rest. If Geo is used as part of a disaster recovery strategy, this protects you against data loss.

## Unified DevOps and Security

### Comment on whole file in merge requests

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/project/merge_requests/changes.md#add-a-comment-to-a-merge-request-file)

{{< /details >}}

Merge requests now support commenting on an entire file, because not all merge request feedback is line-specific. If a file is deleted, you might want more information about why. You might also want to provide feedback about a filename, or general comments about structure.

### Create a changelog from the GitLab CLI

<!-- categories: GitLab CLI -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/project/changelogs.md#from-the-gitlab-cli)

{{< /details >}}

Changelogs generate comprehensive lists of changes based on commits to a project. They can be challenging to automate or view, and require interacting with the GitLab API.

With the release of [GitLab CLI v1.30.0](https://gitlab.com/gitlab-org/cli/-/releases/v1.30.0) you can now generate changelogs for projects directly from your shell. The `glab changelog generate` command makes it easier to review, automate, and publish changelogs.

Thanks [Michael Mead](https://gitlab.com/michael-mead) for your contribution!

### Fail closed for invalid Security Policy approval checks

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/merge_requests/approvals/_index.md#invalid-rules) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/389905)

{{< /details >}}

Security and compliance policies allow organizations to enforce checks and balances across multiple projects to align with their security and governance programs. It’s critical for our customers to ensure changes that impact policies do not result in the guardrails coming down. With this update, invalid rules will “fail closed”, blocking MRs until invalid rules in any scan result policies are addressed.

### Install npm packages from your group or subgroup

<!-- categories: Package Registry -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/packages/npm_registry/_index.md#install-from-a-group) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/299834)

{{< /details >}}

You can use your project’s Package Registry to publish and install npm packages. You simply authenticate using an access token (personal, job, deploy, or project) and start publishing packages to your GitLab project.

This works great if you have a small number of projects. Unfortunately, if you have multiple projects, you might quickly find yourself adding dozens or even hundreds of different sources. It is common for teams in large organizations to publish packages to their project’s Package Registry alongside the source code and pipelines. Simultaneously, they need to be able to easily install dependencies from other projects within the groups and subgroups in their organization.

To make sharing packages easier between projects, you can now install packages from your group so you don’t have to remember which package lives in which project. Using an authentication token of your choice, you can install any of the group npm packages after you add your group as a source for npm packages.

### Add a description to design uploads

<!-- categories: Portfolio Management, Design Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/issues/design_management.md#add-a-design-to-an-issue) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9694)

{{< /details >}}

Currently the [Design uploads](../../user/project/issues/design_management.md#add-a-design-to-an-issue) have no metadata to explain their purpose, or why they are being uploaded. We’ve added a text box as a description so you can help users understand the image better.

### Configure the static file directory in GitLab Pages

<!-- categories: Pages -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/pages/introduction.md#customize-the-default-folder) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/10126)

{{< /details >}}

You can now configure the static file directory for GitLab Pages to any name (by default `public`).
This makes it easier to use Pages with popular static site frameworks such as Next.js, Astro, or Eleventy,
without needing to change the output folder in their configuration.

### Code Quality analyzer updates

<!-- categories: Code Quality -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../ci/testing/code_quality.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/412459)

{{< /details >}}

GitLab Code Quality supports [integrating tools you already run](../../ci/testing/code_quality.md) and also offers [a CI/CD template](../../ci/testing/code_quality.md) that runs the CodeClimate scanning system. We published the following updates to the CodeClimate-based analyzer during the 16.1 release milestone:

- Updated CodeClimate to version 0.96.0. This version includes:
  - A new plugin for `golangci-lint`.
  - A new available version for the `bundler-audit` plugin.
- Added support for a configurable path to the Docker API Socket.
  - Thanks to [`@tsjnsn`](https://gitlab.com/tsjnsn) for this [community contribution](https://gitlab.com/gitlab-org/ci-cd/codequality/-/merge_requests/73). Updates to include this variable in the CI/CD template are tracked in [an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/409738).

See the [CHANGELOG](https://gitlab.com/gitlab-org/ci-cd/codequality/-/blob/master/CHANGELOG.md?ref_type=heads#anchor-0960) for further details.

If you [include the GitLab-managed Code Quality template](../../ci/testing/code_quality.md) ([`Code-Quality.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Code-Quality.gitlab-ci.yml)), you automatically receive these updates.

For Code Quality changes in previous releases, see [the most recent update](https://about.gitlab.com/releases/2023/04/22/gitlab-15-11-released/#static-analysis-analyzer-updates).

### SAST analyzer updates

<!-- categories: SAST -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/analyzers.md) | [Related issue](../../user/application_security/_index.md)

{{< /details >}}

GitLab SAST includes [many security analyzers](../../user/application_security/sast/_index.md#supported-languages-and-frameworks) that the GitLab Static Analysis team actively maintains, updates, and supports. We published the following updates during the 16.1 release milestone:

- The Semgrep-based analyzer is updated to use version 1.23.0 of the Semgrep engine. We’ve also [clarified guidance and improved efficacy](https://docs.gitlab.com/#clearer-guidance-and-better-coverage-for-sast-rules) of the GitLab-managed rules that are used to scan C, C#, Go, and Java. See the [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/CHANGELOG.md#v434) for further details.
- The SpotBugs-based analyzer now supports changing the “effort level” by [setting the `SAST_SCANNER_ALLOWED_CLI_OPTS` CI/CD variable](../../user/application_security/sast/_index.md#security-scanner-configuration). This allows you to improve performance by reducing the scan’s precision and its ability to detect vulnerabilities. See the [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs/-/blob/master/CHANGELOG.md#v420) for further details.

If you [include the GitLab-managed SAST template](../../user/application_security/sast/_index.md) ([`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)) and run GitLab 16.0 or higher, you automatically receive these updates.
To remain on a specific version of any analyzer and prevent automatic updates, you can [pin its version](../../user/application_security/sast/_index.md).

For previous changes, see [last month’s updates](https://about.gitlab.com/releases/2023/05/22/gitlab-16-0-released/#sast-analyzer-updates).

### Automatic response to leaked Google Cloud secrets

<!-- categories: Secret Detection -->

{{< details >}}

- Tier: Gold
- Links: [Documentation](../../user/application_security/secret_detection/automatic_response.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/8835)

{{< /details >}}

We’ve integrated Secret Detection with Google Cloud to better protect customers who use GitLab to develop applications on Google Cloud. Now, if an organization leaks a Google Cloud credential to a public project on GitLab.com, GitLab can automatically protect the organization by working with Google Cloud to protect the account.

Secret Detection searches for three types of secrets issued by Google Cloud:

- [Service account keys](https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys)
- [API keys](https://cloud.google.com/docs/authentication/api-keys)
- [OAuth client secrets](https://support.google.com/cloud/answer/6158849#rotate-client-secret)

Publicly leaked secrets are sent to Google Cloud after they’re discovered. Google Cloud verifies the leaks, then works to protect customer accounts against abuse.

This integration is on by default for projects that have [enabled Secret Detection](../../user/application_security/secret_detection/_index.md) on GitLab.com. Secret Detection scanning is available in all GitLab tiers, but an automatic response to leaked secrets is currently only available in Ultimate projects.

See [the blog post about this integration](https://about.gitlab.com/blog/how-secret-detection-can-proactively-revoke-leaked-credentials/) for further details.

### Clearer guidance and better coverage for SAST rules

<!-- categories: SAST -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/analyzers.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/382119)

{{< /details >}}

We’ve updated the GitLab SAST rules to:

- More clearly explain the type of weakness each rule targets and how to fix it. We’ve updated the description and guidance text for C, C#, Go, and Java rules so far. The remaining languages are tracked in [issue 382119](https://gitlab.com/gitlab-org/gitlab/-/issues/382119).
- Catch additional vulnerabilities in existing Java rules.

These improvements are part of a collaboration between the GitLab Static Analysis and Vulnerability Research teams to [improve the default Static Analysis rulesets](https://gitlab.com/groups/gitlab-org/-/epics/8170).
We would welcome any feedback on the default rules for SAST, Secret Detection, and IaC Scanning in [epic 8170](https://gitlab.com/groups/gitlab-org/-/epics/8170).

For more details on the changes to GitLab SAST rules, see the [CHANGELOG](https://gitlab.com/gitlab-org/security-products/sast-rules/-/blob/main/CHANGELOG.md).
As of GitLab 16.1, the [`sast-rules` project](https://gitlab.com/gitlab-org/security-products/sast-rules) is the single source of all GitLab-managed default rules used in the Semgrep-based SAST analyzer.

### Shared ruleset customizations in SAST, IaC Scanning, and Secret Detection

<!-- categories: SAST, Secret Detection -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/customize_rulesets.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/362958)

{{< /details >}}

You can now set a CI/CD variable to share ruleset customizations for [SAST](../../user/application_security/sast/customize_rulesets.md), [IaC Scanning](../../user/application_security/iac_scanning/_index.md), or [Secret Detection](../../user/application_security/secret_detection/pipeline/_index.md) across more than one project.

Sharing a ruleset can help you:

- [Disable predefined rules](../../user/application_security/sast/customize_rulesets.md) that you don’t want to focus on in your projects.
- [Change fields in predefined rules](../../user/application_security/sast/customize_rulesets.md), including the description, message, name, or severity, to reflect organizational preferences. For example, you could adjust the default severity of a rule or add information about how to remediate a finding.
- [Build a custom ruleset](../../user/application_security/sast/customize_rulesets.md) by adding or replacing rules. This option is available only for some analyzers.

Further improvements in this area are discussed in [an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/257928).

### CI/CD: Use `needs` in `rules`

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../ci/yaml/_index.md#rulesneeds) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/31581)

{{< /details >}}

The [needs:](../../ci/yaml/_index.md#needs) keyword defines a dependency relationship between jobs, which you can use to set jobs to run out of stage order. In this release we’ve added the ability to define this relationship for specific `rules` conditions. When a condition matches a rule, the job’s `needs` configuration is completely replaced with the `needs` in the rule. This can help speed up a pipeline based on your defined conditions, when a job can start earlier than normal. You can also use this to force a job to wait for an earlier one to complete before starting, you now have more flexible `needs` options!

### Beautify the UI of CI/CD pipelines and jobs

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/pipelines/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/394768)

{{< /details >}}

One of GitLab’s most used features is CI/CD. In 16.1, we focused on improving the usability and experience of CI/CD pipeline and job list views, as well as the pipeline details page. It’s now easier to find the information you are looking for! If you have any comments about the changes, we’d love to hear from you in our [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/414756).

### Increased storage for GitLab SaaS runners on Linux

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../ci/runners/hosted_runners/linux.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/384223)

{{< /details >}}

After recently upsizing our [GitLab.com SaaS runners on Linux](../../ci/runners/hosted_runners/linux.md) in vCPU and RAM, we have now also increased the storage for `medium` and `large` machine types.

You can now seamlessly build, test, and deploy larger applications that require a secure, on-demand GitLab Runner Linux environment fully integrated with GitLab CI/CD.

### CI/CD job token scope API endpoint

<!-- categories: Secrets Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/jobs/ci_job_token.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/351740)

{{< /details >}}

Starting in GitLab 16.0, the [default CI/CD job token (`CI_JOB_TOKEN`) scope changed](../../ci/jobs/ci_job_token.md) for all new projects. This increased the security of new projects, but added an extra step for users who used automation to create projects. The automation sometimes has to configure the job token scope as well, which could only be done with GraphQL (or manually in the UI), not the REST API.

To make this setting configurable through the REST API as well, [Gerardo Navarro](https://gitlab.com/gerardo-navarro) added a new endpoint to control the job token scope in 16.1. It is available to users with a Maintainer or higher role in the project. Thank you for this great contribution Gerardo!

### Runner details - consolidate runners sharing a configuration

<!-- categories: Fleet Visibility -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner/fleet_scaling/#reusing-a-runner-configuration) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/409388/)

{{< /details >}}

The new runner creation method enables you to re-use a runner configuration for scenarios where you may need to register multiple runners with the same capabilities. Runners registered with the same authentication token share a configuration and are grouped in the new detailed view.

### GitLab Runner 16.1

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 16.1 today! GitLab Runner is the lightweight, highly-scalable agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s new

- [GitLab Runner Fleeting plugin for Azure Virtual Machines (Experimental)](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29410). Thank you to [vincent_stchu](https://gitlab.com/vincent_stchu) for this contribution!

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/-/blob/16-1-stable/CHANGELOG.md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.1)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.1)
- [UI improvements](https://papercuts.gitlab.com/?milestone=16.1)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
