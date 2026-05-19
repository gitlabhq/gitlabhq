---
stage: Release Notes
group: Monthly Release
date: 2023-05-22
title: "GitLab 16.0 release notes"
description: "GitLab 16.0 released with Value Streams Dashboard is now generally available"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On May 22, 2023, GitLab 16.0 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Jimmy Berry

Jimmy [improved the merge request security widget](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117594) by correcting which merge base is used for comparing branches on completed pipelines in the merge request.
Previously, the merge request security widget was comparing the most recent security scan of a completed pipeline on the main branch of the repository. For the vulnerability findings in the merge request security widget to be accurate, we needed to adjust the logic and compare the feature branch to the main branch at the time the feature was branched from main. Without this change users might see misleading results. This was already an [issue](https://gitlab.com/groups/gitlab-org/-/epics/10092) on our roadmap, and Jimmy contributed and accelerated this improvement not only for them, but for all GitLab users.

Jimmy [stated](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/34100#note_1395183419):

> I’ve contributed to a variety of open source projects, but have never experienced such a helpful review process.

Thank you Jimmy for helping us iterate on the logic for vulnerability findings and improve the security features in GitLab!

## Primary features

### Value Streams Dashboard is now generally available

<!-- categories: Value Stream Management, DORA Metrics -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/analytics/value_streams_dashboard.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/403304)

{{< /details >}}

This [new dashboard](https://youtu.be/EA9Sbks27g4) provides strategic insights into metrics that help decision-makers
identify trends and patterns to optimize software delivery. The first iteration of the GitLab Value Streams Dashboard
is focused on enabling teams to continuously improve software delivery workflows by benchmarking value stream life cycle
([value stream analytics](../../user/group/value_stream_analytics/_index.md), [DORA4](../../user/analytics/dora_metrics.md)),
and [vulnerabilities](../../user/application_security/vulnerability_report/_index.md) metrics.

Organizations can use the [Value Streams Dashboard](../../user/analytics/value_streams_dashboard.md)
to track and compare these metrics over a period of time, identify downward trends early, understand security exposure,
and drill down into individual projects or metrics to take actions for improvements.

This comprehensive view built as a single application with a unified data store allows all stakeholders, from
executives to individual contributors, to have visibility into the software development life cycle, without needing
to buy or maintain a third-party tool.

### Upsizing GitLab SaaS runners on Linux

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Tier: Free, Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../ci/runners/hosted_runners/linux.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/388162)

{{< /details >}}

You asked, we listened! In our efforts to be best-in-class for CI/CD build speeds, we’re doubling the vCPU & RAM for all GitLab SaaS runners on Linux, with no increase in the [cost factor](../../ci/pipelines/compute_minutes.md).

We’re excited to see pipelines run faster and boost productivity.

### GPU-enabled SaaS runners on Linux

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Tier: Silver, Gold
- Links: [Documentation](../../ci/runners/hosted_runners/linux.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/358026)

{{< /details >}}

We are aiming to bring the best practices of DevSecOps to data sciences by providing more powerful compute hardware within GitLab runner.
Previously, data scientists may have had workloads that were compute-intensive and as a result, jobs may not have been as quickly executed in GitLab.

Now, with GPU-enabled SaaS runners on Linux, these workloads can be seamlessly supported using GitLab.com.

So why wait? Try out the new runner today and let us know what you think in this [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/403008). We can’t wait to hear your feedback!

### Apple silicon (M1) GitLab SaaS runners on macOS - Beta

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../ci/runners/hosted_runners/macos.md#example-gitlab-ciyml-file) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/342848)

{{< /details >}}

Mobile DevOps teams can now run their entire CI/CD workflows on Apple silicon (M1)
[GitLab SaaS runners on macOS](../../ci/runners/hosted_runners/macos.md)
to seamlessly create, test, and deploy applications for the Apple ecosystem.

With up to **three times** the performance of hosted x86-64 macOS Runners,
you will increase your development team’s velocity in building and deploying applications
that require macOS in a secure, on-demand GitLab Runner build environment integrated with GitLab CI/CD.

### Comment templates

<!-- categories: Code Review Workflow, Team Planning -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/comment_templates.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/7565)

{{< /details >}}

When you’re commenting in issues, epics, or merge requests you might repeat yourself and need to write the same comment over and over. Maybe you always need to ask for more information about a bug report. Maybe you’re applying labels via a quick action as part of a triage process. Or maybe you just like to finish all your code reviews with a funny gif or appropriate emoji. 🎉

Comment templates enable you to create saved responses that you can apply in comment boxes around GitLab to speed up your workflow. To create a comment template, go to **User settings > Comment templates** and then fill out your template. After it’s saved, select the **Insert comment template** icon on any text area, and your saved response will be applied.

This is a great way to standardize your replies and save you time!

### Update your fork from the GitLab UI

<!-- categories: Source Code Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/repository/forking_workflow.md#update-your-fork) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/330243)

{{< /details >}}

Managing your fork just got easier. When your fork is behind, select **Update fork** in the GitLab UI to catch it up with upstream changes. When your fork is ahead, select **Create merge request** to contribute your change back to the upstream project. Both operations previously required you to use the command line.

See how many commits your fork is ahead (or behind) on your project’s main page and at **Repository > Files**. If merge conflicts exist, the UI gives guidance on how to resolve them using Git from the command line.

### Mirror specific branches only

<!-- categories: Source Code Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/repository/mirror/_index.md#mirror-specific-branches) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/1893)

{{< /details >}}

Do you need to mirror a busy repository with many branches, but you only need a few of them? Limit the number of
branches you mirror by creating a regular expression that matches only the branches you need.

Previously, mirrors required you to mirror an entire repository, or all protected branches. This new flexibility
can decrease the amount of data your mirrors push or pull, and keep sensitive branches out of public mirrors.

### New Web IDE experience now generally available

<!-- categories: Web IDE -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/web_ide/_index.md)

{{< /details >}}

Since its introduction, we’ve been iterating on the usability, performance, and stability of the Web IDE, which
has enabled us to build features like remote development workspaces and code suggestions on a powerful foundation.

We have received overwhelmingly positive feedback on the Web IDE Beta and starting in GitLab 16.0, we are making
it the default multi-file code editor across GitLab.

### Workspaces available in Beta for public projects

<!-- categories: Workspaces -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/workspace/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10122)

{{< /details >}}

Stop spending hours, or even days, troubleshooting your local development environment and interpreting inscrutable package installation errors. Now you can define a consistent, stable, and secure development environment in code and use it to create on-demand; all inside Workspaces.

Workspaces serve as personal, ephemeral development environments in the cloud. By eliminating the need for a local development environment, you can focus more on your code and less on your dependencies. Accelerate the process of onboarding to a new project and get up and running in minutes instead of days.

After the GitLab Agent for Kubernetes is configured and [the dependencies are installed](../../user/workspace/_index.md) in your self-hosted cluster or cloud platform of choice, you can define your development environment in a `.devfile.yaml` file and store it in a public project. Then, you and any other developers with access to the agent can create a workspace based on the `.devfile.yaml` file and edit directly in the embedded Web IDE. You’ll have full terminal access to the container, allowing you to work more efficiently. When you’re done, or if something goes wrong, you can shut down the workspace and start a fresh, new workspace for your next development task.

This short video walks you through the lifecycle of a workspace in the current Beta. Learn more about workspaces in the [documentation](../../user/workspace/_index.md) and let us know what you think in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/410031).

### Security training with SecureFlag

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/vulnerabilities/_index.md#enable-security-training-for-vulnerabilities) | [Related issue](https://gitlab.com/gitlab-com/alliances/alliances/-/issues/297)

{{< /details >}}

As security shifts left, remediating security findings without guidance can be challenging. Developers need actionable advice so they can resolve vulnerabilities and continue
building features. Contextual training that is relevant to the specific vulnerability detected was released in GitLab 14.9.

In this release, we are adding an integration with SecureFlag based upon the CWE of the vulnerability. SecureFlag’s
training solution is unique in that the labs involve remediating the vulnerability in a live environment,
which can be transferred to a real environment.

### Token rotation API

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../security/tokens/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/403042)

{{< /details >}}

Previously, to rotate tokens, the token owner had to manually create a new token and replace the existing token.

Now, token owners can use a `:rotate` API endpoint to programatically rotate personal, group, and project access tokens.

### AI-powered workflow features

<!-- categories: Code Suggestions, Duo Agent Platform, SAST -->

{{< details >}}

- Tier: Gold
- Links: [Documentation](../../development/ai_features/_index.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/10524)

{{< /details >}}

GitLab is evolving into an AI‑powered DevSecOps platform. Over the past month, we’ve introduced 10 new experiments
to improve efficiency and productivity across various GitLab features, all leveraging AI.

These AI-powered workflows boost efficiency and reduce cycle times in every phase of the software development lifecycle.

Learn more about [AI-powered workflows](https://about.gitlab.com/solutions/ai/)

### Code Suggestions improvements

<!-- categories: Code Suggestions -->

{{< details >}}

- Tier: Gold, Silver, Free
- Links: [Documentation](../../user/project/repository/code_suggestions/_index.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/9814)

{{< /details >}}

Code Suggestions is now available on GitLab.com for all users for free while the feature is in Beta. Teams can
boost efficiency with the help of generative AI that suggests code while you’re developing.

We’ve extended language support from our initial six languages to now include 13 languages: C/C++, C#, Go, Java,
JavaScript, Python, PHP, Ruby, Rust, Scala, Kotlin, and TypeScript.

We are making improvements to the Code Suggestions underlying AI model weekly to improve the quality of suggestions.
Please remember that AI is non-deterministic, so you may not get the same suggestion week to week.

Read more about these [improvements and what’s next](https://about.gitlab.com/blog/code-suggestions-for-all-during-beta/).

### Error Tracking is now generally available

<!-- categories: Observability -->

{{< details >}}

- Tier: Free, Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../operations/error_tracking.md)

{{< /details >}}

GitLab Error Tracking, which allows developers to discover and view errors generated by their application, is now generally available on GitLab.com! GitLab error tracking helps to increase efficiency and awareness by surfacing error information directly in the same interface as the code is developed, built, deployed, and released.

In this release, we are supporting both the [GitLab integrated error tracking](../../operations/error_tracking.md) and the
[Sentry-based](../../operations/error_tracking.md) backends.

### Custom value streams for project-level value stream analytics

<!-- categories: Value Stream Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/value_stream_analytics/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/382496)

{{< /details >}}

To improve the visibility into the complete workstream, we are adding to the project-level Value Stream Analytics (VSA) the [Overview stage](../../user/group/value_stream_analytics/_index.md) and the option to [create custom value streams](../../user/group/value_stream_analytics/_index.md).

Until now, these features were only available at the group-level VSA only.

## Scale and Deployments

### Rate limit for unauthenticated users of the Projects List API

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../administration/settings/rate_limit_on_projects_api.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/388435)

{{< /details >}}

Unauthenticated users of the Projects List API will be subject to rate limitations moving forward.

On GitLab.com, the limit is set to 400 requests per 10 minutes per unique IP address.

Users of self-managed GitLab instances have the same rate limitation by default, but administrators can change the rate limits as they see fit. We encourage users who need to make more than 400 requests per 10 minutes to the Projects List API to [sign up for a GitLab account](https://about.gitlab.com/pricing/).

### Self-managed GitLab uses two database connections

<!-- categories: Cell -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/omnibus/settings/database.html#configuring-multiple-database-connections) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9627)

{{< /details >}}

Starting with 16.0, self-managed installations of GitLab will have two database connections by default, instead of
one. This change makes self-managed versions of GitLab behave similarly to GitLab.com, and is a step towards enabling
a [separate database for CI features](https://gitlab.com/groups/gitlab-org/-/epics/7509) for self-managed versions of GitLab.

This change applies to installation methods with Omnibus GitLab, GitLab Helm chart, GitLab Operator, GitLab Docker images, and installation from source.

### Option to disable followers

<!-- categories: System Access, User Profile -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/_index.md#disable-following-and-being-followed-by-other-users) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/325558)

{{< /details >}}

We have received feedback from users who wanted to prevent getting unwanted followers of their user profile. We listened to your concerns, so now, in your user profile settings under Preferences, you can disable following.

When you disable this feature, no one can follow you, and you cannot follow anyone. All existing following and follower relationships are removed, and the count is set to zero.

### Delayed group and project deletion set as default

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/gitlab_com/_index.md#delayed-project-deletion) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/389557)

{{< /details >}}

To prevent accidental deletion of projects and groups, starting in GitLab 16.0, the delayed deletion feature will be turned on by default for all GitLab Ultimate and Premium customers.

Self-managed users still have the option to define a deletion delay period of between 1 and 90 days, and SaaS users have a non-adjustable default retention period of 7 days.

Users of Ultimate and Premium groups can still delete a group or project immediately from the group or project settings via a two-step deletion process.

We believe that this change will contribute to a safer deletion process and will be beneficial in preventing accidental deletions. We’d love your feedback in issue [#396996](https://gitlab.com/gitlab-org/gitlab/-/issues/396996).

### GitLab chart improvements

<!-- categories: Cloud Native Installation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/charts/)

{{< /details >}}

- Updates to GitLab 16.0 also update cert-manager to version 1.11.x. This cert-manager update includes breaking changes you must
[read before upgrading](https://cert-manager.io/docs/release-notes/release-notes-1.10/#breaking-changes-you-must-read-this-before-you-upgrade).
These changes include a change to container names that was best done during a major release of GitLab. To see details of updated features, see the
[releases notes for cert-manager 1.11](https://cert-manager.io/docs/release-notes/release-notes-1.11).
- PostgreSQL 12 is no longer supported. The minimum required version is PostgreSQL 13, and support for PostgreSQL 14 is added.
New chart installs of GitLab include PostgreSQL 14 by default, and upgrades must follow the steps for
[upgrading the bundled PostgreSQL version](https://docs.gitlab.com/charts/installation/database_upgrade.html).
- Updates to GitLab 16.0 include an update to the Redis subchart to version 16.13.2, including Redis 6.2.7.
- We have removed the bundled Grafana chart. If you use the bundled Grafana, you must switch to the [newer chart version from Grafana Labs](https://artifacthub.io/packages/helm/grafana/grafana) or a Grafana Operator from a trusted provider.
- GitLab 16.0 includes
[registry services details for webservice and Sidekiq](https://docs.gitlab.com/charts/charts/globals.html#configure-registry-settings)
in the `global.registry.*` configuration for simplification because the values are present in both. You can keep the old behavior with an override.
- The [minimum supported Helm version](https://docs.gitlab.com/charts/installation/tools.html#helm) is 3.5.2.
- The GitLab Runner default version is now Ubuntu 22.04.

### Omnibus improvements

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- PostgreSQL 12 is no longer supported. The minimum required version is PostgreSQL 13. Users of the packaged PostgreSQL 12 must
[perform a database upgrade](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server) before installing GitLab
16.0.
- The new base OS for the Omnibus GitLab docker images is Ubuntu 22.04.
- GitLab 16.0 disables older telemetry endpoints for Consul, which were deprecated in Consul 1.9. This allows us to
[update Consul to newer versions](https://developer.hashicorp.com/consul/docs/v1.12.x/agent/config/config-files#telemetry-parameters).
- GitLab 16.0 includes packages for Red Hat Enterprise Linux (RHEL) 9 and compatible distributions.
- GitLab 16.0 includes [Mattermost 7.10](https://mattermost.com/) with [security updates](https://mattermost.com/security-updates/). An upgrade from earlier versions is recommended.

### Additional Registration Features available to Free users

<!-- categories: Product Analytics -->

{{< details >}}

- Tier: Free
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/settings/usage_statistics.md#registration-features-program) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10508)

{{< /details >}}

GitLab Free customers with a self-managed instance running GitLab Enterprise Edition can now access five more paid features under the [Registration Features](../../administration/settings/usage_statistics.md#registration-features-program) program:

- [Password complexity policy](../../administration/settings/sign_up_restrictions.md)
- [Description change history](../../user/discussions/_index.md#view-description-change-history)
- [Issue board configuration](../../user/project/issue_board.md#configurable-issue-boards)
- [Maintenance mode](../../administration/maintenance_mode/_index.md)
- [Coverage-guided fuzz testing](../../user/application_security/coverage_fuzzing/_index.md)

To get access to these features, register with GitLab and send us activity data through [Service Ping](../../administration/settings/usage_statistics.md#enable-registration-features).

### Import collaborators as an additional item to import

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/import/github.md#select-additional-items-to-import) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/398154)

{{< /details >}}

In GitLab 15.10, we started mapping GitHub repository collaborators as GitLab project members during GitHub project imports. We received
[feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/398154) that this led to confusion and that some GitHub collaborators were
unexpectedly added and consumed seats.

In GitLab 16.0, we’ve iterated and added GitHub repository collaborators to the list of
[additional items to import](../../user/project/import/github.md#select-additional-items-to-import). This gives users the option
to avoid importing these users and to understand the possible implications of importing them.

This option is selected by default. Leaving it selected might result in new users using a seat in the group or namespace, and being granted permissions
[as high as project owner](../../user/project/import/github.md#collaborators-members). Only
direct collaborators are imported. Outside collaborators are never imported.

### Filter GitHub repositories to import

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/import/github.md#filter-repositories-list) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/385113)

{{< /details >}}

If you own or collaborate on a lot of repositories in GitHub, you might have trouble finding those that you want to import to GitLab using the current
filtering option.

To make finding the right repositories easier, we have added additional filters. You can now list subsets of the repositories you can import using three tabs:

- **Owner**, to list repositories you own.
- **Collaborator**, to list repositories you collaborate on.
- **GitHub organization**, to list repositories that belong to GitHub organizations.

On the **Organization** tab, you can further narrow down your search and choose a specific organization and list only repositories belonging
to that organization.

### Mark to-do items completed by other group or project owners Done

<!-- categories: Groups & Projects, User Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/todos.md#actions-that-mark-a-to-do-item-as-done) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/374726)

{{< /details >}}

When a user raises an access request for a group or project, the request appears in the To-Do List of the group or project owner.
For groups and projects that have multiple owners, the request appears in each owner’s To-Do List.

With this new functionality, to-do items that have already been completed by another owner are marked Done in the others’ To-Do Lists.

### Opt in to a new navigation experience

<!-- categories: Navigation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../tutorials/left_sidebar/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9044)

{{< /details >}}

GitLab 16.0 features an all-new navigation experience! To get started, go to your avatar in the top right of the UI and turn on the **New navigation** toggle. The left sidebar changes to a new and improved design, based on user feedback we’ve received over the last year.

Please let us know about your experience in [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/409005). Based on the feedback, we will be progressively enabling the new navigation across our user base, with the final step being removal of the old navigation.

### Limit session length for users

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/profile/_index.md#session-duration) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/30819)

{{< /details >}}

Administrators can remove the “Remember Me” option for users when signing in so that sessions cannot be extended and the user is forced to re-authenticate. Limiting the duration of a session may improve instance security.

### Authenticate with Jira personal access tokens

<!-- categories: Settings -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../integration/jira/configure.md#configure-the-integration) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/8222)

{{< /details >}}

Previously, you could only authenticate the [Jira issue integration](../../integration/jira/configure.md) with a Jira username
and password.

Now you can use a [Jira personal access token](https://confluence.atlassian.com/enterprise/using-personal-access-tokens-1026032365.html) to authenticate
if you are using Jira Data Center and Jira Server with Jira 8.14 and later. A Jira personal access token is a safer alternative to a username and password.

### Placeholder for issue description in Service Desk automated replies

<!-- categories: Service Desk -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/service_desk/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/223751)

{{< /details >}}

It is useful for a Service Desk requester to see their original request in the automated thank you email replies.

In this release, we add an `%{ISSUE_DESCRIPTION}` placeholder so that Service Desk administrators can include the original request in the thank you email.

## Unified DevOps and Security

### Real-time merge request updates

<!-- categories: Web IDE -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/project/merge_requests/_index.md)

{{< /details >}}

When working on merge requests, it’s important to make sure that what you’re seeing is the latest information for approvals, pipelines or other information that might impact your ability to get the changes merged. Historically, this has meant refreshing the merge request or waiting for polling updates to come through.

We’ve improved the experience of both the merge button widget and approval widget inside of the merge request, so that they now update in real-time in the merge request. This is a great improvement to improve the speed at which you can deliver changes, and the confidence at which you can move a merge request forward knowing you’re seeing the latest information.

We’re looking at more areas for [real-time improvements](https://gitlab.com/groups/gitlab-org/-/epics/1812) in merge requests, so follow along for updates.

### Provide a reason when dismissing vulnerabilities in bulk

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/vulnerability_report/_index.md#change-status-of-vulnerabilities) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/408366)

{{< /details >}}

When selecting one or more vulnerabilities in the vulnerability report, it’s possible to change their status in bulk.

With this release, you can now select a dismissal reason when choosing the dismiss
status, and add a comment when changing a vulnerability’s status."

### Add and remove compliance frameworks without using bulk actions

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/compliance_center/compliance_projects_report.md#apply-a-compliance-framework-to-projects-in-a-group)

{{< /details >}}

In GitLab 15.11, we added bulk [adding](../../user/compliance/compliance_center/compliance_projects_report.md#apply-a-compliance-framework-to-projects-in-a-group) and
[removing](../../user/compliance/compliance_center/compliance_projects_report.md#remove-a-compliance-framework-from-projects-in-a-group) of compliance frameworks to the
compliance frameworks report.

Now in GitLab 16.0, you can also add and remove compliance frameworks from projects directly from the report table row.

Before GitLab 16.0, you had to create and edit frameworks in the group’s settings.

Now in GitLab 16.0, you can create or edit your compliance frameworks in the
compliance framework report as well. This simplifies the framework creation workflow and reduces the need to switch contexts while managing your frameworks.

### Filter compliance violations by target branch name

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/compliance_center/compliance_projects_report.md)

{{< /details >}}

Prior to GitLab 16.0, the compliance violations report showed all violations on all branches.

Now you can now filter violations using the new **Search target branch** field, allowing you to focus on the branches that
you are most concerned with.

### Support role-based approval action for scan result policies

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/8018)

{{< /details >}}

With role-based approval actions, you can configure scan result policies to require approval from GitLab-supported roles, including Owners, Maintainers, and Developers.

This gives you additional flexibility over requiring individual approvers or defined groups of users, making it easier to enforce policies based on roles you already leverage in GitLab, at scale, especially across large organizations.

### Introducing Out-of-band Application Security Testing through browser-based DAST

<!-- categories: DAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dast/browser/_index.md)

{{< /details >}}

Previously, GitLab’s DAST analyzers did not support callback attacks while performing active checks. This meant that Out-of-band Application Security Testing (OAST) needed to be configured separately from your DAST scan.

Now, you can run OAST by [extending the browser-based DAST analyzer](../../user/application_security/dast/browser/_index.md) configuration to enable callback attacks.

In this release we are introducing the [BAS.latest.GitLab-ci.yml](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/BAS.latest.gitlab-ci.yml) template. The Breach and Attack Simulation CI/CD template features job configuration for the browser-based DAST analyzer and enables container-to-container networking to add extended DAST scans against service containers to your CI/CD pipeline.

We’re continuously iterating to develop new Breach and Attack Simulation features. We’d love to [hear your feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/404809) on the addition of callback attacks to browser-based DAST.

### Import Maven/Gradle packages by using CI/CD pipelines

<!-- categories: Package Registry -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/packages/package_registry/_index.md#to-import-packages) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/389338)

{{< /details >}}

Have you been thinking about moving your Maven or Gradle repository to GitLab, but haven’t been able to invest the time to plan the migration? GitLab is proud to announce the MVC launch of a Maven/Gradle package importer.

You can now use the Packages Importer tool to import packages from any Maven/Gradle compliant registry, like Artifactory.

To use the tool, simply create a `config.yml` file that contains the details of the packages you want to import into GitLab. Then add the importer to a `.gitlab-ci.yml` pipeline configuration file, and the importer does the rest. It runs in the pipeline, dynamically generating a child pipeline with jobs that import all the packages into your GitLab package registry.

### Download packages from the Maven Registry with Scala

<!-- categories: Package Registry -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/packages/maven_repository/_index.md#install-a-package) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/212854)

{{< /details >}}

The GitLab Package Registry now supports downloading Maven packages using the Scala build tool (`sbt`). Previously, Scala users had no way to download Maven packages from the registry because basic authentication was not supported. As a result, Scala users were either blocked from using the registry or had to use Maven (`mvn`) or Gradle as an alternative.

By adding support for Scala, we hope to help you use the Package Registry with your more data intensive projects.

Please note that publishing artifacts using `sbt` is not yet supported, but you can follow [issue 408479](https://gitlab.com/gitlab-org/gitlab/-/issues/408479) if you are interested in adding support for publishing.

### Add or resolve to-do items on tasks, objectives, and key results

<!-- categories: Team Planning -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/todos.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9750)

{{< /details >}}

We know that GitLab [To-Do List](../../user/todos.md) is a widely adopted feature, but it was not available on tasks, objectives, and key results.

In this release, we’re introducing the ability to toggle a to-do item on or off from a work item record.

### GitLab Pages unique subdomains

<!-- categories: Pages -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/pages/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9347)

{{< /details >}}

In previous versions of GitLab, cookies of different GitLab Pages sites under the same top-level group were visible for other projects under the same top-level because of the GitLab Pages default URL format.

Now, you can secure your sites by assigning a unique subdomain to each GitLab Pages project.

### Add emoji reactions on tasks, objectives and key results

<!-- categories: Team Planning -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/emoji_reactions.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9987)

{{< /details >}}

You can now contribute to tasks, objectives and key results with the addition of emoji reactions for work items.

Before this release, you could only add reactions on issues, merge requests, snippets, and epics.

### Change work item type from quick action

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/quick_actions.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/385227)

{{< /details >}}

With this additional quick action, you can now convert key results to objectives.

### Pick custom colors for labels

<!-- categories: Team Planning -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/project/labels.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/361846)

{{< /details >}}

Until now, you could specify only a fixed number of colors for your labels.

This release introduces a color picker to label management, allowing you to select any range of colors for your labels.

### Reorder child records for tasks, objectives and key results

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/okrs.md#reorder-objective-and-key-result-children) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9548)

{{< /details >}}

If you’re a user of [tasks](../../user/tasks.md) or OKRs you’ve likely wished more than once that we could reorder the child records within the widget!

With this work, users will now be able to reorder child records within work item widgets allowing them to indicate relative priority or signal what’s up next.

### New stage events for custom Value Stream Analytics

<!-- categories: Value Stream Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/value_stream_analytics/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/361983)

{{< /details >}}

Value Stream Analytics has been extended with two new stage events: issue first assigned and merge request first assigned.
These events can be useful for measuring the time it takes for an item to be first assigned to a user.

To implement this feature, GitLab started storing the history of assignment events in GitLab 16.0. This means that issue
and MR assignment events prior to GitLab 16.0 are not available.

### Display message when deploy freeze is active

<!-- categories: Environment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/releases/_index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/212460)

{{< /details >}}

GitLab now shows you a message on the Environments page when a deploy freeze is in effect. This helps ensure your team is aware of when freezes occur, and when deployments are not allowed.

### SAST analyzer updates

<!-- categories: SAST -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/analyzers.md) | [Related issue](../../user/application_security/_index.md)

{{< /details >}}

GitLab SAST includes [many security analyzers](../../user/application_security/sast/_index.md#supported-languages-and-frameworks) that the GitLab Static Analysis team actively maintains, updates, and supports. We published the following updates during the 16.0 release milestone:

- The Semgrep-based analyzer includes updated [GitLab-managed scanning rules](https://gitlab.com/gitlab-org/security-products/sast-rules). See the [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/CHANGELOG.md#v423) for further details. We’ve updated the rules to:
  - Update OWASP mappings to show that they’re based on the 2017 OWASP Top Ten. Thanks to [`@artem-fedorov`](https://gitlab.com/artem-fedorov) for this [community contribution](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/merge_requests/196).
  - Handle additional cases in the `PyYAML.load` rule. Thanks to [`@stevep-arm`](https://gitlab.com/stevep-arm) for this [community contribution](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/merge_requests/237).
  - Significantly improve the descriptions and guidance for C rules based on revisions from the GitLab Vulnerability Research team.
  - Add support for [scanning Scala code](https://docs.gitlab.com/#faster-easier-scala-scanning-in-sast).
- The Flawfinder-based analyzer now supports [passing the `--neverignore` flag](../../user/application_security/sast/_index.md#security-scanner-configuration) to disregard “ignore” directives in comments. See the [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/flawfinder/-/blob/master/CHANGELOG.md#v401) for further details.
- The KICS-based analyzer is updated to KICS version 1.7.0. See the [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/kics/-/blob/main/CHANGELOG.md#v401) for further details.
- The MobSF-based analyzer now supports multiple modules and projects, which resolves several bug reports. See the [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/kics/-/blob/main/CHANGELOG.md#v401) for further details.

Also, [as previously announced](../../update/deprecations.md#secure-analyzers-major-version-update), we increased the major version number of each analyzer as part of GitLab 16.0.

If you [include the GitLab-managed SAST template](../../user/application_security/sast/_index.md) ([`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)) and run GitLab 16.0 or higher, you automatically receive these updates.
To remain on a specific version of any analyzer and prevent automatic updates, you can [pin its version](../../user/application_security/sast/_index.md).

For previous changes, see [last month’s updates](https://about.gitlab.com/releases/2023/04/22/gitlab-15-11-released/#static-analysis-analyzer-updates).

### Secret Detection updates

<!-- categories: Secret Detection -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/secret_detection/_index.md) | [Related issue](../../user/application_security/_index.md)

{{< /details >}}

We regularly release updates to the GitLab Secret Detection analyzer. During the GitLab 16.0 milestone, we:

- Added [GitLab-managed detection rules](../../user/application_security/secret_detection/_index.md) for:
  - Access tokens for the Meta, Oculus, and Instagram APIs.
  - Tokens for the Segment Public API.
- Updated the Gitleaks scanning engine to version 8.16.3.
- [Fixed a bug](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/merge_requests/212) that prevented scanning when a repository had only a single commit.
- Incremented the analyzer major version to `5`, [as previously announced](../../update/deprecations.md#secure-analyzers-major-version-update).

See the [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/CHANGELOG.md#v501) for further details.

If you [use the GitLab-managed Secret Detection template](../../user/application_security/secret_detection/_index.md) ([`Secret-Detection.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/Secret-Detection.gitlab-ci.yml)) and run GitLab 16.0 or higher, you automatically receive these updates.
To remain on a specific version of any analyzer and prevent automatic updates, you can [pin its version](../../user/application_security/secret_detection/_index.md).

For previous changes, see [last month’s updates](https://about.gitlab.com/releases/2023/04/22/gitlab-15-11-released/#static-analysis-analyzer-updates).

### Browser-based DAST performance improvements

<!-- categories: DAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dast/browser/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9945)

{{< /details >}}

We have optimized the way that the browser-based DAST analyzer performs its scans. These improvements have significantly
decreased the amount of time that it takes to run a DAST scan with the browser-based analyzer. The following improvements have been made:

- Added log summary statistics to help determine where time is spent during a scan. This can be enabled by including the environment variable `DAST_BROWSER_LOG="stat:debug"`.
- Optimized passive checks by running them in parallel.
- Optimized passive checks by caching regular expressions used when matching content in HTTP response bodies.
- Optimized how DAST determines whether a page has finished loading. Now, we don’t wait for excluded document types or out-of-scope URLs.
- Reduced waiting time for pages where the DOM stabilizes quickly after page load.

With these improvements, we have seen browser-based DAST scan times reduced by 50%-80%, depending on the complexity and size of the
application being scanned. While this percentage decrease may not be seen in all scans, your browser-based DAST scans should now take significantly less time to complete.

### Faster, easier Scala scanning in SAST

<!-- categories: SAST -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/_index.md#supported-languages-and-frameworks) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/362958)

{{< /details >}}

GitLab Static Application Security Testing (SAST) now offers Semgrep-based scanning for Scala code.
This work builds on our previous introduction of Semgrep-based Java scanning [in GitLab 14.10](https://about.gitlab.com/releases/2022/04/22/gitlab-14-10-released/#faster-easier-java-scanning-in-sast).
As with the other languages we have [transitioned to Semgrep-based scanning](../../user/application_security/sast/analyzers.md#transition-to-semgrep-based-scanning), Scala scanning coverage uses GitLab-managed detection rules to detect a variety of security issues.

The new Semgrep-based scanning runs significantly faster than the existing analyzer based on SpotBugs.
It also doesn’t need to compile your code before scanning, so it’s simpler to use.

GitLab’s Static Analysis and Vulnerability Research teams worked together to translate rules to the Semgrep format, preserving most existing rules.
We also updated, refined, and tested the rules as we converted them.

If you use [the GitLab-managed SAST template](../../user/application_security/sast/_index.md) ([`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)), both Semgrep-based and SpotBugs-based analyzers now run whenever Scala code is found.
In GitLab Ultimate, the Security Dashboard combines findings from the two analyzers, so you won’t see duplicate vulnerability reports.

In a future release, we’ll change [the GitLab-managed SAST template](../../user/application_security/sast/_index.md) ([`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)) to only run the Semgrep-based analyzer for Scala code.
The SpotBugs-based analyzer will still scan code for other languages, including Groovy and Kotlin.
You can [disable SpotBugs early](https://gitlab.com/gitlab-org/gitlab/-/issues/412060) if you prefer to use only Semgrep-based scanning.

If you have any questions, feedback, or issues with the new Semgrep-based Scala scanning, please [file an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Bug&add_related_issue=362958&issue[title]=Feedback%20on%20SAST%20Semgrep%20Scala%20support&issue[description]=%2Flabel%20~%22group%3A%3Astatic%20analysis%22), we’ll be glad to help.

### Create an instance runner in the Admin Area as a user

<!-- categories: Fleet Visibility -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner/register/) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/383139/)

{{< /details >}}

In this new workflow, adding a new runner to a GitLab instance requires authorized users to create a runner in the GitLab UI and include essential configuration metadata. With this method, the runner is now easily traceable to the user, which will help administrators troubleshoot build issues or respond to security incidents.

### Trigger job mirror status of downstream pipeline when cancelled

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../ci/yaml/_index.md#triggerstrategy) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/220794)

{{< /details >}}

Previously, a trigger job configured with `strategy: depends` mirrored the job status of the downstream pipeline. If the downstream pipeline was in the `running` status, the trigger job was also marked as `running`. Unfortunately, if the downstream job did not comnplete and had a status `canceled`, the trigger job’s status was inaccurately `failed`.

In this release, we have updated trigger jobs with `strategy: depend` to reflect the downstream’s pipelines’s statis accurately. When a downstream pipeline is cancelled, the trigger also shows canceled.

This change may have an impact on your existing pipelines, especially if you have jobs that rely on the trigger job’s status being marked as failed. We recommend reviewing your pipeline configurations and making any necessary adjustments to accommodate this change in behavior.

### CI/CD components

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../ci/components/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9945)

{{< /details >}}

In this release we are excited to announce the availability of CI/CD components, as an experimental feature. A CI/CD component is a reusable single-purpose building block that can be used to compose a part of a project’s CI/CD configuration, or even an entire pipeline.

When combined with the [`inputs`](../../ci/yaml/includes.md) keyword, a CI/CD component can be made much more flexible. You can configure the component to your exact needs by inputting values which can be used for job names, variables, credentials, and so on.

### REST API endpoint to create a runner

<!-- categories: Fleet Visibility -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../api/users.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390427)

{{< /details >}}

Users can now use the new REST API endpoint, `POST /user/runners`, to automate the creation of runners associated with a user. When a runner is created, an authentication token is generated. This new endpoint supports the Next GitLab Runner Token Architecture workflow.

### Per-cache fallback cache keys in CI/CD pipelines

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../ci/caching/_index.md#per-cache-fallback-keys) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/22213)

{{< /details >}}

Using a cache is a great way to speed up your pipelines by reusing dependencies that were already fetched in a previous job or pipeline. But when there is no cache yet, the benefits of caching are lost because the job has to start from scratch, fetching every dependency.

We previously introduced a single fallback cache to use when no cache is found, that you can define globally. This was useful for projects that used a similar cache for all jobs. Now in 16.0 we’ve improved that feature with per-cache fallback keys. You can define up to 5 fallback keys for every job’s cache, greatly reducing the risk that a job runs without a useful cache. If you have a wide variety of caches, you can now use an appropriate fallback cache as needed.

### Create a group runner as a user

<!-- categories: Fleet Visibility -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/383143/)

{{< /details >}}

In this new workflow, adding a new runner to a GitLab group requires authorized users to create a runner in the GitLab UI and include essential configuration metadata. With this method, the runner is now easily traceable to the user, which will help administrators troubleshoot build issues or respond to security incidents.

### Configurable maximum number of included CI/CD configuration files

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/settings/continuous_integration.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/207270)

{{< /details >}}

The `include` keyword lets you compose your CI/CD configuration from multiple files. For example, you can split one
long `.gitlab-ci.yml` file into multiple files to increase readability, or reuse one CI/CD configuration file in multiple projects.

Previously, a single CI/CD configuration could include up to 150 files, but in GitLab 16.0 administrators can modify this limit to a different value in the instance settings.

### Create project runners as a user

<!-- categories: Fleet Visibility -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/383144)

{{< /details >}}

In this new workflow, adding a new runner to a project requires authorized users to create a runner in the GitLab UI and include essential configuration metadata.

With this method, the runner is now easily traceable to the user, which will help administrators troubleshoot build issues or respond to security incidents.

### Rate Limit for the `projects/:id/jobs` API endpoint reduced

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../security/rate_limits.md#project-jobs-api-endpoint) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/382985)

{{< /details >}}

Previously, the `GET /api/:version/projects/:id/jobs` was rate limited to 2000 authenticated requests per minute.

To move this in line with other rate limits and improve efficiency and reliability, we have lowered the limit to 600 authenticated requests per minute.

### GitLab Runner 16.0

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 16.0 today! GitLab Runner is the lightweight, highly-scalable agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s new

- [GitLab Runner autoscaling plugin for Google Compute Engine - Experiment](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29217)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-0-stable/CHANGELOG.md)

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.0)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.0)
- [UI improvements](https://papercuts.gitlab.com/?milestone=16.0)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
