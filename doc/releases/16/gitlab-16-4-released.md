---
stage: Release Notes
group: Monthly Release
date: 2023-09-22
title: "GitLab 16.4 release notes"
description: "GitLab 16.4 released with Customizable roles"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On September 22, 2023, GitLab 16.4 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Kik

Kik has been instrumental in designing and beginning the implementation of ActivityPub support
in GitLab. His original deeply detailed architecture plan has been embraced by our product team
and now lives [as an epic](https://gitlab.com/groups/gitlab-org/-/epics/11247) in the GitLab project.
The [first MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127023) implementing this code was
recently merged, followed by a [documentation addition](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130960).

As support for this large feature grows, Kik has shown himself to be a personification of the
[GitLab Values](https://handbook.gitlab.com/handbook/values/) of Collaboration, Iteration and Transparency!

Kik has been a part of the GitLab community for many years, logging his [first issue](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/4037#note_4651432)
over 7 years ago. He’s chosen to become a bit more active over the last few months. When asked about
his contributions, he stated:

> If there is anything to highlight, it’s probably how enabling GitLab is, allowing to see its source code and tinker with it, while being welcoming to contributions, no matter how ambitious they are. :)

He has also chosen to help pioneer our sustainability efforts by choosing to have
[trees planted](https://tree-nation.com/trees/view/5119567) in his name instead of opting for swag. 🌳

Thank you, Kik, for choosing to help build GitLab and being a part of our amazing community! 🙌

## Primary features

### Customizable roles

<!-- categories: User Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/permissions.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/393235)

{{< /details >}}

Group Owners or administrators can now create and remove custom roles using the UI under the Roles and Permissions menu. To create a custom role, you add [permissions](../../user/permissions.md) on top of an existing [base role](../../user/permissions.md#roles). Currently, there are a limited number of permissions that can be added to a base role, including [granular security permissions](https://docs.gitlab.com/#granular-security-permissions), the ability to approve merge requests, and view code. Each milestone, new permissions will be released that can then be added to existing permissions to create custom roles.

### Create workspaces for private projects

<!-- categories: Workspaces -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/workspace/_index.md#personal-access-token)

{{< /details >}}

Previously, it was not possible to [create a workspace](../../user/workspace/configuration.md) for a private project. To clone a private project, you could only authenticate yourself after you created the workspace.

With GitLab 16.4, you can create a workspace for any public or private project. When you create a workspace, you get a personal access token to use with the workspace. With this token, you can clone private projects and perform Git operations without any additional configuration or authentication.

### Access clusters locally using your GitLab user identity

<!-- categories: Environment Management, User Profile -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/clusters/agent/user_access.md#access-a-cluster-with-the-kubernetes-api) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/11235)

{{< /details >}}

Allowing developers access to Kubernetes clusters requires either developer cloud accounts or third-party authentication tools. This increases the complexity of cloud identity and access management. Now, you can grant developers access to Kubernetes clusters using only their GitLab identities and the agent for Kubernetes. Use traditional Kubernetes RBAC to manage authorizations within your cluster.

Together with the [OIDC cloud authentication](../../ci/cloud_services/_index.md) offering in GitLab pipelines, these features allow GitLab users to access cloud resources without dedicated cloud accounts without jeopardizing security and compliance.

In this first iteration of cluster access, you must [manage your Kubernetes configuration manually](../../user/clusters/agent/user_access.md). [Epic 11455](https://gitlab.com/groups/gitlab-org/-/epics/11455) proposes to simplify setup by extending the GitLab CLI with related commands.

### Group/sub-group level dependency list

<!-- categories: Dependency Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dependency_list/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/8090)

{{< /details >}}

When reviewing a list of dependencies, it is important to have an overall view. Managing dependencies at the project level is problematic for large organizations that want to audit their dependencies across all their projects. With this release, you can see all dependencies at the project or group level, including subgroups. This feature is now available by default.

### Vulnerability bulk status updates

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/vulnerability_report/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/4649)

{{< /details >}}

Some vulnerabilities need to be addressed in bulk. Whether they are false positives or no longer detected, it’s important to minimize the noise and triage vulnerabilities with ease.
With this release you can bulk change the status and make a comment for multiple vulnerabilities from a group or project Vulnerability Report.

### Granular security permissions

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/permissions.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10684)

{{< /details >}}

Some organizations want to give their security teams the least amount of access necessary so they can adhere to the [Principle of Least Privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege).
Security teams should not have access to write code updates, but they must be able to approve merge requests, view vulnerabilities, and update a vulnerability’s status.

GitLab now allows users to [create a custom role](../../user/permissions.md) based on the access of the [Reporter](../../user/permissions.md) role, but with the added permissions of:

- Viewing the dependency list (`read_dependency`).
- Viewing the security dashboard and vulnerability report (`read_vulnerability`).
- Approving a merge request (`admin_merge_request`).
- Changing status of a vulnerability (`admin_vulnerability`).

We plan to remove the ability to change the status of a vulnerability from the Developer role for all tiers in 17.0, as noted in this [deprecation entry](../../update/deprecations.md#deprecate-change-vulnerability-status-from-the-developer-role). Feedback on this proposed change can be shared in [issue 424688](https://gitlab.com/gitlab-org/gitlab/-/issues/424668).

### Fast-forward merge support for merge trains

<!-- categories: Merge Trains -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/pipelines/merge_trains.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/4911)

{{< /details >}}

[Fast-forward merge](../../user/project/merge_requests/methods/_index.md#fast-forward-merge) is a common and popular merge method which avoids merge commits, but requires more rebasing. Separately, Merge Trains are a powerful tool to help with some of the greater challenges related to frequently merging into the main branch. Unfortunately, before this release you could not use merge trains and fast-forward merge together.

In this release, self-managed admins can now enable both Fast-forward merge and merge trains in the same project. You can get all the benefits of merge trains, which ensure all your commits work together before merging, with the cleaner commit history of fast forward merges!

To enable the Fast-forward merge trains, locate the feature flag `fast_forward_merge_trains_support`, which has been disabled by default, and enable it.

### Set `id_token` globally and eliminate configuration for individual jobs

<!-- categories: Secrets Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/yaml/_index.md#id_tokens) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/419750)

{{< /details >}}

In GitLab 15.9 we announced the [deprecation of older versions of JSON web tokens](../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated) in favor of `id_token`. Unfortunately, jobs had to be modified individually to accommodate this change. To enable a smooth transition to `id_token`, beginning from GitLab 16.4, you can set `id_tokens` as a global default value in `.gitlab-ci.yml`. This feature automatically sets the `id_token` configuration for every job. Jobs that use OpenID Connect (OIDC) authentication no longer require you to set up a separate `id_token`.

[Use `id_token` and OIDC to authenticate with third party services](../../ci/secrets/id_token_authentication.md). The required `aud` sub-keyword is used to configure the `aud` claim for the JWT.

## Scale and Deployments

### Elasticsearch index integrity now generally available

<!-- categories: Global Search -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../integration/advanced_search/elasticsearch.md#index-integrity) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/214601)

{{< /details >}}

With GitLab 16.4, Elasticsearch index integrity is generally available for all GitLab users. Index integrity helps detect and fix missing repository data. This feature is automatically used when code searches scoped to a group or project return no results.

### Omnibus improvements

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- GitLab 16.4 includes packages for [OpenSUSE 15.5](https://en.opensuse.org/Release_announcement_15.5).

### Add webhooks for added or revoked emoji reactions

<!-- categories: Notifications -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/integrations/webhook_events.md#emoji-events) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/290773)

{{< /details >}}

To provide as many opportunities for automation and integration with third-party systems as possible, we have added support for creating webhooks that trigger when a user adds or revokes an emoji reaction.

You could use the new webhook, for example, to send an email when users react to issues or merge requests with emoji.

### Create custom role name and description using API

<!-- categories: System Access -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/member_roles.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/416751)

{{< /details >}}

When creating a custom role, you can now use the member roles API to add a name (required) and description (optional). Any existing custom roles have been given the name `Custom`, and you can use the API to change a custom role’s name to a name of your choosing.

### Trigger Slack notifications for group mentions

<!-- categories: Settings -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/integrations/gitlab_slack_application.md#trigger-notifications-for-group-mentions) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/417751)

{{< /details >}}

GitLab can send messages to Slack workspace channels for certain GitLab events. With this release, you can now trigger [Slack notifications](../../user/project/integrations/gitlab_slack_application.md#notification-events) for group mentions in public and private contexts in:

- Issue and merge request descriptions
- Comments on issues, merge requests, and commits

### Expand configurable import limits available in application settings

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/settings/import_and_export_settings.md#timeout-for-decompressing-archived-files) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/421432)

{{< /details >}}

We recently turned a few hardcoded import limits into configurable application settings to allow self-managed
GitLab administrators to adjust these limits according to their needs.

In this release, we’ve added the timeout for decompressing archived files as a configurable application setting.

This limit was hardcoded at 210 seconds. On GitLab.com, and for self-managed installations by default, we’ve set this limit to 210 seconds. Both self-managed GitLab and
GitLab.com administrators can adjust this limit as needed.

### Custom email address for Service Desk

<!-- categories: Service Desk -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/service_desk/configure.md#custom-email-address) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/329990)

{{< /details >}}

Service Desk is one of the most meaningful connections between your business and your customers. Now you can use your own custom email address to send and receive emails for Service Desk.
With this change, it is much easier to maintain brand identity and instill customer confidence that they are communicating with the correct entity.

This feature is in Beta. We encourage users to try Beta features and
provide feedback in [the feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/416637).

### Geo supports unified URLs on Cloud Native Hybrid sites

<!-- categories: Disaster Recovery, Geo Replication -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/geo/secondary_proxy/_index.md#set-up-a-unified-url-for-geo-sites) | [Related epic](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3522)

{{< /details >}}

Geo now supports unified URLs on [Cloud Native Hybrid](../../administration/reference_architectures/_index.md#cloud-native-hybrid) sites, which means that Cloud Native Hybrid sites can share a single external URL with the primary site. This delivers a seamless GitLab UI and Git developer experience for your remote teams who can be automatically directed to the optimal Geo secondary site based on their location using a single common URL. With this update, unified URLs are now supported across all GitLab reference architectures.

### Geo verifies object storage

<!-- categories: Geo Replication, Disaster Recovery -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/geo/replication/object_storage.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/8056)

{{< /details >}}

Geo adds the ability to verify object storage when [object storage replication is managed by GitLab](../../administration/geo/replication/object_storage.md#enabling-gitlab-managed-object-storage-replication). To protect your object storage data against corruption, Geo compares the file size between the primary and secondary sites. If Geo is part of your disaster recovery strategy, and you enable GitLab-managed object storage replication, this protects you against data loss. Additionally, it also reduces the need to copy data that may already be present on a secondary site. For example, when adding an old primary back as a secondary site.

## Unified DevOps and Security

### Support for `environment` keyword in downstream pipelines

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/pipelines/downstream_pipelines.md#downstream-pipelines-for-deployments) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/369061)

{{< /details >}}

If you need to trigger a downstream pipeline from a CI/CD pipeline job, you can use the `trigger` keyword. To enhance your deployment management, you can now specify an environment with the `environment` keyword when you use `trigger`. For example, you might trigger a downstream pipeline for the `main` branch on your `/web-app` project with environment name `dev` and a specified environment URL.

Previously, when you ran separate pipelines for CI and CD and used the `trigger` keyword to start the CD pipeline, specifying environment details was not possible. This made it hard to track deployments from your CI project. Adding support for environments simplifies deployment tracking across projects.

### Allow users to define branch exceptions to enforced security policies

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9567)

{{< /details >}}

Security policies enforce scanners to run in GitLab projects, as well as enforce MR checks/approvals to ensure security and compliance. With branch exceptions, you can more granularly enforce policies and exclude enforcement for any given branch that is out of scope. Should a developer create a development or test branch that is unintentionally affected by heavy-handed enforcement, they can work with security teams to exempt the branch within the security policy.

For scan execution policies, you can configure exceptions for the [pipeline](../../user/application_security/policies/scan_execution_policies.md#pipeline-rule-type) or [schedule](../../user/application_security/policies/scan_execution_policies.md#schedule-rule-type) rule type. For scan result policies, you can specify branch exceptions for the [scan_finding](../../user/application_security/policies/merge_request_approval_policies.md#scan_finding-rule-type) or [license_finding](../../user/application_security/policies/merge_request_approval_policies.md#license_finding-rule-type) rule type.

### Notifications for expiring access tokens

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../security/tokens/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/367705)

{{< /details >}}

Group and project access tokens are frequently used for automation. It is important that administrators and group Owners are notified when one of these tokens is close to expiry, so interruptions are avoided. Administrators and group Owners now receive a notification email when a token is seven days or less away from expiry.

### Email notification when access expires

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/group/_index.md#add-users-to-a-group) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/12704)

{{< /details >}}

A user will get an email notification seven days before their group or project access expires. This only applies if there is an access expiration date set. Previously, there were no notifications when access expired. Advance notice means you can contact your GitLab administrator to ensure continuous access.

### Browser-based DAST active check 22.1 is enabled by default

<!-- categories: DAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dast/browser/checks/_index.md#active-checks) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/392718)

{{< /details >}}

Browser-based DAST active check 22.1 has been enabled by default. It replaces ZAP check 6, which has been disabled. Check 22.1 identifies “Improper limitation of a pathname to a restricted directory (Path traversal)”, which can be exploited by inserting a payload into a parameter on the URL endpoint, allowing for arbitrary files to be read.

### Private registry support for Operational Container Scanning

<!-- categories: Container Scanning -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/clusters/agent/vulnerabilities.md#scanning-private-images) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/415451)

{{< /details >}}

[Operational Container Scanning](../../user/clusters/agent/vulnerabilities.md) can now access and scan images from private container registries. OCS uses the image pull secrets to access private registry containers.

### Dependency and License Scanning support for pnpm lockfile v6.1

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/413903)

{{< /details >}}

Thanks to a community contribution from [Weyert de Boer](https://gitlab.com/weyert-tapico), GitLab Dependency and License Scanning now support analyzing pnpm projects using v6.1 lockfile format.

### SAST analyzer updates

<!-- categories: SAST -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/analyzers.md) | [Related issue](../../user/application_security/_index.md)

{{< /details >}}

GitLab SAST includes [many security analyzers](../../user/application_security/sast/_index.md#supported-languages-and-frameworks) that the GitLab Static Analysis team actively maintains, updates, and supports. We published the following updates during the 16.4 release milestone:

- Updated the KICS-based analyzer to version 1.7.7 of the KICS scanner. See the [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/kics/-/blob/main/CHANGELOG.md?ref_type=heads#v415) for further details.
- Updated the Sobelow-based analyzer to version 0.13.0 of the Sobelow scanner. We also updated the base image for the analyzer to Elixir 1.13 to improve compatibility with more recent Elixir releases. See the [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow/-/blob/master/CHANGELOG.md?ref_type=heads#v421)
- Updated the PMD Apex-based analyzer to version 6.55.0 of the PMD scanner. See the [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex/-/blob/master/CHANGELOG.md?ref_type=heads#v413) for further details.
- Changed the PHPCS Security Audit-based analyzer to remove the `Security.Misc.IncludeMismatch` rule. See the [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/phpcs-security-audit/-/blob/master/CHANGELOG.md?ref_type=heads#v411) for further details.
- Updated the rules used in the Semgrep-based analyzer to fix rule errors, fix broken links in rule descriptions, and resolve conflicts between Java and Scala rules that had the same rule IDs. We also increased the maximum size of custom rule files to 10 MB. See the [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/CHANGELOG.md?ref_type=heads#v4412) for further details.

If you [include the GitLab-managed SAST template](../../user/application_security/sast/_index.md) ([`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)) and run GitLab 16.0 or higher, you automatically receive these updates.
To remain on a specific version of any analyzer and prevent automatic updates, you can [pin its version](../../user/application_security/sast/_index.md).

For previous changes, see [last month’s updates](https://about.gitlab.com/releases/2023/08/22/gitlab-16-3-released/#sast-analyzer-updates).

### Improved SAST vulnerability tracking

<!-- categories: SAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/373921)

{{< /details >}}

GitLab SAST [Advanced Vulnerability Tracking](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking) makes triage more efficient by keeping track of findings as code moves.

In GitLab 16.4, we’ve enabled Advanced Vulnerability Tracking for new languages and analyzers.
In addition to its [existing coverage](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking), advanced tracking is now available for:

- Java, in the SpotBugs-based SAST analyzer.
- PHP, in the PHPCS Security Audit-based SAST analyzer.

This builds on previous expansions and improvements [released in GitLab 16.3](https://about.gitlab.com/releases/2023/08/22/gitlab-16-3-released/#improved-sast-vulnerability-tracking).
We’re tracking further improvements in [epic 5144](https://gitlab.com/groups/gitlab-org/-/epics/5144).

These changes are included in [updated versions](https://docs.gitlab.com/#sast-analyzer-updates) of GitLab SAST [analyzers](../../user/application_security/sast/analyzers.md).
Your project’s vulnerability findings are updated with new tracking signatures after the project is scanned with the updated analyzers.
You don’t have to take action to receive this update unless you’ve [pinned SAST analyzers to a specific version](../../user/application_security/sast/_index.md).

### Pipeline-specific CycloneDX SBOM exports

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/dependency_list_export.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/333463)

{{< /details >}}

We’ve added an API that allows you to download a CycloneDX SBOM, which lists all the components detected in a CI pipeline. This includes both application-level dependencies and system-level dependencies.

### Users with the Maintainer role can view runner details

<!-- categories: Fleet Visibility -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/permissions.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/384179)

{{< /details >}}

Users with the Maintainer role for a group can now view details for group runners. Users with this role can view group runners to quickly determine which runners are available, or validate that automatically created runners were registered successfully to the group namespace.

### macOS 13 (Ventura) image for SaaS runners on macOS

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../ci/runners/hosted_runners/macos.md#supported-macos-images) | [Related issue](https://gitlab.com/gitlab-org/ci-cd/shared-runners/infrastructure/-/issues/101)

{{< /details >}}

Teams can now seamlessly create, test, and deploy applications for the
Apple ecosystem on macOS 13.

SaaS runners on macOS allow you to increase your development teams’ velocity in building and deploying applications
that require macOS in a secure, on-demand GitLab Runner build environment integrated with GitLab CI/CD.

### GitLab Runner 16.4

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 16.4 today! GitLab Runner is the lightweight, highly-scalable agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s new

- [Add queue duration histogram metric to the runner Prometheus metric endpoint](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36627)

#### Bug Fixes

- [Kubernetes runner pods not cleaned up in GitLab Runner 16.3.0](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36803)
- [`gitlab-runner-helper` terminated during cache downloading](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27984)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-4-stable/CHANGELOG.md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.4)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.4)
- [UI improvements](https://papercuts.gitlab.com/?milestone=16.4)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
