---
stage: Release Notes
group: Monthly Release
date: 2025-09-18
title: "GitLab 18.4 release notes"
description: "GitLab 18.4 released with GitLab Duo Model Selection now generally available"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On September 18, 2025, GitLab 18.4 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Patrick Rice

Patrick Rice continues his exceptional dedication to GitLab’s open source community as contributor, maintainer,
and mentor.
A [top 5 contributor](https://contributors.gitlab.com/leaderboard?fromDate=2025-01-01&toDate=2025-09-18&search=&communityOnly=true)
over the past year, Patrick maintains the [GitLab Terraform Provider](https://gitlab.com/gitlab-org/terraform-provider-gitlab)
and [client-go](https://gitlab.com/gitlab-org/api/client-go) projects,
handling feature additions, releases, issue triage, and community onboarding.
He embodies GitLab’s mission that everyone can contribute, having worked his way up from
contributor to project maintainer.

Patrick’s impact extends beyond code contributions to community building and coaching,
helping new contributors get started and grow in the project.
Patrick previously nominated and supported Heidi Berry who won the [17.11 Notable Contributor award](https://about.gitlab.com/releases/2025/04/17/gitlab-17-11-released/#notable-contributor).
He also shared insights with the [GitLab for Education](https://about.gitlab.com/solutions/education/)
team on working with students learning GitLab to help us grow the next generation of developers.

“I’d love to encourage new contributors to join us in collaborating on the Terraform Provider
and client-go projects,” Patrick says.
“We can always use more friendly faces in our community.”

“Patrick has continued relentlessly supporting the GitLab team and customers,” says [Lee Tickett](https://gitlab.com/leetickett-gitlab),
Staff Fullstack Engineer at GitLab, who nominated Patrick for the award.
[Timo Furrer](https://gitlab.com/timofurrer), Senior Backend Engineer at GitLab, supported the nomination.
“Apart from his daily contributions to the Terraform Provider and client-go,” Timo adds,
“he’s helping GitLab customers directly with their IaC journey by showcasing what is possible with the
GitLab Terraform Provider.”

Patrick is an Enterprise Architect at Kingland and member of the [GitLab Community Core Team](https://about.gitlab.com/community/core-team/).
This marks his second Notable Contributor award, having [previously won in GitLab 15.8](https://about.gitlab.com/releases/2023/01/22/gitlab-15-8-released/#mvp) in January 2023.

Thanks to Patrick for his sustained contributions and dedication to supporting GitLab customers
and growing our open source community!

## Primary features

### GitLab Duo Model Selection now generally available

<!-- categories: Model Personalization -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Core, Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/gitlab_duo/model_selection.md#select-a-model-for-a-feature) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/18818)

{{< /details >}}

GitLab Duo Model Selection is now generally available, giving organizations greater control over which AI models power their development workflows.

Owners of top-level groups on GitLab.com and administrators on Self-Managed and Dedicated can now choose a specific model from a variety of GitLab AI model vendors for use with their GitLab Duo features, accessed through the GitLab-hosted AI gateway.

GitLab users that belong to multiple namespaces on GitLab.com can now also set a default namespace to ensure consistent AI model preferences across all development contexts. For more information on GitLab Duo Model Selection, [read the blog](https://about.gitlab.com/blog/speed-meets-governance-model-selection-comes-to-gitlab-duo/).

### GitLab Knowledge Graph

<!-- categories: Duo Agent Platform, Duo Chat, Code Suggestions, Vulnerability Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](https://gitlab-org.gitlab.io/rust/knowledge-graph/) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/17514)

{{< /details >}}

The GitLab Knowledge Graph provides rich code intelligence across your codebase. Developers can understand and navigate their projects with greater context, making it easier to plan changes, perform impact analysis, and work with GitLab Duo agents to accelerate development tasks.

The GitLab Duo Agent Platform leverages the Knowledge Graph to increase the accuracy of AI agents. By mapping files and definitions across a codebase, the Knowledge Graph provides enhanced context that allows Duo agents to understand relationships across your entire local workspace—unlocking faster and more precise responses to complex questions.

This release of the Knowledge Graph focuses on local code indexing, where the CLI turns your codebase into a live, embeddable graph database for RAG. You can install it with a simple one-line script, parse local repositories, and connect via MCP to query your workspace.

Our vision for the Knowledge Graph project is two-fold: building a vibrant community edition that developers can run locally today, which will serve as the foundation for a future, fully integrated Knowledge Graph Service within GitLab.com and self-managed instances.

This feature is in beta status. Provide feedback in [issue 160](https://gitlab.com/gitlab-org/rust/knowledge-graph/-/issues/160).

### End user model selection now available with GitLab Duo

<!-- categories: Model Personalization -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com
- Add-ons: Duo Core, Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/gitlab_duo/model_selection.md#select-a-model-for-a-feature) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/19251)

{{< /details >}}

GitLab Duo model selection for end-users is now in public beta on GitLab.com. Users can now select their preferred model for GitLab Duo Agentic Chat directly in the GitLab UI, giving developers personalized control over their AI assistance experience.

When allowed by namespace owners on GitLab.com, end-users can choose from available GitLab AI Vendor models for use with GitLab Duo Agentic Chat. Namespace owners can continue to set organization-wide model preferences through namespace settings, or allow end-user model selection.

To get started, look for the model dropdown in GitLab Duo Agentic Chat to select your preferred model. Note that changing models will start a fresh conversation, and your preferences will be remembered for future sessions.

### CI/CD job tokens can authenticate Git push requests

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../ci/jobs/ci_job_token.md#allow-git-push-requests-to-your-project-repository) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/389060)

{{< /details >}}

You can now allow CI/CD job tokens generated in your project to authenticate Git push requests to the project’s repository.
Enable this with the Job token permissions settings in the UI, or alternatively with the `[ci_push_repository_for_job_token_allowed](../../api/projects.md#edit-a-project)`
parameter in the project’s REST API endpoint.

### GitLab Duo context exclusion

<!-- categories: Duo Agent Platform, Duo Chat, Code Suggestions, Vulnerability Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/gitlab_duo/context.md#exclude-context-from-code-review) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/17124)

{{< /details >}}

GitLab Duo context exclusion allows you to control which project content is excluded as context for GitLab Duo. This is helpful to protect sensitive information such as password files and configuration files. You can exclude individual files, specific directories, specific file types, or any combination of these.

This feature is currently in beta. Provide feedback on GitLab Duo context exclusion in [issue 566244](https://gitlab.com/gitlab-org/gitlab/-/issues/566244).

### Expanded AWS region support for GitLab Dedicated

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../administration/dedicated/create_instance/data_residency_high_availability.md#supported-regions)

{{< /details >}}

GitLab Dedicated now supports deployment in all AWS regions, enabling you to select from an [expanded list of regions](../../administration/dedicated/create_instance/data_residency_high_availability.md#supported-regions) for your primary, secondary, and backup deployment location.

This expansion is enabled by AWS’s rollout of io2 disks across all regions, which meet GitLab Dedicated’s standards for high availability and disaster recovery.

All newly available regions can be selected when provisioning your GitLab Dedicated instance in Switchboard.

### Simulate CI/CD Pipelines against different branch

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../ci/pipeline_editor/_index.md#validate-cicd-configuration) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/482676)

{{< /details >}}

Previously, when using the pipeline editor and validating your changes using the Validate tab, you could only run a simulation for the default branch. In this release, we’ve expanded this capability. You can now select any branch to simulate pipelines against. This improvement gives you greater flexibility in testing and validating your pipelines. You can ensure they perform as expected across different cases, including your stable branches or feature branches.

## Agentic Core

### Automatic Duo Code Review for groups and applications

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com
- Add-ons: Duo Enterprise
- Links: [Documentation](../../user/project/merge_requests/duo_in_merge_requests.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/554070)

{{< /details >}}

You can now use group or application settings to enable automatic Duo Code Review for multiple projects. This can help you quickly enable Duo Code Review for all projects in a group, rather than individually enabling specific projects.

This feature is currently available in GitLab.com, and we plan to make it available for GitLab Self-Managed in a future release. Provide feedback in [issue 517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386).

### Additional supported models for GitLab Duo Self-Hosted

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enteprise
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16742)

{{< /details >}}

GitLab Self-Managed customers with GitLab Duo Enterprise can now use additional supported models with GitLab Duo.
OpenAI GPT-5 is now supported on Azure OpenAI. Open source OpenAI GPT OSS 20B and 120B aer also now supported on vLLM and Azure OpenAI.
To leave feedback on using these models with GitLab Duo Self-Hosted, see [issue 523918](https://gitlab.com/gitlab-org/gitlab/-/issues/523918).

### Duo Code Review on GitLab Duo Self-Hosted is generally available

<!-- categories: Code Suggestions, Self-Hosted Models -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/_index.md#gitlab-duo) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/548975)

{{< /details >}}

GitLab Duo Code Review on GitLab Duo Self-Hosted is now generally available. Use Code Review on GitLab Duo Self-Hosted to accelerate your development process without compromising on data sovereignty. When Code Review reviews your merge requests, it identifies potential bugs and suggests improvements for you to apply directly. Use Code Review to iterate on and improve your changes before you ask a human to review. This feature includes support for Mistral, Meta Llama, Anthropic Claude, and OpenAI GPT model families.

Provide feedback on Code Review in [issue 517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386).

## Unified DevOps and Security

### Pipeline secret detection now excludes certain files and directories by default

<!-- categories: Secret Detection -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/secret_detection/pipeline/_index.md#excluded-items) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/560147)

{{< /details >}}

Pipeline secret detection now automatically excludes [certain file types and directories](../../user/application_security/secret_detection/pipeline/_index.md#excluded-items)
if they have a low likelihood of containing secrets, improving scan performance. These changes are released in analyzer
[version 7.11.0](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v7.11.0).

### Secret detection analyzer Git fetching improvements

<!-- categories: Secret Detection -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/secret_detection/pipeline/_index.md#how-the-analyzer-fetches-commits) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/17315)

{{< /details >}}

Version [7.12.0](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v[7.12.0](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v7.12.0)) of the secret detection analyzer adds significant improvements to the way Git commits are fetched. The analyzer now parses `--depth` and `--since` options passed from `SECRET_DETECTION_LOG_OPTIONS`, so you can further specify how many commits you want to scan. The analyzer also selects appropriate fetch strategies based on context, which prevents a known issue where potentially millions of commits were unnecessarily fetched, even with shallow depth configurations.

This enhancement reduces job timeouts, decreases resource consumption, and provides more predictable scan performance. Experience faster secret detection scans, especially in large repositories, with clearer logging that matches the actual fetching behavior.

### Significantly faster Advanced SAST scanning

<!-- categories: SAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/sast/gitlab_advanced_sast.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16561)

{{< /details >}}

Every minute counts when you’re enabling security scans in your merge requests and pipelines.
We routinely ship performance improvements for Advanced SAST, targeting both the engine and its detection rules.

In this release, we’re highlighting a specific improvement that cuts scan runtime by as much as 78% in our benchmark and real-world tests.
We’ve added caching in a performance-sensitive part of the scanning process, leading to significantly faster scans in large repositories.

This improvement is automatically enabled in Advanced SAST analyzer version 2.9.6 and later.
You can see which analyzer version you’re using by [checking scan job logs](../../user/application_security/sast/gitlab_advanced_sast.md).

### Operational Container Scanning severity threshold configuration

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/clusters/agent/vulnerabilities.md#configure-trivy-severity-threshold-filter) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/559278)

{{< /details >}}

You can now configure Operational Container Scanning (OCS) to only return vulnerabilties at or above a certain severity level.
After you set a severity threshold, vulnerabilities below the severity you choose are no longer returned in the Vulnerability Report, API payloads, and other reporting mechanisms.
This can help you focus on the vulnerabilities you want to remediate.

To enable this filtering, [set a `severity_threshold`](../../user/clusters/agent/vulnerabilities.md#configure-trivy-severity-threshold-filter) in your OCS configuration.

We gratefully acknowledge this community contribution from [John Walsh](https://gitlab.com/mjohnw).
To learn more about contributing to GitLab, check out the [Community Contribution program](https://about.gitlab.com/community/contribute/).

### Publish OpenTofu modules and providers to the GitLab container registry with CI/CD templates

<!-- categories: Infrastructure as Code -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](https://gitlab.com/components/opentofu#publish-providers-to-the-gitlab-oci-registry) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/562715)

{{< /details >}}

The GitLab container registry now supports the media types to
host OpenTofu modules and providers.

Version [3.1.0](https://gitlab.com/components/opentofu/-/releases/[3.1.0](https://gitlab.com/components/opentofu/-/releases/3.1.0)) of the
[OpenTofu CI/CD component](https://gitlab.com/components/opentofu) supports
a new `provider-release` template to deploy an OpenTofu provider into the GitLab registry
using the OCI format. Now, you can host private OpenTofu providers directly in GitLab.

In addition, the `module-release` template now supports a new `type` input that you can set to `oci`
to deploy the OpenTofu module in the GitLab registry using the OCI format.

### Bypass confirmation for enterprise users when reassigning placeholders

<!-- categories: Importers -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/import/mapping/reassignment.md#bypass-confirmation-when-reassigning-placeholder-users) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/17871)

{{< /details >}}

Users with the Owner role for a group can now bypass user confirmation when reassigning placeholders to active enterprise users in that group. This way, enterprise users do not have to keep checking their emails to confirm reassignments. After the time limit for the setting is reached, email confirmation requests are sent again for all new reassignments.

Enterprise users still receive notification emails after the reassignment is complete, ensuring transparency throughout the process.

### Configure how to view issues from the Issues page

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/project/issues/managing_issues.md#open-issues-in-a-panel) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/570776)

{{< /details >}}

You now have full control over your listing page view, choose which metadata appears and whether to open work items in a drawer, making it easier to focus on the information that matters most to you.

Previously, all metadata fields were always visible, which could make scanning through work items overwhelming. Now you can customize your view by turning on or off specific fields like assignees, labels, dates, and milestones.

With the new toggle that switches between the drawer view and full-page navigation you can quickly review details while maintaining context of your list, or open the full page when you need more screen space for detailed editing and comprehensive navigation.

### Enhanced parent filtering for epic and issue lists

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/project/issues/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/556200)

{{< /details >}}

We’ve replaced the “epic” filter on the Issues and Epics pages with a more flexible “parent” filter. This change lets you filter by any parent work item, not just epics. You can now easily find child tasks by filtering by their parent issue, or find issues by filtering by their parent epic, giving you better visibility into your work hierarchy across both issue and epic lists.

### Issue boards now show complete epic hierarchies

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/project/issue_board.md#filter-issues) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/358416)

{{< /details >}}

You can now view all issues from child epics when filtering by a parent epic in issue boards, bringing consistency with how the Issues page already works. This improvement helps you better track and visualize your complete epic hierarchy without missing any issues nested in child epics, making your project management workflow more efficient and reliable.

### Text editors toolbar parity

<!-- categories: Markdown -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/rich_text_editor.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/507377)

{{< /details >}}

The GitLab plain text editor now includes the same formatting options as the rich text editor. The plain text editor toolbar has been updated with a “More options” menu that provides access to advanced formatting tools like:

- Code blocks
- Details blocks
- Horizontal rules
- Mermaid diagrams
- PlantUML diagrams
- Table of contents

Both editors now have consistent button placement and separators, making it easier to switch between editing modes while maintaining access to familiar formatting options.

### Vulnerability details shows the auto-resolve pipeline ID

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/policies/vulnerability_management_policy.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/566392)

{{< /details >}}

When troubleshooting vulnerabilities that have been automatically resolved, and later redetected, it can be helpful to compare the current pipeline to the pipeline where the vulnerability was resolved.

If a vulnerability is automatically resolved, the vulnerability notes in the vulnerability details page now include the pipeline ID where it occurred.

### Enhanced controls for who can download job artifacts

<!-- categories: Artifact Security -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../ci/yaml/_index.md#artifactsaccess) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/454398)

{{< /details >}}

In GitLab 16.11, we added the `artifacts:access` keyword enabling users to control whether artifacts can be downloaded by all users with access to the pipeline, only users with the Developer role or higher, or no user at all.

In this release, you can now restrict who can download artifacts to only the Maintainer role or higher, giving you one more option for controlling who can download job artifacts.

### GitLab Runner 18.4

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 18.4 today! GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### Bug Fixes

- [FIPS runners fail to start jobs with GitLab Runner 18.2.1](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38963)
- [The `chown` command for runners with custom ConfigMap & security context constraints (SCC) fails after Operator v1.37.0 upgrade on OpenShift 4.16.27](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/246)
- [Reinstate `FF_RETRIEVE_POD_WARNING_EVENTS` in GitLab 17.x.x releases due to early removal in 17.2](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38851)
- [All GitLab Runner jobs fail due to filesystem permission errors](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/214)
- [Build jobs fail sporadically with permission denied error](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37464)
- [GitLab Runner Helm chart upgrade broke the variables](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30851)
- [Enabling `FF_USE_FASTZIP` does not enable fastzip](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28989)
- [GitLab Runner encounters an `UnsupportedOperation` error when trying to stop Spot instances created with one-time requests](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28865)
- [Long polling for GitLab Runners does not work properly in Kubernetes deployed environments](https://gitlab.com/gitlab-org/gitlab/-/issues/331460)
- [Allow admins to override image:Kubernetes:user value](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38894)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-4-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-4-stable/CHANGELOG.md).md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.4)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.4)
- [UI improvements](https://papercuts.gitlab.com/?milestone=18.4)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
