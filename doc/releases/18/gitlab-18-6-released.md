---
stage: Release Notes
group: Monthly Release
date: 2025-11-20
title: "GitLab 18.6 release notes"
description: "GitLab 18.6 released with The new GitLab UI: Designed for productivity"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On November 20, 2025, GitLab 18.6 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Samaksh Agarwal

Every developer using the GitLab Development Kit (GDK) benefits from Samaksh’s
[contribution to improve the readability of `gdk status`](https://gitlab.com/gitlab-org/gitlab-development-kit/-/merge_requests/5227).
While this enhancement may appear simple on the surface, it demonstrates exceptional attention to
developer experience and understanding of how small improvements can have
widespread impact.

The improved readability of `gdk status`
saves time for every developer using GDK and considerably increases the
accessibility of one of the core pieces of the development environment. This
type of contribution shows maturity in understanding how to make meaningful
improvements to the developer workflow.

Reflecting on his contributions, Samaksh shares: “GitLab Development Kit (or GDK)
has been my choice of active contributions for now, because I personally like to
work on the side that makes experience for other contributors easy and convenient.
And that’s the kind of developer I wanna be. The one that can use his skills to
make others’ lives easier.”

When asked about his experience contributing to GitLab, Samaksh notes: “I’d like
to recommend GitLab to everyone who wants to try a fresh and quality open source
experience. When I first started contributing to GitLab, I was a bit overwhelmed
but everyone in the community was so supportive, helpful and welcoming that it all
went away. I am absolutely in love with the community and how they do things around
here. From writing excellent documentation, to maintaining peak code quality, to
genuinely appreciating their contributors, GitLab community is absolutely wonderful.”

## Primary features

### The new GitLab UI: Designed for productivity

<!-- categories: Design Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../tutorials/gitlab_navigation.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/17279)

{{< /details >}}

Introducing a smarter, more intuitive GitLab UI that puts developer productivity first.

The new side-by-side design uses contextual panels to keep you in your workflow, reducing unnecessary clicks and helping teams work faster. Customize your workspace, maximize screen real estate, and enjoy a cleaner, more dynamic experience that adapts to your workflow.

GitLab is committed to continuous improvement, so please share your thoughts in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/577554) and help shape the future of GitLab.

### Exact code search in limited availability

<!-- categories: Global Search -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/search/exact_code_search.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/17918)

{{< /details >}}

With this release, exact code search is now in limited availability. You can use exact match and regular expression modes to search for code across an entire instance, in a group, or in a project. Exact code search is built on top of the open-source search engine Zoekt.

For GitLab.com, exact code search is enabled by default. For GitLab Self-Managed, an administrator must [install Zoekt](../../integration/zoekt/_index.md#install-zoekt) and [enable exact code search](../../integration/zoekt/_index.md#enable-exact-code-search).

This feature is in active development. We welcome your feedback in [issue 420920](https://gitlab.com/gitlab-org/gitlab/-/issues/420920)!

### CI/CD Components can reference their own metadata

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../ci/yaml/expressions.md#component-context) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/438275)

{{< /details >}}

Previously, CI/CD components couldn’t reference their own metadata, such as version numbers
or commit SHAs, within their configuration. This lack of information could cause you to use configuration with
hardcoded values or complex workarounds. Writing configuration this way can
lead to version mismatches when components build resources such as Docker images,
because there’s no way to automatically tag those resources with the component’s compatible version.

In this release, we’ve introduced the ability to access component context with the `spec:component` keyword.
You can now build and publish versioned resources like Docker images when you release a component version,
ensuring everything is in sync, eliminating manual version management, and preventing version mismatches.

### Support dynamic job dependencies in `needs:[parallel:matrix](../../ci/yaml.md#parallelmatrix)`

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../ci/yaml/matrix_expressions.md#matrix-expressions-in-needsparallelmatrix) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/423553)

{{< /details >}}

[`parallel:matrix`](../../ci/yaml/_index.md#parallelmatrix) makes it possible
to easily run multiple jobs in parallel with different requirements, for example
to test code for multiple platforms at the same time. But if you wanted later jobs
to use `needs:parallel:matrix` to depend on specific parallel jobs, the configuration was complex
and inflexible.

Now, with the new `$[[matrix.VARIABLE]]` expression introduced as a Beta feature,
users can create dynamic 1-1 dependencies which makes complex `parallel:matrix` configurations
much easier to manage. This can help you create faster pipelines, with efficient artifact handling,
better scalability, and cleaner configuration. This feature is particularly valuable for multi-platform builds,
Terraform deployments across multiple environments, and any workflow requiring parallel processing across multiple dimensions.

### GitLab Security Analyst Agent available as a foundational agent

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Add-ons: Duo Core, Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/duo_agent_platform/agents/foundational_agents/security_analyst_agent.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/19659)

{{< /details >}}

The GitLab Security Analyst Agent is now a foundational agent in GitLab Duo Agentic Chat. This means that users do not have to manually add the GitLab Security Analyst agent from the AI Catalog, and this agent is available by default for GitLab Self-Managed and GitLab Dedicated as well.
This specialized assistant provides AI-native vulnerability management and security analysis, helping you investigate findings, triage vulnerabilities, and navigate compliance requirements without any setup.

This feature is in beta, and we welcome your feedback in [issue 576916](https://gitlab.com/gitlab-org/gitlab/-/issues/576916).

### Model selection for GitLab Duo Agentic Chat in VS Code and JetBrains IDEs

<!-- categories: Editor Extensions, Model Personalization -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Add-ons: Duo Core, Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/gitlab_duo/model_selection.md#select-a-model-for-a-feature) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/19345)

{{< /details >}}

Easily choose your preferred AI model right in GitLab Duo Chat, now available in the VS Code and JetBrains IDEs. Use the dropdown list in the GitLab Duo Chat panel to select among Claude, GPT, and other supported models. Model availability is managed by your organization admins, ensuring you have access to the right models for your workflow.

### Security dashboard upgrade (beta on GitLab.com)

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com
- Links: [Documentation](../../user/application_security/security_dashboard/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/18509)

{{< /details >}}

The new security dashboards have been updated and modernized. The initial features in the beta release include:

- A vulnerabilities over time chart that supports:
  - Filtering based on project or report type.
  - Grouping by report type and severity.
  - Direct links to vulnerabilities in the vulnerability report.
- A risk score module that calculates the estimated risk for a group or project based on a GitLab algorithm.

The new security dashboards released in 18.6 are currently available on GitLab.com only.

## Agentic Core

### GitLab MCP server available in [beta](../../policy/development_stages_support.md#beta)

<!-- categories: MCP Server -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Add-ons: Duo Core, Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/gitlab_duo/model_context_protocol/mcp_server.md)

{{< /details >}}

The GitLab MCP server is available in [beta](../../policy/development_stages_support.md#beta). With the GitLab MCP server, you can use AI assistants like Claude Code, Cursor, and other MCP-compatible tools to interact with your GitLab projects, issues, merge requests, and pipelines, all without building custom integrations for each tool.

To get started, [turn on beta and experimental features](../../user/gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features) in your GitLab Duo settings.

The GitLab MCP server provides key tools covering issues, merge requests, and pipelines, and we continue to refine it based on user feedback. This feature might have incomplete functionality or bugs. Try it out and share feedback in [issue 561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564).

### Advanced search available for both issue descriptions and comments

<!-- categories: Global Search -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/search/advanced_search.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/513146)

{{< /details >}}

Advanced search now returns matching results from both issue descriptions and comments. Previously, users had to search issue descriptions and comments separately. This improvement provides a more streamlined and comprehensive search workflow for GitLab issues.

### Gemini 2.5 Flash model compatible with GitLab Duo Agent Platform for [GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models)

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/572353)

{{< /details >}}

You can now use the Gemini 2.5 Flash model on GitLab Duo Agent Platform with GitLab Duo Self-Hosted.

## Scale and Deployments

### Rate limit for listing project and group members

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../administration/settings/rate_limit_on_projects_api.md#configure-rate-limits-on-listing-project-members) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/580116)

{{< /details >}}

We’ve introduced rate limiting for the `/api/v4/projects/:id/members/all` and `/api/v4/groups/:id/members/all`
endpoints to improve API stability and ensure fair resource usage across all users.
The `GET /api/v4/projects/:id/members/all` and `GET /api/v4/groups/:id/members/all`
endpoints now have a rate limit of 200 requests per minute per user.

This change helps protect GitLab instances from excessive API usage that could impact performance for all users.
The limit of 200 requests per minute provides ample capacity for normal usage patterns while preventing potential abuse or unintentional resource exhaustion.
If your integrations or scripts use this endpoint, ensure they handle rate limit responses appropriately (HTTP 429) and implement retry logic with backoff as needed.
Most users should not be affected by this change under normal usage patterns.

## Unified DevOps and Security

### Increased rule coverage for secret push protection and pipeline secret detection

<!-- categories: Secret Detection -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/secret_detection/detected_secrets.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/576279)

{{< /details >}}

We’ve added support for 40 new rules to GitLab’s pipeline secret detection. Some existing rules have also been updated
to improve quality and reduce false positives. These changes are released in [version 7.20.1](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v7.20.1) of the secrets analyzer.

### Code Owners now supports inherited group memberships

<!-- categories: Code Review Workflow, Source Code Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/project/codeowners/advanced.md#group-inheritance-and-eligibility)

{{< /details >}}

Code ownership is critical for maintaining code quality and ensuring the right
people review changes to sensitive parts of your codebase. However, managing
Code Owners in organizations with complex group structures has been challenging.
Previously, to reference a group in your `CODEOWNERS` file, that group had to be
directly invited to each specific project, even if it was already a member of
a parent group.

Code Owners now supports groups with inherited memberships as eligible approvers:

- Groups with inherited access through parent group membership are recognized as valid code owners when Code Owners approvals are enabled.
- No need to invite groups directly to every project.
- Existing `CODEOWNERS` files continue to work without changes.
- Same level of control over who can approve changes to critical code paths.

This change reduces administrative overhead while maintaining the security and
approval requirements that Code Owners provide.

### Toggle draft merge request visibility on your homepage

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/project/merge_requests/homepage.md#set-your-display-preferences) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/551475)

{{< /details >}}

On your homepage, draft merge requests can clutter your merge request view and
distract from work that’s ready for action. Previously, you could not filter them
out.

You can now hide draft merge requests from the **Your merge requests** section on
your homepage by using the display preferences. When you hide draft merge requests:

- They are excluded from the active count.
- A footer displays the number of filtered draft merge requests.
- Your preference is saved automatically.

This change helps you focus on merge requests that need immediate attention.

### New GitLab CLI features and improvements

<!-- categories: GitLab CLI -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](https://docs.gitlab.com/cli/) | [Related issue](https://gitlab.com/gitlab-org/cli/-/releases)

{{< /details >}}

The GitLab CLI (glab) provides new features and improvements to enhance your
GitLab workflow from the command line:

- **Enhanced authentication**: Auto-detect GitLab URLs from git remotes during login, making it easier to authenticate against the correct GitLab instance.
- **Flexible pipeline monitoring**: View any pipeline by ID with the `ci-view` command.
- **GPG key management**: Manage GPG keys directly from the CLI with new commands.
- **Project member management**: Add, remove, and update project members from the command line.
- **Improved Git integration**: Enhanced git-credential plugin with support for all token types.
- **Modern user interface**: Updated prompt library for better confirmation dialogs and consistent GitLab theme across UI components.

For a full list of changes and updates, see [CLI releases](https://gitlab.com/gitlab-org/cli/-/releases).
To get started with the GitLab CLI or update to the latest version,
see the [installation guide](https://gitlab.com/gitlab-org/cli/#installation).

### Webhook notifications for merge request review re-requests

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/project/integrations/webhook_events.md#re-request-review-events)

{{< /details >}}

Webhook integrations are critical for automating workflows and keeping
external systems synchronized with GitLab merge request activities.
However, when reviewers were re-requested for merge requests, webhook
consumers had no way to identify which specific reviewer was being
re-requested, making it difficult to trigger appropriate notifications
or automation.

Webhook payloads for merge requests now include a `re_requested` attribute
in reviewer data that clearly indicates which reviewer was re-requested:

- Set to `true` for the specific reviewer being re-requested.
- Set to `false` for all other reviewers.

This improvement enables more precise automation around the merge request
review process. Webhook consumers can send targeted notifications,
update external tracking systems, and trigger appropriate workflows when
reviews are re-requested.

### Web IDE support for offline GitLab Self-Managed environments

<!-- categories: Web IDE, Editor Extensions -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/settings/web_ide.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/15146)

{{< /details >}}

GitLab Self-Managed administrators in offline or tightly controlled network environments can now configure a custom Web IDE extension host domain, enabling full Web IDE functionality without external internet access.

Previously, the Web IDE required connectivity to `.cdn.web-ide.gitlab-static.net` to load VS Code extensions and functionality. This requirement blocked Web IDE adoption for security-conscious organizations, government and public sector customers, and enterprises with strict network policies.

With this update, administrators can configure their GitLab instance to serve Web IDE assets directly, removing the dependency on external domains. You can now:

- Use the full Web IDE feature set in completely offline environments.
- Enable the Extension Marketplace with a custom extension registry service.
- Enable Markdown preview, code editing, and GitLab Duo Chat within the Web IDE in isolated networks.

### Webhook triggers for system-initiated approval resets

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/project/integrations/webhook_events.md#system-initiated-merge-request-events) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/553070)

{{< /details >}}

Integrating GitLab with external systems through webhooks is critical for automated
workflows and keeping teams informed about merge request status changes. However, when
GitLab automatically resets approvals (such as when new commits are pushed to a merge
request with “Reset approvals on push” enabled), external systems could not distinguish
these system-initiated events from manual user actions.

GitLab now includes enhanced webhook payloads that clearly identify system-initiated approval
resets. When approvals are automatically reset, webhooks now include:

- A `system` field set to `true`.
- A `system_action` field that provides specific context about why the reset occurred, such as `approvals_reset_on_push` or `code_owner_approvals_reset_on_push`.

This means your webhook integrations can now distinguish between manual approval changes and
automatic system resets, enabling more sophisticated automation workflows that respond
appropriately to the specific context of each approval change.

### GitLab Duo Planner Agent now available by default

<!-- categories: Team Planning -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Core, Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/duo_agent_platform/agents/foundational_agents/planner.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/580924)

{{< /details >}}

The GitLab Duo Planner Agent is now available by default in the agent dropdown in GitLab Duo Chat, eliminating the need to manually add it from the AI Catalog. With full context of your work items, epics, issues, and tasks, the Planner Agent can now assist you at both the group and project levels.

Get started with [**[example prompts](../../user/duo_agent_platform/agents/foundational_agents/planner.md#example-prompts)**](../../user/duo_agent_platform/agents/foundational_agents/planner.md#example-prompts) to see how the Planner Agent can help you break down complex work, create implementation plans, and organize your team’s objectives.

This feature is in beta, and we welcome your feedback in [issue 576622](https://gitlab.com/gitlab-org/gitlab/-/issues/576622).

### Helm chart registry: No more 1,000 chart limit

<!-- categories: Package Registry -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/packages/helm_repository/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/545919)

{{< /details >}}

GitLab’s Helm chart registry previously generated metadata responses on-the-fly, which created performance bottlenecks when repositories contained large numbers of charts. To maintain system stability, we enforced a hard limit of the 1,000 most recent charts. This limit caused frustrating 404 errors when platform teams tried to access older chart versions.

Platform engineers were forced to implement complex workarounds, like splitting charts across multiple repositories, manually managing chart retention policies, or maintaining separate chart storage solutions. These workarounds added operational overhead and fragmented deployment workflows, making it harder to maintain centralized chart governance.

In GitLab 18.6, we’ve eliminated the 1,000 chart limitation by pre-computing metadata responses and storing them in object storage. This architectural change delivers both unlimited chart access and improved performance, as metadata is generated once in background jobs rather than on every request.

### Warn mode in merge request approval policies (Beta)

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#warn-mode) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/19595)

{{< /details >}}

Security teams can now use warn mode to test and validate the impact of security policies before applying enforcement, reducing developer friction during security policy rollouts.

When you create or edit a [merge request approval policy](../../user/application_security/policies/merge_request_approval_policies.md), you can now choose between `warn` or `enforce` enforcement options.

Policies in warn mode generate informative bot comments without blocking merge requests. Optional approvers can be designated as points of contact for policy questions. This approach enables security teams to assess policy impact and build developer trust through transparent, gradual policy adoption.

Clear indicators in merge requests tell users when policies are in `warn` or `enforce` mode, and audit events track policy violations and dismissals for compliance reporting. Developers can dismiss vulnerabilities while providing reasoning for the dismissal, creating a collaborative approach to security policy management.

### Security attributes (Beta)

<!-- categories: Security Asset Inventories -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/attributes/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/19597)

{{< /details >}}

Security teams can now apply business context to projects by leveraging security attributes.

Security attributes are organized by categories including business impact (with structured pre-defined selections), application, business unit, internet exposure, and location. Alternatively, you can create your own attribute categories and define labels within those categories.

By applying these attributes across your projects, you can much more quickly search, filter, and identify which projects within the security inventory that require action based on risk posture and organizational context. You may now:

- Identify projects that are mission critical and requiring better scan coverage
- Review scan coverage by application or business unit
- Search and filter based on the attributes applied to your projects
- Quickly locate projects that contribute to applications which are publicly accessible/exposed

### Exceptions to bypass merge request approval policies

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/18114)

{{< /details >}}

Organizations can now designate specific users, groups, roles, or custom roles that can bypass merge request approval policies in case critical situations occur. This capability provides flexibility for emergency responses, while maintaining comprehensive audit trails and governance controls.

**Emergency bypass with accountability**: Designated users can bypass approval requirements during critical incidents, security hotfixes, or urgent production issues. When emergencies strike, authorized personnel can merge or push changes immediately while the system captures detailed justification and audit information for compliance review.

**Key capabilities include:**

- **Documented bypass process**: When authorized users invoke a policy bypass, they must provide detailed reasoning using an intuitive modal interface, ensuring every exception is properly documented with context.
- **Comprehensive audit integration**: Every bypass generates detailed audit events including user identity, policy context, reasoning, and timestamps for complete visibility into exception usage patterns.
- **Flexible configuration**: Define exception permissions for policies using YAML or UI configuration, supporting individual users, GitLab groups, standard roles, and custom roles.
- **Git-based push exceptions**: Users with pre-approved policy exceptions may push directly when invoking the push bypass option `security_policy.bypass_reason`.

This feature eliminates the need to entirely disable security policies during emergencies, providing a controlled path for urgent changes while preserving organizational governance and audit requirements.

### Designate an account succession beneficiary

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/profile/account/account_succession.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/330669)

{{< /details >}}

You can now designate an account beneficiary permission to manage your GitLab account if you are incapacitated or unavailable. To access your account, the beneficiary must provide appropriate legal documentation. This feature helps ensure the continuity of your work and projects while preventing unauthorized access.

### Group Owners can update primary emails for enterprise users

<!-- categories: System Access -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/enterprise_user/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/425837)

{{< /details >}}

Group owners can can now update the primary email address of enterprise users in their group. Updates can be made through the Users API. Previously, each enterprise user had to manually update their own email address. This change makes it easier to manage enterprise users at scale.

### GitLab Runner 18.6

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 18.6 today! GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s New

- [Implement minimal job confirmation API](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39013)

#### Bug Fixes

- [GitLab Runner does not expand the variables in the Docker image platform option](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38488)
- [Helper sidecar container fails to upload cache to S3 bucket from another account](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37879)
- [Automatically canceled job continues execution and fails](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37878)
- [Missing UTF8 BOM in the generated PowerShell script allows remote code execution using merge request title with character Ä](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36060)
- [Intermittent Kubernetes API server request failures with Kubernetes executor](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30109)
- [When using a Kubernetes executor, jobs with large commit messages fail](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/26624)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-6-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-6-stable/CHANGELOG.md).md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.6)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.6)
- [UI improvements](https://papercuts.gitlab.com/?milestone=18.6)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
