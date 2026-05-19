---
stage: Release Notes
group: Monthly Release
date: 2025-04-17
title: "GitLab 17.11 release notes"
description: "GitLab 17.11 released with Customize compliance frameworks with requirements and compliance controls"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On April 17, 2025, GitLab 17.11 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Heidi Berry

For 17.11, we’re delighted to recognize [Heidi Berry](https://gitlab.com/heidi.berry) as our Notable Contributor!

Heidi has been a standout contributor to the [GitLab Terraform Provider](https://gitlab.com/gitlab-org/terraform-provider-gitlab) and [client-go](https://gitlab.com/gitlab-org/api/client-go) projects. Over the past several releases, she has consistently delivered highly requested features including the ability to use [custom roles with Group SAML links](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/1949), support for setting [branch protection defaults for group](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/2113), and automatic [token rotation for service account tokens](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/2206).

Beyond feature development, Heidi has been instrumental in maintenance activities - [helping with issue backlog refinement](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/issues/1035#note_2305643918), [updating older tests for improved readability](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/2298), and [enhancing documentation with better examples](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/2201). Her contributions to client-go are particularly valuable as this library powers many downstream projects that both customers and GitLab use to interact with GitLab, including the Terraform provider and glab.

“If you have ever wanted to try your hand at open source contributing, try out client-go and terraform-provider-GitLab,” says Heidi. “They have great documentation to get you started, and supportive maintainers ready to help. I have enjoyed using these projects to learn the go language in a practical way.”

Heidi was nominated by another community contributor, [Patrick Rice](https://gitlab.com/PatrickRice), who is an Enterprise Architect at Kingland and member of the GitLab community Core Team. Patrick says: “With over 100 merged contributions so far across the 17 release cycle and more issue comments, Heidi has been a great help to GitLab and Terraform. Thank you so much for your contributions!”

“Heidi does phenomenal work,” said [Timo Furrer](https://gitlab.com/timofurrer), Senior Backend Engineer in Deploy::Environments at GitLab. “She regularly goes the extra mile and implements the necessary SDK code in client-go. Heidi not only contributes a lot of code, but also helps with issue triaging. It’s an immense help and it’s the reason community-driven projects like these can sustain.”

Heidi is a Lead Software Engineer at The Co-operative Group, where she helps make developer experience efficient, secure and as effortless as possible.

Thank you, Heidi, for your tremendous contributions to GitLab!

## Primary features

### Customize compliance frameworks with requirements and compliance controls

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/compliance_center/compliance_status_report.md)

{{< /details >}}

Previously, compliance frameworks in GitLab could be created as a label to identify that your project has certain
compliance requirements or needs additional oversight. This label could then be used as a scoping mechanism to
ensure that security policies could be enforced on all projects within a group.

In this release, we are introducing a new way for compliance managers to get more in-depth compliance monitoring
in GitLab through ‘requirements’.

With requirements, as part of a custom compliance framework, you can define specific requirements from a number of
different compliance standards, laws, and regulations that must be followed as an organization.

We are also expanding the number of compliance controls (previously known as compliance checks) that we offer from
five to over 50! These 50 out-of-the-box (OOTB) controls can be mapped to the compliance framework requirements.

These controls check particular project, security, and merge request settings across your GitLab instance to help
you meet requirements under a number of different compliance standards, laws, and regulations such as SOC2, NIST,
ISO 27001, and the GitLab CIS Benchmark.

Adherence to these controls is reflected in standard adherence report, which is redesigned to take into account
requirements and the mapping of controls to those requirements.

In addition to expanding our OOTB controls, we now allow users to map requirements to external controls, which can
be for items, programs, or systems that exist outside the GitLab platform. These mappings allow you to use the
GitLab compliance centre as the single source of truth when it comes to your compliance monitoring and audit
evidence needs.

### GitLab Eclipse plugin available in beta

<!-- categories: Editor Extensions -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](https://docs.gitlab.com/editor_extensions/eclipse/setup/) | [Related epic](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/89)

{{< /details >}}

We’re thrilled to announce the beta release of the GitLab Eclipse plugin, now available in the [Eclipse Marketplace](https://marketplace.eclipse.org/content/gitlab-eclipse). This powerful new plugin extends GitLab’s Duo features directly into your Eclipse IDE, giving you seamless access to Duo Chat and AI-powered code suggestions.

As the plugin is currently in beta, we’re actively improving features, including expanding authentication options, and refining the final user experience. Your feedback is invaluable. Please share your thoughts to help us make the GitLab Eclipse plugin even better by adding your feedback [in issue 162](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/162).

### More GitLab Duo features now available on GitLab Duo Self-Hosted

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/_index.md#feature-versions-and-status) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/17072)

{{< /details >}}

You can now use more [GitLab Duo](https://about.gitlab.com/gitlab-duo/) features with GitLab Duo Self-Hosted in your GitLab Self-Managed instance. The following features are available in beta:

- [Root Cause Analysis](../../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)
- [Vulnerability Explanation](../../user/application_security/analyze/duo.md)
- [Vulnerability Resolution](../../user/application_security/vulnerabilities/_index.md#vulnerability-resolution)
- [AI Impact Dashboard](../../user/analytics/duo_and_sdlc_trends.md)
- [Discussion Summary](../../user/discussions/_index.md#summarize-issue-discussions-with-gitlab-duo-chat)
- [Merge Request Commit Message](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message)
- [Merge Request Summary](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes)
- [GitLab Duo for the CLI](https://docs.gitlab.com/editor_extensions/gitlab_cli/#gitlab-duo-for-the-cli)

[Code Review Summary](../../user/project/merge_requests/duo_in_merge_requests.md#summarize-a-code-review) is also available on GitLab Duo Self-Hosted as an experiment.

### Extension marketplace for Web IDE on self-managed instances

<!-- categories: Web IDE -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../administration/settings/vscode_extension_marketplace.md)

{{< /details >}}

We’re thrilled to announce the launch of the extension marketplace in the Web IDE for self-managed users. With the extension marketplace, you can discover, install, and manage third-party extensions to enhance your development experience.

By default, the GitLab instance is configured to use the Open VSX extension registry. To activate this, follow the [enable with default extension registry](../../administration/settings/vscode_extension_marketplace.md#enable-the-extension-registry) steps.

If you want to use your own or custom registry, you also have the option to [connect a custom extension registry](../../administration/settings/vscode_extension_marketplace.md#modify-the-extension-registry). This provides you with more flexibility to manage available extensions.

After enabling the extension marketplace, individual users must still opt in to use it. They can do this by going to the **Integrations** section in their [Preferences](https://gitlab.com/-/profile/preferences) settings.

It’s important to note that some extensions require a local runtime environment and are not compatible with the web-only version. Despite this, you can still choose from thousands of available extensions to boost your productivity and customize your workflow.

### GitLab Duo with Amazon Q is generally available

<!-- categories: Code Suggestions -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/duo_amazon_q/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16879)

{{< /details >}}

We’re excited to announce general availability for GitLab Duo with Amazon Q, a joint offering that brings together the comprehensive GitLab AI-powered DevSecOps platform with autonomous Amazon Q AI agents in a single, integrated solution. GitLab Duo with Amazon Q integrates AI agents directly into development workflows, allowing developers to accelerate key tasks without switching tools. Acting as intelligent assistants within the GitLab DevSecOps platform, these agents automate time-consuming processes like code generation, testing, reviews, and Java modernization, helping teams focus on innovation while maintaining security and quality standards.

GitLab Duo with Amazon Q provides major benefits for development teams:

- Streamline feature development from idea to code: use `/q dev`, which will convert an issue description directly into merge-ready code in minutes.
- Modernize legacy code without the headache: use `/q transform` to automate the entire Java modernization process.
- Accelerate code reviews without sacrificing quality: use `/q review` to get instant, intelligent feedback on code quality and security directly in merge requests.
- Automate testing to ship with confidence: use `/q test` to generate comprehensive unit tests that understand your application logic.

### Enhance security with protected container tags

<!-- categories: Container Registry -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/packages/container_registry/protected_container_tags.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/523893)

{{< /details >}}

Container registries are critical infrastructure for modern DevSecOps teams. Until now, GitLab users with the Developer role or higher could push and delete any container tag in their projects, creating risks of accidental or unauthorized changes to production-critical container images.

With protected container tags, you now have fine-grained control over who can push or delete specific container tags. You can:

- Create up to five protection rules per project.
- Use RE2 regex patterns to protect tags like `latest`, semantic versions (for example, `v1.0.0`), or stable release tags (for example, `main-stable`).
- Restrict push and delete operations to Maintainer, Owner, or Administrator roles.
- Prevent protected tags from being removed by cleanup policies.

This feature requires the next-generation container registry, which is already enabled by default on GitLab.com. For GitLab Self-Managed instance, you’ll need to enable the [metadata database](../../administration/packages/container_registry_metadata_database.md) to use protected container tags.

### Safeguard your registry with protected Maven packages

<!-- categories: Package Registry -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/packages/package_registry/package_protection_rules.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/323969)

{{< /details >}}

We’re thrilled to introduce support for protected Maven packages to enhance the security and stability of your GitLab package registry. Accidental modification of packages can disrupt the entire development process. With protected packages, you can safeguard your most important dependencies against unintended changes.

In GitLab 17.11, you can now protect Maven packages by creating protection rules. If a package matches a protection rule, only specified users can push new versions of the package. Package protection rules prevent accidental overwrites, improve compliance with regulatory requirements, and reduce the need for manual oversight.

[Protected packages](https://gitlab.com/groups/gitlab-org/-/epics/5574) support for Maven and other package formats are all community contributions from `gerardo-navarro` and the Siemens crew. Thank you, Gerardo, and the rest of the crew from Siemens for their many contributions to GitLab! If you want to learn more about how Gerardo and the Siemens crew contributed this change, check out this [video](https://www.youtube.com/watch?v=5-nQ1_Mi7zg) in which Gerardo shares his learnings and best practices for contributing to GitLab based on his experience as an external contributor.

### Epic, issue, and task custom fields

<!-- categories: Team Planning -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/work_items/custom_fields.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/14904)

{{< /details >}}

With this release, you can configure text, number, single-select,
and multi-select custom fields for issues, epics, tasks, objectives, and key
results. While labels have been the primary way to categorize work items up
to this point, custom fields provide a more user-friendly approach for adding
structured metadata to your planning artifacts.

Custom fields are configured in your top-level group and cascade to all subgroups and projects.
You can map fields to one or more work item types and filter by custom field values in the issues and epics lists.

### New issue look now generally available

<!-- categories: Team Planning -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/issues/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/525547)

{{< /details >}}

As of this release, the new issue look is generally available and replaces the legacy issue experience. Issues now share a common framework with epics and tasks, featuring real-time updates and workflow improvements:

- **Drawer view:** You can open items from lists or boards in a drawer for quick viewing without leaving your current context. A button at the top lets you expand to a full-page view.
- **Change type:** Convert types between epics, issues, and tasks using the “Change type” action (replaces “Promote to epic”)
- **Start date:** Issues now support start dates, aligning their functionality with epics and tasks.
- **Ancestry:** The complete hierarchy is above the title and the Parent field in the sidebar. To manage relationships, use the new quick action commands `/set_parent`, `/remove_parent`, `/add_child`, and `/remove_child`.
- **Controls:** All actions are now accessible from the top menu (vertical ellipsis), which remains visible in the sticky header when scrolling.
- **Development:** All development items (merge requests, branches, and feature flags) related to an issue or task are now consolidated in a single, convenient list.
- **Layout:** UI improvements create a more seamless experience between issues, epics, tasks, and merge requests, helping you navigate your workflow more efficiently.
- **Linked items:** Create relationships between tasks, issues, and epics with improved linking options. Drag and drop to change link types and toggle the visibility of labels and closed items.

### Service accounts UI

<!-- categories: System Access -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/service_accounts.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9965)

{{< /details >}}

You now can use a dedicated space to create and manage service accounts in the GitLab UI. This interface allows you to create, monitor, and control automated access to your GitLab resources. Previously, this functionality was only available in the API.

### Automated Duo Pro and Duo Enterprise seat assignment

<!-- categories: System Access -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/group/saml_sso/group_sync.md#manage-gitlab-duo-seat-assignment) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/502496)

{{< /details >}}

You can now automatically assign a Duo Pro or Duo Enterprise seat to users with SAML Group Sync. As long as the GitLab group has available Duo Pro or Duo Enterprise seats, any user mapped from the identity provider is automatically assigned a seat. This reduces the effort to manage seat assignments.

### CI/CD pipeline inputs

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../ci/inputs/_index.md#for-a-pipeline)

{{< /details >}}

CI/CD variables are essential for dynamic CI/CD workflows, and are used for many things, including as environment variables, context variables, tool configuration, and matrix variables. But developers sometimes rely on CI/CD variables to inject [pipeline variables](../../ci/variables/_index.md#use-pipeline-variables) into pipelines to manually modify pipeline behavior, which have some risks due to the higher precedence of pipeline variables.

In GitLab 17.11 and later, you can now use `inputs` to safely modify pipeline behavior instead of using pipeline variables, including in scheduled pipelines, downstream pipelines, triggered pipelines, and other cases. Inputs provide developers with a more structured and flexible solution for injecting dynamic content at CI/CD job runtime. After you switch to inputs, you can completely [disable access to pipeline variables](../../ci/variables/_index.md#restrict-pipeline-variables).

We’d greatly appreciate it if you could try it out and share your feedback through this dedicated [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/533802).

## Agentic Core

### GitLab Duo Chat now uses Anthropic Claude Sonnet 3.7

<!-- categories: Duo Chat -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/gitlab_duo_chat/examples.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/521034)

{{< /details >}}

GitLab Duo Chat now uses Anthropic Claude Sonnet 3.7 as the base model, replacing Claude 3.5 Sonnet for answering most questions.

Claude 3.7 Sonnet has strongly improved coding and reasoning capabilities, making it even better at explaining code, generating code, processing text data, and answering complex DevSecOps questions. You’ll notice more detailed and accurate Chat responses in these areas.

This upgrade applies to all Chat features, and ensures a consistent and improved experience across the entire Chat interface.

### Open files as context now available on GitLab Duo Self-Hosted Code Suggestions

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../user/project/repository/code_suggestions/context.md#using-open-files-as-context) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16611)

{{< /details >}}

On GitLab Duo Self-Hosted, you can now use [files open in tabs in your IDE](../../user/project/repository/code_suggestions/context.md#using-open-files-as-context) as context when using Code Suggestions.

### Select individual models for AI-powered features on GitLab Duo Self-Hosted

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#select-a-self-hosted-model-for-a-feature) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/17099)

{{< /details >}}

On GitLab Duo Self-Hosted, you can now select and configure individual supported models for each GitLab Duo feature and sub-feature on your GitLab Self-Managed instance.

To leave feedback, go to [issue 524175](https://gitlab.com/gitlab-org/gitlab/-/issues/524175).

### Llama 3 models generally available for GitLab Duo Chat and Code Suggestions

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/15678)

{{< /details >}}

Llama 3 models are now generally available with GitLab Duo Self-Hosted to support GitLab Duo Chat and Code Suggestions.

To leave feedback on using these models with GitLab Duo Self-Hosted, see [issue 523918](https://gitlab.com/gitlab-org/gitlab/-/issues/523918).

### Manage multiple conversations in GitLab Duo Chat

<!-- categories: Duo Chat -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/gitlab_duo_chat/_index.md#have-multiple-conversations) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16108)

{{< /details >}}

Multiple conversations with GitLab Duo Chat is now available in GitLab Self-Managed instances in the web UI. You can create new conversations, browse your conversation history, and switch between conversations without losing context.

For your privacy, conversations with no activity for 30 days are automatically deleted, and you can manually delete any conversation at any time. On GitLab Self-Managed, administrators can reduce how long conversations are retained for.

Share your experience with us in [issue 526013](https://gitlab.com/gitlab-org/gitlab/-/issues/526013).

## Scale and Deployments

### All auto-disabled webhooks now automatically re-enable

<!-- categories: Notifications -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/integrations/webhooks.md#auto-disabled-webhooks) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/396577)

{{< /details >}}

With this release, webhooks that return `4xx` errors are now automatically re-enabled. All errors (`4xx`, `5xx`, or server errors) are treated the same way, allowing for more predictable behavior and easier troubleshooting. This change was announced in [this blog post](https://about.gitlab.com/blog/gitlab-webhooks-get-smarter-with-self-healing-capabilities/).

Failing webhooks are temporarily disabled for one minute, extending to a maximum of 24 hours. After a webhook fails 40 consecutive times, it now becomes permanently disabled.

Webhooks that were permanently disabled in GitLab 17.10 and earlier underwent a data migration.

- For GitLab.com, these changes apply automatically.
- For GitLab Self-Managed and GitLab Dedicated, these changes affect only those instances where the `auto_disabling_webhooks``ops` flag is enabled.

Thanks to [Phawin](https://gitlab.com/lifez) for [this community contribution](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166329)!

### Ghost user contributions auto-mapped during imports

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/import/mapping/post_migration_mapping.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/514014)

{{< /details >}}

Previously, ghost user contributions would create placeholder references that required manual reassignment, creating extra work during migrations.
Now, importers using new [contributions and membership mapping functionality](../../user/import/mapping/post_migration_mapping.md), migration by direct transfer, GitHub, Bitbucket Server and Gitea importers,
handle ghost user contributions more intelligently.
When importing content to GitLab, contributions previously made by the ghost user on
the source instance are now automatically mapped to the ghost user on the destination instance.

This enhancement eliminates the creation of unnecessary placeholder users for ghost user contributions,
reducing clutter in user mapping interface and simplifying the migration process.

### SAML verification for contribution reassignment when importing to GitLab.com

<!-- categories: Importers -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/import/mapping/reassignment.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/513686)

{{< /details >}}

In this milestone, we’ve added SAML verification checks to contribution reassignment when importing to GitLab.com. These checks prevent reassignment errors in groups where SAML SSO is enabled.

If you import to GitLab.com and use SAML SSO for GitLab.com groups, all users must link their SAML identity to their GitLab.com account before you can reassign contributions and memberships.
When you reassign contributions to users who have not verified their SAML identity, you’ll receive error messages. These messages explain the steps to take to help ensure your group memberships are attributed correctly.

### Filter placeholder users in Admin area

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../administration/admin_area.md#administering-users) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/521974)

{{< /details >}}

Previously, placeholder users created during imports appeared mixed with regular users
without clear distinction in the **Admin** area **Users** page.

With this release, administrators can now filter for placeholder accounts from the search box
in the **Users** page in the **Admin** area. To do this, select `Type` in the dropdown list,
then choose `Placeholder`.

### Placeholder user limits appear in group usage quotas

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/import/mapping/post_migration_mapping.md#placeholder-user-limits) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/486691)

{{< /details >}}

For imports to GitLab.com, placeholder users are limited per top-level group. These limits depend on your GitLab license and number of seats. With this release, it’s possible to check your placeholder user usage and limits for a top-level group in the UI.

To view your current usage and limits:

1. On the left sidebar, select **Search or go to** and find your group. This group must be at the top level.
1. Select **Settings > Usage Quotas**.
1. Select the **Import** tab.

### Geo - New replicables view

<!-- categories: Disaster Recovery, Geo Replication -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/geo/_index.md)

{{< /details >}}

We are introducing a new look and feel for the replicables view in Geo. The new experience better aligns with the rest of GitLab and provides a more streamlined and less cluttered interface to review the synchronization and verification status of Geo secondary sites. In addition, there is now a click-through detailed view for each replicable item, providing information such as the primary and secondary checksums, error details, and much more. This information will make troubleshooting Geo synchronization issues much easier.

### Linux package improvements

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/omnibus/) | [Related issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8504)

{{< /details >}}

In GitLab 18.0, the minimum-supported version of PostgreSQL will be version 16. To prepare for this change, on
instances that don’t use [PostgreSQL Cluster](../../administration/postgresql/replication_and_failover.md),
upgrades to GitLab 17.11 will attempt to automatically upgrade PostgreSQL to version 16.

If you use [PostgreSQL Cluster](../../administration/postgresql/replication_and_failover.md) or [opt out of this automated upgrade](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades), you must [manually upgrade to PostgreSQL 16](https://docs.gitlab.com/omnibus/settings/database/#upgrade-packaged-postgresql-server)
to be able to upgrade to GitLab 18.0.

### Pre-deployment opt-out toggle to disable event data sharing

<!-- categories: Application Instrumentation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../administration/settings/event_data.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/510333)

{{< /details >}}

In GitLab 18.0, we plan to enable event-level product usage data collection from GitLab Self-Managed and GitLab Dedicated instances. Unlike aggregated data, event-level data provides GitLab with deeper insights into usage, allowing us to improve user experience on the platform and increase feature adoption.

Starting in GitLab 17.11, you will have the ability to opt out of event data collection before it starts, effectively allowing you to choose participation in advance. For more information and details on how to opt-out please see our documentation.

## Unified DevOps and Security

### Increased rule coverage for secret push protection and pipeline secret detection

<!-- categories: Secret Detection -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/secret_detection/detected_secrets.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/534106)

{{< /details >}}

GitLab secret detection has received significant updates, including 17 new secret push protection rules and 12 new pipeline secret detection rules. Some existing rules have also been updated to improve quality and reduce false positives. For details, see v0.9.0 in the [change log](https://gitlab.com/gitlab-org/security-products/secret-detection/secret-detection-rules/-/blob/main/CHANGELOG.md#v090).

### Static reachability beta with Python support

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dependency_scanning/static_reachability.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/15781)

{{< /details >}}

The Composition Analysis team has released beta support for static reachability for Python. This beta release focuses on enhancing stability, observability, and provides a better user experience via easier configuration.

Static reachability enriches software composition analysis (SCA) results. Powered by GitLab Advanced SAST, static reachability scans project source code to identify which open source dependencies are in use.

You can use the data produced by static reachability as part of your triage and remediation decision making. Static reachability data can also be used with CVSS and EPSS scores, as well as KEV indicators to provide a more focused view of your vulnerabilities.

We welcome feedback on this feature. If you have questions, comments, or would like to engage with our team please see this [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/535498).

### Dynamic analysis support for reflected XSS checks

<!-- categories: DAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dast/browser/checks/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/525861)

{{< /details >}}

The Dynamic Analysis team has introduced a check for [CWE-79](https://cwe.mitre.org/data/definitions/79.html). This work allows our DAST scanner to check for reflected XSS attacks.

Checking for Reflective XSS is on by default. To turn off this check, in you configuration, set `DAST_FF_XSS_ATTACK: false`.
If you have questions or feedback, see [issue 525861](https://gitlab.com/gitlab-org/gitlab/-/issues/525861).

### Use imported files as context in Code Suggestions

<!-- categories: Code Suggestions -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/project/repository/code_suggestions/context.md#using-imported-files-as-context) | [Related epic](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/58)

{{< /details >}}

GitLab Duo Code Suggestions can now use imported files in your IDE to enrich and improve the quality of suggestions. Imported files provide additional context about your project. Imported file context is supported for JavaScript and TypeScript files.

### Assign projects when creating compliance frameworks

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate, Premium
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/compliance_frameworks/_index.md#apply-a-compliance-framework-to-a-project) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/500520)

{{< /details >}}

In the past, you couldn’t assign new compliance frameworks to projects without navigating to the **Projects** tab
in the compliance center after creating the compliance framework. This situation created unnecessary friction to
creating new compliance frameworks in your groups.

In GitLab 17.11, when creating a compliance framework, we introduced a new step that provides the option of
assigning multiple projects to the compliance framework before it is created.

This new feature:

- Helps keep you in the compliance framework creation workflow.
- Provides guidance for you to understand that compliance frameworks work together with projects in a group to
monitor and enforce compliance adherence for the entire group.

### Kubernetes 1.32 support

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/509283)

{{< /details >}}

This release adds full support for Kubernetes version 1.32, released in December 2024. If you deploy your apps to Kubernetes, you can now upgrade your connected clusters to the most recent version and take advantage of all its features.

You can read more about [our Kubernetes support policy and other supported Kubernetes versions](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features).

### Configure SAML single sign-on with multiple identity providers in Switchboard

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- Tier: Gold
- Links: [Documentation](../../administration/dedicated/configure_instance/authentication/saml.md)

{{< /details >}}

You can now configure SAML single sign-on (SSO) for your GitLab Dedicated instance for up to ten identity providers (IdPs).

All SAML configuration options available for GitLab Dedicated instances can be configured for each individual IdP.

If you had previously configured multiple IdPs, you can now view and edit all existing SAML configurations directly in Switchboard.

### Docker Hub authentication UI for the dependency proxy

<!-- categories: Container Registry -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/packages/dependency_proxy/_index.md#authenticate-with-docker-hub) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/521954)

{{< /details >}}

We’re excited to announce UI support for Docker Hub authentication in the GitLab Dependency Proxy. This feature was initially introduced in GitLab 17.10 with GraphQL API support only, and now includes a user interface for easier configuration.

With this enhancement, you can now configure Docker Hub authentication directly from your group settings page, helping you:

- Avoid pipeline failures due to rate limits.
- Access private Docker Hub images.
- Store your Docker Hub credentials, [personal access token](https://docs.docker.com/security/for-developers/access-tokens/), or [organization access tokens](https://docs.docker.com/security/for-admins/access-tokens/) securely.

This streamlined approach makes it easier to maintain uninterrupted access to Docker Hub images in your CI/CD pipelines without using the GraphQL API.

### Set work in progress limits by weight

<!-- categories: Team Planning -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/issue_board.md#work-in-progress-limits) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/119208)

{{< /details >}}

You can now set work in progress limits by weight in addition to issue count, giving you more flexibility in managing your team’s workload.

Control the flow of work based on the complexity or effort of each task, rather than just the number of issues. Teams that use issue weights to represent effort can now ensure they don’t overcommit by limiting the total weight of issues in a given board list.

Use this feature to optimize your team’s productivity and create a more balanced workflow that accounts for varying task complexity.

### Improved wiki sidebar styling

<!-- categories: Wiki -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/wiki/_index.md#customize-sidebar)

{{< /details >}}

The custom wiki sidebar now features improved styling with reduced heading sizes and better left-padding for lists. These ergonomic enhancements improve the readability of custom navigation created through the `_sidebar` wiki page.

Custom sidebars help teams organize their wiki content in a way that makes sense for their unique knowledge base structure. With this styling update, the sidebar is now easier to scan, creating a clearer visual hierarchy that helps team members find relevant information more quickly.

### Display last comment as a column in GLQL views

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/glql/fields.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/512154)

{{< /details >}}

GLQL views now support displaying the last comment on an issue or merge request as a column. By including `lastComment` as a field in your GLQL query, you can see the most recent updates without leaving your current context.

Previously, you had to open each issue or merge request individually to view the last comment, which was time consuming and made it difficult to get a quick overview of progress. This improvement helps teams maintain momentum by providing at-a-glance visibility into ongoing conversations and status updates.

We welcome your feedback on this enhancement and GLQL views in general on our [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/509791).

### Nuxt project template for GitLab Pages

<!-- categories: Pages -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/pages/getting_started/pages_new_project_template.md)

{{< /details >}}

GitLab provides templates for the most popular Static Site Generators (SSGs), and you can now create a GitLab Pages site using Nuxt, a powerful framework built on Vue.js. Nuxt is particularly valuable for teams looking to build modern, performant web applications with less configuration overhead.

This addition expands your options for quickly launching a Pages site with built-in CI/CD pipelines and a modern development experience, without spending time on initial setup and configuration.

### CycloneDX export for the project dependency list

<!-- categories: Dependency Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dependency_list/_index.md#export) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/524733)

{{< /details >}}

Many organizations now require a software bill of materials (SBOM) to meet regulatory requirements and help further increase the security of the software supply chain. Previously, you could only export your dependency list as a JSON or CSV file from GitLab. Now, GitLab can generate your SBOM by exporting your dependency list in the widely-adopted CycloneDX format.

To download an SBOM directly as a CycloneDX file, in the dependency list, select **Export** > **Export as CycloneDX (JSON)**.

### Email delivery for dependency list and vulnerability report export

<!-- categories: Dependency Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dependency_list/_index.md#export) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/513149)

{{< /details >}}

Previously, when exporting the dependency list or the vulnerability report, you had to remain on the page until the export completed before you could download the report.

Now, you are notified by email with a download link when the dependency list or vulnerability report export is complete.

### Export dependency list in CSV format

<!-- categories: Dependency Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dependency_list/_index.md#export) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/435843)

{{< /details >}}

Previously, you could not export a dependency list from GitLab as CSV file. Now, when you download a dependency list, you can select the new CSV option to export the list in this format.

### Tool filter replaced with Scanner and Report Type filters

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/vulnerability_report/_index.md#report-type-filter) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/503371)

{{< /details >}}

Previously, the **tool** search filter in the vulnerability report allowed you to filter results based on a single group of tools that included the type of scanner (like ESLint or Gemnasium) and the type of report (like SAST or container scanning).

To help you find the appropriate tools more easily, we’ve replaced the **tool** filter with the **scanner** filter and the **report type** filter. You can now filter your search based on each of these types of tools separately.

### Store and filter a `source` value for CI/CD jobs

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/jobs.md#retrieve-a-job-by-job-id) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/11796)

{{< /details >}}

GitLab 17.11 introduces a new feature that allows users to verify the origin of build artifacts by tracking the source attribute of CI/CD jobs. This enhancement is particularly valuable for security and compliance workflows. For example, organizations can implement software supply chain security measures or require verifiable evidence of security scans for compliance purposes.

Jobs in GitLab now store and display a `source` value that identifies whether they originated from:

- A scan execution policy
- A pipeline execution policy
- A regular pipeline

You can access the `source` attribute on the **Build** > **Jobs** page with a new filter option, using the Jobs API, or through the ID token `claims` for artifact verification.

With this new feature, you can now:

- Verify the authenticity of security scan results.
- Filter jobs by source type to quickly identify policy-enforced scans.
- Implement cryptographic verification of artifacts using the new ID token claims.
- Ensure compliance requirements are met with proper audit trails.

Security and compliance teams can leverage this feature to:

- View only policy-enforced jobs using the new filter on the Jobs page.
- Automate tasks by accessing the `source` field in the Jobs API.
- Implement artifact verification using the new ID token claims:
  - `job_source`: Identifies the job’s origin.
  - `job_policy_ref_uri`: Points to the policy file (for policy-defined jobs).
  - `job_policy_ref_sha`: Contains the git commit SHA of the policy.

### Enhanced sorting options for access tokens

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/personal_access_tokens.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/519716)

{{< /details >}}

There are now additional sorting options for access tokens in the UI and API. These sorting options complement GitLab’s existing token management capabilities, giving you more control over your access token inventory, and helping you better maintain access token security. The new sorting options include:

- Sort by expiration date (ascending): View the tokens that expire soonest.
- Sort by expiration date (descending): View the tokens with the longest remaining lifetime.
- Sort by last used date (ascending): View the tokens that have not been used recently.
- Sort by last used date (descending): View the tokens used most recently.

### Token statistics for service account management

<!-- categories: System Access -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/service_accounts.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/520472)

{{< /details >}}

The token management interface for service accounts now includes a helpful statistics dashboard that provides at-a-glance information about your token inventory. This information can help you assess the state of your tokens and identify tokens that require attention.
The statistics dashboard includes four key metrics:

- Active tokens: View the total number of active tokens
- Expiring tokens: Identify tokens that expire in the next two weeks
- Revoked tokens: Track tokens that were manually revoked
- Expired tokens: Monitor tokens that have previously expired
Thank you [Chaitanya Sonwane](https://gitlab.com/chaitanyason9) for your contribution!

### Improved pipeline graph visualization for failed jobs

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/pipelines/_index.md#view-pipelines)

{{< /details >}}

You can now quickly identify failed jobs in the pipeline graph with new visual indicators. Failed job groups are highlighted in the pipeline graph, and failed jobs are grouped at the top of each stage. This improved visualization helps you troubleshoot pipeline failures without having to search through complex pipeline structures.

### Force-cancel CI/CD jobs stuck in canceling state

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/jobs/_index.md#force-cancel-a-job) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/467107)

{{< /details >}}

CI/CD jobs can occasionally get stuck in the ‘canceling’ state, blocking deployments or access to shared resources.

Users with the Maintainer [role](../../user/permissions.md) can now force-cancel these stuck jobs directly from the job logs page, ensuring problematic jobs can be properly terminated.

### Improved runner management in projects

<!-- categories: Fleet Visibility -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/runners/runners_scope.md#project-runners)

{{< /details >}}

You can now manage runners more efficiently in your projects. Runners are displayed in a single-column layout and organized in their own lists instead of the previous two-column view.

This improved organization makes it simpler to find and manage runners, with new features including a list of assigned projects, runner managers, and jobs that a runner has run. For information about additional runner management improvements planned for GitLab 18.0, see [issue 33803](https://gitlab.com/gitlab-org/gitlab/-/issues/33803).

### GitLab Runner 17.11

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 17.11 today! GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s new

- [Code sign GitLab Runner Windows executables](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2483)

#### Bug Fixes

- [Cleaning Git configuration in GitLab Runner 17.10.0 results in an error](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38681)
- [The `FF_DISABLE_UMASK_FOR_KUBERNETES_EXECUTOR` flag doesn’t disable the `umask` command](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38382)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-11-stable/CHANGELOG.md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.11)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.11)
- [UI improvements](https://papercuts.gitlab.com/?milestone=17.11)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
