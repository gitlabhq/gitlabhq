---
stage: Release Notes
group: Monthly Release
date: 2023-07-22
title: "GitLab 16.2 release notes"
description: "GitLab 16.2 released with All new rich text editor experience"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On July 22, 2023, GitLab 16.2 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor

Xing Xin was recognized for a recent merge request to [use quarantined repo for conflict detection](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6008). Karthik Nayak, a Sr. Backend Engineer at GitLab, noted: “Using quarantined repositories allows for avoiding stale objects in git repositories if an operation fails midway. Xing was able to recognize an RPC where we could introduce a quarantine repository and also responded to feedback with good pointers and was able to convince us around some questions with good knowledge about the codebase.”

Xing has been contributing to GitLab and the Gitaly project since 2020. A bytedancer from ByteDance, Xing also spends time in Alibaba Cloud and AntGroup, focusing on code hosting and engineer efficiency. Xing added that the “GitLab community inspired me a lot for both the best practices of managing code and the comments from all the kind reviewers. Hope to grow together with the community.”

Missy Davies is one of the newest members of the [GitLab Heroes](https://contributors.gitlab.com/docs/previous-heroes) program. She was recognized for [many recent contributions](https://gitlab.com/gitlab-org/gitlab/-/merge_requests?scope=all&state=merged&assignee_username=missy-davies) across GitLab projects, including several merge requests for the [Pipeline Execution](https://handbook.gitlab.com/handbook/engineering/development/ops/verify/pipeline-execution/) and [Environments](https://handbook.gitlab.com/handbook/engineering/development/ops/deploy/environments/) groups.

Missy has also been an active member of the GitLab Contributor Community and regularly engages in community events, office hours, and on the Discord server. Both Lee Tickett and Marco Zille, members of the GitLab Community Core Team, highlighted Missy’s engagement with the wider community. Lee added that Missy has been “living our values”.

Missy shared that she has found great enjoyment in her growing involvement in the world of open source at GitLab. She values the strong sense of community, the continuous learning opportunities, and shared passion for open source principles. As a backend developer with experience working with Ruby on Rails and Python, Missy has been an impactful GitLab contributor since 2022.

A big thanks to all of our community contributors this past release 🙌

## Primary features

### All new rich text editor experience

<!-- categories: Team Planning, Portfolio Management, Code Review Workflow -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/rich_text_editor.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10378)

{{< /details >}}

GitLab 16.2 features an all-new rich text editing experience! This new capability is available for everyone, as an alternative to the existing Markdown editing experience.

For many, using the plain text editor for comments or descriptions is a barrier to collaboration. Remembering the syntax for image references or working with long tables can be tedious even for those who are relatively experienced with the syntax. The rich text editor aims to break down these barriers by providing a “what you see is what you get” editing experience and an extensible foundation on which we can build custom editing interfaces for things like diagrams, content embeds, media management, and more.

The rich text editor is now available in all issues, epics and merge requests. We plan to make it available in more places across GitLab soon. You can follow our progress [here](https://gitlab.com/groups/gitlab-org/-/epics/10378).

We are proud of the new editing experience and can’t wait to see what you think. Please try the new rich text editor and let us know about your experience in [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/416293).

### GitLab triggers a Flux synchronization without any configuration

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/clusters/agent/gitops.md#immediate-git-repository-reconciliation) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/392852)

{{< /details >}}

By default, Flux synchronizes Kubernetes manifests at regular intervals. Triggering a reconciliation immediately when a manifest changes by default requires additional configuration. With the GitLab agent for Kubernetes, you can push a change to your manifest and trigger a Flux sync automatically.

### Support for Keyless Signing with Cosign

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Silver, Gold
- Links: [Documentation](../../ci/yaml/signing_examples.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/10254)

{{< /details >}}

Properly storing, rotating, and managing signing keys can be difficult and typically requires the overhead of managing a separate Key Management System (KMS). GitLab now supports keyless signing through a native integration with the Sigstore Cosign tool which allows for easy, convenient, and secure signing within the GitLab CI/CD pipeline. Signing is done using a very short-lived signing key. The key is generated through a token obtained from the GitLab server using the OIDC identity of the user who ran the pipeline. This token includes unique claims that certify the token was generated by a CI/CD pipeline.

To begin using keyless signing for your build artifacts, container images, and packages, users only need to add a few lines to their CI/CD file as [shown in our documentation](../../ci/yaml/signing_examples.md).

### Command palette

<!-- categories: Navigation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/search/command_palette.md)

{{< /details >}}

If you’re a power user, using the keyboard to navigate and take action can be frustrating. Now, a new command palette helps you use the keyboard to get more done.

To enable the command palette, open the left sidebar and click **Search GitLab** (🔍) or use the / key.

Type one of the special characters:

- > - Create a new object or find a menu item
- @ - Search for a user
- : - Search for a project
- / - Search for project files in the default repository branch

### GitLab Duo Code Suggestions improvements powered by Google AI

<!-- categories: Code Suggestions -->

{{< details >}}

- Tier: Gold, Silver, Free
- Links: [Documentation](../../user/project/repository/code_suggestions/_index.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/9814)

{{< /details >}}

Code Suggestions now use Google Cloud’s customizable foundation models and open generative AI infrastructure, with generative AI support in Vertex AI.

GitLab Code Suggestions are routed through Google Vertex AI Codey API’s [Data Governance](https://cloud.google.com/vertex-ai/docs/generative-ai/data-governance) and [Responsible AI](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/responsible-ai). As of July 22, Code Suggestions inferences against the currently opened file and has a context window of 2,048 tokens and 8,192 character limits. This limit includes content before and after the cursor, the file name, and the extension type. Learn more about Google Vertex AI [`code-gecko`](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/models).

[The Google Vertex AI Codey APIs](https://cloud.google.com/vertex-ai/docs/generative-ai/code/code-models-overview#supported_coding_languages) directly support: C++, C#, Go, Google SQL, Java, JavaScript, Kotlin, PHP, Python, Ruby, Rust, Scala, Swift, TypeScript. And for infrastructure files, support: Google Cloud CLI, Kubernetes Resource Model (KRM), and Terraform.

We are continuously iterating to improve Code Suggestions. Give it a try and [share your feedback with us](https://gitlab.com/gitlab-org/gitlab/-/issues/405152).

### Track your machine learning model experiments

<!-- categories: MLOps -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/project/ml/experiment_tracking/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125758)

{{< /details >}}

When data scientists create machine learning (ML) models, they often experiment with different parameters, configurations, and feature engineering, so they can improve the performance of the model. The data scientists need to keep track of all of this metadata and the associated artifacts, so they can later replicate the experiment. This work is not trivial, and existing solutions require complex setup.

With machine learning model experiments, data scientists can log parameters, metrics, and artifacts directly into GitLab, giving easy access to their most performant models. This feature is an experiment.

### New customization layer for the Value Streams Dashboard

<!-- categories: Value Stream Management, DORA Metrics -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/analytics/value_streams_dashboard.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/388890)

{{< /details >}}

We added a new configuration file to the [Value Streams Dashboard](https://youtu.be/EA9Sbks27g4) for easier customization of the dashboard’s data and appearance. In this file you can define various settings and parameters, such as title, description, and number of panels and filters. The file is schema-driven and managed with version control systems like Git. This enables tracking and maintaining a history of configuration changes, reverting to previous versions if necessary, and collaborating effectively with team members.

The new configuration also includes the option to filter the metrics by labels. You can adjust the [metrics comparison panel](https://about.gitlab.com/blog/getting-started-with-value-streams-dashboard/) based on your areas of interest, filter out irrelevant information, and focus on the data that is most relevant to your analysis or decision-making process.

## Scale and Deployments

### Group-level wiki now available in Advanced Search

<!-- categories: Global Search -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/search/advanced_search.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/336100)

{{< /details >}}

With this release, we’ve extended Advanced Search to include [group-level wikis](../../user/project/wiki/group.md). Users will now be able to find content in these wikis more easily and quickly than before.

### Omnibus improvements

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- Our version of Redis is updated to the latest stable version, [`7.0.12`](https://raw.githubusercontent.com/redis/redis/7.0/00-RELEASENOTES).
- For fresh installations of GitLab, you can now opt-in to using [PostgreSQL 14](https://www.postgresql.org/docs/14/release-14.html#id-1.11.6.12.4).

### View deployments from Jira issues mentioned in GitLab commits

<!-- categories: Settings -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../integration/jira/development_panel.md#information-displayed-in-the-development-panel) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/300031)

{{< /details >}}

Previously, GitLab deployments were linked from the Jira development panel only when a Jira issue
was mentioned in either the branch or merge request associated with the deployment.
This was often inconvenient for users because it required them to deploy
from merge requests, which is not the typical workflow.

With this release, GitLab deployments also scan for Jira issue mentions in the messages of the
last 5,000 commits made to the branch after the last successful deployment. The GitLab deployment is associated with all of the mentioned Jira issues.

### Automatic deletion of unconfirmed users

<!-- categories: System Access -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/moderate_users.md#automatically-delete-unconfirmed-users) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/352514)

{{< /details >}}

When invitations are sent to an incorrect email address, they can never be confirmed. Previously, administrators had to manually delete these accounts. Now, administrators can turn on automatic deletion of unconfirmed users after a specified number of days. Similarly, on GitLab.com, unconfirmed accounts will be deleted automatically after [the specified number of days](../../user/gitlab_com/_index.md).

### Improved security for feed tokens

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../security/tokens/_index.md#feed-token) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/414257)

{{< /details >}}

Feed tokens have been made more secure by only working for the URL they were generated for. This narrows the scope of feeds that can be read if the token was leaked.

### GitLab for Slack app available on self-managed GitLab

<!-- categories: Settings -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/settings/slack_app.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/358872)

{{< /details >}}

With this release, the GitLab for Slack app is available on self-managed instances. On self-managed GitLab, you can create
a copy of the GitLab for Slack app from a [manifest file](https://api.slack.com/reference/manifests#creating_apps) and
install that copy in your Slack workspace. Each copy is private and not publicly distributable.

To create and configure the app, see [GitLab for Slack app administration](../../administration/settings/slack_app.md).

### Speed up imports from GitHub using multiple access tokens

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/import.md#import-repository-from-github) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/337232)

{{< /details >}}

By default, the GitHub importer uses a single access token when importing projects from GitHub to GitLab. An access token for a user account is typically rate limited to
5000 requests per hour. This can significantly reduce the speed of the importer when:

- Importing multiple small to medium sized projects.
- Importing a single massive project with a lot of data.

With this release, you can pass a list of access tokens to the GitHub importer API so that the API can rotate through them when rate limited.
When using multiple access tokens:

- The tokens cannot be from the same account because they would all share one rate limit.
- Tokens must have the same permissions and sufficient privileges to the repositories to import.

### Sync auditor role with OIDC provider

<!-- categories: User Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/auth/oidc.md#auditor-groups) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/389321)

{{< /details >}}

You can now sync OIDC groups to the `auditor` role in GitLab. This allows automated user lifecycle management facilitated by OIDC to use the `auditor` role, which was previously unsupported in the role mapping.

Thank you [Marin Hannache](https://gitlab.com/mareo) for your contribution!

### Improved sign-in and sign-up pages

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../administration/settings/sign_up_restrictions.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/385651)

{{< /details >}}

The GitLab sign-in and sign-up pages have been improved:

- Two column layout when custom text is present.
- Fixed issue with `Remember me` checkbox with multiple LDAPs.
- Improved dark mode experience.
- Larger single sign-on buttons.
- Moved footer to bottom of page to avoid hiding page elements.
- Language switcher added to the SAML sign-on page.
- Password checks enabled in the registration trial page.

### Backup adds the ability to skip projects

<!-- categories: Backup/Restore of GitLab instances -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/18287)

{{< /details >}}

The built-in backup and restore tool adds the ability to skip specific repositories. The Rake task now accepts a list of comma-separated group or project paths to be skipped during the backup or restore by using the new `SKIP_REPOSITORIES_PATHS` environment variable. This will allow you to skip, for example, stale or archived projects which do not change over time, saving you a) time by speeding up the backup run, and b) space by not including this data in the backup file.
Thanks to [Yuri Konotopov](https://gitlab.com/nE0sIghT) for this [community contribution](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/merge_requests/196)!

### Geo add individual resync and reverification for all components

<!-- categories: Geo Replication, Disaster Recovery -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/geo/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/364727)

{{< /details >}}

Geo adds the ability to resync and reverify individual items for all component types managed by the [self-service framework](../../development/geo/framework.md). Now you can force a resync or reverification operation on any individual item managed by Geo by using the UI. This can help expedite a resync or reverification operation for failed items, or after changes have been applied to fix sync or verification errors.

## Unified DevOps and Security

### Improve Git LFS download performance

<!-- categories: Source Code Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../topics/git/lfs/_index.md)

{{< /details >}}

For instances which store LFS objects in object storage without [proxy download enabled](../../administration/object_storage.md#proxy-download), GitLab now processes LFS requests in bulk. This dramatically improves the performance of downloading a large number of LFS objects.

Previously, due to how LFS objects were fetched, GitLab created many very small requests which checked user permissions and redirected to the object stored externally. This had the potential to cause significant load and a reduction in performance. With this fix, we have reduced load on the primary GitLab instance and provided a faster download experience for our users.

### Install the agent for Kubernetes using extra volumes in the Helm chart

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/clusters/agent/install/_index.md#customize-the-helm-installation) | [Related issue](https://gitlab.com/gitlab-org/charts/gitlab-agent/-/issues/33)

{{< /details >}}

The `agentk` component of the agent for Kubernetes requires a token to authenticate with GitLab. Previously, you could provide the token as-is, or as a reference to the Kubernetes secret that contains the token. However, you might operate in an environment where the secret is already available in a volume, and prefer to mount that volume instead of creating a separate secret. From GitLab 16.2, the GitLab agent Helm chart ships with this added feature thanks to a community contribution from [Thomas Spear](https://gitlab.com/tspearconquest).

### Support for custom CI variables in the Scan Execution Policies editor

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/scan_execution_policies.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9566)

{{< /details >}}

You can now define custom CI variables, including their values, in the Scan Execution Policies editor. CI variables defined in a policy override the matching variables defined in the projects enforced by the policy. For example, a policy may define a CI Variable `SAST_EXCLUDED_ANALYZERS` to `brakeman`. When the scanner is enforced in a project, the scanner will run with the variable set to `brakeman` regardless of any variables defined in the project’s CI configuration. For each scan type, you can define values for default variables, also create custom key-value pairs for custom CI variables. This makes customizing a scan execution policy quicker and easier.

### Allow scan execution policies to enable CI/CD pipelines in development projects

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/scan_execution_policies.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/6880)

{{< /details >}}

In previous GitLab versions, security policies were not enforced on projects without a `.gitlab-ci.yml` file, or where AutoDevOps was disabled. In GitLab 16.2, security policies implicity enable CI/CD pipelines on projects that do not contain a `.gitlab-ci.yml` file. This is another step in ensuring compliance of security policies and allow you to enforce secret detection, static analysis, or any other jobs where builds are not required.

### Target "Default" or "Protected" branches in security policies

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#scan_finding-rule-type) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9468)

{{< /details >}}

Scan execution and scan result policies will allow you to scope enforcement to branches that are “Default” branches or “Protected branches” across the many projects a policy is enforcing. Rather than requiring policies to specify branch names explicitly, policies can be enforced more broadly and ensure branches with atypical names are not excluded from compliance.

Branch rules can be configured across our various security policy rule types by using the `branch_type` field:

- [Scan_finding rule types for scan result policies](../../user/application_security/policies/merge_request_approval_policies.md#scan_finding-rule-type)
- [License_finding rule types for scan result policies](../../user/application_security/policies/merge_request_approval_policies.md#license_finding-rule-type)
- [Pipeline rule types for scan execution policies](../../user/application_security/policies/scan_execution_policies.md#pipeline-rule-type)
- [Schedule rule types for scan execution policies](../../user/application_security/policies/scan_execution_policies.md#schedule-rule-type)

### Audit event streaming to Google Cloud Logging

<!-- categories: Audit Events -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

You can now select Google Cloud Logging as a destination for audit event streams.

Previously, you had to use the headers to try to build a request that Google Cloud Logging would accept. This method was prone to errors and
could be difficult to troubleshoot.

Now, you can select Google Cloud Logging as the destination for the stream and provide your project ID, client email, log ID, and private
key to allow for a more seamless integration.

### Compliance frameworks report export

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/compliance_center/compliance_projects_report.md#export-a-report-of-compliance-frameworks-on-projects-in-a-group)

{{< /details >}}

You can now export a report of compliance frameworks and their associated projects to a CSV file.

With the addition of the compliance frameworks report at the group level, you were able to see and
manage which projects your compliance frameworks applied to.

With the new export, you can keep a copy of that file for reference. You might keep the file as a
single source of truth for the ideal state of your project and compliance framework relationships. Or you
might send the file people in your organization who may not work in GitLab, but have an interest in seeing
which projects are tagged with which frameworks.

### Group/Sub-Group Level Dependency List

<!-- categories: Dependency Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dependency_list/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/8090)

{{< /details >}}

When reviewing a list of dependencies, it is important to have an overall view.
Managing dependencies at the project level is problematic for large organizations that want to audit their dependencies across all their projects.
With this release, you can see all dependencies at the project or group level, including subgroups. This feature is off by default behind feature flag `group_level_dependencies`.

### Allow initial push to protected branches

<!-- categories: Compliance Management, Source Code Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/repository/branches/default.md#protect-initial-default-branches)

{{< /details >}}

In previous versions of GitLab, when a default branch was fully protected, only project maintainers and owners could push an initial commit to a default branch.

This caused problems for developers who created a new project, but couldn’t push an initial commit to it because only the default branch existed.

With the **Fully protected after initial push** setting, developers can push the initial commit to the default branch of a repository, but cannot push
any commits to the default branch afterward. Similar to when a branch is fully protected, project maintainers can always push to the default branch but no one
can force push.

### Instance-level streaming audit events

<!-- categories: Audit Events -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

Before GitLab 16.1, only audit events from top-level groups could be streamed to an external destination.

Now, instance administrators can add a streaming destination for audit events produced at the instance level.

### Streaming audit event filtering UI

<!-- categories: Audit Events -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

In previous version of GitLab, you had to use the GraphQL API to add audit event type filters to your audit event streams.

Now, you can use the filter dropdown in the GitLab UI to see all the available audit event types, grouped by the
area of GitLab to which they are relevant, and search for the exact types you want to send in a stream.

This significantly reduces the time needed to add filtering to audit event streams because you no longer have to pull the entire list using the API and
search through the list manually.

### Interactive diff suggestions in merge requests

<!-- categories: Team Planning, Portfolio Management, Code Review Workflow -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/project/merge_requests/reviews/suggestions.md#using-the-rich-text-editor) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/406726)

{{< /details >}}

When you suggest changes in a merge request, you can now edit your suggestions more quickly. In a comment, switch to the rich text editor and use the UI to move up and down the lines of text. With this change, you can view your suggestions exactly as they will appear when the comment is posted.

The rich text editor is a new way of editing in GitLab. It’s available in merge requests, but also available alongside the plain text editor in issues and epics.

We plan to have the rich text editor available in more areas of GitLab soon and we are actively working on that. You can follow our progress [here](https://gitlab.com/groups/gitlab-org/-/epics/10378).

### Import PyPI packages with CI/CD pipelines

<!-- categories: Package Registry -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/packages/package_registry/_index.md#to-import-packages) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/389339)

{{< /details >}}

Have you been thinking about moving your PyPI repository to GitLab, but haven’t been able to invest the time to migrate? In this release, GitLab is launching the first version of a PyPI package importer.

You can now use the Packages Importer tool to import packages from any PyPI-compliant registry, like Artifactory.

### Add emoji reactions to comments on uploaded designs

<!-- categories: Design Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/emoji_reactions.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/29756)

{{< /details >}}

You can now express your thoughts more creatively by adding emoji
reactions to comments in [Design Management](../../user/project/issues/design_management.md).
This feature adds a touch of fun and ease to collaboration, fostering better
communication and enabling teams to provide quick feedback in a more expressive
way.

### SAST analyzer updates

<!-- categories: SAST -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/analyzers.md) | [Related issue](../../user/application_security/_index.md)

{{< /details >}}

GitLab SAST includes [many security analyzers](../../user/application_security/sast/_index.md#supported-languages-and-frameworks) that the GitLab Static Analysis team actively maintains, updates, and supports.

During the 16.2 release milestone, our changes focused on the Semgrep-based analyzer and the GitLab-maintained rules it uses for scanning. We released the following changes:

- Clarified the explanation and guidance for JavaScript rules, building on [improvements for other languages released in GitLab 16.1](https://about.gitlab.com/releases/2023/06/22/gitlab-16-1-released/#clearer-guidance-and-better-coverage-for-sast-rules)
- Updated rules to find additional vulnerabilities in Java and JavaScript.
- Changed the default configuration for which files are ignored in scans by:
  - Removing `.gitignore` exclusion. Thanks to [`@SimonGurney`](https://gitlab.com/SimonGurney) for this community contribution.
  - Respecting locally-defined `.semgrepignore` files. Thanks to [`@hmrc.colinameigh`](https://gitlab.com/hmrc.colinameigh) for this community contribution.
- Improved a rule related to Go memory aliasing. Thanks to [`@tyage`](https://gitlab.com/tyage) for this community contribution.
- Removed a `-1` suffix added to the Semgrep rule IDs for JavaScript rules. This was added in GitLab 16.0 as a side-effect of an unrelated change, but interfered with customers’ existing `semgrepignore` comments.

See the [`semgrep` CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/CHANGELOG.md#v440) and [`sast-rules` CHANGELOG](https://gitlab.com/gitlab-org/security-products/sast-rules/-/blame/main/CHANGELOG.md) for further details.
We’re tracking further improvements to GitLab-managed rulesets in [epic 10907](https://gitlab.com/groups/gitlab-org/-/epics/10907).

If you [include the GitLab-managed SAST template](../../user/application_security/sast/_index.md) ([`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)) and run GitLab 16.0 or higher, you automatically receive these updates.
To remain on a specific version of any analyzer and prevent automatic updates, you can [pin its version](../../user/application_security/sast/_index.md).

For previous changes, see [last month’s updates](https://about.gitlab.com/releases/2023/06/22/gitlab-16-1-released/#sast-analyzer-updates).

### Secret Detection updates

<!-- categories: Secret Detection -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/secret_detection/_index.md) | [Related issue](../../user/application_security/_index.md)

{{< /details >}}

We regularly release updates to the GitLab Secret Detection analyzer. During the GitLab 16.2 milestone, we:

- Added [GitLab-managed detection rules](../../user/application_security/secret_detection/_index.md) for:
  - OpenAI API keys.
  - CircleCI Personal and Project access tokens. Thanks to [`@nathanwfish`](https://gitlab.com/nathanwfish) for this community contribution.
- Improved performance of rules that use the `keywords` optimization.
- Fixed [an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/358073) where Secret Detection results created permalinks to the wrong location in the repository.

See the [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/CHANGELOG.md#v514) for further details.

If you [use the GitLab-managed Secret Detection template](../../user/application_security/secret_detection/_index.md) ([`Secret-Detection.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/Secret-Detection.gitlab-ci.yml)) and run GitLab 16.0 or higher, you automatically receive these updates.
To remain on a specific version of any analyzer and prevent automatic updates, you can [pin its version](../../user/application_security/secret_detection/_index.md).

For previous changes, see [the most recent Secret Detection update](https://about.gitlab.com/releases/2023/05/22/gitlab-16-0-released/#secret-detection-updates).

### Support for NuGet v2 in Dependency and License Scanning

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/398680)

{{< /details >}}

In addition to NuGet `v1` lock files, GitLab Dependency and License Scanning both now support analyzing dependencies defined in NuGet `v2` lock files.

### Improved SAST vulnerability tracking

<!-- categories: SAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/5144)

{{< /details >}}

GitLab SAST [Advanced Vulnerability Tracking](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking) makes triage more efficient by keeping track of findings as code moves.
We’ve released two improvements in GitLab 16.2:

1. Expanded language support: Advanced Vulnerability Tracking is now enabled for C#.
1. Better tracking: We’ve improved the tracking algorithm to handle whitespace and comments better in C, C#, Go, Java, JavaScript, and Python. We’ve also fixed issues with tracking certain Go functions.

We’re tracking further improvements, including expansion to more languages, better handling of more language constructs, and improved tracking for Python and Ruby, in [epic 5144](https://gitlab.com/groups/gitlab-org/-/epics/5144).

These changes are included in [updated versions](https://docs.gitlab.com/#sast-analyzer-updates) of GitLab SAST [analyzers](../../user/application_security/sast/analyzers.md).
Your project’s vulnerability findings are updated with new tracking signatures after the project is scanned with the updated analyzers.
You don’t have to take action to receive this update unless you’ve [pinned SAST analyzers to a specific version](../../user/application_security/sast/_index.md).

### CI/CD: Support for `when: never` on conditional includes

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/yaml/includes.md#include-with-rulesif) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/348146)

{{< /details >}}

[`include`](../../ci/yaml/_index.md#include) is one of the most popular keywords to use when writing a full CI/CD pipeline. If you are building larger pipelines, you are probably using the `include` keyword to bring external YAML configuration into your pipeline.

In this release, we are expanding the power of the keyword so you can use `when: never` when using [`rules` with `include`](../../ci/yaml/includes.md#use-rules-with-include). Now, you can decide when external CI/CD configuration will be excluded when a specific rule is satisfied. This will help you write a standardized pipeline with better ability to dynamically modify itself based on the conditions you choose.

### Medium SaaS runners on Linux available to all tiers

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Tier: Free, Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../ci/runners/hosted_runners/linux.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/418124)

{{< /details >}}

We have now made our medium [GitLab SaaS runner on Linux](../../ci/runners/hosted_runners/linux.md) with 4 vCPUs and 16 GB RAM available to all tiers.

Previously users on the Free tier were only able to use our small Linux runner, sometimes causing longer CI/CD execution times.
We are excited to see our Free users accelerate their pipeline speeds.

### GitLab Runner 16.2

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 16.2 today! GitLab Runner is the lightweight, highly-scalable agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s new

- [Retry all k8s API calls in the runner Kubernetes executor](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/4143)

#### Bug Fixes

- [CI job scripts do not complete when dockerd or any process runs in the background](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2880)
- [GitLab-runner-helper servercore image missing for v16.1.0](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/33918)
- [Error:could not create cache adapter](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/3802)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-2-stable/CHANGELOG.md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.2)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.2)
- [UI improvements](https://papercuts.gitlab.com/?milestone=16.2)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
