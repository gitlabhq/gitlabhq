---
stage: Release Notes
group: Monthly Release
date: 2025-08-21
title: "GitLab 18.3 release notes"
description: "GitLab 18.3 released with Duo Agent Platform in Visual Studio (Beta)"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On August 21, 2025, GitLab 18.3 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Ahmed Kashkoush

For 18.3, we’re excited to recognize [Ahmed Kashkoush](https://gitlab.com/ahmad-kashkoush) as our
Notable Contributor!

Ahmed has been a standout contributor to the [GitLab Web IDE](https://gitlab.com/gitlab-org/gitlab-web-ide)
through his [Google Summer of Code participation](https://gitlab.com/ahmad-kashkoush/gsoc-2025-final-report) this summer.
He has consistently delivered essential Git operations, directly addressing long-standing
community requests.
His five substantial merge requests include [commit and force push capabilities](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/497),
[update confirmation message](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/540),
[commit amend functionality](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/507),
[branch creation operations](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/534),
and [branch deletion features](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/539).

Beyond implementing new features, Ahmed resolved a 5+ year old feature request for amending existing
commits from the Web IDE, a feature with 24 thumbs up from the community.
His comprehensive branch management implementation brings the Web IDE closer to feature parity with
local development environments, eliminating the need for users to switch between interfaces for
basic Git operations.
Ahmed’s work directly supports [GitLab’s mission](https://handbook.gitlab.com/handbook/company/mission/)
that “everyone can contribute” by making the Web IDE more accessible to developers.

Ahmed was nominated by [Enrique Alcántara](https://gitlab.com/ealcantara), Staff Frontend
Engineer at GitLab, who served as his mentor throughout the Google Summer of Code program.
“Ahmed shows dedication to solving real user pain points,” says Enrique.
“His work demonstrates the impact a focused contributor can have on improving core GitLab functionality.”

Ahmed’s contributions showcase the power of mentorship and community collaboration in open source
development and make GitLab more accessible to developers regardless of their local setup.

Thank you, Ahmed, for your exceptional contributions to GitLab’s Web IDE!

## Primary features

### Duo Agent Platform in Visual Studio (Beta)

<!-- categories: Editor Extensions -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/duo_agent_platform/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/179)

{{< /details >}}

We are excited to announce the public beta release of the Duo Agent Platform for Visual Studio! With this release, Visual Studio users can now access Duo Agent Platform’s advanced AI-powered capabilities directly within their IDE.

The Duo Agent Platform brings two powerful features to your workflow:

- **Agentic chat**: Quickly accomplish conversational tasks such as creating and editing files, searching your codebase with pattern matching and grep, and getting instant answers about your code—all without leaving Visual Studio.
- **Agent flows**: Tackle larger, more complex tasks with comprehensive planning and implementation support. Agent flows help you turn high-level ideas into architecture and code, leveraging GitLab resources like issues, merge requests, commits, CI/CD pipelines, and security vulnerabilities.

Both features offer intelligent search across documentation, code patterns, and project information, empowering you to move seamlessly from quick edits to in-depth project analysis.

Try the Duo Agent Platform beta in Visual Studio today and experience a new level of productivity and AI assistance in your development workflow.

### Embedded views (powered by GLQL)

<!-- categories: Markdown, Wiki, Team Planning -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/glql/_index.md#embedded-views) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/15008)

{{< /details >}}

This release introduces embedded views, powered by GLQL, to general availability. Create and embed dynamic, queryable views of GitLab data directly where your work lives: in wiki pages, epic descriptions, issue comments, and merge requests.

Embedded views provide a stable foundation for teams to track work progress without navigating between multiple locations. Query issues, merge requests, epics, and other work items using familiar syntax, then display the results as tables or lists with customizable fields and filtering.

Embedded views transform static documentation into living dashboards that stay current with your project data, helping teams maintain context and improve collaboration across their workflows.

We welcome your feedback as we continue to enhance embedded views. Please share your thoughts and suggestions in our [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/509792).

### Migration by direct transfer

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/group/import/direct_transfer_migrations.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/11398)

{{< /details >}}

Migration by direct transfer is now generally available. To migrate GitLab groups and projects between GitLab instances by direct transfer, you can use the GitLab UI or the [REST API](../../api/bulk_imports.md).

Compared to [migration by uploading an export file](../../user/project/settings/import_export.md#migrate-projects-by-uploading-an-export-file), direct transfer:

- Works more reliably with large projects.
- Supports migrations with a larger version gap between the source and destination instances.
- Offers better insights into the migration process and results.

On GitLab.com, migration by direct transfer is enabled by default. On GitLab Self-Managed and GitLab Dedicated, an administrator must [enable the feature](../../administration/settings/import_and_export_settings.md#enable-migration-of-groups-and-projects-by-direct-transfer).

### Fine-grained permissions for CI/CD job tokens

<!-- categories: Permissions -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../ci/jobs/fine_grained_permissions.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/15258)

{{< /details >}}

Pipeline security just got more flexible. Job tokens are ephemeral credentials that provide access to resources in pipelines. Until now, these tokens inherited full permissions from the user, often resulting in unnecessarily broad access capabilities.

With our new fine-grained permissions for job tokens feature, you can now precisely control which specific resources a job token can access within your projects. This allows you to implement the principle of least privilege in your CI/CD workflows, granting only the minimal access necessary for jobs to complete their tasks when accessing your projects with the CI/CD job token.

We’re actively working to add [additional fine-grained permissions](https://gitlab.com/groups/gitlab-org/-/epics/6310) to reduce reliance on long-lived tokens in pipelines.

### Code Review available on GitLab Duo Self-Hosted (Beta)

<!-- categories: Code Suggestions, Self-Hosted Models -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/524929)

{{< /details >}}

You can now use GitLab Duo Code Review on GitLab Duo Self-Hosted. This feature is in beta on GitLab Duo Self-Hosted, with support for Mistral, Meta Llama, Anthropic Claude, and OpenAI GPT model families.

Use Code Review on GitLab Duo Self-Hosted to accelerate your development process without compromising on data sovereignty. When Code Review reviews your merge requests, it identifies potential bugs and suggests improvements for you to apply directly. Use Code Review to iterate on and improve your changes before you ask a human to review.

Provide feedback on Code Review in [issue 517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386).

### Customize instructions for GitLab Duo Code Review

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Add-ons: Duo Enterprise
- Links: [Documentation](../../user/project/merge_requests/duo_in_merge_requests.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/545136)

{{< /details >}}

Enforce consistent code review standards across your projects with custom instructions for GitLab Duo Code Review. Define specific review criteria for different file types using glob patterns, ensuring language-specific conventions are applied where they matter most.

With custom instructions, you can:

- Describe your team’s code review standards
- Use glob patterns to define file-specific instructions
- Observe clearly labeled feedback that references your custom instructions

Simply create a `.GitLab/duo/mr-review-instructions.YAML` file in your repository with your custom instructions. GitLab Duo will automatically incorporate these instructions into its reviews, citing the specific instruction group when providing feedback.

Help us improve this feature by sharing your thoughts and suggestions in our [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/517386).

### Bring your own models to GitLab Duo Self-Hosted (Beta)

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/517581)

{{< /details >}}

GitLab Duo Self-Hosted now enables you to bring your own model to use with GitLab Duo features. This feature is in beta, and available to all GitLab Self-Managed customers with GitLab Duo Enterprise. Instance administrators can configure any compatible model for use with a supported GitLab Duo feature.

This feature makes GitLab Duo Self-Hosted more flexible, but GitLab cannot guarantee that all GitLab Duo features will work with every compatible model. Instance administrators are responsible for validating the compatibility and performance of their chosen model. GitLab does not provide technical support for issues specific to your chosen model or platform.

### Hybrid model selection on GitLab Duo Self-Hosted (Beta)

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/17192)

{{< /details >}}

You can now use a mix of GitLab AI vendor models and privately configured self-hosted models on GitLab Duo Self-Hosted. This feature is in beta and available on GitLab Self-Managed to all GitLab Duo Enterprise customers.

With hybrid models on GitLab Duo Self-Hosted, GitLab Self-Managed instance administrators can now choose between a self-hosted model and self-hosted AI gateway, or a GitLab AI vendor model and the GitLab-hosted AI gateway, on a feature-by-feature basis. This enables administrators to balance their security and scalability requirements. To provide feedback on hybrid model selection, see [issue 561048](https://gitlab.com/gitlab-org/gitlab/-/issues/561048).

### Surfacing violations of compliance framework controls (Beta)

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/compliance/compliance_center/compliance_violations_report.md)

{{< /details >}}

Previously, the compliance violations report provided a high-level view of merge request activity for all projects
in a group. The available compliance violations related to separation of duty concerns, such as:

- Detecting when an author of a merge request approved their own merge request.
- When a merge request was merged with fewer than two approvals.

However, user feedback revealed that users found violation classifications confusing and difficult to understand, due to not aligning well with actual compliance use cases.

GitLab 18.3 significantly enhances the violations report by expanding beyond separation of duty to include violations of compliance controls and requirements in compliance frameworks.
Each custom compliance framework control has an associated audit event that provides detailed context about violations: who committed the violation, when it occurred, and how to fix it.
This includes the user’s name and IP address, plus actionable remediation suggestions.

These improvements give compliance managers more powerful and relevant context to ensure their organization adheres to specific compliance frameworks,
while providing reassurance that non-compliance can be effectively identified, rectified, and prevented.

### New Web IDE source control operations

<!-- categories: Web IDE -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/project/web_ide/_index.md#use-source-control)

{{< /details >}}

We’re excited to announce additional source control functionalities in the Web IDE. You can manage your Git workflow more efficiently without leaving your browser. In the **Source Control** panel, you can now:

- Create and delete branches.
- Create a branch from any existing branch as your base.
- Amend your last commit for quick fixes.
- Force push changes directly from the interface.

These enhancements bring Git operations right to your fingertips. For information about the functionalities available to you, see [Use source control](../../user/project/web_ide/_index.md#use-source-control).

### AWS Secrets Manager support for GitLab CI/CD

<!-- categories: Secrets Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../ci/secrets/aws_secrets_manager.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/17822)

{{< /details >}}

Secrets stored in AWS Secrets Manager can now be easily retrieved and used in CI/CD jobs. Our new integration with AWS simplifies the process of interacting with AWS Secrets Manager through GitLab CI/CD, helping our AWS customers streamline build and deploy processes!

Thank you to [Markus Siebert](https://gitlab.com/m-s-db) and [Henry Sachs](https://gitlab.com/DerAstronaut) who helped build this feature through [GitLab’s Co-Create program](https://about.gitlab.com/community/co-create/)!

### Custom admin role

<!-- categories: Permissions -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../user/custom_roles/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/15069)

{{< /details >}}

The custom admin role brings granular permissions to the Admin area for GitLab Self-Managed and GitLab Dedicated instances. Instead of granting full access, administrators can now create specialized roles that access only the specific functions needed by users. This feature helps organizations implement the principle of least privilege for administrative functions, reduce security risks from overprivileged access, and improve operational efficiency.

If you have questions, want to share your implementation experience, or would like to engage directly with our team about potential improvements, see the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/509376).

## Agentic Core

### More models available for use with GitLab Duo Self-Hosted

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/560016)

{{< /details >}}

GitLab Self-Managed customers with GitLab Duo Enterprise can now use Anthropic Claude 4 with GitLab Duo Self-Hosted.
Claude 4 is supported on AWS Bedrock. Open source OpenAI GPT OSS 20B and 120B have been added as experimental models,
and are available on vLLM, Azure OpenAI, and AWS Bedrock. To leave feedback on using these models with GitLab Duo Self-Hosted,
see [issue 523918](https://gitlab.com/gitlab-org/gitlab/-/issues/523918).

## Scale and Deployments

### New navigation experience for groups in Your work

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/group/_index.md#group-visibility) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/502487)

{{< /details >}}

We’re excited to announce significant improvements to the group overview in **Your work**, designed to streamline how you discover and access your groups.
The new tabbed interface features a **Member** tab, which provides a comprehensive view of accessible groups, and an **Inactive** tab to track groups pending deletion.
We’ve also streamlined group management by adding **Edit** and **Delete** actions to the list view for users with appropriate permissions.
We hope that these improvements make it easier to find and manage the groups that matter most to you.

We value your feedback on this update! Join the discussion in [epic 18401](https://gitlab.com/groups/gitlab-org/-/epics/18401) to share your experience with the new navigation system.

### Enhanced **Admin** area projects list

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../administration/admin_area.md#administering-projects) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/17782)

{{< /details >}}

We’ve upgraded the **Admin** area projects list to provide a more consistent experience for GitLab administrators:

- Delayed deletion protection: Project deletions now follow the same safe deletion flow used throughout GitLab, preventing accidental data loss.
- Faster interactions: Filter, sort, and paginate projects without page reloads for a more responsive experience.
- Consistent interface: The projects list now matches the look and behavior of other project lists across GitLab.

This update brings the administrator experience in line with GitLab design standards, and adds important safety features to protect your data. Future enhancements to project management will automatically appear in all project lists throughout the platform.

## Unified DevOps and Security

### Improved file location information for Dependency Scanning analyzer

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#customizing-behavior-with-the-cicd-template) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/537716)

{{< /details >}}

Being able to trace a dependency back to its source is important, especially for
vulnerability remediation. Previously, the Dependency Scanning analyzer sometimes
linked to job artifacts which were deleted when they expired. This made it
difficult to trace back to the source of the dependency.
The Dependency Scanning analyzer can now link to the project file that introduced
the dependency. With this option enabled, links in the dependency list and
vulnerability report are reliable.
Users may enable this functionality by setting `DS_FF_LINK_COMPONENTS_TO_GIT_FILES=true`
for the Dependency Scanning job.

### User-defined source for license information

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md#use-cyclonedx-report-as-a-source-of-license-information) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/501662)

{{< /details >}}

Users may now choose which source of license information has priority -
the GitLab License database or a CycloneDX SBOM report. This provides users
with more flexibility in sourcing license information for their open-source dependencies.
Users who wish to define the source of license information may
use the [Security Configuration UI](../../user/application_security/detect/security_configuration.md#with-the-ui) to make a selection. By default we use the SBOM data as a source
for license information.

### Concise DAST job output

<!-- categories: DAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/dast/browser/troubleshooting.md#what-is-dast-doing) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/18342)

{{< /details >}}

GitLab 18.3 introduces several improvements to the dynamic analysis security testing job output.

This improved job output provides clear, structured information that
helps you understand scan results and troubleshoot failures.

Each section of the job output is concise and intuitive, with a link to our troubleshooting documentation at the bottom of the output.
To override concise job output, set `DAST_FF_DIAGNOSTIC_JOB_OUTPUT: "true"` in your DAST configuration.

### Instance level compliance and policy management (Beta)

<!-- categories: Compliance Management, Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../user/compliance/compliance_frameworks/centralized_compliance_frameworks.md)

{{< /details >}}

Enterprise users want to manage their compliance frameworks and security policies across multiple top-level groups.
This is often the case when all groups in an instance:

- Share the same compliance frameworks. For example, when all projects in a group must adhere to the ISO 27001 standard.
- Enforce similar policies. For example, when all groups share the same pipeline execution policy.

With GitLab 18.3, compliance and security policy management is now available in beta for GitLab Self-Managed
instances. You can now create, configure, and allocate compliance frameworks and
security policies from a single top-level group and enforce them across all of the other top-level groups across your
GitLab Self-Managed instance.

When you use a compliance and security policy top-level group, you have a single source of truth
where you can manage and edit your compliance frameworks and security policies.
Group admins can then apply these compliance frameworks and security policies to all the projects within those groups.

When you manage key frameworks and policies from the chosen top-level compliance and security policy group,
it’s easier to manage and enforce key compliance and security needs across your GitLab Self-Managed instance.
However, groups still retain the ability to create their own compliance frameworks and security policies to address
specific situations or workflows that can arise in those groups.

This feature is for GitLab Self-Managed customers because GitLab.com and GitLab Dedicated customers are already
able to manage policies centrally within a single top-level group or namespace.

### Faster workspace startup with shallow cloning

<!-- categories: Workspaces -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/workspace/_index.md#shallow-cloning)

{{< /details >}}

Workspaces now use shallow cloning to reduce startup time. During initialization, GitLab downloads only the latest commit history instead of the full Git history. After the workspace starts, Git converts the shallow clone to a full clone in the background.

This feature applies automatically to all new workspaces, no configuration is required, and it doesn’t affect your development workflow.

### New CLI commands for GitLab-managed OpenTofu and Terraform states

<!-- categories: GitLab CLI, Infrastructure as Code -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/infrastructure/iac/terraform_state.md) | [Related issue](https://gitlab.com/gitlab-org/cli/-/issues/7954)

{{< /details >}}

The GitLab CLI (`glab`) now includes a new top-level command, `opentofu`.
The `opentofu` command is aliased to `terraform` and `tf` commands to assist with GitLab-managed
OpenTofu and Terraform states.

The following commands have been added:

- `glab opentofu init`: Initialize the state backend locally.
- `glab opentofu state list`: List all states in a project.
- `glab opentofu state download`: Download the latest state or a specific version.
- `glab opentofu state delete`: Delete the entire state or a specific version.
- `glab opentofu state lock`: Lock a state.
- `glab opentofu state unlock`: Unlock a state

To manage state with the `opentofu` command, you must have at least `glab` 1.66 or later.

### Kubernetes 1.33 support

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/538906)

{{< /details >}}

GitLab now fully supports Kubernetes version 1.33. If you deploy your apps to Kubernetes, you can upgrade your connected clusters to the most recent version and take advantage of all its features.

For more information, see the [Supported Kubernetes versions for GitLab features](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features).

### OAuth apps support SSO authentication

<!-- categories: Pages, System Access -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../api/oauth2.md#authorization-code-flow)

{{< /details >}}

OAuth applications can now seamlessly integrate with your organization’s single sign-on requirements. Previously, users had to authenticate twice: first with GitLab, then with SSO, creating unnecessary friction and complexity.

Now, OAuth applications can specify a parameter in their authorization requests to automatically trigger SSO authentication when required. This provides:

- A unified authentication experience for users
- Automatic compliance with your organization’s SSO policies
- Consistent security across all GitLab integrations
- Simple implementation for developers with just a parameter addition

Your OAuth integrations now respect SSO policies automatically, eliminating confusing authentication workflows while maintaining security.

### Control unique domains default for GitLab Pages sites

<!-- categories: Pages -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../administration/pages/_index.md#disable-unique-domains-by-default)

{{< /details >}}

Administrators can now set the default behavior for unique domains on new GitLab Pages sites. By default, new Pages sites use unique domain URLs (like `my-project-1a2b3c.example.com`) to prevent cookie sharing between sites.

With this new setting for the instance, you can set new Pages sites to use path-based URLs (like `my-namespace.example.com/my-project`) by default. This helps organizations align GitLab Pages behavior with their workflows and security requirements.

Users can still override this setting for individual projects, and existing Pages sites remain unaffected.

### Enhancements to wiki functionality

<!-- categories: Wiki -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/discussions/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16403)

{{< /details >}}

This release introduces an enhanced wiki experience with three key improvements: you can now subscribe to wiki pages, view wiki comments while editing a page, and sort wiki page comments.

These enhancements help teams collaborate more effectively on documentation by letting you:

- Discuss content directly in context.
- Suggest improvements and corrections.
- Keep documentation accurate and up-to-date.
- Share knowledge and expertise.

With these updates, your GitLab wiki becomes living documentation that evolves alongside your projects through direct feedback and discussion.

### Bulk edit epic assignees, milestones, and more

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/group/epics/manage_epics.md#bulk-edit-epics) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/11901)

{{< /details >}}

You can now bulk edit more epic attributes in a group. In addition to labels, you can now update assignee, health status, subscription, confidentiality, and milestone for multiple epics at once.

This enhancement makes it faster to manage large numbers of epics by letting you apply the same changes across multiple epics simultaneously.

### Grant pipeline execution policies access to CI/CD configurations via API

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../api/projects.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/524124)

{{< /details >}}

Use the Projects REST API to programmatically enable or disable the **Pipeline execution policy** setting in security policy projects with the new `spp_repository_pipeline_access` field. Previously, this setting could only be managed through the GitLab UI. With this enhancement, you can now:

- `GET` the current **Pipeline execution policy** status.
- `PUT` to enable or disable the setting programmatically.

This improvement enables better automation and integration workflows for teams managing security policies at scale.

### Group by OWASP 2021 in the vulnerability report

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../user/application_security/vulnerability_report/_index.md#advanced-vulnerability-management) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/532703)

{{< /details >}}

In the vulnerability report for projects and groups, you can now group the vulnerabilities by their OWASP Top 10 2021 category. Available for GitLab.com and GitLab Dedicated instances only.

### Scan execution policy templates

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/policies/scan_execution_policies.md#scan-execution-policy-editor) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/11919)

{{< /details >}}

Scan execution policy templates help you quickly create scan execution policies based on common use cases. Choose from three
templates:

- Merge request security
- Scheduled scanning
- Release security

Once you select a template, choose which GitLab security scans to enable with the template to get up and running immediately. If you have more advanced use cases, you can switch to the custom configuration to extend the policy with specific branch patterns, pipeline sources, and more.

### Security policy audit events

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/compliance/audit_event_streaming.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/15869)

{{< /details >}}

GitLab Ultimate now provides comprehensive audit events for security policy management, with events organized and centralized within each security policy project.

Security teams can now:

- Track all policy modifications with detailed metadata.
- Monitor enforcement failures, including scan and pipeline execution failures.
- Monitor skipped scan execution and pipeline execution pipelines.
- Detect policy violations within each project, including MRs merged with policy violations.
- Receive alerts when limits are exceeded.
- Detect policy configuration errors.
- Use streaming-only options for high-volume scenarios.

New audit events include:

- [security_policy_create](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_create](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_create.yml).yml)
- [security_policy_delete](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_delete](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_delete.yml).yml)
- [security_policy_update](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_update](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_update.yml).yml)
- [security_policy_merge_request_merged_with_policy_violations](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_merge_request_merged_with_policy_violations](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_merge_request_merged_with_policy_violations.yml).yml)
- [security_policy_yaml_invalidated](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_yaml_invalidated](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_yaml_invalidated.yml).yml)
- [security_policies_limit_exceeded](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_yaml_invalidated.yml)
- [security_policy_violations_detected](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_violations_detected](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_violations_detected.yml).yml) (streaming only)
- [security_policy_pipeline_failed](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_pipeline_failed](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_pipeline_failed.yml).yml) (streaming only)
- [security_policy_pipeline_skipped](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_pipeline_skipped](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_pipeline_skipped.yml).yml) (streaming only)
- [merge_request_branch_bypassed_by_security_policy](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/audit_events/types/[merge_request_branch_bypassed_by_security_policy](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/audit_events/types/merge_request_branch_bypassed_by_security_policy.yml).yml)

This enhancement strengthens your security posture by ensuring you have access to policy changes, configuration errors, and enforcement gaps, enabling faster incident response and thorough auditing capabilities.

### Service account and access token exceptions for approval policies

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#access-token-and-service-account-exceptions) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/18112)

{{< /details >}}

The new **Service Account & Access Token Exceptions** feature allows you to designate service accounts and access tokens that can bypass merge request approval policies when necessary. This eliminates friction for known automations, while preserving security controls.

**Key capabilities include:**

- Automated workflow support: Configure specific service accounts, bot users, group access tokens, and project access tokens to bypass approval requirements for CI/CD pipelines, pull mirroring, and automated version updates. Service accounts can push directly to protected branches using approved tokens while maintaining restrictions for human users.
- Emergency access and auditing: Enable break-glass scenarios for critical incidents with comprehensive audit trails. All bypass events generate detailed audit logs with context and reasoning, supporting compliance requirements while allowing rapid response during outages or security fixes.
- GitOps integration: Unblock common automation challenges including repository mirroring, external CI systems (Jenkins, CloudBees), automated changelog generation, and GitFlow release processes. Service accounts receive the minimum required permissions with token-based access scoped to specific projects and branches.

This enhancement maintains strict security policies with flexibility for modern DevOps automation needs, eliminating custom workarounds while preserving governance controls.

### SAML SSO support for session timeout attribute

<!-- categories: System Access -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/group/saml_sso/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/262074)

{{< /details >}}

GitLab now automatically detects and respects the `SessionNotOnOrAfter` attribute in SAML assertions from your Identity Provider (IdP).
When this attribute is present, GitLab sets user sessions to expire at the time specified by your IdP,
ensuring consistent session management across your organization. This feature requires no configuration changes - if your IdP provides the attribute, GitLab automatically honors the specified expiration time.

### Additional service account email configuration options

<!-- categories: System Access -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/profile/service_accounts.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/537976)

{{< /details >}}

By default, GitLab automatically generates an email address for new service accounts. Organizations can now assign a custom email address for service accounts through the UI. Previously, custom email configuration was only possible through the Service Accounts API. This change allows organizations to better route notifications to designated email addresses.

### Enterprise user enhancements

<!-- categories: System Access -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/enterprise_user/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9262)

{{< /details >}}

GitLab 18.3 introduces enterprise user enhancements that give organizations greater control over user privacy and lifecycle management.

Group owners can now delete enterprise users in their namespace with the Users API. This destructive action unlinks user contributions and associates them with a system-wide Ghost user. These option is particularly valuable for cleaning up users erroneously created with automated SCIM imports or managing federated environments where usernames and emails need to be repurposed.

Additionally, organizations can now hide enterprise user emails on their user profiles, providing broader email privacy enforcement for all enterprise users.

### SSH key security warnings

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/ssh.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/432624)

{{< /details >}}

GitLab now displays a security warning in the UI when a user uploads a weak SSH key. This warning appears for older key types or keys with insufficient bit length (less than 2048 bits). This change helps educate users about SSH key security best practices and encourages the use of stronger cryptographic keys.

### GitLab Runner 18.3

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 18.3 today! GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### Bug Fixes

- [In GitLab 18.2.0, runners are unable to pull the job cache by using the subdirectory file as cache key](https://gitlab.com/gitlab-org/gitlab/-/issues/556464)
- [Docker executor fails to start jobs intermittently and returns an `incorrect username or password` error message.](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38707)
- [Inconsistency in `*_get_sources` hooks usage between `none` and `empty` Git strategies](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38703)
- [Operator deployed with non-OLM manifests assumes wrong default images](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/228)
- [Operator creates ConfigMap with the wrong name if CR has the `app.kubernetes.io/instance` label](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/183)
- [Operator 1.10.0 on OpenShift 4.9 fails to create runner ConfigMap and start pod in the `gitlab-runner` namespace](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/138)

#### What’s new

- [GitLab Runner Operator now supports runner manager pod annotation](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/245)
- [GitLab Runner Operator now supports OpenShift 4.19](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/253)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-3-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-3-stable/CHANGELOG.md).md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.3)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.3)
- [UI improvements](https://papercuts.gitlab.com/?milestone=18.3)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
