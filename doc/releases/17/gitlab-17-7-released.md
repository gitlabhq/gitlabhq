---
stage: Release Notes
group: Monthly Release
date: 2024-12-19
title: "GitLab 17.7 release notes"
description: "GitLab 17.7 released with New Planner user role"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On December 19, 2024, GitLab 17.7 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Vedant Jain

Everyone can [nominate GitLab’s community contributors](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)!
Show your support for our active candidates or add a new nomination! 🙌

Vedant has been an outstanding community contributor, known for his proactive approach to contributing, his commitment to delivering, and his collaboration skills. He excels at taking on feedback, incorporating it into his work, and seeking assistance when needed, ensuring that his contributions are not only completed but also meet GitLab’s standards.

His contributions include streamlining project management processes with [Abstracted work item attributes to a single list/board](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172191), [Ordering of metadata on work items](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173033), and feature development in [Remember the collapsed state of work item widgets](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171228). Vedant also fixed links in the UI to documentation ([1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170633), [2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170534)), helping the technical writing team as part of an important effort to improve UX across the entire product.

[Amanda Rueda](https://gitlab.com/amandarueda), Sr. Product Manager, Product Planning at GitLab, nominated Vedant and highlighted his proactive and community-oriented mindset, “Vedant’s work not only addresses user needs but through his contributions, he is co-creating a more stable and reliable GitLab environment. By contributing to bug fixes, usability improvements, and maintenance efforts, he has played a vital role in enhancing the overall quality of the product. His proactive approach and cross-group contributions embody GitLab’s core values of iteration, customer collaboration, and continuous improvement, making him a standout contributor in the community.”

“Thanks to everyone who helped me achieve my contributions,” says Vedant. “So grateful that I am able to make a good impact and looking forward to more contributions.”

Vedant is a Frontend Engineer at Atlan, an active metadata platform for modern data teams, and a Google Summer of Code 2024 Mentor.

We are so grateful to Vedant for all of his contributions and to all of our open source community for contributing to GitLab!

## Primary features

### New Planner user role

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/permissions.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/482733)

{{< /details >}}

We’ve introduced the new Planner role to give you tailored access to Agile planning tools like epics, roadmaps, and Kanban boards without over-provisioning [permissions](../../user/permissions.md). This change helps you collaborate more effectively while keeping your workflows secure and aligned with the principle of least privilege.

### Instance administrators can control which integrations can be enabled

<!-- categories: Settings -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/settings/project_integration_management.md#integration-allowlist) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/500610)

{{< /details >}}

Instance administrators can now configure an allowlist to control which integrations can be enabled on a GitLab instance. If an empty allowlist is configured, no integrations are allowed on the instance. After an allowlist is configured, new GitLab integrations are not on the allowlist by default.

Previously enabled integrations that are later blocked by the allowlist settings are disabled. If these integrations are allowed again, they are re-enabled with their existing configuration.

### New user contribution and membership mapping available in direct transfer

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/import/direct_transfer_migrations.md) | [Related epic](https://gitlab.com/gitlab-org/gitlab/-/issues/478054)

{{< /details >}}

The new method of user contribution and membership mapping is now available when you migrate between GitLab instances by [direct transfer](../../user/group/import/_index.md). This feature offers flexibility and control for both users managing the import process and users receiving contribution reassignments. With the new method, you can:

- Reassign memberships and contributions to existing users on the destination instance after the import has completed. Any memberships and contributions you import are first mapped to placeholder users. All contributions appear associated with placeholders until you reassign them on the destination instance.
- Map memberships and contributions for users with different email addresses on source and destination instances.

When you reassign a contribution to a user on the destination instance, the user can accept or reject the reassignment.

For more information, see [streamline migrations with user contribution and membership mapping](https://about.gitlab.com/blog/streamline-migrations-with-user-contribution-and-membership-mapping/). To leave feedback, add a comment to [issue 502565](https://gitlab.com/gitlab-org/gitlab/-/issues/502565).

### Auto-resolve vulnerabilities when not found in subsequent scans

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/vulnerability_management_policy.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/5708)

{{< /details >}}

GitLab’s [security scanning tools](../../user/application_security/_index.md) help identify known vulnerabilities and potential weaknesses in your application code. Scanning feature branches surfaces new weaknesses or vulnerabilities so they can be remediated before merging. In the case of vulnerabilities already in your project’s default branch, fixing these in a feature branch will mark the vulnerability as no longer detected when the next default branch scan runs. While it is informative to know which vulnerabilities are no longer detected, each must still be manually marked as Resolved to close them. This can be time consuming if there are many of these to resolve, even when using the new [Activity filter](../../user/application_security/vulnerability_report/_index.md#activity-filter) and [bulk-changing status](../../user/application_security/vulnerability_report/_index.md#change-status-of-vulnerabilities).

We are introducing a new policy type *Vulnerability Management policy* for users who want vulnerabilities automatically set to Resolved when no longer detected by automated scanning. Simply configure a new policy with the new Auto-resolve option and apply it to the appropriate project(s). You can even configure the policy to only Auto-resolve vulnerabilities of a certain severity or from specific security scanners. Once in place, the next time the project’s default branch is scanned, any existing vulnerabilities that are no longer found will be marked as Resolved. The action updates the vulnerability record with an activity note, timestamp when the action occurred, and the pipeline the vulnerability was determined to be removed in.

### Rotate personal, project, and group access tokens in the UI

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/personal_access_tokens.md#rotate-a-personal-access-token) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/241523)

{{< /details >}}

You can now use the UI to rotate personal, project, and group access tokens. Previously, you had to use the API to do this.

Thank you [shangsuru](https://gitlab.com/shangsuru) for your contribution!

### Track CI/CD component usage across projects

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../api/graphql/reference/_index.md#cicatalogresourcecomponentusage) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/466575)

{{< /details >}}

Central DevOps teams often need to track where their CI/CD components are used across pipelines to better manage and optimize them. Without visibility, it’s challenging to identify outdated component use, understand adoption rates, or support component life cycles.

To address this, we’ve added a new GraphQL query that enables DevOps teams to view a list of projects where a component is used across their organization’s pipelines.
This capability empowers DevOps teams to enhance productivity and make better decisions by providing crucial insights.

### Small hosted runner on Linux Arm available to all Tiers

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Tier: Free, Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../ci/runners/hosted_runners/linux.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/501423)

{{< /details >}}

We are excited to introduce the small hosted runner on Linux Arm for GitLab.com, available for all tiers.
This 2 vCPUs Arm runner is fully integrated with GitLab CI/CD and allows you to
build and test applications natively on the Arm architecture.

We are determined to provide the industry’s fastest CI/CD build speed and look forward to seeing teams achieve even shorter feedback cycles and ultimately deliver software faster.

## Scale and Deployments

### Omnibus improvements

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

Because of a bug, FIPS Linux packages for GitLab 17.6 and earlier did not use the system Libgcrypt, but the same Libgcrypt bundled with regular Linux packages.

This issue is fixed for all FIPS Linux packages for GitLab 17.7, except for AmazonLinux 2. The Libgcrypt version of AmazonLinux 2 is not compatible with the GPGME and GnuPG versions shipped with the FIPS Linux packages.

FIPS Linux packages for AmazonLinux 2 will continue to use the same Libgcrypt bundled with the regular Linux packages, otherwise we would have to downgrade GPGME and GnuPG.

## Unified DevOps and Security

### Improved detection accuracy in Advanced SAST

<!-- categories: SAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/gitlab_advanced_sast.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/14685)

{{< /details >}}

We’ve updated Advanced SAST to detect the following vulnerability classes more accurately:

- C#: OS command injection and SQL injection.
- Go: path traversal.
- Java: code injection, CRLF injection in headers or logs, cross-site request forgery (CSRF), improper certificate validation, insecure deserialization, unsafe reflection, and XML external entity (XXE) injection.
- JavaScript: code injection.

We’ve also improved detection of user input sources for C# (ASP.NET) and Java (JSF, HttpServlet) and updated severity levels for consistency.

To see which types of vulnerabilities Advanced SAST detects in each language, see [Advanced SAST coverage](../../user/application_security/sast/advanced_sast_coverage.md).
To use this improved cross-file, cross-function scanning, [enable Advanced SAST](../../user/application_security/sast/gitlab_advanced_sast.md#turn-on-gitlab-advanced-sast).
If you’ve already enabled Advanced SAST, the new rules are [automatically activated](../../user/application_security/sast/rules.md#how-rule-updates-are-released).

### Efficient risk prioritization with KEV

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/graphql/reference/_index.md#cveenrichmenttype) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/11912)

{{< /details >}}

In GitLab 17.7, we added support for the Known Exploited Vulnerabilities Catalog (KEV). The [KEV Catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog) is maintained by CISA and curates listings of CVEs that have been exploited in the wild. You can leverage KEV to better prioritize scan results and to help evaluate the potential impact a vulnerability may have on your environment.

This data is available to composition analysis users through GraphQL. There is [planned work](https://gitlab.com/gitlab-org/gitlab/-/issues/427441) to support displaying this data in the GitLab UI.

### Expanded Code Flow view for Advanced SAST

<!-- categories: SAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/gitlab_advanced_sast.md#code-flow)

{{< /details >}}

The Advanced SAST [code flow view](../../user/application_security/sast/gitlab_advanced_sast.md#code-flow) is now available wherever vulnerabilities are shown, including the:

- [Vulnerability Report](../../user/application_security/vulnerability_report/_index.md).
- [Merge request security widget](../../user/application_security/sast/_index.md#merge-request-widget).
- [Pipeline security report](../../user/application_security/detect/security_scanning_results.md).
- [Merge request changes view](../../user/application_security/sast/_index.md#merge-request-changes-view).

The new views are enabled on GitLab.com. On GitLab self-managed, the new views are on by default starting in GitLab 17.7 (MR changes view) and GitLab 17.6 (all other views). For details on supported versions and feature flags, see [code flow feature availability](../../user/application_security/sast/gitlab_advanced_sast.md#code-flow).

To learn more about Advanced SAST, see [the announcement blog](https://about.gitlab.com/blog/gitlab-advanced-sast-is-now-generally-available/).

### New `/help` command in GitLab Duo Chat

<!-- categories: Editor Extensions, Duo Chat -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/gitlab_duo_chat/examples.md#gitlab-duo-chat-slash-commands) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/462122)

{{< /details >}}

Discover GitLab Duo Chat’s powerful features! Just type `/help` in the chat message field to explore everything it can do for you.

Give it a try and see how GitLab Duo Chat can make your work smoother and more efficient.

### Setting `environment.action: access` and `prepare` resets the `auto_stop_in` timer

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/yaml/_index.md#environmentauto_stop_in) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/437133)

{{< /details >}}

Previously, when using the `action: prepare`, `action: verify`, and `action: access` jobs together with the `auto_stop_in` setting, the timer was not reset. Starting in 18.0, `action: prepare` and `action: access` will reset the timer, while `action: verify` leaves it untouched.

For now, you can change to the new implementation by enabling the `prevent_blocking_non_deployment_jobs` feature flag.

Multiple breaking changes are intended to differentiate the behavior of the `environment.action: prepare | verify | access` values. The `environment.action: access` keyword will remain the closest to its current behavior, except for the timer reset.

To prevent future compatibility issues, you should review your use of these keywords.
Learn more about these proposed changes in the following issues:

- [Issue 437132](https://gitlab.com/gitlab-org/gitlab/-/issues/437132)
- [Issue 437133](https://gitlab.com/gitlab-org/gitlab/-/issues/437133)
- [Issue 437142](https://gitlab.com/gitlab-org/gitlab/-/issues/437142)

### Kubernetes 1.31 support

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/501390)

{{< /details >}}

This release adds full support for Kubernetes version 1.31, released in August 2024. If you deploy your apps to Kubernetes, you can now upgrade your connected clusters to the most recent version and take advantage of all its features.

For more information, see our [Kubernetes support policy and other supported Kubernetes versions](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features).

### Set namespace and Flux resource path from CI/CD job

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/environments/kubernetes_dashboard.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/500164)

{{< /details >}}

To use the dashboard for Kubernetes, you need to select an agent for Kubernetes connection from the environment settings, and optionally configure a namespace and a Flux resource to track the reconciliation status. In GitLab 17.6, we added support for selecting an agent with a CI/CD configuration. However, configuring the namespace and the Flux resource still required you to use the UI or make an API call. In 17.7, you can fully configure the dashboard using the CI/CD syntax with the `environment.kubernetes.namespace` and `environment.kubernetes.flux_resource_path` attributes.

### Group and project access tokens in credentials inventory

<!-- categories: System Access -->

{{< details >}}

- Tier: Gold
- Offering: GitLab.com
- Links: [Documentation](../../administration/credentials_inventory.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/498333)

{{< /details >}}

Group and project access tokens are now visible in the credentials inventory on GitLab.com. Previously, only personal access tokens and SSH keys were visible. Additional token types in the inventory allow for a more complete picture of credentials across the group.

### Extended token expiration notifications

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../security/tokens/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/464040)

{{< /details >}}

Previously, token expiration email notifications were only sent seven days before expiry. Now, these notifications are also sent 30 and 60 days before expiry. The increased frequency and date range of notifications makes users more aware of tokens that may be expiring soon.

### Unicode 15.1 emoji support 🦖🍋‍🟩🐦‍🔥

<!-- categories: Markdown -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](https://gitlab-org.gitlab.io/ruby/gems/tanuki_emoji/) | [Related issue](https://gitlab.com/gitlab-org/ruby/gems/tanuki_emoji/-/issues/28)

{{< /details >}}

In previous versions of GitLab, emoji support was limited to an older Unicode standard, which meant some newer emojis were unavailable.

GitLab 17.7 introduces support for Unicode 15.1, bringing the latest emoji additions. This includes exciting new options like the t-rex 🦖, lime 🍋‍🟩, and phoenix 🐦‍🔥, allowing you to express yourself with the most up-to-date symbols.

Additionally, this update enhances emoji diversity, ensuring greater representation across cultures, languages,
and identities, helping everyone feel included when communicating on the platform.

### Set your preferred text editor as default

<!-- categories: Text Editors -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/preferences.md#set-the-default-text-editor) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/423104)

{{< /details >}}

In this version, we’re introducing the ability to set a default text editor for a more personalized editing experience. With this change, you can now choose between the rich text editor, the plain text editor, or opt for no default, allowing flexibility in how you create and edit content.

This update ensures smoother workflows by aligning the editor interface with individual preferences or team standards. With this enhancement, GitLab continues to prioritize customization and usability for all users.

### New description field for access tokens

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/personal_access_tokens.md#create-a-personal-access-token) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/443819)

{{< /details >}}

When creating a personal, project, group, or impersonation access token, you can now optionally enter a description of that token. This helps provide extra context about the token, such as where and how is it used.

### Enable secret push protection in your groups with APIs

<!-- categories: Secret Detection -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/group_security_settings.md)

{{< /details >}}

With this release, you can now enable secret push protection on all projects in your group via the [REST API](../../api/group_security_settings.md) and the [GraphQL API](../../api/graphql/reference/_index.md#mutationsetgroupsecretpushprotection). This allows you to efficiently enable secret push protection on a per-group basis instead of project by project. Audit events are logged every time push protection is enabled or disabled.

### New API endpoint to list enterprise users

<!-- categories: System Access -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../api/group_enterprise_users.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/438366)

{{< /details >}}

Group Owners can now use a dedicated API endpoint to list enterprise users and any associated attributes.

### Remove Owner base role from custom roles

<!-- categories: Permissions -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/custom_roles/_index.md#create-a-custom-member-role) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/474273)

{{< /details >}}

The Owner base role is no longer available when creating a custom role as it provided no additional value because permissions are additive. Existing custom roles with the Owner base role are not impacted by this change.

### Navigation and usability improvements for the compliance center

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate, Premium
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/compliance_center/compliance_frameworks_report.md)

{{< /details >}}

We continue to make iterative and important improvements to the compliance center’s user experience for both groups
and projects.

With GitLab 17.7, we shipped two key improvements:

- Users can now filter by groups in the **Projects** tab of the compliance center, which gives another option
to users to apply, filter, and search for the appropriate project, and the compliance framework attached to that
project.
- A project’s compliance center now has a **Frameworks** tab, which allows users to search for compliance
frameworks attached to that particular project.

Please note that adding or editing frameworks is still done on groups, not projects.

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.7)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.7)
- [UI improvements](https://papercuts.gitlab.com/?milestone=17.7)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
