---
stage: Release Notes
group: Monthly Release
date: 2023-12-21
title: "GitLab 16.7 release notes"
description: "GitLab 16.7 released with GitLab Duo Code Suggestions is generally available"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On December 21, 2023, GitLab 16.7 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor

As we continue to focus on growing our wider community, we are incredibly happy to see both MVPs nominated by members of [the Core team](https://about.gitlab.com/community/core-team/).

Muhammed was nominated for adding support for [specifying platform when using Docker images with GitLab Runner](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112907).
This contribution took 9 months of collaboration and showed Muhammed’s commitment and perseverance when a bug required a [follow-up](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137100).
This solved a popular two-year-old [issue](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27919). “Great shoutout to the GitLab Runner team” Muhammed said, “for supporting me on bringing a long awaited feature to fruition”.
Muhammed is an Automation Engineer at [Airtime Rewards](https://www.airtimerewards.co.uk/), working mainly with Terraform and promoting CI/CD and automation practices within the engineering teams.

Niklas was nominated for his continued contributions and support in many different forms.
Today marks exactly 1 year since his last MVP award.
Niklas tackles daunting work which proves challenging even for GitLab team members and plays a huge part in maintaining our wider community contributors.
Read more in the [nomination issue](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/34762#note_1681021745).

Thank you Muhammed and Niklas! 🙌

## Primary features

### GitLab Duo Code Suggestions is generally available

<!-- categories: Code Suggestions -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/repository/code_suggestions/_index.md)

{{< /details >}}

[GitLab Duo Code Suggestions](https://about.gitlab.com/solutions/code-suggestions/) is now generally available!

GitLab Duo Code Suggestions helps teams create software faster and more efficiently, by completing lines of code and defining and generating logic for functions.

Code Suggestions is built with privacy as a critical foundation. Private, non-public customer code stored in GitLab is not used as training data. Learn about [data usage](../../user/gitlab_duo/data_usage.md) when using Code Suggestions.

In the general release, we’ve made [Code Suggestions available across several IDEs](../../user/project/repository/code_suggestions/_index.md). Code Suggestions is also now more intuitive and responsive.

GitLab Duo Code Suggestions is [free to try](../../user/project/repository/code_suggestions/_index.md) subject to the [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/) until February 15, 2024. Starting today, you can buy Code Suggestions as an add-on to GitLab subscriptions for an introductory price of $9 USD per user/per month. Please [contact us](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/) to get started with Code Suggestions.

### Use GitLab pages without a wildcard DNS

<!-- categories: Pages -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/pages/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/17584)

{{< /details >}}

Previously, to create a GitLab Pages project, you needed a domain formatted like name.example.io or name.pages.example.io. This requirement meant you had to set up wildcard DNS records and SSL/TLS certificates. In GitLab 16.7, you can set up a GitLab Pages project without a DNS wildcard. This feature is an experiment.

Removing the requirement for wildcard certificates eases administrative overhead associated with GitLab pages. Some customers can’t use GitLab Pages because of organizational restrictions on wildcard DNS records or certificates.

We welcome feedback related to this feature in [issue 434372](https://gitlab.com/gitlab-org/gitlab/-/issues/434372).

### New drill-down view from Insights report charts

<!-- categories: Value Stream Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/insights/_index.md#drill-down-on-charts) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/372215)

{{< /details >}}

With the [Insights report](https://www.youtube.com/watch?v=OMTfPsLa98I) you can analyze patterns over time using customizable charts. The new drill-down capability added to the “Bugs created by priority” and “Bugs created by severity” Insights reports allows you to drill down on the [Issue analytics](../../user/group/issues_analytics/_index.md) report for deeper analysis.

We plan to include this capability in the other Insight reports as a custom option in a later version.

### SAST results in MR changes view

<!-- categories: SAST -->

{{< details >}}

- Tier: Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/application_security/sast/_index.md#merge-request-changes-view) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10959) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/432704)

{{< /details >}}

SAST findings now appear in the merge request Changes view.
This makes it easier to see, understand, and fix potential weaknesses during the code review process.

Lines containing SAST issues are marked by a symbol beside the gutter.
Select the symbol to see the list of issues, then select an issue to see its details.

We’ve enabled this feature on GitLab.com.
We plan to enable the [feature flag](https://gitlab.com/gitlab-org/gitlab/-/issues/410191) by default for Self-Managed instances in GitLab 16.8.

### CI/CD Catalog - Beta release

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../ci/components/_index.md#cicd-catalog)

{{< /details >}}

GitLab 16.7 sees the Beta release of the CI/CD catalog! The catalog is where you can search for [CI/CD components](../../ci/components/_index.md) maintained by you, your organization, or the public community. This is the place where DevOps engineers come together to create, contribute, and share reusable pipeline configurations.

Unlike other methods of reusing CI/CD configuration, CI/CD components published in the catalog have an improved experience, and are easily added to your pipeline. We invite you to start testing this new and exciting feature! You can try out components that others have created and shared in the catalog, or create your own components and share them with everyone.

While this is our initial beta release of the feature, we continue to work on making the experience even better. Our goal is to make the CI/CD catalog a fundamental part of the GitLab CI/CD experience.

## Scale and Deployments

### Add a Mastodon handle to your User Profile

<!-- categories: User Profile -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/_index.md#add-external-accounts-to-your-user-profile-page) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/428442)

{{< /details >}}

You can now list your Mastodon handle on the User Profile. With this enhancement we are now supporting a fediverse social network, which will help in advancing [ActivityPub for GitLab](https://gitlab.com/groups/gitlab-org/-/epics/11247).

### Group descriptions extended to 500 characters

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/416146)

{{< /details >}}

Group descriptions can now contain up to 500 characters. If you try to save a group description with more than 500 characters, a warning message appears stating that the description is too long. Thanks to @freznicek for this community contribution!

### Search bar more prominent on the search results page

<!-- categories: Global Search -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/search/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/424619)

{{< /details >}}

The search bar is now more prominent on the search results page. To increase the search bar visibility, the group and project filters have been moved to the left sidebar.

### Issues with code more discoverable in advanced search

<!-- categories: Global Search -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/search/advanced_search.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/421012)

{{< /details >}}

In GitLab 16.7, issues with code have become more discoverable. With advanced search, you can now find issues that contain code snippets and logs in their descriptions.

### Customize time format for display

<!-- categories: User Profile -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/preferences.md#customize-time-format) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/15206)

{{< /details >}}

Until now, GitLab only displayed time in 12 hour format, which could not be changed.

From this release, thanks to the community contribution, you can customize the format used to display time in places like issue lists, overview pages or when setting your status.
You can display times as:

- 12 hour format, for example `2:34 PM`.
- 24 hour format, for example `14:34`.

Thanks to [Thorben Westerhuys](https://gitlab.com/n0rdlicht) for this [community contribution](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130789)!

In the following milestone we will [audit all timestamps](https://gitlab.com/groups/gitlab-org/-/epics/12215) shown across the GitLab product to make them respect the setting.

### Access the Admin Area from the left sidebar

<!-- categories: Navigation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../administration/admin_area.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/415854)

{{< /details >}}

Administrators can now access the Admin Area in one step, by using a link at the bottom of the left sidebar. Previously, you had to select **Search or go to** and then select **Admin Area**. This change should save you time when accessing the Admin Area.

### Remove hardcoded time limit for migrations to complete

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/import/_index.md#limits) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/429867)

{{< /details >}}

GitLab groups and project migrations done by direct transfer can become stuck for various reasons. In the past, to avoid leaving these migrations in an incomplete state
indefinitely, GitLab periodically executed a worker to identify migrations that hadn’t completed within 8 hours. GitLab marked these migrations as timed out.

For large organizations, the migration process can take longer than 8 hours, so this amount of time was not always sufficient to properly determine if a migration was stuck.
As a result, this worker might have incorrectly marked a migration as stuck.

In this milestone, instead of using an 8 hour time limit, GitLab now only marks the migration as stuck if the child workers stop working for 24 hours.

### Comprehensive results of imports by direct transfer

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/import/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/394727)

{{< /details >}}

Knowing how crucial for our users is to understand the results of the import process, in this milestone we further improved on information presented for imports by
direct transfer. We now display import status badges next to GitLab groups and projects on:

- The [page where you can select groups and projects to import](../../user/group/import/_index.md).
- The [page listing imported groups and projects](../../user/group/import/_index.md).

The import status badges are:

- **Not started**
- **Pending**
- **Importing**
- **Failed**
- **Timeout**
- **Cancelled**
- **Complete**
- **Partially completed**

The **Partially completed badge** was added in this release and identifies a completed import process that has some items (such as merge requests or issues) not imported.

Groups that an import process was started for have a **View details** link that shows imported subgroups and projects for that particular group. From there, you can see
the list of items that couldn’t be imported (if any) by clicking a **See failures** link. **See failures** was
[released in the last release](https://about.gitlab.com/releases/2023/11/16/gitlab-16-6-released/#comprehensive-list-of-items-that-failed-to-be-imported).

In this milestone we also improved navigation with the breadcrumbs between those pages.

### Reopen Service Desk issues when an external participant comments

<!-- categories: Service Desk -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/service_desk/configure.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/8549)

{{< /details >}}

You can now configure GitLab to reopen closed issues when an external participant adds
a new comment on an issue by email. This gives you full visibility into ongoing conversations,
even after an issue has been resolved.

It also adds an internal comment that mentions the assignees of the issue and creates to-do
items for them. This way you can make sure you never miss a follow-up email again.

### Backups supports alternate compression libraries

<!-- categories: Backup/Restore of GitLab instances -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/backup_restore/backup_gitlab.md#backup-compression)

{{< /details >}}

You can now override the default single-threaded gzip compression library with an alternate compression library of your choice for backups using the `COMPRESS_CMD` and `DECOMPRESS_CMD` commands. This allows you to leverage parallel compression libraries to speed up the compression stage of the backup by using the power of modern multi-core processors. The commands include support for passing options to the compression library allowing you to adjust parameters such as compression levels and speed.

## Unified DevOps and Security

### Define a network policy with egress rules

<!-- categories: Workspaces -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/workspace/gitlab_agent_configuration.md)

{{< /details >}}

In GitLab 16.7, you can now define a network policy with egress rules when you configure the GitLab agent for Kubernetes to support Workspaces. Use this feature for your self-hosted installation where the GitLab instance resolves to a private IP or when a workspace must access a cloud resource on a private IP range.

### Add custom emoji to groups

<!-- categories: Code Review Workflow, Team Planning -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/emoji_reactions.md)

{{< /details >}}

Who doesn’t love a good emoji to really express yourself? When commenting on items across GitLab, you’ve used our default set of emoji to add reactions, but sometimes those emoji just weren’t enough to express your emotions.
Groups can now add custom emoji to use across their projects. Custom emoji allow you to express your true feelings and communicate more clearly with the rest of your team. We can’t wait to see how you’ll react next.

### Complex merge request dependency chains now supported

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/project/merge_requests/dependencies.md#nested-dependencies)

{{< /details >}}

GitLab merge request dependencies are a great way to ensure that code changes that rely on other changes aren’t merged in a way that could break the codebase. Previously, GitLab didn’t allow complex dependency chains, which could result in circular references or deep nesting.

The limitations around dependency hierarchy, and items in the chain, have been removed. Merge request dependencies can now be more complex: a single merge request can be blocked by up to 10 merge requests, and in turn, block to 10 other merge requests. Deeper dependency chains make it possible to represent more complex workflows via dependencies. We’re excited to see how you continue to expand your usage of this feature.

### Notify me when any merge request needs approval

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/profile/notifications.md#edit-notification-settings)

{{< /details >}}

When your approval is required for a merge request, you need to be notified to take action. Some users only want notifications when their approval is required, which is typically done by adding a user by name to review the changes. However, some users want a notification for any merge request they are eligible to approve, *even if they aren’t added by name as reviewers.*

Enable the **Added as approver** custom notification level to trigger an email and to-do for each merge request you are eligible to approve. This helps you be aware of merge requests sooner in the process, and take action to get the proposal merged.

### Beta support for OpenTofu

<!-- categories: Infrastructure as Code -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/infrastructure/iac/_index.md) | [Related issue](https://gitlab.com/gitlab-org/terraform-images/-/issues/114)

{{< /details >}}

If you’re switching from Terraform to OpenTofu, this release of GitLab adds preliminary support for OpenTofu. Because OpenTofu is a fork of Terraform, the MR widget integration, module registry, and GitLab-managed Terraform state work by default. We added support for OpenTofu in the `gitlab-terraform` helper image to simplify the usage of the GitLab IaC offering.

GitLab continues to support Terraform for the MR widget, module registry, and GitLab-managed Terraform state.

### Custom time period for access tokens rotation

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/personal_access_tokens.md#rotate-a-personal-access-token) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/416795)

{{< /details >}}

You can now optionally input a new parameter, `expires_at`, when rotating an access token. This allows you to create a custom expiry date for the token. Previously, each rotation extended the expiration one week from the previous expiry date. This new option provides flexibility in rotation interval.

### Use the UI to assign users to custom roles

<!-- categories: Permissions -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/custom_roles/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/393239)

{{< /details >}}

You can now use the UI to assign a custom role to a new user, or change an existing user’s role to a custom role. You can do this in any part of the UI where you can currently assign or change a user’s role. Previously, you could only do this through the API.

### Enforce variables in Scan Execution Policies with the highest precedence

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/variables/_index.md#cicd-variable-precedence) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/424028)

{{< /details >}}

CI/CD variable precedence has been improved to first prioritize variables defined in scan execution policies.

As organizations work to meet compliance requirements, a common need is to ensure that security scanners are enabled in business critical applications.

Scan execution policies allow teams to enforce scanners and to define default and custom CI/CD variables. With this enhancement to CI/CD variable precedence, teams can be confident that regardless of how pipelines are triggered, the variables defined with compliance in mind remain intact.

### SAML attribute statements support Microsoft SAML attribute format

<!-- categories: User Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../integration/saml.md#configure-assertions) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/420766)

{{< /details >}}

SAML attribute statements now support the Microsoft SAML attribute format, which is in URL form. Previously, self-managed instance administrators had to manually configure attribute statements, and GitLab.com group owners had to add custom attributes to their SAML responses. This change allows both self-managed GitLab and GitLab.com to work with Microsoft without any manual configuration.

### Improvements to rich text editor

<!-- categories: Team Planning, Portfolio Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/rich_text_editor.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136437)

{{< /details >}}

In GitLab 16.2 we released the rich text editor as an alternative to the existing Markdown editing experience. The rich text editor provides a “what you see is what you get” editing experience and an extensible foundation on which we can build custom editing interfaces for things like diagrams, content embeds, media management, and more.

With GitLab 16.7, we’ve changed the rich text editor to match the behavior with our Markdown editing experience and fix reported bugs. We’ve [changed the sorting order in the labels autocomplete modal to be consistent between the Markdown and rich-text editor](https://gitlab.com/gitlab-org/gitlab/-/issues/419097), [addressed a bug in the options returned in the unassign quick action in the rich-text editor](https://gitlab.com/gitlab-org/gitlab/-/issues/420344), [added support for custom emojis](https://gitlab.com/gitlab-org/gitlab/-/issues/422958), and [updated the look and feel of the quick action selection dropdown to be consistent in the two editing experiences](https://gitlab.com/gitlab-org/gitlab/-/issues/406714), among other improvements.

### List repository tags with new Container Registry API

<!-- categories: Container Registry -->

{{< details >}}

- Tier: Free, Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../api/container_registry.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/411387)

{{< /details >}}

Previously, the Container Registry relied on the Docker/OCI [listing image tags registry API](https://gitlab.com/gitlab-org/container-registry/-/blob/5208a0ce1600b535e529cd857c842fda6d19ad59/docs/spec/docker/v2/api.md#listing-image-tags) to list and display tags in GitLab. This API had significant performance and discoverability limitations.

This API performed slowly because the number of network requests against the registry scaled with the number of tags in the tags list. In addition, because the API didn’t track publish time, the published timestamp was often incorrect. There were also limitations when displaying images based on Docker manifest lists or OCI indexes, such as for multi-architecture images.

To address these limitations, we introduced a new registry [list repository tags API](https://gitlab.com/gitlab-org/container-registry/-/blob/5208a0ce1600b535e529cd857c842fda6d19ad59/docs/spec/gitlab/api.md#list-repository-tags). By updating the user interface to use the new API, the number of requests to the Container Registry is reduced to just one. Publish timestamps are also accurate, and there is more robust support for multi-architecture images.

This feature is available only on GitLab.com. Self-managed support is blocked until the next-generation Container Registry is generally available. To learn more, see [issue 423459](https://gitlab.com/gitlab-org/gitlab/-/issues/423459).

### Rename projects with container images in the container registry on GitLab.com

<!-- categories: Container Registry -->

{{< details >}}

- Tier: Free, Silver, Gold
- Links: [Documentation](../../user/project/working_with_projects.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10433)

{{< /details >}}

Before this release, you could not rename a project that had a container repository with at least one tag without having first deleted all container images associated with that project.

This was a real problem that forced users to rely on custom scripts to manually delete/move all tags before a different project name could be used, but now you can rename projects on GitLab.com, even if they have container images in the registry!

### Filter by predefined date ranges in Value Stream Analytics

<!-- categories: Value Stream Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/value_stream_analytics/_index.md#data-filters) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/408656)

{{< /details >}}

The value stream analytics report now has a set of filter options for data in the last 30, 60, 90, or 180 days. These new filter options simplify the date selection process, making it more efficient and user-friendly to understand [where time is spent during the development lifecycle](https://about.gitlab.com/blog/value-stream-total-time-chart/).

### Support for Continuous Vulnerability Scanning for Dependency Scanning

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/continuous_vulnerability_scanning/_index.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/11474)

{{< /details >}}

Continuous Vulnerability Scanning is now Generally Available. With CVS enabled, your projects are automatically scanned when advisories are added to the GitLab Advisory Database. If new dependency-related vulnerabilities are identified, vulnerabilities are created automatically.

### DAST vulnerability check updates

<!-- categories: DAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dast/browser/checks/_index.md#active-checks)

{{< /details >}}

During the 16.7 release milestone, we enabled the following active checks for browser-based DAST by default:

- Check 89.1 replaces ZAP checks 40018, 40019, 40020, 40021, 40022, 40024, 40027, 40033, and 90018 and identifies SQL Injection.
- Check 918.1 replaces ZAP check 40046 and identifies Server Side Request Forgery.
- Check 98.1 replaces ZAP check 7 and identifies PHP Remote File Inclusion.
- Check 917.1 replaces ZAP check 90025 and identifies Expression Language Injection.
- Check 1336.1 replaces ZAP check 90035 and Server-Side Template Injection.

### DAST authentication now supports multi-step login forms

<!-- categories: DAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dast/browser/configuration/authentication.md#configuration-for-a-multi-step-login-form) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/11585)

{{< /details >}}

The new `DAST_AFTER_LOGIN_ACTIONS` variable enables you to provide a list of actions to be executed after login. This allows for multi step login interactions, for example Azure AD’s “Keep Me Signed In” workflow.

### Updated SAST rules to reduce false-positive results

<!-- categories: SAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/rules.md#important-rule-changes) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/8170)

{{< /details >}}

We’ve updated the default ruleset used in GitLab SAST to provide higher-quality results.
We analyzed each rule that was previously included by default, then removed rules that did not provide enough value in most codebases.

The rule changes are included in updated versions of the Semgrep-based GitLab SAST [analyzer](../../user/application_security/sast/analyzers.md).
This update is automatically applied on GitLab 16.0 or newer unless you’ve [pinned SAST analyzers to a specific version](../../user/application_security/sast/_index.md).

Existing scan results from the removed rules are [automatically resolved](../../user/application_security/sast/_index.md#automatic-vulnerability-resolution) after your pipeline runs a scan with the updated analyzer.

We’re working on more SAST rule improvements in [epic 10907](https://gitlab.com/groups/gitlab-org/-/epics/10907).

### `artifacts:public` CI/CD keyword now generally available

<!-- categories: Job Artifacts -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/yaml/_index.md#artifactspublic) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/11667)

{{< /details >}}

Previously, the `artifacts:public` keyword was only available as a default disabled feature for self-managed instances. Now in GitLab 16.7 we’ve made the `artifacts:public` keyword generally available for all users. You can now use the `artifacts:public` keyword in CI/CD configuration files to control whether job artifacts should be publicly accessible.

### Improved ability to keep the latest job artifacts

<!-- categories: Job Artifacts -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/428408)

{{< /details >}}

In GitLab 13.0 we introduced the ability to keep the job artifacts from the most recent successful pipeline. Unfortunately, the feature also marked all [failed](https://gitlab.com/gitlab-org/gitlab/-/issues/266958) and [blocked](https://gitlab.com/gitlab-org/gitlab/-/issues/387087) pipelines as the latest pipeline regardless of whether they were the most recent or not. This led to a buildup of artifacts in storage which had to be deleted manually.

In GitLab 16.7 the bugs causing this unintended behavior are resolved. Job artifacts from failed and blocked pipelines are only kept if they are from the most recent pipeline, otherwise they will follow the `expire_in` configuration. Affected GitLab.com customers should see artifacts which were inadvertently kept now unlocked and removed after a new pipeline run.

The **Keep artifacts from most recent successful jobs** setting overrides the job’s `artifacts: expire_in` configuration and can result in a large number of artifacts stored without expiry. If your pipelines create many large artifacts, they can fill up your project storage quota quickly. We recommend disabling this setting if this feature is not required.

### GitLab Runner 16.7

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 16.7 today! GitLab Runner is the lightweight, highly-scalable agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s new

- [Implement graceful shutdown for Docker executor](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/6359)
- [Dynamically create PVC volumes with storage classes for Kubernetes](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27835)

#### Bug Fixes

- [allow_failure:exit codes unusable with custom executor because exit code is always 1](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28658)
- [Add better handling of signals in the runner helper and build container for the Kubernetes executor](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36996)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-7-stable/CHANGELOG.md).

### GitLab Runner supports SLSA v1.0 statement

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../ci/runners/configure_runners.md#artifact-provenance-metadata) | [Related issue](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36869)

{{< /details >}}

Runners can now generate provenance metadata with a statement that adheres to [SLSA 1.0](https://slsa.dev/spec/v1.0/). To enable SLSA 1.0, set the `SLSA_PROVENANCE_SCHEMA_VERSION=v1` variable in the `.gitlab-ci.yml` file. The SLSA version 1.0 statement is planned to become the default version in GitLab 17.0.

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.7)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.7)
- [UI improvements](https://papercuts.gitlab.com/?milestone=16.7)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
