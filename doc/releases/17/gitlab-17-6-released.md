---
stage: Release Notes
group: Monthly Release
date: 2024-11-21
title: "GitLab 17.6 release notes"
description: "GitLab 17.6 released with Use self-hosted model for GitLab Duo Chat"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On November 21, 2024, GitLab 17.6 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Joel Gerber

Everyone can [nominate GitLab’s community contributors](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)!
Show your support for our active candidates or add a new nomination! 🙌

Joel was recognized for being an invaluable contributor to our CI components, offering insightful feedback on merge requests,
and thoughtful comments on complex discussions.
His contributions include [UI polish for the CI/CD catalog](https://gitlab.com/gitlab-org/gitlab/-/issues/464703),
highly requested documentation improvements for the GitLab Terraform Provider, [job log timestamps](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164595),
and [providing feedback to the UI/UX team](https://gitlab.com/gitlab-org/gitlab/-/issues/482524#note_2089551197).

Joel is a Staff Software Engineer at [HackerOne](https://www.hackerone.com/) and was nominated by
[Lee Tickett](https://gitlab.com/leetickett-gitlab), Staff FullStack Engineer, Contributor Success at GitLab,
for his contributions and for providing valuable feedback.

[Gina Doyle](https://gitlab.com/gdoyle), Senior Product Designer at GitLab, added to the nomination.
“There was a lot of discussion going on internally that led the MR process to be more complicated,” says Gina.
“But Joel stayed strong and active within the discussion and completed the contribution.”

“Joel also contributed to the UI polish on the CI/CD catalog issue,” says [Sunjung Park](https://gitlab.com/sunjungp),
Staff Product Designer at GitLab.
“It makes our user interface beautiful and consistent with other areas.”

We are so grateful to Joel for all of his contributions and to all of our open source community for contributing to GitLab!

## Primary features

### Use self-hosted model for GitLab Duo Chat

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/501267)

{{< /details >}}

You can now host selected large language models (LLMs) in your own infrastructure and configure those models as the source for GitLab Duo Chat. This feature is in beta and available with an Ultimate and Duo Enterprise subscription on self-managed GitLab environments.

With self-hosted models, you can use models hosted either on-premise or in a private cloud as the source for GitLab Duo Chat or Code Suggestions (introduced as a beta feature in GitLab 17.5). For Code Suggestions, we currently support open-source Mistral models on vLLM or AWS Bedrock, Claude 3.5 Sonnet on AWS Bedrock, and OpenAI models on Azure OpenAI. For Chat, we currently support open-source Mistral models on vLLM or AWS Bedrock, and Claude 3.5 Sonnet on AWS Bedrock. By enabling self-hosted models, you can leverage the power of generative AI while maintaining complete data sovereignty and privacy.

Please leave feedback in [issue 501268](https://gitlab.com/gitlab-org/gitlab/-/issues/501268).

### Enhanced merge request reviewer assignments

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/merge_requests/reviews/_index.md#request-a-review)

{{< /details >}}

After you’ve carefully crafted your changes and prepared a merge request, the next step is to identify reviewers who can help move it forward. Identifying the right reviewers for your merge request involves understanding who the right approvers are, and who might be a subject matter expert (CODEOWNER) for the changes you’re proposing.

Now, when assigning reviewers, the sidebar creates a connection between the approval requirements for your merge request and reviewers. View each approval rule, then select from approvers who can satisfy that approval rule and move the merge request forward for you. If you use [optional CODEOWNER sections](../../user/project/codeowners/reference.md#optional-sections) those rules are also shown in the sidebar to help you identify appropriate subject matter experts for your changes.

Enhanced reviewer assignments is the next evolution of applying intelligence to assigned reviewers in GitLab. This iteration builds on what we’ve learned from suggested reviewers, and how to effectively identify the best reviewers for moving a merge request forward. In [upcoming iterations](https://gitlab.com/groups/gitlab-org/-/epics/14808) of reviewer assignments, we’ll continue to enhance the intelligence used to recommend and rank possible reviewers.

### Support for private container registries in workspaces

<!-- categories: Workspaces -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/workspace/configuration.md#configure-support-for-private-container-registries)

{{< /details >}}

GitLab workspaces now offer support for private container registries. With this setup, you can pull container images from any private registry of your choice. As long as your Kubernetes cluster has a valid image pull secret, you can reference the secret in your [GitLab agent configuration](../../user/workspace/gitlab_agent_configuration.md).

This feature simplifies workflows, especially for teams that use custom or third-party container registries, and improves the flexibility and security of containerized development environments.

### Extension marketplace now available in workspaces

<!-- categories: Workspaces -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/web_ide/_index.md#manage-extensions)

{{< /details >}}

The extension marketplace is now available in workspaces. With the extension marketplace, you can discover, install, and manage third-party extensions to enhance your development experience. Choose from thousands of extensions to boost your productivity or customize your workflow.

The extension marketplace is disabled by default. To get started, go to your user preferences and [enable the extension marketplace](../../user/profile/preferences.md#integrate-with-the-extension-marketplace). For enterprise users, only users with the Owner role for a top-level group can [enable the extension marketplace](../../user/enterprise_user/_index.md#enable-the-extension-marketplace-for-enterprise-users).

### Improved workspace lifecycle with delayed termination

<!-- categories: Workspaces -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/workspace/_index.md#automatic-workspace-stop-and-termination)

{{< /details >}}

With this release, a workspace now stops rather than terminates after the configured timeout has elapsed. This feature means you can always restart your workspaces and pick up where you left off.

By default, a workspace automatically:

- Stops 36 hours after the workspace was last started or restarted
- Terminates 722 hours after the workspace was last stopped

You can configure these settings in your [GitLab agent configuration](../../user/workspace/gitlab_agent_configuration.md).

With this feature, a workspace remains available for approximately one month after it was stopped. This way, you get to keep your progress while optimizing workspace resources.

### Display release notes on deployment details page

<!-- categories: Continuous Delivery -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/environments/deployment_approvals.md#view-blocked-deployments) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/493260)

{{< /details >}}

Have you ever wondered what might be included in a deployment you’ve been asked to approve? In past versions, you could create a release with a detailed description about its content and instructions for testing, but the related environment-specific deployment did not show this data. We are happy to share that GitLab now displays the release notes under the related deployment details page.

Because GitLab releases are always created from a Git tag, the release notes are shown only on deployments related to the tag-triggered pipeline.

This feature was contributed to GitLab by [Anton Kalmykov](https://gitlab.com/antonkalmykov). Thank you!

### Admin setting to enforce CI/CD job token allowlist

<!-- categories: Secrets Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../administration/settings/continuous_integration.md#access-job-token-permission-settings) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/496647)

{{< /details >}}

Previously, we announced that the default CI/CD job token (`CI_JOB_TOKEN`) behavior [will change in GitLab 18.0](../../update/deprecations.md#cicd-job-token---authorized-groups-and-projects-allowlist-enforcement), requiring you to explicitly add indvidual [projects or groups to your project’s job token allowlist](../../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) if you want them to continue to be able to access your project.

Now, we are giving self-managed and Dedicated instance administrators the ability to enforce this more secure setting on all projects on an instance. After you enable this setting, all projects will need to make use of their allowlist if they want to use CI/CD job tokens for authentication. *Note: We recommend enabling this setting as part of a strong security policy.*

### Track CI/CD job token authentications

<!-- categories: Secrets Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/jobs/ci_job_token.md#job-token-authentication-log) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/467292)

{{< /details >}}

Previously it was difficult to track which other projects were using accessing your project by authenticating with CI/CD job tokens. To make it easier for you to audit and control access to your project, we’ve added an authentication log.

With this authentication log, you can view the list of other projects that have used a job token to authenticate with your project, both in the UI and as a downloadable CSV file. This data can be used to audit project access and aid in populating the job token allowlist to enable stronger [control over which projects can access your project](../../ci/jobs/ci_job_token.md#control-job-token-access-to-your-project).

### Vulnerability report grouping

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/vulnerability_report/_index.md#group-vulnerabilities) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10164)

{{< /details >}}

Users require the ability to view vulnerabilities in groups. This will help security analysts optimize their triage tasks by utilizing bulk actions. In addition users can see how many vulnerabilities match their group; i.e. how many OWASP Top 10 vulnerabilities are there?

### Model registry now generally available

<!-- categories: MLOps -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/ml/model_registry/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/14998)

{{< /details >}}

GitLab’s model registry, now generally available, is your centralized hub for managing machine learning models as part of your existing GitLab workflow. You can track model versions, store artifacts and metadata, and maintain comprehensive documentation in the model card.

Built for seamless integration, the model registry works natively with [MLflow clients](../../user/project/ml/experiment_tracking/mlflow_client.md) and connects directly to your CI/CD pipelines, enabling automated model deployment and testing. Data scientists can manage models through an intuitive UI or existing MLflow workflows, while MLOps teams can leverage semantic versioning and CI/CD integration for streamlined production deployments all within the [GitLab API](../../api/model_registry.md).

Please feel free to drop us a note in our [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/504458) and we’ll get back in touch! Get started today by going to **Deploy > Model registry** in your GitLab instance.

### New tenant networking configurations for GitLab Dedicated

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../administration/dedicated/configure_instance/network_security.md#outbound-privatelink-connections)

{{< /details >}}

As a GitLab Dedicated tenant administrator, you can now use Switchboard to set up outbound private links and private hosted zones. You can also monitor your network connections by viewing periodic snapshots in Switchboard.

Outbound private links and private hosted zones establish secure network connectivity between resources in your AWS account and GitLab Dedicated.

### New adherence checks for SAST and DAST security scanners

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/compliance_center/compliance_status_report.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/12661)

{{< /details >}}

GitLab offers a wide range of security scanners such as SAST, secret detection, dependency scanning, container scanning, and more
so that you can check your applications for security vulnerabilities.

You need to have a way to show auditors and relevant compliance authorities that your applications have adhered to regulatory standards that require you to have security
scanners set up for your repositories.

To help you demonstrate adherence to these standards, this release includes two new checks as part of the standard adherence report in the Compliance Centre. These
new checks check whether SAST and DAST has been enabled for projects within a group. The checks confirm that the SAST and DAST security scanners
correctly ran in a project and the pipeline results has the correct resulting artifacts.

## Scale and Deployments

### Project events for group webhooks

<!-- categories: Notifications -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/integrations/webhook_events.md#project-events) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/359044)

{{< /details >}}

In this release, we’ve added project events to group webhooks. Project events are triggered when:

- A project is created in a group.
- A project is deleted in a group.

These events are triggered for [group webhooks](../../user/project/integrations/webhooks.md#group-webhooks) only.

### Filter GitLab Duo users by assigned seat

<!-- categories: Add-on Provisioning -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: GitLab Duo Pro, GitLab Duo Enterprise
- Links: [Documentation](../../subscriptions/subscription-add-ons.md#view-assigned-gitlab-duo-users) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/14683)

{{< /details >}}

In previous versions of GitLab, the user list displayed on the GitLab Duo seat assignment page could not be filtered, making it difficult to see which users had previously been assigned a GitLab Duo seat. Now, you can filter your user list by Assigned seat = Yes or Assigned seat = No to see to see which users are currently assigned or not assigned a GitLab Duo seat, allowing for ease in adjusting seat allocations.

### GitLab Duo seat assignment email update

<!-- categories: Seat Cost Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170507)

{{< /details >}}

All users on self-managed instances will receive an email when they are assigned a GitLab Duo seat.

Previously, those assigned a Duo Enterprise seat or those granted access by bulk assignment would not be notified. You wouldn’t know you were assigned a seat unless someone told you, or you noticed new functionality in the GitLab UI.

To disable this email, an administrator can disable the `duo_seat_assignment_email_for_sm` feature flag.

## Unified DevOps and Security

### Efficient risk prioritization with EPSS

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/graphql/reference/_index.md#cveenrichmenttype) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/11544)

{{< /details >}}

In GitLab 17.6, we added support for the Exploit Prediction Scoring System (EPSS). EPSS gives each CVE a score between 0 and 1 indicating the probability of the CVE being exploited in the next 30 days. You can leverage EPSS to better prioritize scan results and to help evaluate the potential impact a vulnerability may have on your environment.

This data is available to composition analysis users through GraphQL.

### Enable Secret Push Protection in your projects via API

<!-- categories: Secret Detection -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/projects.md)

{{< /details >}}

It’s now easier to programatically enable secret push protection. We’ve updated the application settings REST API, allowing you to:

1. Enable the feature in your self-managed instance so that it can be enabled on a per-project basis.
1. Check whether the feature has been enabled on a project.
1. Enable the feature for a specified project.

### Secret Push Protection audit events for applied exclusions

<!-- categories: Secret Detection -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/secret_detection/exclusions.md)

{{< /details >}}

Audit events are now logged when a secret push protection exclusion is applied. This enables security teams to audit and track any occurence when a secret on the project’s exclusions list is allowed to be pushed.

### Automated Repository X-Ray

<!-- categories: Code Suggestions -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/project/repository/code_suggestions/repository_xray.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/14100)

{{< /details >}}

Repository X-Ray enriches code generation requests for GitLab Duo Code Suggestions by providing additional context about a project’s dependencies to improve the accuracy and relevance of code recommendations. This improves the quality of code generation. Previously, Repository X-Ray used a CI job that you had to configure and manage.

Now, when a new commit is pushed to your project’s default branch, Repository X-Ray automatically triggers a background job that scans and parses the applicable configuration files in your repository.

### Corporate network support for GitLab Duo

<!-- categories: Editor Extensions -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../editor_extensions/language_server/_index.md#enable-proxy-authentication) | [Related issue](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/159)

{{< /details >}}

The latest update to the GitLab Duo plugin introduces advanced proxy authentication. This enables developers to connect seamlessly in environments with strict corporate firewalls. Building on our existing HTTP proxy support, this enhancement allows for authenticated connections. It ensures secure and uninterrupted access to Duo features in VS Code and JetBrains IDEs.

This update is crucial for developers needing secure, authenticated connections in restricted network environments. It ensures all Duo features remain available without compromising security.

### Merge at a scheduled date and time

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/merge_requests/auto_merge.md#prevent-merge-before-a-specific-date)

{{< /details >}}

Some merge requests may need to be held for merging until after a certain date or time. When that date and time does pass you need to find someone with permissions to merge and hope they’re available to take care of it for you. If this is after hours or the timeline is critical you may need to prepare folks well in advance for the task.

Now, when you create or edit a merge request you can specify a `merge after` date. This date will be used to prevent the merge request from being merged until it has passed. Using this new capability with our previously released [improvements to auto-merge](https://about.gitlab.com/releases/2024/09/19/gitlab-17-4-released/#auto-merge-when-all-checks-pass) gives you the flexibility to schedule merge requests to merge in the future.

A big thank you to [Niklas van Schrick](https://gitlab.com/Taucher2003) for the amazing contribution!

### Add support for values to the `glab agent bootstrap` command

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/cluster/agent/bootstrap.md#options) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/482844)

{{< /details >}}

In the last release, we introduced support for easy agent bootstrapping to the GitLab CLI tool. GitLab 17.6 further improves the `glab cluster agent bootstrap` command with support for custom Helm values. You can use the `--helm-release-values` and `--helm-release-values-from` flags to customize the generated `HelmRelease` resource.

### Select a GitLab agent for an environment in a CI/CD job

<!-- categories: Environment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/environments/kubernetes_dashboard.md#configure-a-dashboard-for-a-dynamic-environment) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/467912)

{{< /details >}}

To use the dashboard for Kubernetes, you need to select an agent for Kubernetes connection from the environment settings. Until now, you could select the agent only from the UI or (from GitLab 17.5) the API, which made configuring a dashboard from CI/CD difficult. In GitLab 17.6, you can configure an agent connection with the `environment.kubernetes.agent` syntax.
In addition, [issue 500164](https://gitlab.com/gitlab-org/gitlab/-/issues/500164) proposes to add support for selecting a namespace and Flux resource from your CI/CD configuration.

### Audit events for privileged actions

<!-- categories: Audit Events -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/compliance/audit_event_types.md#groups-and-projects) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/486532)

{{< /details >}}

There are now additional audit events for privileged settings-related administrator actions. A record of when these settings were changed can help improve security by providing an audit trail.

### New audit event when merge requests are merged

<!-- categories: Audit Events -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/audit_event_types.md#compliance-management) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/442279)

{{< /details >}}

With this release, when a merge request is merged, a new audit event type called `merge_request_merged` is triggered that contains key information about
the merge request, including:

- The title of the merge request
- The description or summary of the merge request
- How many approvals were required for merge
- How many approvals were granted for merge
- Which users approved the merge request
- Whether committers approve the merge request
- Whether authors approved the merge request
- The date/time of the merge
- The list of SHAs from Commit history

### Disable OTP authenticator and WebAuthn devices independently

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/account/two_factor_authentication.md#disable-two-factor-authentication) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/393419)

{{< /details >}}

It is now possible to disable the OTP authenticator and WebAuthn devices individually or simultaneously. Previously, if you disabled the OTP authenticator, the WebAuthn device(s) were also disabled. Because the two now operate independently, there is more granular control over these authentication methods.

### Use API to get information about tokens

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../api/admin/token.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/443597)

{{< /details >}}

Administrators can use the new token information API to get information about personal access tokens, deploy tokens, and feed tokens. Unlike other API endpoints that expose token information, this endpoint allows administrators to retrieve token information without knowing the type of the token.

Thank you [Nicholas Wittstruck](https://gitlab.com/nwittstruck) and the rest of the crew from Siemens for your contribution!

### More information in sign in emails from new locations

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/profile/notifications.md#notifications-for-unknown-sign-ins) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/296128)

{{< /details >}}

GitLab optionally sends an email when a sign-in from a new location is detected. Previously, this email only contained the IP address, which is difficult to correlate to a location. This email now contains city and country location information as well.

Thank you [Henry Helm](https://gitlab.com/shangsuru) for your contribution!

### Prevent modification of group protected branches

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#approval_settings) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13776)

{{< /details >}}

When a merge request approval policy is configured to prevent group branch modification, policies now account for protected branches configured for a group. This setting ensures that branches protected at the group level cannot be unprotected. Protected branches restrict certain actions, such as deleting the branch and force pushing to the branch. You can override this behavior and declare exceptions for specific top-level groups with the new `approval_settings.block_group_branch_modification` property to allow group owners to temporarily modify protected branches when necessary.

This new project override setting ensures that group protected branch settings cannot be modified to circumvent security and compliance requirements, ensuring more stable enforcement of protected branches.

### Top-level group Owners can create service accounts

<!-- categories: System Access -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/468806)

{{< /details >}}

Currently, only administrators can create service accounts on GitLab self-managed. Now, there is an optional setting which allows top-level group Owners to create service accounts. This allows administrators to choose if they would like a wider range of roles that are allowed to create service accounts, or keep it as an administrator-only task.

### Service accounts badge

<!-- categories: System Access -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/service_accounts.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/439768)

{{< /details >}}

Service accounts now have a designated badge and can be easily identified in the users list. Previously, these accounts only had the `bot` badge, making it difficult to distinguish between them and group and project access tokens.

### Deploy your Pages site with any CI/CD job

<!-- categories: Pages -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/pages/_index.md#user-defined-job-names)

{{< /details >}}

To give you more flexibility in designing your pipelines, you no longer
need to name your Pages deploy job `pages`. You can now simply use the
`pages` attribute in any CI/CD job to trigger a Pages deployment.

### AI Impact Analytics API for GitLab Duo Pro

<!-- categories: Value Stream Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../api/graphql/reference/_index.md#aimetrics)

{{< /details >}}

GitLab Duo Pro customers can now programmatically access AI Impact Analytics metrics with the `aiMetrics` GraphQL API. Metrics include the number of assigned GitLab Duo seats, Duo Chat users, and Code Suggestion users. The API also provides granular counts for code suggestions that are shown and accepted. With this data, you can calculate the acceptance rate for Code Suggestions, and better understand your Duo Pro users’ adoption of Duo Chat and Code Suggestions. You can also pair AI Impact Analytics metrics with Value Stream Analytics and DORA metrics to gain deeper insight into how adopting Duo Chat and Code Suggestions are impacting your team’s productivity.

### Easily remove closed items from your view

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/epics/manage_epics.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/456941)

{{< /details >}}

You can now hide closed items from the linked and child items lists by turning off the **Show closed items** toggle. With this addition, you have greater control over your view and can focus on active work while reducing visual clutter in complex projects.

### Query user-level GitLab Duo Enterprise usage metrics

<!-- categories: Value Stream Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../api/graphql/reference/_index.md#aiusermetrics) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/483049)

{{< /details >}}

Prior to this release, it was not possible to get GitLab Duo Chat and Code Suggestions usage data per Duo Enterprise user. In 17.6, we’ve added a GraphQL API to provide visibility into the number of code suggestions accepted and Duo Chat interactions for each active Duo Enterprise user. The API can help you get more granular insight into who is using which Duo Enterprise features and how frequently. This is the first iteration toward our goal of [providing more comprehensive Duo Enterprise usage data](https://gitlab.com/groups/gitlab-org/-/epics/15026) within GitLab.

### Support for license data from CycloneDX SBOMs

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/415935)

{{< /details >}}

The License Scanner now has the ability to consume a dependency’s license from a CycloneDX SBOM that includes [supported package types](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md#supported-languages-and-package-managers).

In cases where the `licenses` field of a CycloneDX SBOM is available, users will see license data from their SBOM. In cases where the SBOM lacks license information we will continue to provide this data from our License database.

### macOS Sequoia 15 and Xcode 16 job image

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../ci/runners/hosted_runners/macos.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/502852)

{{< /details >}}

You can now create, test, and deploy applications for the newest
generations of Apple devices using macOS Sequoia 15 and Xcode 16.

GitLab’s [hosted runners on macOS](../../ci/runners/hosted_runners/macos.md)
help your development teams build and deploy macOS applications faster in a secure,
on-demand build environment integrated with GitLab CI/CD.

Try it out today by using the `macos-15-xcode-16` image in your `.gitlab-ci.yml` file.

### JaCoCo test coverage visualization now generally available

<!-- categories: Code Testing and Coverage -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/testing/code_coverage/jacoco.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/227345)

{{< /details >}}

You can now see JaCoCo test coverage results directly in your merge request diff view. This visualization allows you to quickly identify which lines are covered by tests and which need additional coverage before merging.

### GitLab Runner 17.6

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 17.6 today! GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### Bug Fixes

- [In GitLab Runner 17.5.0, pods fail to become attachable](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38260)
- [Runner crashes with `exec format error` when installing the fleeting plugin](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38247)
- [Kubernetes executor pods with cgroup v2 enabled hang when OOMKilled](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38244)
- [Runner defaults are not honoured when registering runner with a configuration template](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38231)
- [GitLab Runner waits for Kubernetes pods to become attachable during the polling period when using exec mode](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37244)
- [Authentication issues occur when the feature flag `FF_GIT_URLS_WITHOUT_TOKENS` is enabled](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38268)

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.6)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.6)
- [UI improvements](https://papercuts.gitlab.com/?milestone=17.6)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
