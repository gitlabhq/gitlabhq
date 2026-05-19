---
stage: Release Notes
group: Monthly Release
date: 2024-03-21
title: "GitLab 16.10 release notes"
description: "GitLab 16.10 released with Semantic versioning in the CI/CD catalog"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On March 21, 2024, GitLab 16.10 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor

[Lennard Sprong](https://gitlab.com/X_Sheep) previously won the GitLab MVP award in 15.4 and
was also nominated in 16.9.
He continues to provide contributions to GitLab Workflow for VS Code, merging 8 contributions
in the past two months.
Some of his past contributions include the ability to [watch the trace of running CI jobs](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/674),
[view downstream pipelines](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/1336),
and [compare images in merge requests](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/1319).
Lennard is also actively involved in issues inside the [GitLab-vscode-extension](https://gitlab.com/gitlab-org/gitlab-vscode-extension)
project.

[Erran Carey](https://gitlab.com/erran), Staff Fullstack Engineer at GitLab, nominated Lennard and
noted that “Lennard resolved an [issue viewing pipelines](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1000)
affecting GitLab Community Edition users.
He pointed impacted users to the existing workaround before [creating a merge request](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/1417)
to address the issue.”

[Tomas Vik](https://gitlab.com/viktomas), Staff Fullstack Engineer at GitLab, additionally supported Lennard and highlighted a contribution
to [add support for image diff](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/1319)
that allows people to view image changes during merge request review.

[Marco Zille](https://gitlab.com/zillemarco) also wins his second GitLab MVP award, previously winning in 15.3.
Marco was recognized not only for code contributions this release, but also for ongoing efforts supporting GitLab’s wider
community of contributors, running community pairing sessions, collaborating with GitLab team members, and
reviewing merge requests.

Marco added the ability to [cancel a pipeline immediately after one job fails](https://gitlab.com/gitlab-org/gitlab/-/issues/23605).
The feature is enabled and available on GitLab.com but still behind a feature flag
for self-hosted instances.
It will be made available for everyone in 16.11.

[Allison Browne](https://gitlab.com/allison.browne), Senior Backend Engineer at GitLab, nominated Marco for picking up this long
standing and highly requested feature request in pipeline execution.
[Fabio Pitino](https://gitlab.com/fabiopitino), Principal Engineer at GitLab, added that “Marco
not only implemented the fix but also was instrumental to the design of the feature,
bringing use cases and discussing them with customers interested in the feature.”

[Peter Leitzen](https://gitlab.com/splattael) additionally supported Marco’s nomination by highlighting how Marco helped to [review
and then finish a fix](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112813#note_1737719869)
for loading the stack trace from Sentry.

We are so grateful for the continued support from Lennard and Marco to improve GitLab and support our
open source community! 🙌

## Primary features

### Semantic versioning in the CI/CD catalog

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/components/_index.md#component-versions) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/442238)

{{< /details >}}

To enforce consistent behavior across published components, in GitLab 16.10 we will enforce Semantic versioning for components that are published to the CI/CD catalog. When publishing a component, the tag must follow the 3-digit semantic versioning standard (for example `1.0.0`).

When using a component with the `include: component` syntax, you should use the published semantic version. Using `~latest` continues to be supported, but it will always return the latest published version, so you must use it with caution as it could include breaking changes. Shorthand syntax is not supported, but it will be in an upcoming milestone.

### GitLab Duo access governance control

<!-- categories: Duo Chat -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/gitlab_duo/turn_on_off.md)

{{< /details >}}

Generative AI is revolutionizing work processes, and you can now facilitate the adoption of these technologies without compromising privacy, compliance, or intellectual property (IP) protections.

You can now disable GitLab Duo AI features for a project, a group, or an instance by using the API. You can then enable GitLab Duo for specific projects or groups when you’re ready. These changes are part of a suite of expected work to make AI features more granular to control.

### Wiki templates

<!-- categories: Wiki -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/wiki/_index.md#wiki-page-templates) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/16608)

{{< /details >}}

This version of GitLab introduces all-new templates to the Wiki. Now, you can create templates to streamline creating new pages or modifying existing ones. Templates are wiki pages that are stored in the templates directory in the wiki repository.

With this enhancement, you can make your wiki page layouts more consistent, create or restructure pages faster, and ensure that information is presented clearly and coherently in your knowledge base.

### New ClickHouse integration for high-performance DevOps Analytics

<!-- categories: Value Stream Management -->

{{< details >}}

- Tier: Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/group/contribution_analytics/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/428260)

{{< /details >}}

The [Contribution Analytics report](../../user/group/contribution_analytics/_index.md) is now more performant and backed by an advanced analytics database using ClickHouse on GitLab.com. This upgrade set the foundation for new extensive analytics and reporting features, allowing us to deliver high-performance analytics aggregations, filtering, and slicing across multiple dimensions. Support for self-managed customers to be able to add to this capability is proposed in [issue 441626](https://gitlab.com/gitlab-org/gitlab/-/issues/441626).

Although ClickHouse enhances GitLab’s analytics capabilities, it’s not meant to replace PostgreSQL or Redis, and the existing capabilities remain unchanged.

### GitLab Pages and Advanced Search available on GitLab Dedicated

<!-- categories: GitLab Dedicated -->

{{< details >}}

- Tier: Gold
- Links: [Documentation](../../subscriptions/gitlab_dedicated/_index.md#available-features) | [Related issue](https://about.gitlab.com/dedicated/)

{{< /details >}}

[GitLab Pages](../../user/project/pages/_index.md) and [Advanced Search](../../user/search/advanced_search.md) have been enabled for all [GitLab Dedicated instances](https://about.gitlab.com/dedicated/). These features are included in your GitLab Dedicated subscription.

Advanced Search enables faster, more efficient search across your entire GitLab Dedicated instance. All capabilities of Advanced Search can be used with GitLab Dedicated instances.

With GitLab Pages, you can publish static websites directly from a repository in GitLab Dedicated. Some capabilities of Pages are [not yet available](../../subscriptions/gitlab_dedicated/_index.md#gitlab-pages) for GitLab Dedicated instances.

### Offload CI traffic to Geo secondaries

<!-- categories: Geo Replication -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/geo/secondary_proxy/runners.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9779)

{{< /details >}}

You can now offload CI runner traffic to Geo secondary sites. Locate runner fleets where they are more convenient and economical to operate and manage, while reducing cross-region traffic. Distribute the load across multiple secondary Geo sites. Reduce load on the primary site, reserving resources for serving developer traffic. After this setup, the developer experience is transparent and seamless. Developer workflows for the setup and configuration of jobs remain unchanged.

## Scale and Deployments

### GitLab chart improvements

<!-- categories: Cloud Native Installation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/charts/)

{{< /details >}}

In GitLab 16.10, we’ve removed support for installing GitLab on Kubernetes 1.24 and older. Kubernetes maintenance support of Kubernetes 1.24 ended
in July 2023.

GitLab 16.10 includes support for installing GitLab on Kubernetes 1.27. For more information, see our new [Kubernetes version support policy](https://handbook.gitlab.com/handbook/engineering/careers/matrix/infrastructure/core-platform/distribution/). Our goal is to support newer versions of
Kubernetes closer to their official release.

### Omnibus improvements

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

GitLab 16.10 introduces a new major version of Patroni, version 3.0.1. This version upgrade will require downtime. For more
information and instructions, see the
[16.10 section of our GitLab 16 changes page](../../update/versions/gitlab_16_changes.md#16100).

GitLab 16.10 also includes a new version of Alertmanager, namely version 0.27. Most notably, this version includes the removal of API v1. For more information on this
release, see the [Alertmanager changelog](https://github.com/prometheus/alertmanager/blob/v0.27.0/CHANGELOG.md#0270--2024-02-28).

GitLab 16.10 also includes [Mattermost 9.5](https://docs.mattermost.com/deploy/mattermost-changelog.html#release-v9-5-extended-support-release).
Mattermost 9.5 includes various security updates and the deprecation of support for MySQL 5.7. Users on this version of MySQL must update.

### Filter members by Enterprise users with GraphQL API

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../api/graphql/reference/_index.md#groupgroupmembers) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/356062)

{{< /details >}}

With the GraphQL API you can now filter group members by Enterprise users.

### Blocked users are excluded from the followers list

<!-- categories: User Profile -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/_index.md#follow-users) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/441774)

{{< /details >}}

Previously, when a user who followed you was blocked, they still appeared in the followers list of your User Profile. From GitLab 16.10, blocked users are hidden from the followers list. If the user is unblocked, they will reappear in the followers list.

Thank you @SethFalco for this community contribution!

### Filter groups by visibility in the REST API

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/groups.md#list-groups) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/429314)

{{< /details >}}

You can now filter groups by visibility in the [Groups API](../../api/groups.md). You can use filtering to focus on groups with a specific visibility level, making it easier to audit GitLab implementations.

Thank you @imskr for this community contribution!

### Updated project deletion functionality

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/working_with_projects.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/443682)

{{< /details >}}

Now it’s easier to identify deleted projects in project lists. From GitLab 16.10, deleted projects display a `Pending deletion` badge next to the project title on the project overview page. An alert message clarifies that deleted projects are read-only. This message is visible on all project pages to ensure that this context is not lost even when working on sub-pages of the deleted project.

### Threaded notifications supported in Google Chat

<!-- categories: Settings -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/integrations/hangouts_chat.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/438452)

{{< /details >}}

Previously, notifications sent from GitLab to a space in Google Chat could not be created as replies to specified threads.
With this release, threaded notifications are enabled by default in Google Chat for the same GitLab object (for example, an issue or merge request).

Thanks to [Robbie Demuth](https://gitlab.com/robbie-demuth) for [this community contribution](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145187)!

### Custom payload template for webhooks

<!-- categories: Notifications -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/integrations/webhooks.md#custom-webhook-template) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/362504)

{{< /details >}}

Previously, GitLab webhooks could send only specific JSON payloads, which meant the receiving endpoints had to understand the webhook format. To use those webhooks, you had to either use an app to specifically support GitLab or write your own endpoint.

With this release, you can set a custom payload template in the webhook configuration. The request body is rendered from the template with the data for the current event.

Thanks to [Niklas](https://gitlab.com/Taucher2003) for [this community contribution](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142738)!

### Create Service Desk tickets from the UI and API

<!-- categories: Service Desk -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/service_desk/using_service_desk.md#create-a-service-desk-ticket-in-gitlab-ui) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/433376)

{{< /details >}}

Now you can create Service Desk tickets from the UI and the API using the `/convert_to_ticket user@example.com` quick action on a regular issue.

Create a regular issue and add a comment with the `/convert_to_ticket user@example.com` quick action. The provided email address becomes the external author of the ticket. GitLab doesn’t send the [default thank you email](../../user/project/service_desk/configure.md). You can add a public comment on the ticket to let the external participant know that the ticket has been created.

Adding a Service Desk ticket using the API follows the same concept: Create an issue using the [Issues API](../../api/issues.md) and use the `issue_iid` to add a note with the quick action using the [Notes API](../../api/notes.md).

## Unified DevOps and Security

### Automatically collapse generated files in merge requests

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/project/merge_requests/changes.md#collapse-generated-files)

{{< /details >}}

Merge requests can contain changes from users and automated processes or compilers. Files like `package-lock.json`, `Gopkg.lock`, and minified `js` and `css` files increase the number of files shown in a merge request review, and distract reviewers from the human-generated changes. Merge requests now display these files collapsed by default, to help:

- Focus reviewer attention on important changes, but enable a full review if desired.
- Reduce the amount of data needed to load the merge request, which might help larger merge requests perform better.

For examples of the file types that are collapsed by default, see the [documentation](../../user/project/merge_requests/changes.md#collapse-generated-files). To collapse more files and file types in the merge request, specify them as `gitlab-generated` in your project’s `.gitattributes` file.

You can leave feedback on this change in [issue 438727](https://gitlab.com/gitlab-org/gitlab/-/issues/438727).

### Expanded checks in merge widget

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/project/merge_requests/auto_merge.md)

{{< /details >}}

The merge widget explains clearly if your merge request is not mergeable, and why. Previously, only one merge blocker was displayed at a time. This increased review cycles and forced you to resolve problems individually, without knowing if more blockers remained.

When you view a merge request, the merge widget now gives you a comprehensive view of problems, both remaining and resolved. Now you can understand at a glance if multiple blockers exist, fix them all in a single iteration, and increase your confidence that no hidden blockers have been missed.

### Manually refresh the dashboard for Kubernetes

<!-- categories: Environment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/environments/kubernetes_dashboard.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/429531)

{{< /details >}}

GitLab 16.10 adds a dedicated refresh feature to the dashboard for Kubernetes. Now you can manually fetch Kubernetes resource data, and ensure you have access to the most recent information about your clusters.

### Improved environment details page

<!-- categories: Environment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/environments/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/431746)

{{< /details >}}

The environment details page is improved in GitLab 16.10. When you select an environment from the environment list, you can review up-to-date information about your deployments and connected Kubernetes clusters, all in one convenient layout.

### Improved error message for authentication rate limit

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../security/rate_limits.md#failed-authentication-ban-for-git-and-container-registry) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/22787)

{{< /details >}}

When authenticating with GitLab, it is possible to hit the authentication attempt rate limit, such as when using a script. Previously, if you hit the authentication rate limit, a `403 Forbidden` message was returned, which did not explain why you are getting this error. We now return a more descriptive error message which tells you that you’ve hit the authentication rate limit.

### Audit event `scope` attribute

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

Audit events now include a `scope` attribute that indicates if the event is associated with an entire instance, a group, a project, or a user.

This new attribute helps users determine where an event originated in audit event payloads. It also allows our
[audit event type documentation](../../administration/compliance/audit_event_reports.md) to list all available scopes for an audit event
type.

You can use this new attribute to parse through external streaming destinations or to better understand context around events.

### Custom names for service accounts

<!-- categories: User Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/service_accounts.md#create-a-service-account) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/415973)

{{< /details >}}

You can now customize a service account’s username and display name. Previously, these were auto-generated by GitLab. With a custom name, it is easier to understand the purpose of the service account, and distinguish it from other accounts in the user list.

### Audit event for assigning a custom role

<!-- categories: Permissions -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../administration/compliance/audit_event_reports.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/427954)

{{< /details >}}

GitLab now records an audit event when a user is assigned a different role, regardless of whether that role is a default role or a custom role. This event is important to identify if user permissions have been added or changed in case of privilege escalation.

### New permissions for custom roles

<!-- categories: Permissions -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/custom_roles/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/391760)

{{< /details >}}

To create custom roles, you can now choose two new permissions:

- Manage CI/CD Variables
- Ability to delete a group

With the release of these custom permissions, you can reduce the number of Owners needed in a group by creating a custom role with these Owner-equivalent permissions. Custom roles let you define granular roles that give a user only the permissions they need to do their job, and reduce unnecessary privilege escalation.

### Scan result policies are now "Merge request approval policies"

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9850)

{{< /details >}}

As we’ve expanded capabilities of the policy type to support overriding project settings and enforce approval requirements, we’ve updated the policy name to the more apt “merge request approval policy”.

Merge request approval policies do not replace or conflict with existing merge request approval rules. Instead they provide Ultimate tier customers the ability to create global enforcement across projects through policies managed by central security and compliance teams - an increasingly challenging task for large-scale organizations.

### Webhooks support mutual TLS

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/project/integrations/webhooks.md#configure-webhooks-to-support-mutual-tls) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/27450)

{{< /details >}}

You can now configure webhooks to support mutual TLS. This configuration establishes the authenticity of the webhook source and enhances security. You configure the client certificate in PEM format, which is presented to the server during the TLS handshake. You can also protect the certificate with a PEM passphrase.

### Sign-in page improvements

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](https://gitlab.com/gitlab-org/gitlab/-/issues/412845) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/412845)

{{< /details >}}

The GitLab sign-in page has been refreshed with improvements that fix spacing issues, broken elements, and alignment. There is also additional support for dark mode, and a button to manage cookie preferences. The combination of these improvements gives a fresh look and improved functionality on the sign-in page.

### Smart card support for Active Directory LDAP

<!-- categories: User Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/auth/smartcard.md#authentication-against-an-active-directory-ldap-server) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/328074)

{{< /details >}}

Smart card authentication against an LDAP server now supports Entra ID (formerly known as Azure Active Directory). This makes it easy to sync user identity data from Entra ID, and authenticate against LDAP with smart cards.

### Use merge base pipeline for merge request approval policy comparison

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#understanding-merge-request-approval-policy-approvals) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/428518)

{{< /details >}}

This enhancement aligns the logic of the merge request approval policy evaluation with the security MR widget, ensuring that findings that violate a merge request approval policy align with the results displayed in the widget. By aligning the logic, security, compliance, and development teams can more consistently identify which findings violate a policy and require approval.
Rather than comparing to the target branch’s latest completed `HEAD` pipeline, scan result policies now compare to a common ancestor’s latest completed pipeline, the “merge base”.

### Support domain-level redirects for GitLab Pages

<!-- categories: Pages -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/pages/redirects.md#domain-level-redirects) | [Related issue](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/601)

{{< /details >}}

Previously, GitLab focused on supporting simple redirect rules. In GitLab 14.3, we [introduced](https://gitlab.com/gitlab-org/gitlab-pages/-/merge_requests/458) support for splat and placeholder redirects.

From GitLab 16.10, GitLab Pages supports domain-level redirects. You can combine domain-level redirects with [splat rules](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/601) to dynamically rewrite the URL path. This improvement helps prevent confusion and ensure that you can still find your information after a domain change, even if you use an old domain.

### List repository tags with the new container registry API

<!-- categories: Container Registry -->

{{< details >}}

- Tier: Free, Silver, Gold
- Links: [Documentation](../../api/container_registry.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10208)

{{< /details >}}

Previously, the container registry relied on the Docker/OCI [listing image tags registry API](https://gitlab.com/gitlab-org/container-registry/-/blob/5208a0ce1600b535e529cd857c842fda6d19ad59/docs/spec/docker/v2/api.md#listing-image-tags) to display tags in GitLab. This API had significant performance and discoverability limitations.

This API performed slowly because the number of network requests against the registry scaled with the number of tags in the tags list. In addition, because the API didn’t track publish time, the published timestamp was often incorrect. There were also limitations when displaying images based on Docker manifest lists or OCI indexes, such as for multi-architecture images.

To address these limitations, we introduced a new registry [list repository tags API](https://gitlab.com/gitlab-org/container-registry/-/blob/5208a0ce1600b535e529cd857c842fda6d19ad59/docs/spec/gitlab/api.md#list-repository-tags). In GitLab 16.10, we’ve completed the migration to the new API. Now, whether you use the UI or the REST API, you can expect improved performance, accurate publication timestamps, and robust support for multi-architecture images.

This improvement is available only on GitLab.com. Self-managed support is blocked until the next-generation container registry is generally available. To learn more, see [issue 423459](https://gitlab.com/gitlab-org/gitlab/-/issues/423459).

### New contributor count metric in the Value Streams Dashboard

<!-- categories: Value Stream Management -->

{{< details >}}

- Tier: Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/analytics/value_streams_dashboard.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/433353)

{{< /details >}}

To enable software leaders to gain insights into the relationship between team velocity, software stability, security exposures, and team productivity, we introduced a new [**Contributor count** metric in the Value Streams Dashboard](../../user/analytics/value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports). The contributor count represents the number of monthly unique users with contributions in the group. This metric is designed to track adoption trends over time, and is based on [contributions calendar events](../../user/profile/contributions_calendar.md#user-contribution-events).

The **Contributor count** metric is available only on GitLab.com, and requires the [contribution analytics report to be configured to run through ClickHouse](../../user/group/contribution_analytics/_index.md#contribution-analytics-with-clickhouse). [Issue 441626](https://gitlab.com/gitlab-org/gitlab/-/issues/441626) tracks efforts to make this feature available to self-managed customers as well.

### Inherited filters in Value Stream Analytics for seamless and accurate workflow analysis

<!-- categories: Value Stream Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/issues_analytics/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/439615)

{{< /details >}}

[Value stream analytics](../../user/group/value_stream_analytics/_index.md) now applies the same filters when drilling down from the **Lead time** tile to the [**Issue Analytics** report](../../user/group/issues_analytics/_index.md). The filter inheritance helps you dive deeper and seamlessly into data as you switch between analytics views.

### Add an issue to the current or next iteration with a quick action

<!-- categories: Team Planning -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/quick_actions.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/384885)

{{< /details >}}

The `/iteration` quick action now accepts a cadence reference with `--current` or `--next` arguments. If your group has a single iteration cadence, you can quickly assign an issue to the current or next iteration by using `/iteration --current|next`. If your group contains many iteration cadences, you can specify the desired cadence in the quick action by referencing the cadence name or ID. For example, `/iteration [cadence:"<cadence name>"|<cadence ID>] --next|current`.

### Continuous Vulnerability Scanning available by default for Container Scanning

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/continuous_vulnerability_scanning/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10174)

{{< /details >}}

Continuous Vulnerability Scanning for Container Scanning is now available by default. The default availability removes the need to opt into this functionality through a feature flag. To learn more about the benefits of Continuous Vulnerability Scanning, see the documentation link.

### Improved Dependency Scanning support for sbt

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#supported-languages-and-package-managers) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390287)

{{< /details >}}

We have updated the mechanism we use to generate the list of dependencies for projects using sbt. This change is only applicable to projects using sbt version 1.7.2 and later. To fully leverage Dependency Scanning for sbt projects, you should upgrade to sbt version 1.7.2 and later.

### DAST analyzer performance updates

<!-- categories: DAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dast/browser/_index.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/12194)

{{< /details >}}

During the 16.10 release milestone, proxy-based DAST was:

- Upgraded ZAP to version 2.14.0. For more information, see [issue 442056](https://gitlab.com/gitlab-org/gitlab/-/issues/442056).

We also completed the following browser-based DAST crawler performance improvements:

- Limit the number of goroutines created when crawling. For more information, see [issue 440151](https://gitlab.com/gitlab-org/gitlab/-/issues/440151).
- Optimize finding elements to interact with. This reduced scan time by 6%. For more information, see [issue 440295](https://gitlab.com/gitlab-org/gitlab/-/issues/440295).
- Optimize JSON unmarshalling of DevTools messages. This reduced scan time by 7%. For more information, see [issue 439726](https://gitlab.com/gitlab-org/gitlab/-/issues/439726).

### GitLab Runner 16.10

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 16.10 today! GitLab Runner is the lightweight, highly-scalable agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

Bug fixes:

- [Memory leak when jobs are cancelled in the Runner Kubernetes executor](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27857)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-10-stable/CHANGELOG.md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.10)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.10)
- [UI improvements](https://papercuts.gitlab.com/?milestone=16.10)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
