---
stage: Release Notes
group: Monthly Release
date: 2025-02-20
title: "GitLab 17.9 release notes"
description: "GitLab 17.9 released with GitLab Duo Self-Hosted is generally available"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On February 20, 2025, GitLab 17.9 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor

We’re excited to recognize [Salihu Dickson](https://gitlab.com/salihudickson) as our MVP for his outstanding contributions to developing [Comments on Wiki pages](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171764), a highly-requested feature that gathered [over 200 positive reactions](https://gitlab.com/groups/gitlab-org/-/epics/14062) from the community!

His dedication spanned over six months, delivering an implementation of [wiki top-level discussions](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171764) with nearly 4,000 lines of code. Salihu also created several proof-of-concept implementations and improved the Wiki experience with additional features and bug fixes.

“Salihu has been an outstanding Community Contributor in developing Comments on Wiki pages!” shares [Matthew Macfarlane](https://gitlab.com/mmacfarlane), Product Manager, Plan:Knowledge at GitLab. “Salihu’s extensive knowledge of the product has allowed us to deliver this key feature more efficiently. As a Product Manager, it is a joy to work with contributors like Salihu!”

“An incredible achievement!” shares [Alex Fracazo](https://gitlab.com/afracazo), Senior Product Designer, Plan:Knowledge at GitLab. “Salihu didn’t just build the basic functionality, but delivered a comprehensive end-to-end feature from top-level discussions on Wiki pages to error handling and test coverage.” Many members of the GitLab team showed strong appreciation for Salihu’s work, including Natalia Tepluhina, Principal Engineer, Vue.js core team member, and [Vladimir Shushlin](https://gitlab.com/vshushlin), Engineering Manager, Plan:Knowledge at GitLab, highlighting his technical skills and collaboration.

Salihu, a front-end engineer at Elixir Cloud and two-time GSoC mentor, shared - “I’d like to thank everyone who worked closely with me to make this possible. A special thank you to [Himanshu Kapoor](https://gitlab.com/himkp) (Staff Frontend Engineer, Plan:Knowledge at GitLab) - your mentorship over the past few months has been instrumental to all the work I’ve done here, and I truly appreciate all the guidance and support you’ve provided. Bringing this feature to life was really a team effort—from the reviewers who meticulously went through hundreds of lines of code, to the backend developers like [Piotr Skorupa](https://gitlab.com/pskorupa) (Backend Engineer, Plan:Knowledge at GitLab), who made this possible.” He expressed enthusiasm about collaborating with the team and “contributing to many more impactful features in the future!”

We are so grateful to Salihu for all of his contributions and to all of our open source community for contributing to GitLab!

## Primary features

### GitLab Duo Self-Hosted is generally available

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/517102)

{{< /details >}}

You can now host selected large language models (LLMs) in your own infrastructure and configure those models as the source for GitLab Duo Code Suggestions and Chat. This feature is now generally available on self-managed GitLab environments with applicable licensing.

With GitLab Duo Self-Hosted, you can use models hosted either on-premise or in a private cloud as the source for GitLab Duo Chat or Code Suggestions. We currently support open-source Mistral models on vLLM or AWS Bedrock, Claude 3.5 Sonnet on AWS Bedrock, and OpenAI models on Azure OpenAI. By enabling self-hosted models, you can leverage the power of generative AI while maintaining complete data sovereignty and privacy.

Please leave feedback in [issue 512753](https://gitlab.com/gitlab-org/gitlab/-/issues/512753).

### Run multiple Pages sites with parallel deployments

<!-- categories: Pages -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/pages/_index.md#parallel-deployments) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/14434)

{{< /details >}}

You can now create multiple versions of your GitLab Pages sites simultaneously with parallel deployments. Each deployment gets a unique URL based on your configured prefix. For example, with a unique domain your site would be accessible at `project-123456.gitlab.io/prefix`, or without a unique domain at `namespace.gitlab.io/project/prefix`.

This feature is especially helpful when you need to:

- Preview design changes or content updates.
- Test site changes in development.
- Review changes from merge requests.
- Maintain multiple site versions (for example, with localized content).

Parallel deployments expire after 24 hours by default to help manage storage space, though you can customize this duration or set deployments to never expire. For automatic cleanup, parallel deployments created from merge requests are deleted when the merge request is merged or closed.

### Add project files to Duo Chat in VS Code and JetBrains IDEs

<!-- categories: Editor Extensions, Duo Chat -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/gitlab_duo_chat/examples.md#ask-about-specific-files-in-the-ide) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/15183)

{{< /details >}}

Add your project files directly to Duo Chat in VS Code and JetBrains to unlock more powerful, context-aware AI assistance.

By adding project files, Duo Chat gains deep understanding of your specific codebase, enabling it to provide highly contextual and accurate responses. This context awareness gives you more relevant code explanations, precise debugging help, and suggestions that seamlessly integrate with your existing codebase. We welcome your feedback on this new, exciting feature. Please share your thoughts in our [feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/492443) issue.

### Workspaces container support with Sysbox

<!-- categories: Workspaces -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/workspace/configuration.md#build-and-run-containers-in-a-workspace)

{{< /details >}}

GitLab workspaces now supports building and running containers directly in your development environment. When your workspace runs on a Kubernetes cluster configured [with Sysbox](../../user/workspace/configuration.md#with-sysbox), you can build and run containers without additional configuration.

Introduced in GitLab 17.4 as part of our [sudo access feature](https://about.gitlab.com/releases/2024/09/19/gitlab-17-4-released/#secure-sudo-access-for-workspaces), this capability enables you to maintain your complete container workflow in your GitLab workspace environment.

### Create workspaces without a custom devfile

<!-- categories: Workspaces -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/workspace/_index.md#gitlab-default-devfile)

{{< /details >}}

Previously, setting up a workspace required creating a `devfile.yaml` configuration file. GitLab now provides you with a default file that includes common development tools. This enhancement:

- Removes configuration barriers.
- Enables you to create a workspace quickly from any project.
- Includes common development tools pre-configured and ready to use.
- Lets you focus on development instead of configuration.

Start developing and create a workspace immediately without additional setup or configuration steps.

### GitLab-managed Kubernetes resources

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/clusters/agent/managed_kubernetes_resources.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16130)

{{< /details >}}

Deploy your applications to Kubernetes with more control and automation using [GitLab-managed Kubernetes resources](../../user/clusters/agent/managed_kubernetes_resources.md). Previously, you had to manually configure Kubernetes resources for each environment. Now, you can use GitLab-managed Kubernetes resources to automatically provision and manage these resources.

With GitLab-managed Kubernetes resources, you can:

- Automatically create namespaces and service accounts for new environments
- Manage access permissions through role bindings
- Configure other required Kubernetes resources

When your developers deploy applications, GitLab automatically creates the necessary Kubernetes resources based on the provided resource templates, streamlining your deployment process and maintaining consistency across environments.

### Simplified access to deployments within project environments

<!-- categories: Environment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/environments/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/505770)

{{< /details >}}

Have you ever struggled to get an overview of your deployments within a project? You can now view recent deployment details in the environments list without having to expand each environment. For each environment, the list shows your latest successful deployment and, if different, your most recent deployment attempt.

### Wiki page comments

<!-- categories: Wiki -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/discussions/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/14062)

{{< /details >}}

You can now add comments directly on wiki pages, transforming your documentation into an interactive collaboration space.

Comments and threads on wiki pages help teams:

- Discuss content directly in context.
- Suggest improvements and corrections.
- Keep documentation accurate and up-to-date.
- Share knowledge and expertise.

With wiki comments, teams can maintain living documentation that evolves alongside their projects through direct feedback and discussion.

### Enhancing workflow visibility: new insights into merge request review time

<!-- categories: Value Stream Management, Code Review Workflow -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/value_stream_analytics/_index.md#value-stream-stage-events) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/503754)

{{< /details >}}

To improve development workflow tracking, [Value Stream Analytics](https://about.gitlab.com/solutions/value-stream-management/) (VSA) has been extended with a new event - *Merge request last approved at*. The [merge request approval](../../user/project/merge_requests/approvals/_index.md) event marks the end of the review phase and the start of the final pipeline run or merge stage. For example, to calculate the total merge request review time, you can create a VSA stage with *Merge request reviewer first assigned* as the start event and *Merge request last approved at* as the end event.

With this enhancement, teams gain deeper insights into opportunities to optimize review times, which help reduce the overall cycle time of development, leading to faster software delivery.

### EPSS, KEV, and CVSS data for vulnerability risk prioritization

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/vulnerabilities/risk_assessment_data.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/11544)

{{< /details >}}

We’ve added support for the following vulnerability risk data:

- Exploit Prediction Scoring System (EPSS)
- Known Exploited Vulnerabilities (KEV)
- Common Vulnerabilities and Exposures (CVE)

You can now efficiently prioritize risk across your dependency and container image vulnerabilities using this data. You can find the data in the Vulnerability Report and in the Vulnerability Details page.

### Configure DAST scans through the UI with full control

<!-- categories: DAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dast/on-demand_scan.md)

{{< /details >}}

To effectively test complex applications, security teams need flexibility when they configure DAST scans. Previously, DAST scans configured through the UI had limited configuration options, which prevented successful scanning of applications with specific security requirements. This meant you had to use pipeline-based scans even for quick security assessments.

You can now configure DAST scans through the UI with the same granular control available in pipeline-based scans. This includes:

- Full authentication configuration, including custom headers and cookies
- Precise crawl settings like maximum pages, maximum depth, and excluded URLs
- Advanced scan timeouts and retry attempts
- Custom scanner behavior, like maximum links to crawl and DOM depth
- Targeted scanning modes for specific vulnerability types

Save these configurations as reusable profiles to maintain consistent security testing across your applications. Every configuration change is tracked with audit events, so you know when scan settings are added, edited, or removed.

This enhanced control helps you run more effective security scans while maintaining compliance using detailed audit trails. Instead of spending time managing pipeline configurations, you can quickly launch the right scan for each application to find and fix vulnerabilities faster.

### Automatic CI/CD pipeline cleanup

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/pipelines/settings.md#automatic-pipeline-cleanup) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/338480)

{{< /details >}}

In the past, if you wanted to delete older CI/CD pipelines, you could only do this through the API.

In GitLab 17.9, we have introduced a project setting that allows you to set a CI/CD pipeline expiry time.
Any pipelines and related artifacts older than the defined retention period are deleted.
This can help reduce the disk usage in projects that run lots of pipelines that generate large artifacts, and even improve overall performance.

## Agentic Core

### Composite identity for more secure AI connections

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../development/ai_features/composite_identity.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/506641)

{{< /details >}}

Previously, a request to GitLab could only be authenticated as a single user. With composite identity, we have now made it possible to authenticate a request as a service account and a user simultaneously.
AI agent use cases often require permissions to be based on the user who initiated the tasks in a system, while simultaneously showing a distinct identity that’s separate from the initiating user. A composite identity is our new identity principal, which represents an AI agent’s identity. This identity is linked with the identity of the human user who requests actions from the agent.
Whenever an AI agent action attempts to access a resource, a composite identity token is used. This token belongs to a service account, and is also linked with the human user who is instructing the agent. The authorization checks that run on the token take into account both principals before granting access to a resource. Both identities need to have access to the resource, otherwise access is denied.
This new functionality enhances our ability to protect resources stored in GitLab.
For more information about how the composite identity for service accounts can be used, see the [documentation](../../development/ai_features/composite_identity.md).

## Scale and Deployments

### Restrict users from making their profile private

<!-- categories: User Management, User Profile -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/settings/account_and_limit_settings.md#prevent-users-from-making-their-profiles-private) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/421310)

{{< /details >}}

Users can choose to make their user profile public or private.
Administrators can now control whether users have the option to make profiles private across their GitLab instance. In the Admin Area, “Allow users to make their profiles private” controls this setting. This setting is enabled by default, allowing users to choose private profiles.

### Manage project integrations from a group with the REST API

<!-- categories: Source Code Management, Settings -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/group_integrations.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/328496)

{{< /details >}}

Previously, you could manage project integrations from a group in the GitLab UI only. With this release, it’s possible to manage these integrations with the REST API too.

Thanks to [Van](https://gitlab.com/van.m.anderson) for their [initial community contribution](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148283), which was subsequently picked up and completed by GitLab.

### Group sharing visibility enhancement

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/members/sharing_projects_groups.md#view-shared-groups) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/378629)

{{< /details >}}

We’re excited to announce expanded visibility for group sharing across GitLab. Previously, while you could see shared projects on a group’s overview page, you couldn’t see which groups your group had been invited to join. Now you can view both **Shared projects** and **Shared groups** tabs on the group overview page, giving you a complete view of how your groups are connected and shared throughout your organization. This makes it easier to audit and manage group access across your organization.

We welcome feedback about this change in [epic 16777](https://gitlab.com/groups/gitlab-org/-/epics/16777).

## Unified DevOps and Security

### Enable Dependency Scanning using SBOM for Cargo, Conda, Cocoapods and Swift projects

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/519597)

{{< /details >}}

In GitLab 17.9 the Composition Analysis team starts the transition to Dependency Scanning using SBOM with the new Dependency Scanning analyzer. This analyzer will be a replacement for Gemnasium, which will reach end of support in 18.0, remaining available for use through GitLab 19.0.

The Dependency Scanning using SBOM approach will better support customers through expansion of language support, a tighter integration and experience within the GitLab platform, and a shift towards industry standard report types (SBOM-based scanning and reporting). As of GitLab 17.9, the new Dependency Scanning analyzer will be enabled by default in the `latest` Dependency Scanning CI/CD template (`Dependency-Scanning.latest.gitlab-ci.yml`) for the following project and file types:

- C/C++/Fortran/Go/Python/R projects using conda with a `conda-lock.yml` file.
- Objective-C projects using Cocoapods with a `podfile.lock` file.
- Rust projects using Cargo with a `cargo.lock` file.
- Swift projects using Swift with a `package.resolved` file.

With this change we are introducing a new CI/CD variable: `DS_ENFORCE_NEW_ANALYZER` which is set to `false` by default.

This approach ensures that all existing customers of the `latest` template continue to use the Gemnasium analyzer by default and it enables automatically the new Dependency Scanning analyzer for the file types listed above.

Existing customers who wish to migrate to the new Dependency Scanning analyzer can set `DS_ENFORCE_NEW_ANALYZER` to `true` (at the project, group, or instance level). You can read more about this change in the [deprecation announcement](../../update/deprecations.md#dependency-scanning-upgrades-to-the-gitlab-sbom-vulnerability-scanner) and the associated [migration guide](../../user/application_security/dependency_scanning/migration_guide_to_sbom_based_scans.md).

Customers who want to entirely prevent the use of the new Dependency Scanning analyzer must set the CI/CD variable `DS_EXCLUDED_ANALYZERS` to `dependency-scanning`.

### License scanning support for Swift packages

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/506730)

{{< /details >}}

In GitLab 17.9, we added support for license scanning on Swift packages. This will allow users who use Swift within their projects to better understand the licensing of their Swift packages.

This data is available to composition analysis users through the Dependency List, SBOM reports, and GraphQL API.

### Multi-core Advanced SAST offers faster scans

<!-- categories: SAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/_index.md#security-scanner-configuration) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/514156)

{{< /details >}}

GitLab Advanced SAST now offers multi-core scanning as an opt-in feature to improve performance.
This can reduce scan duration significantly, especially for larger codebases.

To enable it, set the `SAST_SCANNER_ALLOWED_CLI_OPTS` CI/CD variable to `--multi-core N`, where `N` is the desired number of cores to use.
You should only set this variable on the `gitlab-advanced-sast` job, not any other jobs.
Check [the documentation](../../user/application_security/sast/_index.md#security-scanner-configuration) for important guidance on how to select the right value.

We’re working to enable this performance improvement by default; this is tracked in [issue 517409](https://gitlab.com/gitlab-org/gitlab/-/issues/517409).

### Apply a compliance framework by using a project's compliance center

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate, Premium
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/compliance_center/compliance_projects_report.md) | [Related epic](https://gitlab.com/gitlab-org/gitlab/-/issues/507986)

{{< /details >}}

In GitLab 17.2, we released the ability for group owners to apply and remove compliance frameworks for all projects
in a group by using the group’s compliance center.

We have expanded this to now allow group owners to also apply and remove compliance frameworks at the project level.
This will make it even easier for group owners to apply and monitor compliance frameworks at the project level.

The ability to apply and remove compliance frameworks at the project level is only available for group owners and
not project owners.

### Workspace extensions now support proposed APIs

<!-- categories: Workspaces -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/workspace/_index.md#extension-marketplace)

{{< /details >}}

Workspace extensions now support enabling proposed APIs, improving compatibility and reliability in production environments. This update allows extensions that depend on proposed APIs to run without errors, including critical development tools like the Python Debugger. The change expands API access while maintaining stability.

### Implement OCI-based GitOps with the FluxCD CI/CD component

<!-- categories: Container Registry, Deployment Management, Component Catalog -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](https://gitlab.com/components/fluxcd/) | [Related issue](https://gitlab.com/gitlab-org/ci-cd/deploy-stage/environments-group/experiments/fluxcd-ci-cd-component/-/issues/1)

{{< /details >}}

Have you ever wondered how to implement GitOps best practices with GitLab? The new [FluxCD component](https://gitlab.com/components/fluxcd/) makes it easy. Use the FluxCD component to package Kubernetes manifests into OCI images and store the images in OCI-compatible container registries. You can optionally sign the images and trigger an immediate FluxCD reconciliation.

### Get started with the GitLab integration with Kubernetes

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/clusters/agent/getting_started.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/505216)

{{< /details >}}

In this release, we added new Kubernetes Getting started guides that show you how to use GitLab to deploy applications to Kubernetes directly and with FluxCD. These easy-to-follow tutorials don’t require in-depth Kubernetes knowledge to complete, so both novice and experienced users can learn how to integrate GitLab and Kubernetes.

To supplement the Kubernetes Getting started guides, we also included a series of recommendations for integrating GitLab into Kubernetes environments.

### Discover and migrate certificate-based Kubernetes clusters

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/cluster_discovery.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/512420)

{{< /details >}}

The certificate-based Kubernetes integration will be turned off on GitLab.com for all users between May 6, 2025 9:00 AM UTC and May 8, 2025 22:00 PM UTC, and will be removed from GitLab Self-Managed instances in GitLab 19.0 (expected in May 2026).

To help users migrate, we added a new cluster API endpoint that group Owners can query to [discover any certificate-based clusters](../../api/cluster_discovery.md) registered to a group, subgroup, or project. We also updated the [migration documentation](../../user/infrastructure/clusters/migrate_to_gitlab_agent.md) to provide instructions for different types of use cases.

We encourage all GitLab.com users to check if they are affected, and to plan their migrations as soon as possible.

### Enforce custom stages in pipeline execution policies

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/pipeline_execution_policies.md#inject_policy-type) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/475152)

{{< /details >}}

We’re excited to introduce a new capability for pipeline execution policies that allows you to enforce **custom stages** into your CI/CD pipelines in `Inject` mode. This feature provides greater flexibility and control over your pipeline structure while maintaining security and compliance requirements, supplying you with:

- **Enhanced pipeline customization**: Define and inject custom stages at specific points in your pipeline, allowing for more granular control over job execution order.
- **Improved security and compliance**: Ensure that security scans and compliance checks run at the most appropriate times in your pipeline, such as after build but before deployment.
- **Flexible policy management**: Maintain centralized policy control while allowing development teams to customize their pipelines within defined guardrails.
- **Seamless integration**: Custom stages work alongside existing project stages and other policy types, providing a non-disruptive way to enhance your CI/CD workflows.

**How does it work?**

The new and improved `inject_policy` strategy for pipeline execution policies allows you to define custom stages in your policy configuration. These stages are then intelligently merged with your project’s existing stages using a Directed Acyclic Graph (DAG) algorithm, ensuring proper ordering and preventing conflicts.

For example, you can now easily inject a custom security scanning stage between your build and deploy stages.

The `inject_policy` stage replaces `inject_ci` which will be deprecated, allowing you to opt into the `inject_policy` mode to gain the benefits. The `inject_policy` mode will become the default when configuring policies with `Inject` in the policy editor.

### Rotate access tokens with `self_rotate` scope

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/personal_access_tokens.md#personal-access-token-scopes) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/430748)

{{< /details >}}

You can now use the `self_rotate` scope to rotate access tokens. This scope is available for personal, project, or group access tokens. Previously, this required two requests: One to obtain a new token, then another to perform the token rotation.

Thank you [Stéphane Talbot](https://gitlab.com/stalb) and [Anthony Juckel](https://gitlab.com/ajuckel) for your contribution!

### View inactive project and group access tokens

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate, Silver, Gold
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/project/settings/project_access_tokens.md#view-your-access-tokens) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/462217)

{{< /details >}}

You can now view inactive group and project access tokens in the UI. Previously, GitLab instantly deleted project and group access tokens after they expired or were revoked. This lack of a record of inactive tokens made auditing and security reviews more difficult. GitLab now retains inactive group and project access token records for 30 days, which helps teams track token usage and expiration for compliance and monitoring purposes.

### View access token IP addresses

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/personal_access_tokens.md#view-token-usage-information) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/428577)

{{< /details >}}

Previously, when viewing your personal access tokens, the only usage information you could see was how many minutes ago the token was used. Now, you can also see up to the last seven IP addresses that the tokens were used from. This combined information can help you track where your token is being used.

Thank you [Jayce Martin](https://jrm2k.us), [Avinash Koganti](http://www.linkedin.com/in/avinash-koganti-38b511162), [Austin Dixon](https://austindixon.net/), and [Rohit Kala](https://www.linkedin.com/in/rohit-kala-1b891a179) for your contribution!

### Control access to GitLab Pages for groups

<!-- categories: Pages -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/pages/pages_access_control.md#remove-public-access-for-group-pages)

{{< /details >}}

You can now restrict GitLab Pages access at the group level. Group owners can enable a single setting to make all Pages sites in a group and its subgroups visible only to project members. This centralized control simplifies security management without modifying individual project settings.

### Change work item type to another

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/tasks.md#convert-a-task-into-another-item-type) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/385131)

{{< /details >}}

You can now easily change the type of your work items, giving you the flexibility to manage your projects more efficiently.

### Speed up adding new child items by keeping the form open

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/work_items/child_items.md#work-with-multi-level-hierarchies) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/497767)

{{< /details >}}

We’ve streamlined the process of creating multiple child items by keeping the form open after each submission, making it easier to add multiple entries without extra clicks. This update saves you time and ensures a smoother workflow when managing your tasks.

### Work items GraphQL API - additional query filters

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/graphql/reference/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/513308)

{{< /details >}}

The Work Items GraphQL API now includes additional query filters that let you filter by:

- Created, updated, closed, and due dates
- Health status
- Weight

These new filters give you more control when querying and organizing work items through the API.

### Block deletion of active security policy projects

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/_index.md) | [Related epic](https://gitlab.com/gitlab-org/gitlab/-/issues/482967)

{{< /details >}}

To ensure secure management of security policies and prevent disruption to enabled and enforced policies, we’ve added protection to prevent deletion of security policy projects that are in active use.

If a security policy project is linked to any groups or projects, the links must be removed before the security policy project can be deleted.

### Dependency list filter by component in projects

<!-- categories: Dependency Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dependency_list/_index.md#filter-dependency-list) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16490)

{{< /details >}}

On the Dependencies list in a project, you can now filter by the package name using the Component filter.

Previously, you could not search for packages in the Dependencies list for a project level. Now, setting the Component filter will find packages that contain the specified string.

### Filter by identifier in the project Vulnerability Report

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/vulnerability_report/_index.md#filtering-vulnerabilities) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13340)

{{< /details >}}

In the Vulnerability Report for a project, you can now filter the results by vulnerability identifier so you can find specific vulnerabilities (like CVEs or CWEs) that are in your project.
You can use the identifier in conjunction with other filters like the severity, status, or tool filters. The vulnerability identifier filter is limited to reports with 20,000 vulnerabilities or less.

### Support custom roles in merge request approval policies

<!-- categories: Permissions, Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#require_approval-action-type) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13550)

{{< /details >}}

We’ve made merge request approval policies more flexible by adding the ability to assign custom roles as approvers.

You can now tailor approval requirements to match your organization’s unique team structures and responsibilities, ensuring the right roles are engaged in the review process based on the policy. For example, require approval from AppSec Engineering roles for security reviews and Compliance roles for license approvals.

### Search and filter the Credentials Inventory

<!-- categories: System Access -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../administration/credentials_inventory.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/345734)

{{< /details >}}

You can now use search and filter capabilities in the Credentials Inventory. This makes it easier to identify tokens and keys which fall within certain user-defined parameters, including tokens that expire within a certain window. Previously, the entries in the Credentials Inventory were presented as a static list.

### OAuth application authorization audit event

<!-- categories: Audit Events -->

{{< details >}}

- Tier: Ultimate, Premium
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/audit_event_types.md#authorization) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/514152)

{{< /details >}}

Previously, when a user authorized an OAuth application, no audit event was generated. However, this event is important for security teams to
monitor the OAuth applications authorized by users on a specific GitLab instance.

With this release, GitLab now provides a **User authorized an OAuth application** audit event to track when users successfully authorize OAuth
applications. This new audit event further improves your ability to audit your GitLab instance.

### Use API to disable 2FA for individual enterprise users

<!-- categories: System Access -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../api/group_enterprise_users.md#disable-two-factor-authentication-for-an-enterprise-user) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/383319)

{{< /details >}}

You can now use the API to clear all two-factor authentication (2FA) registrations for an individual enterprise user. Previously, this was only possible in the UI. Using the API allows for automated and bulk operations, saving time when 2FA resets need to be done at scale.

### Email notifications for service accounts

<!-- categories: System Access -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/profile/service_accounts.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/428750)

{{< /details >}}

You can now set a custom email address to receive email notifications for service accounts. When a custom email address is specified when creating a service account, GitLab sends notifications to that address. Each service account must use a unique email address. This can help you monitor processes and events more effectively.

Thank you [Gilles Dehaudt](https://gitlab.com/tonton1728), [Étienne Girondel](https://gitlab.com/lenaing), [Kevin Caborderie](https://gitlab.com/Densett), [Geoffrey McQuat](https://gitlab.com/gmcquat), [Raphaël Bihore](https://gitlab.com/rbihore) from the [SNCF Connect & Tech team](https://www.sncf-connect-tech.fr/) for your contribution!

### Support for additional group memberships with multiple OIDC providers

<!-- categories: System Access -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/auth/oidc.md#configure-multiple-openid-connect-providers) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/408248)

{{< /details >}}

You can now configure additional group memberships when using multiple OIDC providers. Previously, if you configured multiple OIDC providers, you were limited to a single group membership.

### Custom expiration date for rotated service account tokens

<!-- categories: System Access -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../api/service_accounts.md#rotate-a-personal-access-token-for-a-group-service-account) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/505671)

{{< /details >}}

When rotating an access token for a service account, you can now use the `expires_at` attribute to set a custom expiration date. Previously, tokens automatically expired seven days after rotation. This allows for more granular management of token lifetimes, enhancing your ability to maintain secure access controls.

### Support merge request variables in pipeline execution policies

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/pipeline_execution_policies.md) | [Related epic](https://gitlab.com/gitlab-org/gitlab/-/issues/512916)

{{< /details >}}

Pipeline execution policies now support additional merge request variables, allowing you to create more sophisticated policies that take into account information related to the merge request. This provides more targeted and efficient control over CI/CD enforcement. The following variables are now supported:

- `CI_MERGE_REQUEST_SOURCE_BRANCH_SHA`
- `CI_MERGE_REQUEST_TARGET_BRANCH_SHA`
- `CI_MERGE_REQUEST_DIFF_BASE_SHA`

With this enhancement, you can:

- Implement advanced security scans that compare changes between source and target branches, ensuring thorough code review and vulnerability detection.
- Create dynamic pipeline configurations that adapt based on the specifics of each merge request, streamlining your development process.

### New permissions for custom roles

<!-- categories: Permissions -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/custom_roles/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/14746)

{{< /details >}}

You can create custom roles with the [Read compliance dashboard](https://gitlab.com/gitlab-org/gitlab/-/issues/465324) permission. Custom roles allow you to grant only the specific permissions users need to complete their tasks. This helps you define roles that are tailored to the needs of your group, and can reduce the number of users who need the Maintainer or Owner role.

### GitLab Runner 17.9

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 17.9 today! GitLab Runner is the highly-scalable build agent that runs
your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with
GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s new

- [Add health check for runner autoscaler instances](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38271)
- [Add histogram metrics for runner prepare stage duration](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37471)
- [Add support for custom service container names to the Kubernetes executor](https://gitlab.com/gitlab-org/gitlab/-/issues/421131)

#### Bug Fixes

- [GitLab Runner is unable to retrieve cache from S3 Express One Zone](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38484)
- [GitLab Runner on Kubernetes reports ‘script_failure’ instead of ‘runner_system_failure’ for AWS Spot instances](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37911)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-9-stable/CHANGELOG.md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.9)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.9)
- [UI improvements](https://papercuts.gitlab.com/?milestone=17.9)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
