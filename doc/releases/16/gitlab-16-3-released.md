---
stage: Release Notes
group: Monthly Release
date: 2023-08-22
title: "GitLab 16.3 release notes"
description: "GitLab 16.3 released with New velocity metrics in the Value Streams Dashboard"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On August 22, 2023, GitLab 16.3 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Thomas Spear

Thomas has contributed [15 merge requests](https://gitlab.com/gitlab-org/charts/gitlab-agent/-/merge_requests?scope=all&state=merged&author_username=tspearconquest)
to the [GitLab agent for Kubernetes Helm chart](https://gitlab.com/gitlab-org/charts/gitlab-agent)
in the last month!

Thomas made the chart more mature in terms of security and observability,
made it simpler to troubleshoot issues with agentk, and improved the CI/CD pipeline to check for breaking changes.

As a security engineer, Thomas enjoys collaborating with the team to provide
a more secure default deployment of the GitLab agent.
Thomas expressed thanks for all the timely reviews and feedback, which team members were
more than happy to provide.

Thank you Thomas, your contributions are hugely appreciated! 🙌

We would also like to take the opportunity to thank [Shane Maglangit](https://gitlab.com/ShaneMaglangit)
and [Batuhan Apaydın](https://gitlab.com/batuhan.apaydin) for their great contributions.

## Primary features

### New velocity metrics in the Value Streams Dashboard

<!-- categories: Value Stream Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/analytics/value_streams_dashboard.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/383665)

{{< /details >}}

The [Value Streams Dashboard](https://about.gitlab.com/blog/getting-started-with-value-streams-dashboard/) has been enhanced with new metrics: **Merge request (MR) throughput** and **Total closed issues** (Velocity). In GitLab, **MR throughput** is a count of the number of merge requests merged per month, and **Total closed issues** is the number of flow items closed at a point in time.

With these metrics, you can identify low or high productivity months and the efficiency of [merge request and code review processes](../../user/analytics/merge_request_analytics.md). You can then gauge whether the [Value Stream delivery](../../user/group/value_stream_analytics/_index.md) is accelerating or not.

Over time, the metrics accumulate historical data from MRs and issues. Teams can use the data to determine if delivery rates are accelerating or need improvement, and provide more accurate estimates or forecasts for how much work they can deliver.

To help us improve the Value Streams Dashboard, please share feedback about your experience in this [survey](https://gitlab.fra1.qualtrics.com/jfe/form/SV_50guMGNU2HhLeT4).

### Connect to Workspaces with SSH

<!-- categories: Workspaces -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/workspace/configuration.md#connect-to-a-workspace-with-ssh)

{{< /details >}}

With Workspaces, you can create reproducible, ephemeral, cloud-based runtime environments. Since the feature was introduced in GitLab 16.0, the only way to use a workspace was through the browser-based Web IDE running directly in the environment. The Web IDE, however, might not always be the right tool for you.

With GitLab 16.3, you can now securely connect to a workspace from your desktop with SSH and use your local tools and extensions. The first iteration supports SSH connections directly in VS Code or from the command line with editors like Vim or Emacs. Support for other editors such as JetBrains IDEs and JupyterLab is proposed in future iterations.

### Flux sync status visualization

<!-- categories: Environment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/environments/kubernetes_dashboard.md#flux-sync-status) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/391581)

{{< /details >}}

In previous releases, you probably used `kubectl` or another third-party tool to check the status of your Flux deployments. From GitLab 16.3, you can check your deployments with the environments UI.

Deployments rely on Flux `Kustomization` and `HelmRelease` resources to gather the status of a given environment, which requires a namespace to be configured for the environment. By default, GitLab searches the `Kustomization` and `HelmRelease` resources for the name of the project slug. You can customize the name GitLab looks for in the environment settings.

### Additional filtering for scan result policies

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/6826)

{{< /details >}}

Determining which results from a security or compliance scan are actionable is a significant challenge for security and compliance teams. Granular filters for scan result policies will help you cut through the noise to identify which vulnerabilities or violations require your attention the most. These new filters and filter updates will streamline your workflows:

- Status: Status rule changes introduce more intuitive enforcement of “new” versus “previously existing” vulnerabilities. A new status field `new_needs_triage` allows you to filter only new vulnerabilities that need to be triaged.
- Age: Create policies to enforce approvals when a vulnerability is outside of SLA (days, months, or years) based on the detected date.
- Fix Available: Narrow the focus of your policy to address dependencies that have a fix available.
- False Positive: Filter out false positives that have been detected by our Vulnerability Extraction Tool, for SAST results, and via Rezilion for our Container Scanning and Dependency Scanning results.

### Security findings in VS Code

<!-- categories: Editor Extensions, API Security, Container Scanning, DAST, Fuzz Testing, SAST, Secret Detection, Software Composition Analysis, Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../editor_extensions/visual_studio_code/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10407)

{{< /details >}}

You can now see security findings directly in Visual Studio Code (VS Code), just as you would in a merge request.

You could already monitor the status of your CI/CD pipeline, watch CI/CD job logs, and move through your development workflow in the GitLab Workflow panel.
Now, after you create a merge request for your branch, you can also see a list of new security findings that weren’t previously found on the default branch.

This new feature is part of [GitLab Workflow](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow) for VS Code.
Security scan results are pulled from an API, so this feature is available to developers using GitLab.com or self-managed instances running GitLab 16.1 or higher.

### Use the `needs` keyword with parallel jobs

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/yaml/_index.md#needsparallelmatrix) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/254821)

{{< /details >}}

The `needs` keyword is used to define dependency relationships between jobs. You can use the keyword to configure jobs to be dependent on specific earlier jobs instead of following stage ordering. When the dependent jobs complete, the job can start immediately, speeding up your pipeline.

Previously, it was impossible to use the `needs` keyword to set [parallel matrix](../../ci/yaml/_index.md#parallelmatrix) jobs as dependent, but in this release, we have enabled the ability to use `needs` with parallel matrix jobs too. You can now define a flexible dependency relationship to parallel matrix jobs, which can help speed up your pipeline even more! The earlier your jobs can start, the earlier your pipeline can finish!

### More powerful GitLab SaaS runners on Linux

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../ci/runners/hosted_runners/linux.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/388165)

{{< /details >}}

Having recently upgraded all of our Linux SaaS runners, we are now introducing `xlarge` and `2xlarge`[SaaS runners on Linux](../../ci/runners/hosted_runners/linux.md). Equipped with 16 and 32 vCPUs respectively and fully integrated with GitLab CI/CD, these runners will allow you to build and test your application faster than ever before.

We are determined to provide the industry’s fastest CI/CD build speed and look forward to seeing teams achieve even shorter feedback cycles and ultimately deliver software faster.

### Azure Key Vault secrets manager support

<!-- categories: Secrets Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/secrets/azure_key_vault.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/271271)

{{< /details >}}

Secrets stored in Azure Key Vault can now easily be retrieved and used in CI/CD jobs. Our new integration simplifies the process of interacting with Azure Key Vault through GitLab CI/CD, helping you streamline your build and deploy processes!

## Scale and Deployments

### Include or exclude archived projects from project search results

<!-- categories: Global Search -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/search/_index.md#include-archived-projects-in-search-results) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/413237)

{{< /details >}}

You can now opt to include or exclude archived projects from search results. By default, archived projects are excluded. This feature is available for project search in GitLab. Support for other [global search scopes](../../user/search/_index.md) is proposed in future releases.

### Omnibus improvements

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- GitLab 16.3 includes [Mattermost 8.0](https://mattermost.com/blog/mattermost-v8-0-is-now-available/). This version includes
[security updates](https://mattermost.com/security-updates/) and upgrading from earlier versions is recommended.
- Our Amazon Linux builds are now [Amazon Linux 2023](https://aws.amazon.com/linux/amazon-linux-2023/). Amazon Linux 2022 was never officially
generally available and was replaced with Amazon Linux 2023, so we have adjusted our offering to the updated release.

### Audit event recorded for applications settings change

<!-- categories: Audit Events -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../administration/compliance/audit_event_reports.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/282428)

{{< /details >}}

Application setting changes at an instance, project, and group level are now recorded in the audit log, along with which user made the change. This improves auditing of application settings for both self-managed and SaaS.

### Preserve pull request reviewers when importing from BitBucket Server

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../integration/bitbucket.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/416611)

{{< /details >}}

Until now, the BitBucket Server importer did not import pull request (PR) reviewers and instead categorized them as participants. Information on PR reviewers is
important from an audit and compliance perspective.

In GitLab 16.3, we added support for correctly importing PR reviewers from BitBucket. In GitLab, they become merge request reviewers.

### Configurable import limits available in application settings

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/group/import/_index.md#limits)

{{< /details >}}

Hardcoded limits exist for both migration by direct transfer and by importing export files.

In this release, we’ve made some of these limits configurable in application settings to allow self-managed GitLab administrators to adjust them according to their needs:

- [Maximum relation size that can be downloaded from the source instance in direct transfer](../../administration/settings/account_and_limit_settings.md).
Previously hardcoded at 5 GB. On GitLab.com, we’ve set this limit to 5 GB.
- [Maximum size of a remote import file that can be downloaded from remote Object Storages (such as AWS S3)](../../administration/settings/account_and_limit_settings.md).
Previously hardcoded at 10 GB. On GitLab.com, we’ve set this limit to 10 GB.

We’ve also added a new
[maximum decompressed file size for imported archives](../../administration/settings/account_and_limit_settings.md)
application setting, which replaces the `validate_import_decompressed_archive_size` feature flag. This limit was hardcoded to 10 GB. On GitLab.com, we’ve set this limit to 25
GB.

With these new application settings, both self-managed GitLab and GitLab.com administrators can adjust these limits as needed.

### New navigation has color themes available

<!-- categories: Navigation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/profile/preferences.md)

{{< /details >}}

With the new navigation enabled, you can now select one of five different color themes, and choose the light or dark variety for each. Use themes to identify different environments or choose your favorite color.

### No entity export timeout for migrations by direct transfer

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/import/_index.md#limits) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/392725)

{{< /details >}}

Until now, migrating groups and projects by direct transfer had a 90 minute export timeout. This limit effectively excluded large projects from being migrated, because only projects that could be migrated in under 90 minutes were allowed.

The upper limit for the overall migration timeout is 4 hours, and so the 90 minutes export timeout was not necessary. In this milestone, the limit was removed, allowing larger projects to be migrated.

### Support for Azure AD overage claim

<!-- categories: User Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/saml_sso/group_sync.md#microsoft-azure-active-directory-integration) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/414875)

{{< /details >}}

GitLab SAML Group Sync now supports the Azure AD (now known as Entra ID) overage claim, which allows a user to have over 150 groups associated with them. The previous maximum was 150 groups. For more information, see [Microsoft group overages](https://learn.microsoft.com/en-us/security/zero-trust/develop/configure-tokens-group-claims-app-roles#group-overages).

### Geo verifies group wikis

<!-- categories: Geo Replication, Disaster Recovery -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/geo/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/323897)

{{< /details >}}

Geo is now able to detect and correct data corruption of [group wikis](../../user/project/wiki/group.md) at rest and in transit. If you use Geo as part of your disaster recovery strategy, this helps to protect you against data loss in the event of a failover.

## Unified DevOps and Security

### CODEOWNERS file syntax and format validation

<!-- categories: Source Code Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/project/codeowners/reference.md)

{{< /details >}}

You can now see in the UI if your `CODEOWNERS` file has syntax or formatting errors. Being able to specify code owners offers great flexibility, allowing multiple file locations, sections, and rules to be configured by users. With this new syntax validation, errors in your `CODEOWNERS` file will be surfaced in the GitLab UI, making it easy to spot and fix issues. The following errors will be surfaced:

- Entries with spaces.
- Unparsable sections.
- Malformed owners.
- Inaccessible owners.
- Zero owners.
- Fewer than 1 required approvals.

Previously, the `CODEOWNERS` file didn’t validate the information being entered into the file. This could lead to creating:

- Rules for files/paths that don’t exist.
- Rules that create conflict with other existing rules.
- Rules that don’t apply because of incorrect syntax.

### Kubernetes 1.27 support

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/clusters/agent/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/420859)

{{< /details >}}

This release adds full support for Kubernetes version 1.27, released in April 2023. If you use Kubernetes, you can now upgrade your clusters to the most recent version and take advantage of all its features.

You can read more about [our Kubernetes support policy](../../user/clusters/agent/_index.md) and other supported Kubernetes versions.

### Wrap feature flag names instead of truncating

<!-- categories: Feature Flags -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../operations/feature_flags.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/418147)

{{< /details >}}

If you used feature flags in previous versions of GitLab, you might have noticed that long feature flag names were truncated. This made it difficult to quickly differentiate similar feature flag names.

In GitLab 16.3, the entire feature flag name is shown. Long names wrap across multiple lines, if needed.

### Names for audit event streams

<!-- categories: Audit Events -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

Previously, audit event streaming destinations were assigned by the destination URL. This could lead to confusion when you set up multiple streams for one group or
instance, because you had to expand the destination in the UI to see what filters and custom headers had been applied.

With GitLab 16.3, you can now name audit event streaming destinations to help identify and differentiate them when you have multiple streaming destinations defined.

### Explain this vulnerability

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/application_security/vulnerabilities/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10368)

{{< /details >}}

GitLab surfaces vulnerabilities that contain relevant information, however, sometimes it is unclear where to start. It takes time to research and synthesize information that is surfaced within the vulnerability record. Moreover it can be difficult to figure out how to fix a given vulnerability. With this Beta release, you can click a button to get an explanation and recommendation on how to mitigate the vulnerability, generated by AI.

### Compliance reports renamed to Compliance center

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/compliance_center/_index.md)

{{< /details >}}

To facilitate the growth of compliance-related features beyond reporting and into management, the Compliance reports section of GitLab was renamed to reflect the expanding scope
of the area.

From GitLab 16.3, Compliance reports are known as Compliance center.

### Improve accuracy of scan result policies

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md) | [Related epic](https://gitlab.com/gitlab-org/gitlab/-/issues/379108)

{{< /details >}}

A scan result policy is a type of security policy you use to evaluate and block merge requests if particular rules are violated. Approvers may review and approve the change, or work with their development teams to address any issues (such as addressing critical security vulnerabilities).

Previously, we compared vulnerabilities in the latest source and target branches to detect any new violations of policy rules. But, this might not capture vulnerabilities detected from scans running as a result of various pipeline sources. To increase accuracy, we are now comparing the latest completed pipelines for each pipeline source (with the exception of parent/child pipelines). This will ensure a more comprehensive evaluation and reduce the cases where approvals are required when it may be unexpected.

### Instance-level streaming audit event filters

<!-- categories: Audit Events -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

In GitLab 16.2, we introduced instance-level audit event streaming. However, no filters were available to apply to these streams.

In GitLab 16.3, you can now apply filters by audit event type to instance-level audit event streams. With the addition of these filters in the UI, you can capture a subset
of audit events to send to each streaming location, focusing only on the events that are relevant for you.

### Security bot to trigger scan execution policies pipelines

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/scan_execution_policies.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10756)

{{< /details >}}

Security bot users will be created to support managing background tasks, and to enforce security policies for all newly created or updated security policy project links. This will ease the process for security and compliance team members to configure and enforce policies, specifically removing the need for security policy project maintainers to also maintain `Developer` access in development projects. Security policy bot users will also make it much clearer for users within an enforced project when pipelines are executed on behalf of a security policy, as this bot user will be the pipeline author.

When a security policy project is linked to a group or subgroup, a security policy bot will be created in each project in the group or subgroup. When a link is made to a group, subgroup, or an individual project, a security bot user will be created for the given project or for any projects in the group or subgroup. Any groups, subgroups, or projects that already have a link to a security policy project will be unaffected at this time, but users may re-establish any existing links to take advantage of this feature. In GitLab 16.4, we plan to [enable security bots](https://gitlab.com/gitlab-org/gitlab/-/issues/414376) on all projects hosted on GitLab.com that have existing security policy project links.

### SAST analyzer updates

<!-- categories: SAST -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/analyzers.md) | [Related issue](../../user/application_security/_index.md)

{{< /details >}}

GitLab SAST includes [many security analyzers](../../user/application_security/sast/_index.md#supported-languages-and-frameworks) that the GitLab Static Analysis team actively maintains, updates, and supports. We published the following updates during the 16.3 release milestone:

- The Kics-based analyzer has been updated to use version 1.7.5 of the Kics engine. This update includes various bug fixes, and also adds improvements to error handling for self references in JSON and YAML. See the [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/kics/-/blob/main/CHANGELOG.md?ref_type=heads#v414) for further details.
- The Semgrep-based analyzer has been updated to add support for specifying ambiguous refs during passthrough custom configurations. We’ve also updated the SARIF parser to use Name over Title, and no longer fail scans upon SARIF `toolExecutionNotifications` of level error. See the [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/CHANGELOG.md?ref_type=heads#v446) for further details.

If you [include the GitLab-managed SAST template](../../user/application_security/sast/_index.md) ([`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)) and run GitLab 16.0 or higher, you automatically receive these updates.
To remain on a specific version of any analyzer and prevent automatic updates, you can [pin its version](../../user/application_security/sast/_index.md).

For previous changes, see [last month’s updates](https://about.gitlab.com/releases/2023/07/22/gitlab-16-2-released/#sast-analyzer-updates).

### Dependency and License Scanning support for Java v21

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/387307)

{{< /details >}}

GitLab Dependency and License Scanning now support analyzing Java v21 Maven lock files.

### Runner tags enable UI-based configuration of on-demand DAST scans

<!-- categories: DAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dast/on-demand_scan.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/345430)

{{< /details >}}

You can now use tags to specify which runners you wish to use for on-demand DAST scans. Prior to 16.3, you could configure DAST scans using private runners via CI configuration files. This UI-based configuration enables efficient UI-configuration for managing DAST scans.

### Improved SAST vulnerability tracking

<!-- categories: SAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/5144)

{{< /details >}}

GitLab SAST [Advanced Vulnerability Tracking](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking) makes triage more efficient by keeping track of findings as code moves.
We’ve released two improvements in GitLab 16.3:

1. Expanded language support: In addition to its [existing coverage](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking), we’ve enabled Advanced Vulnerability Tracking for:
  - C and C++, in the Flawfinder-based analyzer.
  - Java, in the MobSF-based analyzer.
  - JavaScript, in the NodeJS-Scan-based analyzer.
1. Better tracking: We’ve improved the tracking algorithm to handle anonymous functions in JavaScript.

This builds on previous expansions and improvements [released in GitLab 16.2](https://about.gitlab.com/releases/2023/07/22/gitlab-16-2-released/#improved-sast-vulnerability-tracking).
We’re tracking further improvements, including expansion to more languages, better handling of more language constructs, and improved tracking for Python and Ruby, in [epic 5144](https://gitlab.com/groups/gitlab-org/-/epics/5144).

These changes are included in [updated versions](https://docs.gitlab.com/#sast-analyzer-updates) of GitLab SAST [analyzers](../../user/application_security/sast/analyzers.md).
Your project’s vulnerability findings are updated with new tracking signatures after the project is scanned with the updated analyzers.
You don’t have to take action to receive this update unless you’ve [pinned SAST analyzers to a specific version](../../user/application_security/sast/_index.md).

### Automatic response to leaked Postman API keys

<!-- categories: Secret Detection -->

{{< details >}}

- Tier: Gold
- Links: [Documentation](../../user/application_security/secret_detection/automatic_response.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/403825)

{{< /details >}}

We’ve integrated Secret Detection with Postman to better protect customers who use Postman in their GitLab projects.

Secret Detection searches for [Postman API keys](https://learning.postman.com/docs/developer/postman-api/authentication/).
If a key is exposed in a public project on GitLab.com, GitLab sends the leaked key to Postman.
Postman verifies the key, then [notifies the owner of the Postman API key](https://learning.postman.com/docs/administration/token-scanner/#protecting-postman-api-keys-in-gitlab).

This integration is on by default for projects that have [enabled Secret Detection](../../user/application_security/secret_detection/_index.md) on GitLab.com.
Secret Detection scanning is available in all GitLab tiers, but an automatic response to leaked secrets is currently only available in Ultimate projects.

See [the Postman blog post about this integration](https://blog.postman.com/protecting-your-postman-api-keys-in-gitlab/) for further details.

### Expose pipeline name as a predefined CI/CD variable

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/variables/predefined_variables.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/420002)

{{< /details >}}

Pipeline names defined with the [`workflow:name`](../../ci/yaml/_index.md#workflowname) keyword are now accessible via the predefined variable `$CI_PIPELINE_NAME`.

### GitLab Runner 16.3

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 16.3 today! GitLab Runner is the lightweight, highly-scalable agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s new

- [Configure project clone directory as safe by default](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29022)

#### Bug Fixes

- [Runner v16.2.0 not available in Debian/RHEL repository](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36048)
- [GitLab-runner with the shell executor sometimes fails to fetch submodules](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/26993)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-3-stable/CHANGELOG.md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.3)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.3)
- [UI improvements](https://papercuts.gitlab.com/?milestone=16.3)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
