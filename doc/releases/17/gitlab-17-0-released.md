---
stage: Release Notes
group: Monthly Release
date: 2024-05-16
title: "GitLab 17.0 release notes"
description: "GitLab 17.0 released with CI/CD Catalog with components and inputs now generally available"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On May 16, 2024, GitLab 17.0 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor

Everyone can [nominate GitLab’s community contributors](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)!
Show your support for our active candidates or add a new nomination 🙌

Niklas van Schrick now has the hat trick with three MVPs and has become one of GitLab’s most consistent contributors with at least one merge request per milestone since GitLab 14.3.

Niklas was nominated by [Magdalena Frankiewicz](https://gitlab.com/m_frankiewicz), Product Manager at GitLab, for contributing a feature to create custom webhook payload templates and then following it up with the [ability to specify custom webhook headers](https://gitlab.com/gitlab-org/gitlab/-/issues/17290).
“This solved a highly demanded 7-year-old feature request with 65 upvotes,” says Magdalena.
“Users can now fully design custom webhooks!”

Niklas is a member of the [GitLab Core Team](https://about.gitlab.com/community/core-team/) and helps the wider community and GitLab live up to our mission to enable everyone to contribute.

“During my journey, I interacted with a lot of different reviewers, maintainers, designers, technical writers, product managers, and probably more,” Niklas says.
“Everyone was helpful and did their best to help move issues and merge requests forward.”

Gerardo Navarro has been contributing to GitLab for over a year and takes home a second GitLab MVP award.

Gerardo was nominated for creating ongoing contributions towards a feature to [show protected packages in the package registry list](https://gitlab.com/gitlab-org/gitlab/-/issues/437926). This feature is part of a series of contributions related to the [protected packages epic](https://gitlab.com/groups/gitlab-org/-/epics/5574) that intends to increase security by enabling fine-grained permissions to create, update, and delete packages from the package registry.

Many thanks to Gerardo Navarro and the rest of the team from Siemens for helping co-create GitLab.

“Thank you very much for appreciating our work with such a cool award,” says Gerardo.
“I feel honored. I am still learning a lot with every contribution.”

## Primary features

### CI/CD Catalog with components and inputs now generally available

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../ci/components/_index.md#cicd-catalog)

{{< /details >}}

The CI/CD Catalog is now generally available. As part of this release, we’re also making [CI/CD components](../../ci/components/_index.md) and [inputs](../../ci/yaml/_index.md#inputs) generally available.

With the CI/CD Catalog, you gain access to a vast array of components created by the community and industry experts.
Whether you’re seeking solutions for continuous integration, deployment pipelines, or automation tasks, you’ll find a diverse selection of components tailored to suit your requirements.
You can read more about the Catalog and its features in the following [blog post](https://about.gitlab.com/blog/ci-cd-catalog-goes-ga-no-more-building-pipelines-from-scratch/).

You’re invited to contribute CI/CD components to the Catalog and help expand this new and growing part of GitLab.com!

### AI Impact analytics in the Value Streams Dashboard

<!-- categories: Value Stream Management, Code Suggestions -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/analytics/duo_and_sdlc_trends.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/12978)

{{< /details >}}

AI Impact is a dashboard available in the Value Streams Dashboard that helps organizations understand the [impact of GitLab Duo on their productivity](https://about.gitlab.com/blog/measuring-ai-effectiveness-beyond-developer-productivity-metrics/).
This new month-over-month metric view compares the AI Usage trends with SDLC metrics like lead time, cycle time, DORA, and vulnerabilities. Software leaders can use the AI Impact dashboard to measure how much time is saved in their end-to-end workstream, while staying focused on business outcomes rather than developer activity.

In this first release, the AI usage is measured as the monthly [Code Suggestions](../../user/project/repository/code_suggestions/_index.md) usage rate, and is calculated as the number of monthly unique Code Suggestions users divided by total monthly unique [contributors](../../user/group/contribution_analytics/_index.md).

The AI Impact dashboard is available to users on the Ultimate tier for a limited time. Afterwards, a GitLab Duo Enterprise license will be required to use the dashboard.

### Introducing hosted runners on Linux Arm

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../ci/runners/hosted_runners/linux.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/365300)

{{< /details >}}

We are excited to introduce hosted runners on Linux Arm for GitLab.com.
The now available `medium` and `large` Arm machine types, equipped with 4 and 8 vCPUs respectively, and fully integrated with GitLab CI/CD, will allow you to build and test your application faster and more cost-efficient than ever before.

We are determined to provide the industry’s fastest CI/CD build speed and look forward to seeing teams achieve even shorter feedback cycles and ultimately deliver software faster.

### Introducing deployment detail pages

<!-- categories: Release Orchestration, Environment Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/environments/deployment_approvals.md#approve-or-reject-a-deployment) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/374538)

{{< /details >}}

You can now link directly to a deployment in GitLab. Previously, if you were collaborating on a deployment, you had to look up the deployment from the deployment list. Because of the number of deployments listed, finding the correct deployment was difficult and prone to error.

From 17.0, GitLab offers a deployment details view that you can link to directly. In this first version, the deployment details page offers an overview of the deployment job and the possibility to approve, reject, or comment on a deployment in a continuous delivery setting. We are looking into further avenues to enhance the deployment details page, including by linking to it from the related pipeline job. We would love to hear your feedback in [issue 450700](https://gitlab.com/gitlab-org/gitlab/-/issues/450700).

### GitLab Duo Chat now uses Anthropic Claude 3 Sonnet

<!-- categories: Duo Chat -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/gitlab_duo_chat/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13297)

{{< /details >}}

GitLab Duo Chat just got a lot better. It now uses Anthropic Claude 3 Sonnet as the base model, replacing Claude 2.1 for answering most questions.

At GitLab, we apply a test-driven approach when choosing the best model for a set of tasks and authoring well-performing prompts. With recent adjustments to the chat prompts, we have achieved significant improvements in the correctness, comprehensiveness, and readability of chat answers based on Claude 3 Sonnet compared to the previous chat version built on Claude 2.1. Hence, we have now switched to this new model version.

### How-to questions in GitLab Duo Chat supported on self-managed deployments

<!-- categories: Duo Chat -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/gitlab_duo_chat/examples.md#ask-about-gitlab) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/451215)

{{< /details >}}

A popular capability of GitLab Duo Chat is answering questions about how to use GitLab. While Chat offers various other capabilities, this particular functionality was previously only available on GitLab.com. With this release, we’re making it accessible to GitLab self-managed deployments as well, aligning with our commitment to delivering a delightful experience across all types of deployments.

Whether you’re a newcomer or an expert, you can ask Chat for help with queries like “How do I change my password in GitLab?” or “How do I connect a Kubernetes cluster to GitLab?”. Chat aims to provide helpful information to solve your problems more efficiently.

### New usage overview panel in the Value Streams Dashboard

<!-- categories: Value Stream Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/analytics/value_streams_dashboard.md#overview) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/438256)

{{< /details >}}

We enhanced the Value Streams Dashboard with an Overview panel. This new visualization addresses the need for executive-level insights into software delivery performance, and gives a clear picture of GitLab usage in the context of software development life cycle (SDLC).

The Overview panel displays metrics for the group level, such as number of (sub)groups, projects, users, issues, merge requests, and pipelines.

### Add a group to the CI/CD job token allowlist

<!-- categories: Secrets Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/jobs/ci_job_token.md#control-job-token-access-to-your-project) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/415519)

{{< /details >}}

Introduced in GitLab 15.9, the CI/CD job token allowlist prevents unauthorized access from other projects to your project. Previously, you could allow access at the project level from other specific projects only, with a maximum limit of 200 total projects.

In GitLab 17.0, you can now add groups to a project’s CI/CD job token allowlist. The maximum limit of 200 now applies to both projects and groups, meaning a project allowlist can now have up to 200 projects and groups authorized for access. This improvement makes it easier to add large numbers of projects associated with a group.

### Enhanced context control with the `rules:exists` CI/CD keyword

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../ci/yaml/_index.md#rulesexistsproject) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/386040)

{{< /details >}}

The `rules:exists` CI/CD keyword has default behaviors that vary based on where the keyword is defined, which can make it harder to use with more complex pipelines. When defined in a job, `rules:exists` searches for specified files in the project running the pipeline. However, when defined in an `include` section, `rules:exists` searches for specified files in the project hosting the configuration file containing the `include` section. If configuration is split over multiple files and projects, it can be hard to know which exact project will be searched for defined files.

In this release, we have introduced `project` and `ref` subkeys to `rules:exists`, providing you a way to explicitly control the search context for this keyword. These new subkeys help you ensure accurate rule evaluation by precisely specifying the search context, mitigating inconsistencies, and enhancing clarity in your pipeline rule definitions.

### Change log for configuration changes made using Switchboard

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../administration/dedicated/configure_instance/_index.md#view-the-configuration-change-log) | [Related issue](https://about.gitlab.com/dedicated/)

{{< /details >}}

You can now view the status of configuration changes made to your GitLab Dedicated instance infrastructure using the Switchboard [configuration page](../../administration/dedicated/configure_instance/_index.md#configure-your-instance-using-switchboard).

All users with access to view or edit your tenant in Switchboard will be able to view changes in the Configuration Change log and track their progress as they are applied to your instance.

Currently, the Switchboard configuration page and change log are available for changes like managing access to your instance by adding an [IP to the allowlist](../../administration/dedicated/configure_instance/network_security.md#ip-allowlist) or configuring your instance’s [SAML settings](../../administration/dedicated/configure_instance/authentication/saml.md).

We will be extending this functionality to enable self-serve updates for additional configurations in [coming quarters](https://about.gitlab.com/releases/whats-new/#whats-coming).

## Scale and Deployments

### GitLab chart improvements

<!-- categories: Cloud Native Installation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/charts/)

{{< /details >}}

The [GitLab Operator](https://docs.gitlab.com/operator/) is now available for production use for cloud-native hybrid installations. See the [installation documentation](https://docs.gitlab.com/operator/installation.html) before adopting the GitLab Operator.

Support for a fallback to BusyBox images when you specify custom BusyBox values (`global.busybox`) is removed. Support for BusyBox-based init containers was deprecated in GitLab 16.2 (Helm chart 7.2) in favor of a common GitLab-based init image.

Support for `gitlab.kas.privateApi.tls.enabled` and `gitlab.kas.privateApi.tls.secretName` is also removed. You must use `global.kas.tls.enabled` and `global.kas.tls.secretName` instead.

The deprecated queue selector and negate options are removed from the Sidekiq chart.

### Linux package improvements

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

CentOS Linux 7 will reach [end of life](https://www.redhat.com/en/topics/linux/centos-linux-eol) on June 30, 2024. This makes GitLab 17.6 the last GitLab version in which we can provide packages for CentOS 7.

### Two database mode is available in Beta

<!-- categories: Cell -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/postgresql/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/432391)

{{< /details >}}

Currently, most self-managed customers only utilize a single database.
In order to ensure that the setup between GitLab.com and self-managed is the same, we ask self-managed customers to migrate and run two databases by default.
In 16.0, two database connections became the default for self-managed installations.
In 17.0, we [release two database mode as a limited Beta](../../administration/postgresql/_index.md), with the goal to make running decomposed generally available by 19.0.
Migration to two databases remains optional in 17.0, but needs to be performed before upgrading to 19.0.

The migration requires downtime.
Self-managed customers can use a [tool](https://gitlab.com/gitlab-org/gitlab/-/issues/368729) that executes this migration with some downtime.
We introduced a new `gitlab-ctl` command that allows you to upgrade your single-database GitLab instances to a decomposed setup.
This setup contains commands that will work with our Linux package.
The [actual migration](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135585) (copying the database) is part of a rake task in the GitLab project.

### Private shared group members are listed on Members tab for all members

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/members/sharing_projects_groups.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/418888)

{{< /details >}}

Previously, when a public group or project invited a private group, the private group was listed only in the Groups tab of the Members page, and private members were not visible to members of the public group. To enable better collaboration between members of these groups, we are now also listing all invited group members in the Members tab, including members from private invited groups. The source of membership will be masked from members that do not have access to the private group. However, the source of membership will be visible to users who have at least the Maintainer role in the project or Owner role in the group, so that they can manage members in their project or group. If the current user viewing the Members tab is unauthenticated or not a member of the group or project, they will not see the private group members. We hope this change will make it easier for group and project members to understand at a glance who has access to a group or project.

### Members page displays members from invited groups

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/members/_index.md#share-a-project-with-a-group) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/219230)

{{< /details >}}

Previously, members of groups that were invited to a group or project were visible only in the Groups tab of the Members page. This meant users had to check both the Groups and Members tabs to understand who has access to a certain group or project. Now, shared members are listed also in the Members tab, giving a complete overview of all the members that are part of a group or project at a glance.

### Import from Bitbucket Cloud by using REST API

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/import.md#import-repository-from-bitbucket-cloud) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/215036)

{{< /details >}}

In this milestone, we added the ability to import Bitbucket Cloud projects by using the REST API.

This can be a better solution for importing a lot of projects than importing by using the UI.

### Re-import a chosen project relation by using the API

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/project_import_export.md#import-project-resources) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/425798)

{{< /details >}}

When importing projects from export files with many items of the same type (for example, merge requests or pipelines), sometimes some of those items weren’t imported.

In this release, we added an API endpoint that re-imports a named relation, skipping items that have already been imported. The API requires both:

- A project export archive.
- A type (issues, merge requests, pipelines, or milestones).

### View issues from multiple Jira projects in GitLab

<!-- categories: Settings -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../integration/jira/configure.md#view-jira-issues) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/12609)

{{< /details >}}

For larger repositories, you can now view issues from multiple Jira projects in GitLab when you set up the Jira issue integration. With this release, you can:

- Enter up to 100 Jira project keys separated by commas.
- Leave **Jira project keys** blank to include all available keys.

When you view Jira issues in GitLab, you can [filter the issues](../../integration/jira/configure.md#filter-jira-issues) by project.

To [create Jira issues for vulnerabilities](../../integration/jira/configure.md#create-a-jira-issue-for-a-vulnerability) in GitLab Ultimate, you can specify only one Jira project.

### Enable viewing Jira issues in GitLab with the REST API

<!-- categories: Source Code Management, Settings -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/project_integrations.md#jira-issues) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/267015)

{{< /details >}}

With this release, you can use the REST API to enable [viewing Jira issues](../../integration/jira/configure.md#view-jira-issues) in GitLab. You can also specify one or more Jira projects to view issues from.

Thanks to [Ivan](https://gitlab.com/ivantedja) for [this community contribution](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150209)!

### Multiple external participants for Service Desk

<!-- categories: Service Desk -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/service_desk/external_participants.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/3758)

{{< /details >}}

Sometimes there is more than one person involved in resolving a support ticket or
the requester wants to keep colleagues up-to date on the state of the ticket.

Now you can have a maximum of 10 external participants without a GitLab account on a
Service Desk ticket and regular issues.

External participants receive Service Desk notification emails for each public comment
on the ticket, and their replies will appear as comments in the GitLab UI.

Simply use the quick actions [`/add_email`](../../user/project/service_desk/external_participants.md#add-an-external-participant)
and [`remove_email`](../../user/project/service_desk/external_participants.md#add-an-external-participant)
to add or remove external participants with a few keystrokes.

You can also configure GitLab to
[add all email addresses from the `Cc` header](../../user/project/service_desk/external_participants.md#add-external-participants-from-the-cc-header)
of the initial email to the Service Desk ticket.

You can [tailor all Service Desk email templates to your liking](../../user/project/service_desk/configure.md#customize-emails-sent-to-external-participants),
using Markdown, HTML, and dynamic placeholders.
An [unsubscribe link placeholder](../../user/project/service_desk/external_participants.md#add-an-external-participant)
is available to make it easy for external participants to opt out of a conversation.

### Indicate that items were imported using direct transfer

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/group/import/direct_transfer_migrations.md#review-results-of-the-import) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/443492)

{{< /details >}}

You can migrate GitLab groups and projects between GitLab instances [by using direct transfer](../../user/group/import/_index.md).

Until now, imported items were not easily identifiable. With this release, we’ve added visual indicators to items imported with direct transfer, where the creator is identified as a specific user:

- Notes (system notes and user comments)
- Issues
- Merge requests
- Epics
- Designs
- Snippets
- User profile activity

## Unified DevOps and Security

### 1Password secrets integration in GitLab Duo Plugin for JetBrains IDEs

<!-- categories: Editor Extensions -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../editor_extensions/jetbrains_ide/_index.md#integrate-with-1password-cli) | [Related issue](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/291)

{{< /details >}}

You can now integrate 1Password secrets management with the GitLab Duo plugin for JetBrains.

Developers can replace their personal access tokens in their JetBrains IDE settings with 1Password secrets references. This simplifies managing secrets, and enables seamless secrets rotation without manual token updates.

### Access GitLab Duo Chat faster with customizable shortcuts

<!-- categories: Editor Extensions, Duo Chat -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../editor_extensions/jetbrains_ide/_index.md) | [Related issue](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/332)

{{< /details >}}

Opening Duo Chat directly from your editor in JetBrains is now even easier.

Use the default Alt+D keyboard shortcut (or set your own) to open Duo Chat quickly and type your question. Use the same keyboard shortcut to close the window.

### Project comment templates

<!-- categories: Code Review Workflow, Team Planning -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/comment_templates.md#for-a-project) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/440818)

{{< /details >}}

Following the release of [group comment templates in GitLab 16.11](https://about.gitlab.com/releases/2024/04/18/gitlab-16-11-released/#group-comment-templates), we’re bringing these to projects in GitLab 17.0.

Across an organization, it can be helpful to have the same templated response in issues, epics, and merge requests. These responses might include standard questions that need to be answered, responses to common problems, or good structure for merge request review comments. Project-level comment templates give you an additional way to scope the availability of templates, bringing organizations more control and flexibility in sharing these across users.

To create a comment template, go to any comment box on GitLab and select **Insert comment template > Manage project comment templates**. After you create a comment template, it’s available for all project members. Select the **Insert comment template** icon while making a comment, and your saved response will be applied.

We’re really excited about this iteration of comment templates and if you have any feedback, please leave it in [issue 451520](https://gitlab.com/gitlab-org/gitlab/-/issues/451520).

### Commit signing for GitLab UI commits

<!-- categories: Source Code Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/gitaly/configure_gitaly.md#configure-commit-signing-for-gitlab-ui-commits) | [Related issue](https://gitlab.com/gitlab-org/gitaly/-/issues/5361)

{{< /details >}}

Previously, web commits and automated commits made by GitLab could not be signed. Now you can configure your self-managed instance with a signing key, a committer name, and email address to sign web and automated commits.

### Increase Kubernetes agent authorization limit

<!-- categories: Continuous Delivery -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/clusters/agent/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/431133)

{{< /details >}}

With the GitLab agent for Kubernetes, you can share a single agent connection with a group. We aim to support a single agent across a large multi-tenant cluster. However, you might have faced a limitation on the number of connection sharing. Until now, an agent could be shared with only 100 projects and groups using [CI/CD](../../user/clusters/agent/ci_cd_workflow.md), and 100 projects and groups using the [`user_access`](../../user/clusters/agent/user_access.md) keyword. In GitLab 17.0, the number of projects and groups you can share with is raised to 500.

If you need to run multiple agents in a cluster, we would like to hear your feedback in [issue 454110](https://gitlab.com/gitlab-org/gitlab/-/issues/454110).

### Support for GitLab agent for Kubernetes in FIPS mode

<!-- categories: Continuous Delivery -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/clusters/kas.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/375327)

{{< /details >}}

From GitLab 17.0, you can install GitLab in FIPS mode with the agent for Kubernetes components enabled. Now, FIPS-compliant users can benefit from all the [Kubernetes integrations with GitLab](../../user/clusters/agent/_index.md).

### Track fast-forward merge requests in deployments

<!-- categories: Continuous Delivery -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/environments/deployments.md#track-newly-included-merge-requests-per-deployment) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/384104)

{{< /details >}}

In past releases, merge requests were tracked in a deployment only if the project’s merge method was **Merge commit** or **Merge commit with semi-linear history**. From GitLab 17.0, merge requests are tracked in deployments, including in projects with the merge method **Fast-forward merge**.

### Identify sessions initiated by Admin Mode

<!-- categories: User Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/settings/sign_in_restrictions.md#check-if-your-session-has-admin-mode-enabled) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/438674)

{{< /details >}}

As an instance administrator, when you use multiple browsers or different computers, it is difficult to know which sessions are in Admin Mode and which aren’t. Now, administrators can go to **User Settings > Active Sessions** to identify which sessions use Admin Mode.

Thank you [Roger Meier](https://gitlab.com/bufferoverflow) for your contribution!

### Customize avatars for users

<!-- categories: User Management -->

{{< details >}}

- Tier: Free, Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../api/users.md#upload-an-avatar-for-yourself) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/356868)

{{< /details >}}

You can now use the API to upload a custom avatar for any user type, including bot users. This can be especially helpful for visually distinguishing bot users, such as group and project access tokens or service accounts, from human users in the UI.
Thank you [Phawin](https://gitlab.com/lifez) for your contribution!

### Edit a custom role and its permissions

<!-- categories: Permissions -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/custom_roles/_index.md#edit-a-custom-role) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/437590)

{{< /details >}}

Previously, you could not edit an existing custom role and its permissions. Now, you can edit a custom role and its permissions without having to re-create the role to make a change.

### New permissions for custom roles

<!-- categories: Permissions -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/custom_roles/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/391760)

{{< /details >}}

There are new permissions available you can use to create custom roles:

- [Assign security policy links](../../user/custom_roles/abilities.md#security-policy-management)
- [Manage and assign compliance frameworks](../../user/custom_roles/abilities.md#compliance-management)
- [Manage webhooks](../../user/custom_roles/abilities.md#webhooks)
- [Manage push rules](../../user/custom_roles/abilities.md#source-code-management)

With the release of these custom permissions, you can reduce the number of Owners needed in a group by creating a custom role with these Owner-equivalent permissions. Custom roles allow you to define granular roles that give a user only the permissions they need to do their jobs, and reduce unnecessary privilege escalation.

### Manage custom roles at self-managed instance level

<!-- categories: Permissions -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/custom_roles/_index.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/11851)

{{< /details >}}

Before this release, on self-managed GitLab, custom roles had to be created at the group level. This meant administrators could not centrally manage custom roles for the instance, which resulted in duplicate roles across the instance. Now custom roles are managed at the self-managed instance level. Only administrators can create custom roles, but both administrators and group Owners can assign these custom roles.

For more information on migrating existing custom roles, API endpoints, and workflows, see [epic 11851](https://gitlab.com/groups/gitlab-org/-/epics/11851).

This update does not impact custom role workflows on GitLab.com.

### UX improvements to custom roles

<!-- categories: Permissions -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/custom_roles/_index.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/11947)

{{< /details >}}

A series of improvements have been made to the user experience for custom roles, specifically:

- [A new page opens when creating a new custom role](https://gitlab.com/gitlab-org/gitlab/-/issues/393238).
- [Improved design for the custom role table](https://gitlab.com/gitlab-org/gitlab/-/issues/437592).
- [Improved design for the delete custom role dialog](https://gitlab.com/gitlab-org/gitlab/-/issues/434431).
- [Precheck permissions of the base role](https://gitlab.com/gitlab-org/gitlab/-/issues/430915).

### Improved branch protection settings for administrators and for groups

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/repository/branches/default.md#for-all-projects-in-an-instance)

{{< /details >}}

Previously, setting up default branch protection options did not allow for the same level of configuration that the settings for protected branches did.

In this release, we have updated the default branch protection settings to provide the same experience that you have with protected branches.
This allows more flexibility in protecting your default branch and simplifies the process to match what already exists in the protected branch settings.

### Optional configuration for policy bot comment

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/scan_execution_policies.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/438272)

{{< /details >}}

The security policy bot posts a comment on merge requests when they violate a policy to help users understand when policies are enforced on their project, when evaluation is completed, and if there are any violations blocking an MR, with guidance to resolve them. These comments are now optional and can be enabled or disabled within each policy. This gives organizations the flexibility and control to determine how they want to communicate about these policies to their users.

### Updated filtering on the Vulnerability Report

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/vulnerability_report/_index.md#filtering-vulnerabilities) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13339)

{{< /details >}}

The old implementation of the Vulnerability Report filters wasn’t scalable.
We were limited by horizontal space on the page. You can now use the filtered
search component to filter the Vulnerability Report by any combination of
status, severity, tool, or activity. This change allows us to add new filters,
like this proposed [filter by identifier](https://gitlab.com/groups/gitlab-org/-/epics/13340).

### Toggle merge request approval policies to fail open or fail closed

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10816)

{{< /details >}}

Compliance operates on a sliding scale for many organizations as they strike a balance between meeting requirements and ensuring developer velocity is not impacted. Merge request approval policies help to operationalize security and compliance in the heart of the DevSecOps workflow - the merge request. We’re introducing a new `fail open` option for merge request approval policies to offer flexibility to teams who want to ease the transition to policy enforcement as they roll out controls in their organization.

When a merge request approval policy is configured to fail open, MRs will now only be blocked if a policy rule is violated **and** if that project has the security analyzer properly configured. If an analyzer is not enabled for a project or if the analyzer does not successfully produce results, the policy will no longer consider this a violation for the given rule and analyzer. This approach allows for progressive rollout of policies as teams work to ensure proper scan execution and enforcement.

### Automatic deletion of unverified secondary email addresses

<!-- categories: User Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/_index.md#delete-email-addresses-from-your-user-profile) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/367823)

{{< /details >}}

If you add a secondary email address to your user profile and do not verify it, that email address is now automatically deleted after three days. Previously, these email addresses were in a reserved state and could not be released without manual intervention. This automatic deletion reduces administrator overhead and prevents users from reserving email addresses that they do not have ownership of.

### Filter package registry UI for packages with errors

<!-- categories: Package Registry -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/packages/package_registry/_index.md#view-packages) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/451054)

{{< /details >}}

You can use the GitLab package registry to publish and download packages. Sometimes, packages fail to upload due to an error. Previously, there was no way to quickly view packages that failed to upload. This made it challenging to get a holistic view of your organization’s package registry.

Now you can filter the package registry UI for packages that failed to upload. This improvement makes it easier to investigate and resolve any issues you encounter.

### New median time to merge metric in Value Streams Dashboard

<!-- categories: Value Stream Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/analytics/value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/435451)

{{< /details >}}

We added a new metric to the Value Streams Dashboard: median time to merge. In GitLab, this metric represents the median time between when a merge request was created and when it was merged. This new metric measures DevOps health by identifying the efficiency and productivity of your merge request and code review processes.

By analyzing how this metric evolves in the [context of other SDLC metrics](https://www.youtube.com/watch?v=yNZRac7gyYo), teams can identify low or high productivity months, understand the impact of new DevOps practices on the development speed and delivery process, reduce their overall lead time, and increase the velocity of their software delivery.

### Design Management features extended to Product teams

<!-- categories: Design Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/issues/design_management.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/438829)

{{< /details >}}

GitLab is expanding collaboration by updating our permissions. Now, users with the Reporter role can access Design Management features, enabling product teams to engage more directly in the design process. This change simplifies workflows and accelerates innovation by inviting broader participation from across your organization.

### Enhanced epic deletion protection

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/epics/manage_epics.md#delete-an-epic) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/452189)

{{< /details >}}

We’ve updated what happens when you delete an epic to better safeguard your project’s structure and data. It’s all about giving you more control and peace of mind while managing your projects.

Now, when you delete a parent epic, instead of deleting all its child records automatically, we preserve them by detaching the parent relationship first. This change provides you with a safer way to manage your epics, ensuring accidental deletions don’t result in losing valuable information.

### Sort the Roadmap by created date, last updated date, and title

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/roadmap/_index.md#sort-and-filter-the-roadmap) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/460492)

{{< /details >}}

We expanded the epic sorting options available in the Roadmap view, providing you more flexibility in organizing and prioritizing your projects. You can now sort epics by **created date**, **last updated date**, and **title**. This enhancement lays the groundwork for even more advanced sorting capabilities in the future to help you manage epics more dynamically.

### Simplified configuration file schema for Value Streams Dashboard

<!-- categories: Value Stream Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/analytics/value_streams_dashboard.md#customize-dashboard-panels) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/432185)

{{< /details >}}

You can now customize Value Streams Dashboard panels using a simplified schema-driven customizable UI framework. In the new format, the fields provide more flexibility of displaying the data and laying out the dashboard panels. With the new framework, administrators can track changes to the dashboard over time. This version history can help you revert to previous versions and compare changes between dashboard versions.

Using this customization, decision-makers can focus on the most relevant information for their business, while teams can better organize and display key DevSecOps metrics.

### Guests in groups can link issues

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/permissions.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10267)

{{< /details >}}

We reduced the minimum role required to relate issues and tasks from Reporter to Guest, giving you more flexibility to organize work across your GitLab instance while maintaining [permissions](../../user/permissions.md).

### Milestones and iterations visible on issue boards

<!-- categories: Team Planning -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/issue_board.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/25758)

{{< /details >}}

We’ve improved issue boards to offer you clearer insights into your project’s timeline and phases. Now, with milestone and iteration details directly visible on issue cards, you can easily track progress and adjust your team’s workload on the fly. This enhancement is designed to make your planning and execution more efficient, keeping you in the loop and ahead of schedule.

### API Security Testing analyzer updates

<!-- categories: API Security -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/api_security_testing/_index.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/13644)

{{< /details >}}

We published the following API Security Testing analyzer updates during the 17.0 release milestone:

- System environment variables are now passed from the CI runner to the custom Python scripts used for certain advanced scenarios (like request signing). This will make implementing these scenarios easier. See [issue 457795](https://gitlab.com/gitlab-org/gitlab/-/issues/457795) for more details.
- API Security containers now run as a non-root user, which improves flexibility and compliance. See [issue 287702](https://gitlab.com/gitlab-org/gitlab/-/issues/287702) for more details.
- Support for servers that only offer TLSv1.3 ciphers, which enables more customers to adopt API Security Testing. See [issue 441470](https://gitlab.com/gitlab-org/gitlab/-/issues/441470) for more details.
- Upgrade to Alpine 3.19, which addresses security vulnerabilities. See [issue 456572](https://gitlab.com/gitlab-org/gitlab/-/issues/456572) for more details.

As [previously announced](../../update/deprecations.md#secure-analyzers-major-version-update), [we increased the major version number of API Security Testing to version 5](https://gitlab.com/gitlab-org/gitlab/-/issues/456874) in GitLab 17.0.

### Dependency Scanning support for Android

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#use-cicd-components) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/12968)

{{< /details >}}

Users of Dependency Scanning can now scan Android projects. To configure Android scanning, use the [CI/CD Catalog component](https://gitlab.com/explore/catalog/components/android-dependency-scanning). Android scanning is also supported for users of the [CI/CD template](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#edit-the-gitlab-ciyml-file-manually).

### Dependency Scanning default Python image

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#supported-languages-and-package-managers) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/441491)

{{< /details >}}

Following the deprecation of Python 3.9 as the default Python image, Python 3.11 is now the default image.

As outlined in the [deprecation notice](../../update/deprecations.md#deprecate-python-39-in-dependency-scanning-and-license-scanning), the target for the new default Python version was 3.10. The direct move to Python 3.11 was required to ensure FIPS compliance.

### DAST now supports both arm64 and amd64 architectures by default

<!-- categories: DAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dast/_index.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/13757)

{{< /details >}}

DAST 5 supports both arm64 and amd64 architectures by default. This enables customers to choose the Runner host architecture and optimize cost savings.

### Streamlined SAST analyzer coverage for more languages

<!-- categories: SAST -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/_index.md#supported-languages-and-frameworks) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/412060)

{{< /details >}}

GitLab Static Application Security Testing (SAST) now scans the same [languages](../../user/application_security/sast/_index.md#supported-languages-and-frameworks) with fewer [analyzers](../../user/application_security/sast/analyzers.md), offering a simpler, more customizable scan experience.

In GitLab 17.0, we’ve replaced language-specific analyzers with [GitLab-managed rules](../../user/application_security/sast/rules.md) in the [Semgrep-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) for the following languages:

- Android
- C and C++
- iOS
- Kotlin
- Node.js
- PHP
- Ruby

As [announced](../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-170), we’ve updated the [SAST CI/CD template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml) to reflect the new scanning coverage and to remove language-specific analyzer jobs that are no longer used.

### Secret Detection now supports remote rulesets when overriding or disabling rules

<!-- categories: Secret Detection -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/secret_detection/pipeline/configure.md#with-a-remote-ruleset) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/425251)

{{< /details >}}

We resolved a Secret Detection bug that impacted remote rulesets. It’s now possible to override or disable rules via remote rulesets. Remote rulesets offer a scalable way to configure rules in a single place, which can be applied across multiple projects.

### Introducing advanced vulnerability tracking for Secret Detection

<!-- categories: Secret Detection -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/secret_detection/pipeline/_index.md#duplicate-vulnerability-tracking) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/434096)

{{< /details >}}

Secret Detection now uses an advanced vulnerability tracking algorithm to more accurately identify when the same secret has moved within a file due to refactoring or unrelated changes. A new finding is no longer created if:

- A leak moves within a file.
- A new leak of the same value appears within the same file.

Otherwise, the existing workflow (merge request widget, pipeline report, and vulnerability report) will treat the findings the same as before. By ensuring that duplicate vulnerabilities are not reported as secrets shift locations, teams are more easily able to manage leaked secrets.

### Semantic version ranges for published CI/CD components

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../ci/components/_index.md#semantic-versioning) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/450835)

{{< /details >}}

When using a CI/CD Catalog component, you might want to have it automatically use the latest version. For example, you don’t want to have to manually monitor all the components you use and manually switch to the next version every time there is a minor update or security patch. But using `~latest` is also a bit risky because minor version updates could have undesired behavior changes, and major version updates have a higher risk of breaking changes.

With this release, you can opt to use the latest major or minor version of a CI/CD component. For example, specify `2` for the component version, and you’ll get all updates for that major version, like `2.1.1`, `2.1.2`, `2.2.0`, but not `3.0.0`. Specify `2.1` and you’ll only get patch updates for that minor version, like `2.1.1`, `2.1.2`, but not `2.2.0`.

### Standardized CI/CD Catalog component publishing process

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../ci/components/_index.md#publish-a-new-release) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/442066)

{{< /details >}}

We have been hard at work on CI/CD components, including making the process of releasing components to the CI/CD Catalog a consistent experience. As part of that work, we’ve made releasing versions from a CI/CD job with the [`release` keyword](../../ci/yaml/_index.md#release) and the `release-cli` image the only method. All improvements to the release process will apply to this method only. To avoid breaking changes introduced by this restriction, make sure you always use the latest version of the image (`release-cli:latest`) or at least a version greater than `v0.17`. The [**Releases** option in the UI](../../user/project/releases/_index.md#create-a-release-in-the-releases-page) is now disabled for CI/CD component projects.

### Always run `after_script` commands for canceled jobs

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/yaml/script.md#set-a-default-before_script-or-after_script-for-all-jobs) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10158)

{{< /details >}}

The [`after_script`](../../ci/yaml/_index.md#after_script) CI/CD keyword is used to run additional commands after the main `script` section of a job. This is often used for cleaning up environments or other resources that were used by the job. However, `after_script` commands did not run if a job was canceled.

As of GitLab 17.0, `after_script` commands will always run when a job is canceled. To opt out, see the [documentation](../../ci/yaml/script.md#skip-after_script-commands-if-a-job-is-canceled).

### GitLab Runner 17.0

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 17.0 today! GitLab Runner is the lightweight, highly-scalable agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s new

- [Documentation for installing the Runner Operator in disconnected network environments](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/123)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-0-stable/CHANGELOG.md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.0)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.0)
- [UI improvements](https://papercuts.gitlab.com/?milestone=17.0)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
