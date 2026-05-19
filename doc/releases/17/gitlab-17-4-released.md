---
stage: Release Notes
group: Monthly Release
date: 2024-09-19
title: "GitLab 17.4 release notes"
description: "GitLab 17.4 released with More context-aware GitLab Duo Code Suggestions using open tabs"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On September 19, 2024, GitLab 17.4 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Archish Thakkar

Everyone can [nominate GitLab’s community contributors](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)!
Show your support for our active candidates or add a new nomination! 🙌

Archish Thakkar is one of GitLab’s top contributors this year with [46 closed issues](https://gitlab.com/groups/gitlab-org/-/issues/?sort=created_date&state=closed&assignee_username%5B%5D=archish27&first_page_size=100) and [119 merged MRs](https://gitlab.com/groups/gitlab-org/-/merge_requests?assignee_username%5B%5D=archish27&first_page_size=100&sort=created_date&state=merged). These contributions have helped Archish earn top spots in the last two [GitLab Hackathons](https://gitlab-community.gitlab.io/community-projects/merge-request-leaderboard/?&createdAfter=2024-08-26&createdBefore=2024-09-02&mergedBefore=2024-10-03&label=Hackathon). He is a Senior Software Engineer at [Middleware](https://middleware.io/) and passionate open source contributor.

Archish was nominated by [Peter Leitzen](https://gitlab.com/splattael), Staff Backend Engineer, Engineering Productivity at GitLab. The nomination was supported by [Max Woolf](https://gitlab.com/mwoolf), Staff Backend Engineer at GitLab, and [James Nutt](https://gitlab.com/jnutt), Senior Backend Engineer at GitLab. Archish’s contributions have increased in the past two months where he has consistently demonstrated outstanding commitment to improving GitLab’s codebase, contributing multiple QoL (Quality of Life) fixes and reducing technical debt.

Many thanks to Archish and the rest of GitLab’s open source contributors for co-creating GitLab!

## Primary features

### More context-aware GitLab Duo Code Suggestions using open tabs

<!-- categories: Editor Extensions, Code Suggestions -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/project/repository/code_suggestions/context.md) | [Related issue](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/206)

{{< /details >}}

Elevate your coding workflow and receive more context-aware Code Suggestions using the contents of other open tabs.

This improvement to Code Suggestions now uses the content of your open editor tabs to provide more relevant and accurate code recommendations.

### Auto-merge when all checks pass

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/merge_requests/auto_merge.md)

{{< /details >}}

Merge requests have many required checks that must pass before they are mergeable. These checks can include approvals, unresolved threads, pipelines, and other items that need to be satisfied. When you’re responsible for merging code, it can be hard to keep track of all of these events, and know when to come back and check to see if a merge request can be merged.

GitLab now supports **Auto-merge** for all checks in merge requests. Auto-merge enables any user who is eligible to merge to set a merge request to **Auto-merge**, even before all the required checks have passed. As the merge request continues through its lifecycle, the merge request automagically merges after the last failing check passes.

We’re really excited about this improvement to accelerate your merge request workflows. You can leave feedback about this feature in [issue 438395](https://gitlab.com/gitlab-org/gitlab/-/issues/438395).

### Extension marketplace now available in the Web IDE

<!-- categories: Web IDE -->

{{< details >}}

- Tier: Free, Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/project/web_ide/_index.md#manage-extensions)

{{< /details >}}

We’re thrilled to announce the launch of the extension marketplace in the Web IDE on GitLab.com. With the extension marketplace, you can discover, install, and manage third-party extensions and enhance your development experience. Some extensions are not compatible with the web-only version because they require a local runtime environment. However, you can still choose from thousands of extensions to boost your productivity or customize your workflow.

The extension marketplace is disabled by default. To get started, you can enable the extension marketplace in the **Integrations** section of your [user preferences](https://gitlab.com/-/profile/preferences). For [enterprise users](../../user/enterprise_user/_index.md), only users with the Owner role for a top-level group can enable the extension marketplace.

### Secure sudo access for workspaces

<!-- categories: Workspaces -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/workspace/configuration.md#configure-sudo-access-for-a-workspace)

{{< /details >}}

You can now configure sudo access for your workspace, making it easier than ever to install, configure, and run dependencies directly in your development environment. We’ve implemented three secure methods to ensure a seamless development experience:

- Sysbox
- Kata Containers
- User namespaces

With this feature, you can fully customize your environment to match your workflow and project needs.

### List Kubernetes resource events

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/environments/kubernetes_dashboard.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/470041)

{{< /details >}}

GitLab provides a real-time view into your pods and streaming pod logs. Until now, however, we didn’t show you resource-specific event information from the UI,
so you still had to use 3rd party tools to debug Kubernetes deployments.
This release adds events to the resource details view of [the dashboard for Kubernetes](../../ci/environments/kubernetes_dashboard.md).

This is the first time we’ve added events to the UI. Currently, events are refreshed every time you open the resource details view. You can track the development of real-time event streaming in [issue 470042](https://gitlab.com/gitlab-org/gitlab/-/issues/470042).

### GitLab Pages without wildcard DNS is generally available

<!-- categories: Pages -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/pages/_index.md#dns-configuration-for-single-domain-sites) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13404)

{{< /details >}}

Previously, to create a GitLab Pages project, you needed a domain formatted like `name.example.io`
or `name.pages.example.io`. This requirement meant you had to set up wildcard DNS records and
TLS certificate. In this release, setting up a GitLab Pages project without a DNS wildcard has
moved from beta to generally available.

Removing the requirement for wildcard certificates eases administrative overhead associated with
GitLab Pages. Some customers can’t use GitLab Pages because of organizational restrictions on
wildcard DNS records or certificates.

### GitLab Pages parallel deployments in beta

<!-- categories: Pages -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/pages/_index.md#parallel-deployments) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10914)

{{< /details >}}

This release introduces Pages parallel deployments in beta. You can now easily preview changes and manage parallel deployments for your
GitLab Pages sites. This enhancement allows for seamless experimentation with new ideas, so you can test and refine your sites with confidence. By
catching any issues early, you can ensure that the live site remains stable and polished, building on the already great foundation of GitLab Pages.

Additionally, parallel deployments can be useful for localization when you deploy different language versions of an application or website.

### Summarize issue discussions with GitLab Duo Chat

<!-- categories: Team Planning -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../user/discussions/_index.md#summarize-issue-discussions-with-gitlab-duo-chat)

{{< /details >}}

Getting up to speed on lengthy issue discussions can be a significant time investment. With this release, AI-generated issue discussion summarization has been integrated with Duo Chat and is now generally available for GitLab.com, Self-managed, and Dedicated customers.

### Advanced SAST is generally available

<!-- categories: SAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/gitlab_advanced_sast.md)

{{< /details >}}

We’re excited to announce that our Advanced Static Application Security Testing (SAST) scanner is now generally available for all GitLab Ultimate customers.

Advanced SAST is a new scanner powered by the technology we [acquired from Oxeye](https://about.gitlab.com/blog/oxeye-joins-gitlab-to-advance-application-security-capabilities/) earlier this year. It uses a proprietary detection engine with rules informed by in-house security research to identify exploitable vulnerabilities in first-party code. It delivers more accurate results so developers and security teams don’t have to sort through the noise of false-positive results.

Along with the new scanning engine, GitLab 17.4 includes:

- A new [code-flow view](../../user/application_security/vulnerabilities/_index.md#vulnerability-code-flow) that traces a vulnerability’s path across files and functions.
- An automatic migration that allows Advanced SAST to “take over” existing results from previous GitLab SAST scanners.

To learn more, see [the announcement blog](https://about.gitlab.com/blog/gitlab-advanced-sast-is-now-generally-available/).

### Hide CI/CD variable values in the UI

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](https://new.docs.gitlab.com/ci/variables/#define-a-cicd-variable-in-the-ui) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/29674)

{{< /details >}}

You might not want anyone to see the value of a variable after it is saved to project settings. You can now select the new **Masked and hidden** visibility option when creating a CI/CD variable. Selecting this option will permanently mask the value of the variable in the CI/CD settings UI, restricting the value from being displayed to anyone in the future and decreasing visibility of your data.

## Scale and Deployments

### Omnibus improvements

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

GitLab 17.4 includes PostgreSQL 16 by default for fresh installations of GitLab.

GitLab 17.7 will include OpenSSL V3. This will affect Omnibus instances with external integration setup’s that do not meet the minimum requirements of TLS 1.2 or above for outbound connections, along with at least 112-bit encryption for TLS certificates. Please review our [OpenSSL upgrade documentation](https://docs.gitlab.com/omnibus/settings/ssl/openssl_3.html) for more information or if your are unsure if your instance will be affected.

### List groups invited to a group or project using the Groups or Projects API

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/groups.md#list-invited-groups) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/465207)

{{< /details >}}

We added new endpoints to the Groups API and Projects API to retrieve the groups that have been invited to a group or project. This functionality is available only on the Members page of a group or project. We hope that this addition will make it easier to automate membership management for your groups and projects. The endpoints are rate-limited to 60 requests per minute per user.

### Restrict group access by domain with the Groups API

<!-- categories: Source Code Management, Groups & Projects -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/groups.md#update-group-attributes) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/351494)

{{< /details >}}

Previously, you could only add domain restrictions at the group level in the UI. Now, you can also do this by using the new `allowed_email_domains_list` attribute in the Groups API.

### Improved source display for group and project members

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/members/_index.md#membership-types) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/431066)

{{< /details >}}

We have simplified the display of the source column on the Members page for groups and projects. Direct members are still indicated as `Direct member`. Inherited members are now listed as `Inherited from` followed by the group name. Members that were added by inviting a group to the group or project are listed as `Invited group` followed by the group name. For members that inherited from an invited group that was added to a parent group, we now display the last step to keep the display actionable for users managing membership.

### GitLab Duo seat assignment email

<!-- categories: Seat Cost Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Pro
- Links: [Documentation](../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164104)

{{< /details >}}

Users on self-managed instances will now receive an email when they are assigned a GitLab Duo seat. Previously, you wouldn’t know you were assigned a seat unless someone told you, or you noticed new functionality in the GitLab UI.

To disable this email, an administrator can disable the `duo_seat_assignment_email_for_sm` feature flag.

### Resend failed webhook requests with the API

<!-- categories: Notifications -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/project_webhooks.md#resend-a-project-webhook-event) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/372826)

{{< /details >}}

Previously, GitLab provided the ability to resend webhook requests only in the UI, which was inefficient if many
requests failed.

So that you can handle failed webhook requests programmatically, in this release thanks to a community contribution, we
added API endpoints for resending them:

- [Project webhook requests](../../api/project_webhooks.md#resend-a-project-webhook-event)
- [Group webhook requests](../../api/group_webhooks.md#resend-group-hook-event) (Premium and Ultimate tier only)

You can now:

1. Get a list of [project hook](../../api/project_webhooks.md#list-project-webhook-events) or [group hook](../../api/group_webhooks.md#list-all-group-hook-events) events.
1. Filter the list to see failures.
1. Use the `id` of any event to resend it.

Thanks to [Phawin](https://gitlab.com/lifez) for [this community contribution](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151130)!

### Idempotency keys for webhook requests

<!-- categories: Notifications -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/integrations/webhooks.md#delivery-headers) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/388692)

{{< /details >}}

From this release, we support an idempotency key in the headers of webhook requests. An idempotency key is a unique ID that remains consistent across webhook retries, which
allows webhook clients to detect retries. Use the `Idempotency-Key` header to ensure the idempotency of webhook effects on integrations.

Thanks to [Van](https://gitlab.com/van.m.anderson) for this [community contribution](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160952)!

## Unified DevOps and Security

### CI/CD component for code intelligence

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/code_intelligence.md#with-the-cicd-component)

{{< /details >}}

Code intelligence in GitLab provides code navigation features when browsing a repository. Getting started with code navigation is often complicated, as you must configure a CI/CD job. This job can require custom scripting to provide the correct output and artifacts.

GitLab now supports an official [Code intelligence CI/CD component](https://gitlab.com/explore/catalog/components/code-intelligence) for easier setup. Add this component to your project by following the instructions for [using a component](../../ci/components/_index.md#use-a-component). This greatly simplifies adopting code intelligence in GitLab.

Currently, the component supports these languages:

- Go version 1.21 or later.
- TypeScript or JavaScript.

We’ll continue to evaluate [available SCIP indexers](https://github.com/sourcegraph/scip?tab=readme-ov-file#tools-using-scip) as we look to broaden language support for the new component. If you’re interested in adding support for a language, please open a merge request in the [code intelligence component](https://gitlab.com/components/code-intelligence) project.

### Linked files in merge request show first

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/merge_requests/changes.md#show-a-linked-file-first)

{{< /details >}}

When you share a link to a specific file in a merge request, it’s often because you want the person to look at something within that file. Merge requests previously needed to load all of the files before scrolling to the specific position you’ve referenced. Linking directly to a file is a great way to improve the speed of collaboration in merge requests:

1. Find the file you want to show first. Right-click the name of the file to copy the link to it.
1. When you visit that link, your chosen file is shown at the top of the list. The file browser shows a link icon next to the file name.

Feedback about linked files can be left in [issue 439582](https://gitlab.com/gitlab-org/gitlab/-/issues/439582).

### Authenticate with OAuth for GitLab Duo in JetBrains IDEs

<!-- categories: Editor Extensions -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../editor_extensions/jetbrains_ide/setup.md#configure-gitlab-duo) | [Related epic](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/70)

{{< /details >}}

Our GitLab Duo plugin for JetBrains now offers a more secure and streamlined onboarding process. Sign in quickly and securely with OAuth. It integrates seamlessly with your existing workflow, with no personal access token required!

### Non-deployment jobs to protected environments aren't turned into manual jobs

<!-- categories: Environment Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/jobs/job_control.md#types-of-manual-jobs) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390025)

{{< /details >}}

Due to an implementation issue, the `action: prepare`, `action: verify`, and `action: access` jobs
become manual jobs when they run against a protected environment. These jobs require manual interaction to run,
although they don’t require any additional approvals.

[Issue 390025](https://gitlab.com/gitlab-org/gitlab/-/issues/390025) proposes to fix the implementation, so these jobs won’t be turned into manual jobs.
After this proposed change, to keep the current behavior, you will need to
[explicitly set the jobs to manual](../../ci/jobs/job_control.md#types-of-manual-jobs).

For now, you can change to the new implementation now by enabling the `prevent_blocking_non_deployment_jobs` feature flag.

Any proposed breaking changes are intended to differentiate the behavior of the
`environment.action: prepare | verify | access` values.
The `environment.action: access` keyword will remain the closest to its current behavior.

To prevent future compatibility issues, you should review your use of these keywords now.
You can learn more about these proposed changes in the following issues:

- [Issue 437132](https://gitlab.com/gitlab-org/gitlab/-/issues/437132)
- [Issue 437133](https://gitlab.com/gitlab-org/gitlab/-/issues/437133)
- [Issue 437142](https://gitlab.com/gitlab-org/gitlab/-/issues/437142)

### Trigger a Flux reconciliation from the cluster UI

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/environments/kubernetes_dashboard.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/434248)

{{< /details >}}

Although you can configure Flux to trigger reconciliations at specified intervals, there are situations where you might want an immediate reconciliation. In past releases, you could trigger the reconciliation from a CI/CD pipeline or from the command line. In GitLab 17.4, you can now trigger a reconciliation from a dashboard for Kubernetes with no additional configuration.

To trigger a reconciliation, go to a configured dashboard and select the Flux status badge.

### Optional token expiration

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/settings/account_and_limit_settings.md#require-expiration-dates-for-new-access-tokens) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/470192)

{{< /details >}}

Administrators can now decide if they want to enforce a mandatory expiration date for personal, project, and group access tokens. If administrators disable this setting, any new access token generated will not be required to have an expiration date. By default this setting is enabled, and an expiration less than that of the maximum allowed lifetime is required. This setting is available in GitLab 16.11 and later.

### Search by multiple compliance frameworks

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/compliance_center/compliance_projects_report.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/462943)

{{< /details >}}

In GitLab 17.3, we provided users with the ability to add multiple compliance frameworks to a project.

Now you can search by multiple compliance frameworks, which makes it easier to search for projects that have multiple compliance frameworks attached to them.

### Grant read access to pipeline execution YAML files in projects linked to security policies

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/469439)

{{< /details >}}

In GitLab 17.4, we added a setting to security policies you can use to grant read access to `pipeline-execution.yml` files for all linked projects. This setting gives you more flexibility to enable users, bots, or tokens that enforce pipeline execution globally across projects. For example, you can ensure a group or project access tokens can read security policy configurations in order to trigger pipelines during pipeline execution. You still can’t view the security policy project repository or YAML directly. The configuration is used only during pipeline creation.

To configure the setting, go to the security policy project you want to share. Select **Settings > General > Visibility, project features, permissions**, scroll to **Pipeline execution policies**, and enable the **Grant access to this repository for projects linked to it as the security policy project source for security policies** toggle.

### Support suffix for jobs with name collisions in pipeline execution policy pipelines

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/pipeline_execution_policies.md#pipeline_execution_policy-schema) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/473189)

{{< /details >}}

An enhancement to the [17.2 release of pipeline execution policies](https://about.gitlab.com/releases/2024/07/18/gitlab-17-2-released/#pipeline-execution-policy-type), policy creators may now configure pipeline execution policies to handle collisions in job names gracefully. With the `policy.yml` for the pipeline execution policy, you may now configure the following options:

- `suffix: on_conflict` configures the policy to gracefully handle collisions by renaming policy jobs, which is the new default behavior
- `suffix: never` enforces all jobs names are unique and will fail pipelines if collisions occur, which has been the default behavior since 17.2

With this improvement, you can ensure security and compliance jobs executed within a pipeline execution policy always run, while also preventing unnecessary impacts to developers downstream.

In a follow-up enhancement, we will introduce the configuration option within the policy editor.

### Resizable wiki sidebar

<!-- categories: Wiki -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/wiki/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154167)

{{< /details >}}

You can now adjust the wiki sidebar to see longer page titles, improving the overall discoverability of
content. As wiki content grows, having a resizable sidebar helps manage and browse through complex hierarchies or extensive
lists of pages more efficiently.

### Support for ingesting CycloneDX 1.6 SBOMs

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/472837)

{{< /details >}}

GitLab 15.3 added support for [ingesting CycloneDX SBOMs](../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx).

In GitLab 17.4 we have added support for ingesting CycloneDX version 1.6 SBOMs.

Fields relating to hardware (HBOM), services (SaaSBOM), and AI/ML models (AI/ML-BOM) are not currently supported. SBOMs that contain data relating to these BOMs will be processed, but the data will not be analyzed or presented to users. Support for these other BOM-types is being tracked in this [epic](https://gitlab.com/groups/gitlab-org/-/epics/14989).

### Automatic cleanup for removed SAST analyzers

<!-- categories: SAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/analyzers.md#analyzers-that-have-reached-end-of-support)

{{< /details >}}

In [GitLab 17.0](../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-170), [16.0](../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-160), and [15.4](../../update/deprecations.md#sast-analyzer-consolidation-and-cicd-template-changes), we streamlined GitLab SAST so it uses fewer separate analyzers to scan your code for vulnerabilities.

Now, after you upgrade to GitLab 17.3.1 or later, a one-time data migration will automatically resolve leftover vulnerabilities from the [analyzers that have reached End of Support](../../user/application_security/sast/analyzers.md#analyzers-that-have-reached-end-of-support).
This helps clean up your Vulnerability Report so you can focus on the vulnerabilities that are still detected by the most up-to-date analyzers.

The migration only resolves vulnerabilities that you haven’t confirmed or dismissed, and it doesn’t affect vulnerabilities that were [automatically translated to Semgrep-based scanning](../../user/application_security/sast/analyzers.md#transition-to-semgrep-based-scanning).

### Secret Detection support for Anthropic API keys

<!-- categories: Secret Detection -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/secret_detection/detected_secrets.md)

{{< /details >}}

Both pipeline and client-side Secret Detection now support detection of [Anthropic](https://www.anthropic.com/) API keys.

### JaCoCo support for test coverage visualization available in beta

<!-- categories: Code Testing and Coverage -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/testing/code_coverage/jacoco.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/227345)

{{< /details >}}

You can now use JaCoCo coverage reports, a popular standard for coverage calculation, inside your merge requests. The feature is available as beta, but ready for testing by anyone who wants to use JaCoCo coverage reports right away. If you have any feedback, feel free to contribute to the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/479804).

### GitLab Runner 17.4

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 17.4 today! GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s new

- [GitLab Runner fleeting plugin for Azure compute (GA)](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29223)

#### Bug Fixes

- [The entire `step_script` contents appear in the job log’s `after_script` section when a Kubernetes executor job is cancelled before completion](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37952)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-4-stable/CHANGELOG.md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.4)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.4)
- [UI improvements](https://papercuts.gitlab.com/?milestone=17.4)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
