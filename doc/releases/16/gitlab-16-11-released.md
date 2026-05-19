---
stage: Release Notes
group: Monthly Release
date: 2024-04-18
title: "GitLab 16.11 release notes"
description: "GitLab 16.11 released with GitLab Duo Chat now generally available"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On April 18, 2024, GitLab 16.11 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor

[Ivan Shtyrliaiev](https://gitlab.com/bahek2462774) has made [half a dozen contributions](https://gitlab.com/groups/gitlab-org/-/merge_requests?scope=all&state=merged&author_username=bahek2462774) to GitLab so far in 2024.
He was nominated by [Hannah Sutor](https://gitlab.com/hsutor), Principal Product Manager at GitLab, who highlighted his contribution to [improve the Users list search and filter experience](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144907).

“This is a huge user experience improvement that helps us go from a horizontally scrollable list of tabs to a much more elegant UX with only 2 tabs and a search box,” Hannah said.
“Now users are able to filter down via the search box rather than horizontally scroll tabs!”

Ivan was noted for picking up this challenging request, working with the GitLab UX team to refine the proposal, and being super responsive to reviews.
[Adil Farrukh](https://gitlab.com/adil.farrukh), Engineering Manager at GitLab, supported the nomination, noting that this feature was not trivial and that Ivan was very responsive to feedback.
[Eduardo Sanz García](https://gitlab.com/eduardosanz), Sr. Frontend Engineer at GitLab, also supported the nomination and commended Ivan’s resilience.

“Really appreciate Eduardo’s review and the GitLab team putting in so much effort to make contributions happen,” Ivan said.
“It was very helpful and I realise how much time it takes.”

Ivan is a frontend software engineer at [Politico](https://www.politico.com/).

[Baptiste Lalanne](https://gitlab.com/BaptisteLalanne) picked up a three-year-old issue with nearly seventy upvotes to contribute a [highly requested feature](https://gitlab.com/gitlab-org/gitlab/-/issues/262674) that adds `retry:exit codes` to the CI/CD configuration.
This contribution empowers our users with enhanced flexibility in managing failed pipeline jobs and jobs with different exit codes.

Baptiste was nominated by [Dov Hershkovitch](https://gitlab.com/dhershkovitch), Product Manager at GitLab.
“Baptiste’s diligent work on this project went above and beyond mere implementation,” Dov said.
“This accomplishment serves as a prime example of our community’s collaborative strength.
Through Baptiste’s efforts, GitLab has not only fulfilled a critical need but also reinforced its commitment to openness and transparency, enriching our open-core mentality.”

“This is heart warming and really appreciated,” Baptiste said.
“I’m really looking forward to continuing my contributions in my spare time as I love it so much.”

Over the past year, Baptiste has merged six merge requests to GitLab and is looking to [contribute to the GitLab Runner](https://docs.gitlab.com/runner/development/) next.
Baptiste is a software engineer for [DataDog](https://www.datadoghq.com/).

A big thanks to our newest MVPs, Ivan and Baptiste, and to the rest of GitLab’s community contributors! 🙌

## Primary features

### GitLab Duo Chat now generally available

<!-- categories: Duo Chat -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/gitlab_duo_chat/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13516)

{{< /details >}}

GitLab Duo Chat is now generally available. As part of this release, we are also making these capabilities generally available:

- Code explanation helps developers and less technical users understand unfamiliar code faster
- Code refactoring enables developers to simplify and improve existing code
- Test generation automates repetitive tasks and helps teams catch bugs sooner

Users can access GitLab Duo Chat in the GitLab UI, in the Web IDE, in VS Code, or in JetBrains IDEs.

Learn more about this release of GitLab Duo Chat from this [blog post](https://about.gitlab.com/blog/gitlab-duo-chat-now-generally-available/).

Chat is currently freely accessible by all Ultimate and Premium users. Instance administrators, group owners, and project owners can choose to [restrict Duo features from accessing and processing their data](../../user/gitlab_duo/turn_on_off.md).

The GitLab Duo Chat is part of [GitLab Duo Pro](https://about.gitlab.com/gitlab-duo/#pricing). To ease the transition for Chat beta users who have yet to purchase GitLab Duo Pro, Duo Chat will remain available to existing Premium and Ultimate customers (without the add-on) for a short period of time. We will announce when access will be restricted to Duo Pro subscribers at a later date.

Feel free to share your thoughts by clicking the feedback button in the chat or by creating an issue and mentioning GitLab Duo Chat. We’d love to hear from you!

### GitLab Duo Chat available in JetBrains IDEs

<!-- categories: Editor Extensions -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../editor_extensions/jetbrains_ide/_index.md) | [Related issue](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/307)

{{< /details >}}

We are happy to announce the availability of GitLab Duo Chat in JetBrains IDEs.

As part of GitLab’s AI offerings, Duo Chat further streamlines the developer experience by directly bringing an interactive chat window into any supported JetBrains IDE and the ability to explain code, write tests, and refactor existing code.

For a complete list of capabilities, see our [Duo Chat documentation](../../user/gitlab_duo_chat/_index.md).

### Security policy scopes

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/scan_execution_policies.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/5510)

{{< /details >}}

Policy scoping provides granular management and enforcement of policies. Across both merge request approval (scan result) policies and scan execution policies, this new feature enables security and compliance teams to scope policy enforcement to a compliance framework or to a set of included/excluded projects in a group.

While today all policies managed in a security policy project are enforced against all linked groups, subgroups, and projects, policy scoping will allow you to refine that enforcement policy by policy. This allows security and compliance teams to:

- More easily manage policies centrally across their organization, while still enforcing policies granularly.
- Get a better sense of how the controls they are implementing and enforcing in GitLab roll up to the compliance frameworks they’ve defined.
- View and manage which policies are linked to a compliance framework through the compliance center.
- Better organize and understand their security and compliance posture.

### Understand your users better with Product Analytics

<!-- categories: Product Analytics -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/analytics/productivity_analytics.md)

{{< /details >}}

It is critical to understand how your users are engaging with your application in order to make data-driven decisions about future innovations and optimizations. Are you seeing an uptick in usage for your top business critical URLs, is there an unusual dip in monthly active users, are you seeing more customers engaging with a mobile Android device? By having the answers to questions like this and making them accessible to your engineering teams from the GitLab platform, your teams can stay in sync with how their development work is affecting user outcomes.

With GitLab’s new Product Analytics feature, you can instrument your applications, collect key usage and adoption data about your users, and then display it inside GitLab. You can visualize data in dashboards, report on it, and filter it in a variety of different ways to find insights about your users. Your team can now quickly identify and respond to unexpected dips or spikes in customer usage that signify an issue, as well as celebrate the success of their recent releases.

To use Product Analytics, you will need a Kubernetes cluster to install this [helm chart](https://gitlab.com/gitlab-org/analytics-section/product-analytics/helm-charts) and
instrument your application to send traffic to it. GitLab will then connect to the cluster to retrieve the
data for visualization.

### Disable personal access tokens for Enterprise Users

<!-- categories: User Management -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/profile/personal_access_tokens.md#disable-personal-access-tokens-for-enterprise-users) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/369504)

{{< /details >}}

GitLab.com group Owners can now disable the creation and use of personal access tokens for any enterprise users in their groups. Due to the powerful privileges that can be associated with personal access tokens, some Owners may want to disable these tokens for security reasons.

This granular control gives options when it comes to balancing security and accessibility on GitLab.com.

### Autocomplete support for links to wiki pages

<!-- categories: Wiki -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/markdown.md#gitlab-specific-references) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/442229)

{{< /details >}}

We’re thrilled to introduce autocomplete support for links to wiki pages in GitLab 16.11! With this new feature, linking to wiki pages from your epics and issues
has never been easier - it’s just a matter of a few keystrokes.

Gone are the days of having to copy and paste wiki page URLs into epic and issue comments. Now, simply navigate to any group or project with wiki pages, access an epic or
issue, and use the autocomplete shortcut to seamlessly link to your wiki pages from the epic or issue!

### Sidebar for metadata on the project overview page

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/working_with_projects.md)

{{< /details >}}

We’ve redesigned the project overview page. Now you can find all of the project information and links in one sidebar rather than multiple areas.

### Email notifications for changes made using Switchboard

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../administration/dedicated/configure_instance/users_notifications.md) | [Related issue](https://about.gitlab.com/dedicated/)

{{< /details >}}

Configuration changes made to your GitLab Dedicated instance by tenant administrators using Switchboard will now generate email notifications when complete.

All users with access to view or edit your tenant in Switchboard will receive a notification for each change made.

### Option to cancel a pipeline immediately if any jobs fails

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/yaml/_index.md#workflowauto_cancelon_job_failure) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/23605)

{{< /details >}}

Sometimes after you notice a job fails, you might manually cancel the rest of the pipeline to save resources while you work on the issue causing the failure. With GitLab 16.11, you can now configure pipelines to be cancelled automatically when any job fails. With large pipelines that take a long time to run, especially with many long-running jobs that run in parallel, this can be an effective way to reduce resource usage and costs.

You can even configure a pipeline to immediately [cancel if a downstream pipeline fails](../../ci/pipelines/downstream_pipelines.md#auto-cancel-the-parent-pipeline-from-a-downstream-pipeline), which cancels the parent pipeline and all other downstream pipelines.

Special thanks to [Marco](https://gitlab.com/zillemarco) for contributing to the feature!

## Scale and Deployments

### Omnibus improvements

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- In GitLab 17.0, the minimum-supported version of PostgreSQL will become 14. In preparation for this change, in GitLab 16.11 we have changed the
`attempt_auto_pg_upgrade?` setting to `true`, which will attempt to automatically upgrade the version of PostgreSQL to 14.This process is the same as for last time we bumped the minimum-supported PostgreSQL version.

### Updated project archiving functionality

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/working_with_projects.md#archive-a-project)

{{< /details >}}

Now it’s easier to identify archived projects in project lists. From 16.11, archived projects display an **Archived** badge in the **Archived** tab of the group overview. This badge is also part of the project title on the project overview page.

An alert message clarifies that archived projects are read-only. This message is visible on all project pages to ensure that this context is not lost even when working on sub-pages of the archived project.

In addition, when deleting a group, the confirmation modal now lists the number of archived projects to prevent accidental deletions.

### Custom webhook headers

<!-- categories: Notifications -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/integrations/webhooks.md#custom-headers) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/17290)

{{< /details >}}

Previously, GitLab webhooks did not support custom headers. This meant you could not use them with systems that accept authentication tokens from headers with specific names.

With this release, you can add up to 20 custom headers when you create or edit a webhook. You can use these custom headers for authentication to external services.

With this feature and the [custom webhook template](../../user/project/integrations/webhooks.md#custom-webhook-template) introduced in GitLab 16.10, you can now fully design custom webhooks. You can configure your webhooks to:

- Post custom payloads.
- Add any required authentication headers.

Like secret tokens and URL variables, custom headers are reset when the target URL changes.

Thanks to [Niklas](https://gitlab.com/Taucher2003) for [this community contribution](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146702)!

### Test project hooks with the REST API

<!-- categories: Notifications -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/projects.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/25329)

{{< /details >}}

Previously, you could test project hooks in the GitLab UI only. With this release, you can now trigger test hooks for specified projects by using the REST API.

Thanks to [Phawin](https://gitlab.com/lifez) for [this community contribution](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147656)!

### GitLab for Slack app configurable for groups and instances

<!-- categories: Settings -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/integrations/gitlab_slack_application.md#from-the-project-or-group-settings) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/391526)

{{< /details >}}

Previously, you could configure the GitLab for Slack app for one project at a time only. With this release, it’s now possible to configure the integration for groups or instances and make changes to many projects at once.

This improvement brings the GitLab for Slack app closer to feature parity with the deprecated [Slack notifications integration](../../user/project/integrations/slack.md).

### Configurable import jobs limit

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/settings/import_and_export_settings.md#maximum-number-of-simultaneous-import-jobs) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/439286)

{{< /details >}}

Until now, the maximum number of import jobs for:

- GitHub importer was 1000.
- Bitbucket Cloud and Bitbucket Server importers was 100.

These limits were hard-coded and couldn’t be changed. These limits might have slowed down imports, because they might have been insufficient
to allow the import jobs to be processed at the same rate they were enqueued.

In this release, we’ve moved the hard-coded limits to application settings. Although we are not increasing these limits on GitLab.com, administrators
of self-managed GitLab instances can now configure the number of import jobs according to their needs.

### Explore your Product Analytics data with GitLab Duo

<!-- categories: Product Analytics -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/analytics/productivity_analytics.md)

{{< /details >}}

[Product Analytics is now generally available](https://docs.gitlab.com/#understand-your-users-better-with-product-analytics), and this release includes a [custom visualization designer](../../user/analytics/analytics_dashboards.md). You can use it to explore your application event data, and build dashboards to help you understand your customers’ usage and adoption patterns.

In the visualization designer, you can now ask GitLab Duo to build visualizations for you by entering plain text requests, for example "Show me the count of monthly active users in 2024" or "List the top urls this week."

GitLab Duo in Product Analytics is available as an Experimental feature.

You can help us mature this feature by providing feedback about your experience with GitLab Duo in the custom visualization designer in this [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/455363).

## Unified DevOps and Security

### Group comment templates

<!-- categories: Code Review Workflow, Team Planning -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/comment_templates.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/440817)

{{< /details >}}

Across an organization it can be helpful to have the same templated response in issues, epics, or merge requests. These responses might include standard questions that need to be answered, responses to common problems, or maybe structure for merge request review comments.

Group comment templates enable you to create saved responses that you can apply in comment boxes around GitLab to speed up your workflow. This new addition to comment templates allows organizations to create and manage templates centrally, so all of their users benefit from the same templates.

To create a comment template, go to any comment box on GitLab and select **Insert comment template > Manage group comment templates**. After you create a comment template, it’s available for all group members. Select the **Insert comment template** icon while making a comment, and your saved response will be applied.

We’re really excited about this next iteration of comment templates and will also be adding [project-level comment templates](https://gitlab.com/gitlab-org/gitlab/-/issues/440818) soon too. If you have any feedback, please leave it in [issue 45120](https://gitlab.com/gitlab-org/gitlab/-/issues/451520).

### Build step of Auto DevOps upgraded

<!-- categories: Auto DevOps -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../topics/autodevops/troubleshooting.md#builder-sunset-error) | [Related issue](https://gitlab.com/gitlab-org/cluster-integration/auto-build-image/-/issues/73)

{{< /details >}}

Because the `heroku/buildpacks:20` image used by the Auto Build component of Auto DevOps was deprecated upstream, we are moving to the `heroku/builder:20` image.

This breaking change arrives outside a GitLab major release to accommodate a breaking change upstream. The upgrade is unlikely to break your pipelines. As a temporary workaround, you can also manually configure the `heroku/builder:20` image and [skip the builder sunset errors](../../topics/autodevops/troubleshooting.md#skipping-errors).

Additionally, we’re planning another major upgrade from `heroku/builder:20` to `heroku/builder:22` in GitLab 17.0.

### Users list search and filter improvements

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/admin_area.md#administering-users) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/238183)

{{< /details >}}

The Admin Area users page has been improved.

Previously, tabs horizontally spanned across the top of the users list, making it difficult to navigate to the desired filter.

Now, filters have been combined into the search box, making it much easier to search and filter users.

Thank you [Ivan Shtyrliaiev](https://www.linkedin.com/in/bahek2462774/) for your contribution!

### Webhook notifications for expiring group and project access tokens

<!-- categories: System Access -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/integrations/webhook_events.md#project-and-group-access-token-events) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/426147)

{{< /details >}}

Webhook events for project and group access tokens are now available.

Previously, email was the only way to get notifications about expiring tokens. A webhook event, if triggered, will be triggered seven days before an access token expires.

### Display linked Security Policies in Compliance Frameworks

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/compliance_frameworks/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/11480)

{{< /details >}}

As the compliance center becomes the battle station for compliance managers, you can now manage compliance frameworks, and also gain insight into controls that have
been created through security policies and linked to a compliance framework.

Enforce security scanners to run in projects that are in-scope for your compliance, enforce two-person approval, or enable vulnerability management workflows
through these extensive controls and then roll them up to a compliance framework, ensuring relevant projects within the framework are properly enforced by the control.

### Renew application secret with API

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../api/applications.md#renew-an-application-secret) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/422420)

{{< /details >}}

You can now use the Applications API to renew application secrets. Previously, you had to use the UI to do this. Now you can use the API to rotate secrets programatically.

Thank you [Phawin](https://gitlab.com/lifez) for your contribution!

### Extend policy bot comment with violation data

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/433403)

{{< /details >}}

The security policy bot gives users context to understand when policies are enforced on their project, when evaluation is completed, and if there are any violations blocking an MR, with guidance to resolve them. We have now extended support in the bot comment to supply additional insight into why an MR may be blocked by a policy, with more granular feedback on how to resolve. Details provided by the comment include:

- Security findings that are specifically blocking the MR
- Out-of-policy licenses
- Policy errors that may default in a “fail closed” and blocking behavior
- Details regarding the pipelines that are being considered in the evaluation for security findings

With these extra details, you can now more quickly understand the state of your MR and self-serve to troubleshoot any issues.

### Authenticate to Google Cloud with workload identity federation

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../integration/google_cloud_iam.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/12758)

{{< /details >}}

Workload identity federation allows you to securely connect workloads between GitLab and Google Cloud without the use of service account keys. This improves security, because keys can potentially be long-lived credentials that expose a vector for attack. Keys also come with management overhead for creating, securing, and rotating.

Workload identity federation allows you to map IAM roles between GitLab and Google Cloud.

This feature is in Beta and is currently available only on GitLab.com.

### Issue with duplicate security policies resolved

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/416903)

{{< /details >}}

In GitLab 16.9 and earlier, it was possible for a project to both inherit security policies from a parent group or subgroup and link to the same security policies project. The result was that policies were duplicated in the policies list.

This issue has been resolved and it is no longer possible to link to a security policies project from which policies are already inherited.

### More username options

<!-- categories: User Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/_index.md#change-your-username) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/429283)

{{< /details >}}

Usernames can only include non-accented letters, digits, underscores (`_`), hyphens (`-`), and periods (`.`).
Usernames must not start with a hyphen (`-`), or end in a period (`.`), `.git`, or `.atom`.

Username validation now more accurately states this criteria. This improved validation means that you are clearer on your options when choosing your username.

Thank you [Justin Zeng](https://www.linkedin.com/in/jzeng88/) for your contribution!

### Improved GitLab Pages visibility in sidebar

<!-- categories: Pages -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/pages/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/18027)

{{< /details >}}

In previous releases, for projects with a GitLab Pages site, it was difficult to find the site URL.

From GitLab 16.11, the right sidebar has a shortcut link to the site, so you can find the URL without needing to check the docs.

### Connect Google Artifact Registry to your GitLab project

<!-- categories: Container Registry -->

{{< details >}}

- Tier: Free, Silver, Gold
- Links: [Documentation](../../user/project/integrations/google_artifact_management.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/12365)

{{< /details >}}

You use the GitLab container registry to view, push, and pull Docker and OCI images alongside your source code and pipelines. For many GitLab customers, this works great for container images during the `test` and `build` phases. But, it’s common for organizations to publish their production images to a cloud provider, like Google.

Previously, to push images from GitLab to Google Artifact Registry, you had to create and maintain custom scripts to connect and deploy to Artifact Registry. This was inefficient and error prone. In addition, there was no way easy way to get a holistic view of all of your container images.

Now, you can leverage the new Google Artifact Management feature to easily connect your GitLab project to an Artifact Registry repository. Then you can use GitLab CI/CD pipelines to publish images to the Artifact Registry. You can also view images that have published to the Artifact Registry in GitLab by going to **Deploy > Google Artifact Registry**. To view details about an image, simply select an image.

This feature is in Beta and is currently available only on GitLab.com.

### Visually distinguish epics using colors

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/epics/manage_epics.md#epic-color) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9033)

{{< /details >}}

To further improve the ability to use portfolio management features across the organization, you can now distinguish epics using colors on [roadmaps](../../user/group/roadmap/_index.md) and [epic boards](../../user/group/epics/epic_boards.md).

Quickly distinguish between group ownership, stage in a lifecycle, development towards maturity, or a number of other categorizations with this lightweight but versatile feature.

### Value stream events can now be calculated cumulatively

<!-- categories: Value Stream Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/value_stream_analytics/_index.md#cumulative-label-event-duration) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/12088)

{{< /details >}}

We introduced a more robust method for calculating durations between label events. This change accommodates scenarios where events occur multiple times, such as label changes in merge requests back and forth between development to review states. Previously, the duration was calculated as the total time elapsed between the first and last label event.

Now, the duration is calculated as cumulative time, meaning it now correctly represents only the time when an issue or merge request had a given label.

### Dependency graph support for dependency scanning SBOMs

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dependency_list/_index.md) | [Related epic](https://gitlab.com/gitlab-org/gitlab/-/issues/366168)

{{< /details >}}

Users can access dependency graph information in CycloneDX SBOMs generated as a part of their dependency scanning report. Dependency graph information is available for the following package managers:

- NuGet
- Yarn 1.x
- sbt
- Conan

### Dependency Scanning support for Yarn v4

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#supported-languages-and-package-managers) | [Related epic](https://gitlab.com/gitlab-org/gitlab/-/issues/431752)

{{< /details >}}

Dependency Scanning supports Yarn v4. This enhancement allows our analyzer to parse Yarn v4 lockfiles.

### DAST analyzer performance updates

<!-- categories: DAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dast/browser/_index.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/12194)

{{< /details >}}

During the 16.11 release milestone we completed the following DAST improvements:

- Snip navigation paths to improve crawler performance, which reduced scan time by 20% according to our benchmark test. [See the issue](https://gitlab.com/gitlab-org/gitlab/-/issues/430815) for more details.
- Optimize DAST reporting to reduce memory usage, which reduced runner memory spikes during DAST scans. [See the issue](https://gitlab.com/gitlab-org/gitlab/-/issues/444180) for more details.

### Automate the creation of Google Compute Engine Runners from GitLab - Public Beta

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../ci/runners/provision_runners_google_cloud.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13494)

{{< /details >}}

Previously, creating GitLab Runners in Google Compute Engine required multiple context switches from GitLab and Google Cloud.

Now, you can easily provision GitLab Runners in Google Compute Engine with a terraform template from the GitLab Runner Infrastructure Toolkit and GitLab to deploy a GitLab runner and provision the Google Cloud infrastructure - without having to switch between multiple systems.

### Improve automatic retry for failed CI jobs with specific exit codes

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/yaml/_index.md#retry) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/262674)

{{< /details >}}

Previously, you could use `retry:when` in addition to `retry:max` to configure how many times a job is retried
when specific failures occur, like when a script fails.

With this release, you can now use [`retry:exit_codes`](../../ci/yaml/_index.md#retryexit_codes)
to configure automatic retries of failed jobs based on specific script exit codes.
You can use `retry:exit_codes` with `retry:when` and `retry:max` to fine-tune your pipeline’s behavior
according to your specific needs and improve your pipeline execution.

Thanks to [Baptiste Lalanne](https://gitlab.com/BaptisteLalanne) for this community contribution!

### GitLab Runner 16.11

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 16.11 today! GitLab Runner is the lightweight, highly-scalable agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### Bug Fixes

- [Crash: fatal error: concurrent map read and map write](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/31077)
- [FF_KUBERNETES_HONOR_ENTRYPOINT feature not working](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37243)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-11-stable/CHANGELOG.md).

### Expanded Hashicorp Vault Secrets support, including Artifactory and AWS

<!-- categories: Secrets Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/secrets/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/366492)

{{< /details >}}

The GitLab integration with HashiCorp Vault has been expanded to support more types of secrets. You can now select a `generic` type of secrets engine, introduced in GitLab Runner 16.11. This generic engine supports HashiCorp Vault [Artifactory Secrets Plugin](https://jfrog.com/help/r/jfrog-integrations-documentation/hashicorp-vault-artifactory-secrets-plugin) and [AWS secrets engine](https://developer.hashicorp.com/vault/docs/secrets/aws). Use this option to safely retrieve the secrets you need and use them in GitLab CI/CD pipelines!

Thanks so much to [Ivo Ivanov](https://gitlab.com/urbanwax) for this great contribution!

### Control who can download job artifacts

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../ci/yaml/_index.md#artifactsaccess) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/428677)

{{< /details >}}

By default, all generated artifacts from CI/CD jobs in a public pipeline are available for download by all users with access to the pipeline. However, there are cases where artifacts should never be downloaded, or only be accessible for download by team members with a higher access level.

So in this release, we’ve added the `artifacts:access` keyword. Now, users can control whether artifacts can be downloaded by all users with access to the pipeline, only users with the Developer role or higher, or no user at all.

### Improved pipeline details page

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../ci/pipelines/_index.md#view-pipelines)

{{< /details >}}

The pipeline graph offers a comprehensive overview of your pipelines, showing job statuses, runtime updates, multi-project pipelines, and parent-child pipelines.

Today, we’re excited to announce the release of the redesigned pipeline graph with enhanced aesthetics, grouped jobs visualization, improved mobile expirence and expanded downstream pipeline visibility within your existing view.

We’d greatly appreciate it if you could try it out and share your feedback through this dedicated [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/450676).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.11)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.11)
- [UI improvements](https://papercuts.gitlab.com/?milestone=16.11)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
