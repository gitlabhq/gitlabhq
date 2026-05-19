---
stage: Release Notes
group: Monthly Release
date: 2024-10-17
title: "GitLab 17.5 release notes"
description: "GitLab 17.5 released with Introducing Duo Quick Chat"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On October 17, 2024, GitLab 17.5 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Jim Ender

Everyone can [nominate GitLab’s community contributors](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)!
Show your support for our active candidates or add a new nomination! 🙌

Jim was recognized for leading an effort to [close nearly 100 backlog issues](https://gitlab.com/gitlab-org/gitlab/-/issues/?sort=updated_desc&state=closed&assignee_username%5B%5D=Jimender2&first_page_size=100)
on GitLab.
He is active in many of our weekly community pairing sessions that dive into some interesting discussions.
Jim also supports people across the [GitLab Community Discord](https://discord.gg/gitlab),
troubleshooting GitLab support requests and guiding new contributors.
Jim works for an industrial technology company writing software for Critical Infrastructure and ERP systems.

“Even small contributions add up to make projects better,” says Jim.
“Something as small as documentation contributions helps others out. You don’t have to champion a full new feature.”

Jim was nominated by [Lee Tickett](https://gitlab.com/leetickett-gitlab), Staff FullStack Engineer, Contributor Success at GitLab.
“Issue triage/curation has been toward the top of my list to get the wider community involved in and Jim is paving the way here,” says Lee.

[Daniel Murphy](https://gitlab.com/daniel-murphy), Senior Program Manager, Contributor Success at GitLab, added to the nomination.
“Jim’s outstanding support for new contributors and guidance in getting them started helps us grow as a community to co-create GitLab.”

“Impressive work on the [merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163849) I reviewed!” says [Vanessa Otto](https://gitlab.com/vanessaotto), Senior Frontend Engineer at GitLab.
“Jim responded quickly, understood the suggestions immediately, and implemented them seamlessly.
It was great to see such efficiency and clarity in Jim’s approach.”

We are so grateful to Jim and all of our open source community for contributing to GitLab!

## Primary features

### Introducing Duo Quick Chat

<!-- categories: Editor Extensions, Duo Chat -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/gitlab_duo_chat/_index.md#in-an-editor-window) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/15218)

{{< /details >}}

Introducing Duo Quick Chat, an AI-powered chat designed to work exactly where you are in your code. Duo Quick Chat operates directly on the lines you’re editing, offering real-time assistance without ever moving you away from your code. Whether you’re refactoring, fixing bugs, or writing tests, Duo Quick Chat provides suggestions and explanations on the spot, ensuring that you stay fully focused without switching context.

### Use self-hosted model for GitLab Duo Code Suggestions

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/498114)

{{< /details >}}

You can now host selected large language models (LLMs) in your own infrastructure and configure those models as the source for Code Suggestions. This feature is in beta and available with an Ultimate and Duo Enterprise subscription on self-managed GitLab environments.

With self-hosted models, you can use models hosted either on-premise or in a private cloud to enable GitLab Duo Code Suggestions. We currently support open-source Mistral models on vLLM or AWS Bedrock. By enabling self-hosted models, you can leverage the power of generative AI while maintaining complete data sovereignty and privacy.

Please leave feedback in [the feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/498376).

### Export code suggestion usage events

<!-- categories: Value Stream Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../api/graphql/reference/_index.md#codesuggestionevent) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/477231)

{{< /details >}}

Previously, AI impact analytics were available only on GitLab.com to GitLab Duo Enterprise customers, and on GitLab self-managed with a ClickHouse integration. Additionally, the default metrics were aggregated.

Now, you can export raw code suggestion events from the GraphQL API. This way you can import the data into your data analysis tool to get deeper insights into acceptance rates across more dimensions, such as suggestion size, language, and user. The raw events are not stored in ClickHouse, so some AI Impact Analytics metrics become available to all GitLab deployments, including GitLab Dedicated and self-managed.

### Have a conversation with GitLab Duo Chat about your merge request

<!-- categories: Duo Chat -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../user/gitlab_duo_chat/examples.md#ask-about-a-specific-merge-request) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/464587)

{{< /details >}}

In response to your feedback, GitLab Duo Chat is now aware of merge requests. Whether you are a reviewer or an author, you can now converse with Chat about a merge request to quickly dig into it, or learn what to do next. Simply open your merge request and open Duo Chat, then start the conversation.

This new feature complements our existing feature, where you can quickly populate the description of a merge request by asking GitLab Duo to [summarize code changes](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes), so that reviewers can get a general understanding of what the merge request is about.

### Enhanced branch rules editing capabilities

<!-- categories: Source Code Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/repository/branches/branch_rules.md#create-a-branch-rule)

{{< /details >}}

In GitLab 15.10, we introduced a [consolidated view for branch-related settings and rules](https://about.gitlab.com/releases/2023/03/22/gitlab-15-10-released/#see-all-branch-related-settings-together). This view provided you with an easy way to understand the configuration of your project across multiple settings.

Building on this feature, you can now directly modify specific branch rules in this view, including branch protections, approval rules, and external status check configurations. These new capabilities lay the foundation for [continued improvements](https://gitlab.com/groups/gitlab-org/-/epics/12546) in branch configuration that will allow for greater flexibility in the future.

We encourage you to explore these new capabilities and to provide feedback. You can do this by contributing to our dedicated [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/486050).

### GitLab Dedicated Tenant Overview in Switchboard

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../administration/dedicated/tenant_overview.md)

{{< /details >}}

Switchboard’s new Tenant Overview now provides a single place to quickly access essential information about your GitLab Dedicated instance.

With this first release, you can now view your current GitLab version, instance URL, and the date and time of your upcoming and past maintenance windows all on the Tenant Overview page.

### Secret Push Protection is generally available

<!-- categories: Secret Detection -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/secret_detection/secret_push_protection/_index.md)

{{< /details >}}

We’re excited to announce that Secret Push Protection is now generally available for all GitLab Ultimate customers.

If a secret, like a key or an API token, is accidentally committed to a Git repository, anyone with access to the repository can impersonate the user of the secret for malicious purposes. A leaked secret costs time and money, and potentially damages a company’s reputation. Secret push protection helps reduce the remediation time and reduce risk by protecting secrets from being pushed in the first place.

Secret push protection has been improved since the beta release. When commits are pushed by using the Git CLI, now only the changes (diff) are scanned for secrets. We’ve also added experimental support for excluding paths, rules, or specific values to avoid false positives.

To learn more, see [the blog](https://about.gitlab.com/blog/prevent-secret-leaks-in-source-code-with-gitlab-secret-push-protection/).

### Credentials Inventory available on GitLab.com

<!-- categories: System Access -->

{{< details >}}

- Tier: Gold
- Offering: GitLab.com
- Links: [Documentation](../../administration/credentials_inventory.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/297441)

{{< /details >}}

The Credentials Inventory is now available for top-level group Owners on GitLab.com. In the Credentials Inventory, you can view your [enterprise user’s](../../user/enterprise_user/_index.md) personal access tokens and SSH keys across your group. You can also revoke, delete, and view additional information about the credentials. Previously, this was only available for administrators on GitLab self-managed.

Group Owners can use the Credentials Inventory to understand the credentials that exist in their purview, and provide increased visibility and control.

### Component filter on the Dependency List

<!-- categories: Dependency Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dependency_list/_index.md#filter-dependency-list) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/12652)

{{< /details >}}

Now, in GitLab, you can filter for specific dependency components quickly to identify whether or not they are used in your group or project.
It is time consuming and inconvenient to manually go through the entire list just to verify whether or not a particular package and version is present.
With the new **filter by component** on the dependency list, you isolate vulnerable dependencies so that you can assess open risks in your application.

## Scale and Deployments

### GitLab chart improvements

<!-- categories: Cloud Native Installation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/charts/)

{{< /details >}}

GitLab 17.5 includes an update to our version of the NGINX Ingress Controller. The `nginx-controller` container image is now version 1.11.2. Please
note this includes new RBAC requirements because the new controller now uses endpointslices and requires an RBAC rule to access them.

### Omnibus improvements

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

GitLab 17.5 includes support for upgrading PostgreSQL from version 14.x to 16.x for single node installations. Automatic upgrades are not enabled and
so PostgreSQL upgrades must be triggered manually.

## Unified DevOps and Security

### Elevate your coding: Duo Chat now in Visual Studio for Windows

<!-- categories: Editor Extensions, Duo Chat -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/gitlab_duo_chat/_index.md#use-gitlab-duo-chat-in-visual-studio-for-windows) | [Related epic](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/77)

{{< /details >}}

Empower your development workflow with Duo Chat, now seamlessly integrated into Visual Studio for Windows. Duo Chat enhances your coding experience by providing AI-powered capabilities to explain, refine, debug code, or write tests all in real-time. This integration allows you to leverage Duo Chat’s advanced AI tools directly within your familiar development environment, improving productivity and enabling faster, more efficient problem-solving.

### Configure agent and GitOps environment settings with the REST API

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/environments.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/412677)

{{< /details >}}

You can check the status of your pods and Flux reconciliation from the GitLab environments UI.
However, this approach is hard to scale because the required settings are exposed only through GraphQL or the UI.
Now, GitLab ships with REST API support for configuring an agent for Kubernetes, as well as setting the namespace and Flux resource per environment.
To further improve support for dynamic environments, [issue 467912](https://gitlab.com/gitlab-org/gitlab/-/issues/467912) proposes adding support for configuring these settings in CI/CD pipelines.

### Easy bootstrapping of GitLab Kubernetes integration

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/clusters/agent/install/_index.md#bootstrap-the-agent-with-flux-support-recommended) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/473987)

{{< /details >}}

GitLab offers flexible, reliable, and secure GitOps support with the [agent for Kubernetes](../../user/clusters/agent/_index.md) and its [Flux integration](../../user/clusters/agent/gitops.md).
Still, bootstrapping Flux with GitLab and setting up the agent for Kubernetes used to require a lot of documentation reading and switching between the GitLab UI and the terminal.
The GitLab CLI now offers [the `glab cluster agent bootstrap` command](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/cluster/agent/bootstrap.md) to simplify installing the agent on top of an existing Flux installation.
Now, you can configure Flux and the agent with just two simple commands.

### Kubernetes integration support for firewalled GitLab installations

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/clusters/agent/_index.md#receptive-agents) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/437014)

{{< /details >}}

Until now, the agent for Kubernetes could be used only if the Kubernetes cluster could connect to the GitLab instance.
This issue meant that some customers couldn’t use the agent if, for example, they ran GitLab on a private network or behind a firewall.
From GitLab 17.5, you can initiate the cluster-GitLab connection from GitLab, assuming that a properly configured `agentk` instance is already waiting for a connection initialization.

Once the initial connection is established, all the features of the agent are available. Initializing from a cluster is not changed with this development.

### Stream Kubernetes resource events

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/environments/kubernetes_dashboard.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/470042)

{{< /details >}}

GitLab provides a real-time view of your pods, as well as pod log streaming, all through the dashboard for Kubernetes.
In GitLab 17.4, we offered a static listing of resource-specific event information from the UI.
This release further improves the dashboard for Kubernetes by letting you stream incoming events as they emerge in the cluster.

### Suspend or resume GitOps reconciliation from the GitLab UI

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/environments/kubernetes_dashboard.md#suspend-or-resume-flux-reconciliation) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/478380)

{{< /details >}}

As a Flux user, have you ever needed to quickly stop an automatic reconciliation or drift remediation? Have you wanted to trigger a `HelmRelease` to synchronize manually removed resources? These actions are best achieved with the Flux suspend and resume functions. Until now, your best option was to use the Flux CLI, which required a context switch and several commands to ensure the right resource was affected. In GitLab 17.5, you can suspend or resume a reconciliation from the built-in dashboard for Kubernetes.

### Improved user management summary

<!-- categories: User Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/profile/account/create_accounts.md#create-a-user-in-the-admin-area) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/456332)

{{< /details >}}

Administrators now have an enhanced, summarized view of the following critical pieces of information about the users on their instance:

- Pending approval.
- Without two-factor authentication.
- Administrators.

This increases user management efficiency, because administrators can quickly see how many users are in these states from the summary view, and filter on them.

### Add groups to security policy scope

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/14149)

{{< /details >}}

You can now target groups/subgroups in security policy scopes. This extends the existing options allowing you to target all projects in a group/subgroup, projects based on a defined project list, and projects matching a list of compliance framework labels.

This gives you further flexibility in enabling policies across your groups, while also being able to apply exceptions to scope projects out of enforcement where necessary.

This improvement also precedes a number of [enhancements](https://gitlab.com/groups/gitlab-org/-/epics/5446) that will simplify the process of linking security policy projects and granularly scoping enforcement of policies.

### Disable password authentication for enterprise users

<!-- categories: User Management -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/group/saml_sso/_index.md#disable-password-and-passkey-authentication-for-enterprise-users) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/373718)

{{< /details >}}

Enterprise users can authenticate using a local account with username and password. Now, group Owners can disable password authentication for the group’s enterprise users. If password authentication is disabled, enterprise users can use either the group’s SAML identity provider to authenticate with GitLab web UI, or a personal access token to authenticate with GitLab API and Git using HTTP Basic Authentication.

### Access compliance center on projects

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/compliance_center/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/441350)

{{< /details >}}

Previously, the compliance center was available only for top-level groups and subgroups.

With this release, we’ve added the compliance center to projects. At this level, compliance center provides
view-only capabilities for checks and violations that pertain to a particular project.

To add or edit a framework, you should access the compliance center on top-level groups instead.

### Migration process for compliance pipelines to security policies

<!-- categories: Compliance Management, Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/compliance_pipelines.md#pipeline-execution-policies-migration) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/11275)

{{< /details >}}

In GitLab 17.3, we announced the deprecation of compliance pipelines and its eventual removal by the 18.0 release.
Instead of compliance pipelines, you should use the pipeline execution policy type instead, which was released in GitLab 17.2.

To help you migrate your existing compliance pipelines over to the pipeline execution policy type, this release includes a
warning banner that:

- Notifies users about the deprecation of compliance pipelines.
- Provides a prompted and guided workflow to migrate existing compliance pipelines to the pipeline execution policy type.

### View token associations using API

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/personal_access_tokens.md#list-all-token-associations) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/466046)

{{< /details >}}

You can now view which groups, subgroups, and projects a token is associated with. This makes it easier to determine the impact of token expirations or revocations, and to understand where a token is able to be used.

### Selective SAML single sign-on enforcement

<!-- categories: User Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/settings/sign_in_restrictions.md#disable-password-and-passkey-authentication-for-users-with-an-sso-identity) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/382917)

{{< /details >}}

Previously, when SAML SSO was enabled, groups could choose to enforce SSO, which required all members to use SSO
authentication to access the group. However, some groups want the security of SSO enforcement for employees or
group members, while still allowing outside collaborators or contractors to access their groups without SSO.

Now, groups with SAML SSO enabled have SSO automatically enforced for all members
who have a SAML identity. Group members without SAML identities are not required to
use SSO unless SSO enforcement is explicitly enabled.

A member has a SAML identity if one or both of the following are true:

- They signed in to GitLab using their GitLab group’s single sign-on URL.
- They were provisioned by SCIM.

To ensure smooth operation of the selective SSO enforcement feature, ensure your SAML configuration is
working properly before selecting the **Enable SAML authentication for this group** checkbox.

### Enhance API performance when working with container registry tags

<!-- categories: Container Registry -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../api/container_registry.md#list-all-registry-repository-tags) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/482399)

{{< /details >}}

We’re excited to announce a significant improvement to our Container Registry API for self-managed GitLab instances. With the release of GitLab 17.5, we’ve implemented keyset pagination for the `:id/registry/repositories/:repository_id/tags` endpoint, bringing it in line with the functionality already available on GitLab.com. This enhancement is part of our ongoing efforts to improve API performance and provide a consistent experience across all GitLab deployments.

Keyset pagination offers a more efficient method for handling large datasets, resulting in improved performance and a better user experience. This update is particularly useful when managing large container registries, as it allows for smoother navigation through repository tags. In order to use this feature, self-managed instances must upgrade to the [next-generation container registry](../../administration/packages/container_registry_metadata_database.md).

### Safeguard your dependencies with protected packages

<!-- categories: Container Registry -->

{{< details >}}

- Tier: Free, Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/packages/package_registry/package_protection_rules.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/472655)

{{< /details >}}

We’re thrilled to introduce support for protected npm packages, a new feature designed to enhance the security and stability of your GitLab package registry. In the fast-paced world of software development, accidental modification or deletion of packages can disrupt entire development processes. Protected packages address this issue by allowing you to safeguard your most important dependencies against unintended changes.

From GitLab 17.5, you can protect npm packages by creating protection rules. If a package is matched by a protection rule, only specified users can update or delete the package. With this feature, you can prevent accidental changes, improve compliance with regulatory requirements, and streamline your workflows by reducing the need for manual oversight.

### Ruby support and rule updates for Advanced SAST

<!-- categories: SAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/gitlab_advanced_sast.md)

{{< /details >}}

We’ve added Ruby support to GitLab Advanced SAST.
To use this new cross-file, cross-function scanning support, [enable Advanced SAST](../../user/application_security/sast/gitlab_advanced_sast.md#turn-on-gitlab-advanced-sast).
If you’ve already enabled Advanced SAST, Ruby support is automatically activated.

In the last month, we’ve also released updates to improve the detection rules for [the other languages Advanced SAST supports](../../user/application_security/sast/gitlab_advanced_sast.md#supported-languages) by:

- Detecting additional Java path traversal, Java command injection, and JavaScript path traversal vulnerabilities.
- Updating CWE mappings to more specifically and consistently identify vulnerability types.
- Increasing the severity of path traversal vulnerabilities.

To see which types of vulnerabilities Advanced SAST detects in each language, see the new [Advanced SAST coverage page](../../user/application_security/sast/advanced_sast_coverage.md).

To learn more about Advanced SAST, see [last month’s announcement blog](https://about.gitlab.com/blog/gitlab-advanced-sast-is-now-generally-available/).

### GitLab Runner 17.5

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 17.5 today! GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s new

- [Support AWS S3 multipart uploads with scoped temporary credentials](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/26921)

#### Bug Fixes

- [Jobs with extra services don’t complete if one of the service container is not running](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38035)
- [The `gitlab-runner-fips-17.4.0-1` package fails to run on Amazon Linux 2 and returns a glibc error](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38034)
- [Cache doesn’t work with Amazon S3 when using S3 Express One Zone endpoints](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37394)
- [Jobs are unable to pull base images if the `DOCKER_AUTH_CONFIG` variable has multiple registries](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28073)

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.5)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.5)
- [UI improvements](https://papercuts.gitlab.com/?milestone=17.5)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
