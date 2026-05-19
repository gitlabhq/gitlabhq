---
stage: Release Notes
group: Monthly Release
date: 2026-03-19
title: "GitLab 18.10 release notes"
description: "GitLab 18.10 released with SAST false positive detection with GitLab Duo Agent Platform"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On March 19, 2026, GitLab 18.10 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Harshith Sudar

Harshith is currently a Level 3 Contributor who has made impactful contributions improving community tooling and analytics, from triage automation and contributor recognition to [GitLab Duo](https://about.gitlab.com/gitlab-duo/) usage insights.

Harshith’s contributions were first recognized by [Lee Tickett](https://gitlab.com/leetickett-gitlab), Fullstack Engineer in DevRel Engineering at GitLab, who nominated him. His work has strengthened how we support contributors behind the scenes through improvements to our automation and contributor-facing experiences. For example, he expanded our triage automation by [updating the `IssueSummary` processor in triage-ops to work with multiple projects](https://gitlab.com/gitlab-org/quality/triage-ops/-/merge_requests/3589), including [contributors.gitlab.com](https://contributors.gitlab.com), making it easier for us to keep more community projects consistently summarized and visible. He also helped recognize community-created content through the [new “Add content” button and flow](https://gitlab.com/gitlab-org/developer-relations/contributor-success/contributors-gitlab-com/-/merge_requests/1250), which lets contributors log blog posts, videos, and other content directly from their profile and get rewarded.

Harshith has also contributed to our analytics and GitLab Duo usage insights. Highlights include [refining how GitLab Duo usage is calculated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207511), improving how AI impact over time can be explored by [removing the 180-day default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218870), and [consolidating DORA metric date range constants](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/216715), as well as enhancing analytics at scale with improvements like adding [infinite scroll for the Value Stream Analytics custom stage label picker](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207796). Together, these changes help teams better understand how GitLab is used in real projects.

In his own words:

> “One thing I’ve really enjoyed while contributing is how thoughtfully ideas are discussed within the community. It’s encouraging to see suggestions explored collaboratively, like in the discussion around [MR !1288](https://gitlab.com/gitlab-org/developer-relations/contributor-success/contributors-gitlab-com/-/merge_requests/1288), which turned into a great learning experience.
> I’m really happy to be part of this community and look forward to making many more contributions in the future.”

Thank you, Harshith, for your ongoing work to improve the GitLab codebase and contributor experience!

Want to connect with Harshith and learn more about his contributions? Visit Harshith’s [GitLab profile](https://gitlab.com/official.harshith1) and his [LinkedIn profile](https://www.linkedin.com/in/harshith-s-a44169282/).

## Primary features

### SAST false positive detection with GitLab Duo Agent Platform

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Add-ons: Duo Core, Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/application_security/vulnerabilities/false_positive_detection.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/19789)

{{< /details >}}

SAST false positive detection, which was first introduced as a beta in GitLab 18.7, is now generally available in GitLab 18.10.

When a security scan runs, GitLab Duo Agent Platform analyzes each critical and high severity SAST vulnerability and determines the likelihood that it’s a false positive.
The assessment appears directly in the vulnerability report, giving teams the context they need to triage with confidence rather than uncertainty.

Key capabilities include:

- Automatic analysis: False positive detection runs automatically after each security scan with no manual intervention required.
- Manual option: Users can manually run false positive detection for individual vulnerabilities on the vulnerability details page for on-demand analysis.
- Focus on high-impact findings: Limiting the analysis to critical and high severity SAST vulnerabilities cuts through the noise where it matters most.
- Contextual AI reasoning: Each assessment explains why a finding may or may not be a false positive, factoring in code context, data flow, and vulnerability characteristics specific to static analysis.
- Seamless workflow integration: Results surface directly in the vulnerability report alongside existing severity, status, and remediation information — no changes to existing workflows required.

This feature is available for Ultimate customers with GitLab Duo Agent Platform. The feature must be enabled in your group or project settings.
We welcome your feedback in [issue 583697](https://gitlab.com/gitlab-org/gitlab/-/issues/583697).

### Purchase GitLab Credits on the Free tier on GitLab.com

<!-- categories: Subscription Management -->

{{< details >}}

- Tier: Free
- Offering: GitLab.com
- Add-ons: GitLab Credits
- Links: [Documentation](../../subscriptions/gitlab_credits.md#for-the-free-tier) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/20165)

{{< /details >}}

Free tier group Owners on GitLab.com can now unlock AI with GitLab Credits. Purchase a monthly credit amount, commit to an annual term, and get access to [GitLab Duo Agent Platform agents and flows](../../subscriptions/gitlab_credits.md#for-the-free-tier). Credits refresh automatically each month, so your team always has what it needs to build faster and smarter.

Key highlights:

- **Usage-based pricing**: Purchase a monthly credit commitment without needing a base plan subscription.
- **Self-service purchasing**: Buy credits through the GitLab purchase flow.
- **Seamless upgrade path**: Your credit commitment transfers if you later upgrade to Premium or Ultimate.
- **Consumption tracking**: Monitor your credit usage through the GitLab Credits dashboard.

This [purchase option](../../subscriptions/gitlab_credits.md#buy-gitlab-credits) is currently only available for free GitLab.com top-level groups.

### Sign in securely with passkeys

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../auth/passkeys.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/10897)

{{< /details >}}

GitLab now supports passkeys for passwordless sign-in and as a phishing-resistant two-factor authentication (2FA) method. Passkeys use public-key cryptography and biometric authentication (fingerprint, face recognition) or your device PIN to securely access your account.

Passkeys offer the following benefits:

- **Passwordless convenience**: Sign in with your device’s biometrics or PIN instead of remembering a password.
- **Multi-device support**: Use passkeys on desktop browsers, mobile devices (iOS 16 or later, Android 9 or later), and FIDO2/WebAuthn-compatible hardware security keys.
- **Phishing-resistant security**: Your private key never leaves your device. GitLab only stores the public key, protecting your account even if GitLab servers are compromised.
- **Automatic 2FA integration**: For accounts with 2FA enabled, passkeys become available as your default 2FA method.

To get started, add a passkey in your account settings. We welcome your questions and feedback in issue [366758](https://gitlab.com/gitlab-org/gitlab/-/work_items/[366758](https://gitlab.com/gitlab-org/gitlab/-/work_items/366758)).

### Introducing the work items list and saved views

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/work_items/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/17530)

{{< /details >}}

The GitLab planning experience is getting a significant upgrade with the work items list and saved views,
bringing together two long-requested capabilities:

- The work items list combines epics, issues, and other work items into a single unified list, eliminating the need to switch between separate pages for different work item types. This makes it easier to understand relationships across your planning objects.
- Saved views allow you to create and save customized list configurations, including filters, sort order, and display options. This makes routine checks more efficient, and supports standardized ways of viewing work across your team.

This is the next step in the GitLab work items journey, a unified architecture designed to deliver
consistency and unlock new capabilities across GitLab planning tools.

Share your thoughts and feedback in [issue 590689](https://gitlab.com/gitlab-org/gitlab/-/work_items/590689).

### Custom agents can use MCP to access external data

<!-- categories: AI Catalog -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com
- Links: [Documentation](../../user/gitlab_duo/model_context_protocol/ai_catalog_mcp_servers.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/590708)

{{< /details >}}

You can now connect custom agents in the AI Catalog to external data sources and tools through the Model Context Protocol (MCP), without leaving GitLab.

This feature is an experiment. Share your feedback in [issue 593219](https://gitlab.com/gitlab-org/gitlab/-/work_items/593219).

### Enforce merge request title naming conventions with regex

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/project/merge_requests/title_validation.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/20108)

{{< /details >}}

Maintaining consistent merge request titles is important for teams that rely on structured
naming conventions. Whether that’s following the Conventional Commits format,
or linking to an internal tracking system. Teams previously needed external tooling or
custom CI/CD pipeline jobs to enforce these conventions, but this approach had a
critical gap. If someone changed the merge request title after the pipeline ran, there was no
re-validation, and the MR could still be merged with a non-compliant title.

You can now configure a required title regex for merge requests in your project settings.
When configured, GitLab evaluates the merge request title against the pattern as a
mergeability check — blocking the merge until the title is updated to comply, regardless
of when the title was last changed.

To set this up, go to your project’s **Settings > Merge requests** and enter a regex
pattern in the **Merge request title must match regex** field.

Your existing merge request workflows continue to work as before. This check only
applies to projects where you explicitly configure a title regex.

### Secret false positive detection with AI (beta)

<!-- categories: Vulnerability Management, Secret Detection -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Add-ons: Duo Core, Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/application_security/vulnerabilities/secret_false_positive_detection.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/20152)

{{< /details >}}

Security teams spend significant time investigating secret detection findings that turn out to be false positives. For example, test credentials, example values, and placeholder tokens that are incorrectly flagged as actual secrets.
False positives create alert fatigue, erode trust in scan results, and divert attention from genuine security risks.

GitLab 18.10 introduces AI-powered secret false positive detection (beta) to focus on the secrets that actually matter.
When a security scan runs, GitLab Duo automatically analyzes each **Critical** and **High** severity secret detection vulnerability to determine if it’s a false positive.

The AI assessment appears directly in the vulnerability report, giving security engineers immediate context to make faster and confident triage decisions.

Key capabilities include:

- Automatic analysis: False positive detection runs automatically after each security scan without manual trigger.
- Manual trigger option: You can manually trigger false positive detection for individual vulnerabilities on the vulnerability details page for on-demand analysis.
- Focus on high-impact findings: Scoped for **Critical** and **High** severity vulnerabilities to maximize signal-to-noise improvement.
- Contextual AI reasoning: Each assessment includes an explanation of why the finding may or may not be a true positive, based on code context and vulnerability characteristics.
- Confidence scoring: Each detection includes a confidence score to help teams prioritize review based on the model’s certainty.
- Seamless workflow integration: Results surface directly in the vulnerability report alongside existing severity, status, and remediation information.

This feature is available as a free beta for Ultimate customers and must be enabled in your group or project settings.
Share feedback in [issue 592861](https://gitlab.com/gitlab-org/gitlab/-/work_items/592861).

### Use runtime inputs with CI/CD jobs

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../ci/jobs/job_inputs.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/17833)

{{< /details >}}

Using CI/CD variables for dynamic job configuration can be challenging. Variables follow a complex override hierarchy that’s difficult to manage, and they can’t be used for a variety of use cases.

Now you can use `inputs` to define explicit, typed inputs at the job level. Use job inputs to define and control the values that a job accepts at runtime. With job inputs, you get:

- Type safety (string, number, boolean, array).
- Default values that can be static or reference existing variables.
- The option to define a strict list of possible values to use.
- Regex support for validating input values.

Job inputs can use the default values without any user interaction, but you can modify the values when retrying a job or running a manual job.

## Agentic Core

### GitLab Blob Search for group and instance code search

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/duo_agent_platform/agents/tools.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/593221)

{{< /details >}}

The [`[gitlab_blob_search](../../user/duo_agent_platform/agents/tools.md)`](../../user/duo_agent_platform/agents/tools.md) tool now enables GitLab AI agents to search your code:

- Across all projects in a group.
- Across all accessible projects on an instance.

Previously, blob search was limited to a single project, or required specifying explicit project IDs. This change makes it easier for AI-powered workflows to discover and reuse code that’s spread across multiple related projects.

### GitLab MCP server tool for pipeline management

<!-- categories: MCP Server -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/gitlab_duo/model_context_protocol/mcp_server_tools.md#manage_pipeline) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/583826)

{{< /details >}}

You can now manage your CI/CD pipelines in a GitLab project with the new `manage_pipeline` tool.
This GitLab MCP server tool lets AI agents create, cancel, retry, delete, and update pipeline metadata in a single call.
With this tool, you no longer have to piece together multiple steps to automate your pipeline workflows.

If you want to see other GitLab MCP sever tools, let us know in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/566375).

### Project Maintainers can enable custom agents and flows

<!-- categories: AI Catalog -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/duo_agent_platform/flows/custom.md#enable-a-flow) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/590573)

{{< /details >}}

Previously, enabling AI agents and flows from the AI Catalog required top-level group permissions.

Now, when browsing the AI Catalog at the explore level or project level, project Maintainers can enable agents and flows directly in their projects.

### Configure network access control for remote flows in projects

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/duo_agent_platform/environment_sandbox.md#configure-a-network-policy) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/593560)

{{< /details >}}

You can now configure [network access controls](../../user/duo_agent_platform/environment_sandbox.md) for flows using GitLab runners in projects.

This provides secure external integrations, while maintaining control over network destinations. This also gives project maintainers the flexibility to allow necessary API connections, MCP servers, and third-party services while enforcing security boundaries.

Configure [network access controls](../../user/duo_agent_platform/environment_sandbox.md) in the `network_policy` section of `agent-config.yml`. The `agent-config.yml` is protected by branch protection rules and MR approval workflows.

### Self-hosted Vertex AI for GitLab Duo Agent Platform

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/supported_llm_serving_platforms.md#configure-authentication-with-google-vertex-ai) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/591604)

{{< /details >}}

Vertex AI is now a supported LLM platform within GitLab Duo Agent Platform Self-Hosted.

Customers can now configure Anthropic models hosted on Vertex AI for use with GitLab Duo Agent Platform features.

### Users can enable agents and flows directly from projects

<!-- categories: AI Catalog -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/duo_agent_platform/agents/custom.md#enable-an-agent) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/588012)

{{< /details >}}

Maintainers and Owners can now enable agents and flows directly from their project or the explore page, without navigating away from their current context.

Top-level group Owners can also select their group, and the specific projects where they want to activate agents and flows, streamlining their workflow setup.

### Support for Agent Skills in IDEs and CI/CD pipelines

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/duo_agent_platform/customize/agent_skills.md) | [Related issue](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/1984)

{{< /details >}}

GitLab Duo Agent Platform now supports the [Agent Skills specification](https://agentskills.io/specification),
an emerging standard for giving AI agents new capabilities and expertise.

You can define Agent Skills at the workspace level for your project
to give agents specialized knowledge and workflows for specific tasks, like writing
tests in a specific framework. Agents automatically discover and load relevant skills
as they encounter matching tasks.

You can also trigger skills manually by name, file path, or custom slash commands.
Agent Skills are accessible for flows and Agentic Chat in your IDE, and for
flows run in CI/CD pipelines. They also work with any other AI tool that supports
the specification.

## Scale and Deployments

### Download credit usage data as CSV

<!-- categories: Consumables Cost Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../subscriptions/gitlab_credits.md#export-usage-data) | [Related issue](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/14504)

{{< /details >}}

Billing managers can now download credit usage data as a CSV file directly from the GitLab Credits dashboard in Customers Portal.

The export provides a daily, per-action breakdown of credit consumption for the current billing month, including commitment, waiver, trial, on-demand, and included credits used.

Finance and operations teams can use this data to perform cost allocation, chargeback reporting, and usage analysis in Excel, Google Sheets, or BI tools without manual data gathering or support requests.

### Link credit usage to GitLab Duo Agent Platform sessions

<!-- categories: Consumables Cost Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../subscriptions/gitlab_credits.md#gitlab-credits-dashboard) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/579139)

{{< /details >}}

The GitLab Credits dashboard now links credit consumption directly to the GitLab Duo Agent Platform session that generated it.

In the per-user drill-down view, the **Action** column for Agent Platform usage rows (such as **Agentic Chat** or **Foundational Agents**) is now a clickable hyperlink that navigates to the corresponding session details.

This link provides a direct audit trail from billing to AI session behavior, so administrators can investigate credit usage, support escalations, and compliance reviews without manually correlating timestamps across separate systems.

### Sort users in the GitLab Credits dashboard

<!-- categories: Consumables Cost Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../subscriptions/gitlab_credits.md#view-the-gitlab-credits-dashboard) | [Related issue](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/15608)

{{< /details >}}

Enterprise administrators can now sort the **Usage by User** table in the GitLab Credits dashboard by total credits used or by username.

The default sort order is by total credits consumed (highest first), so the top consumers are immediately visible without scrolling.

With this view, administrators managing thousands of GitLab Duo users can quickly identify high-usage individuals for cost allocation, chargeback reporting, and license utilization audits.

### New navigation experience for projects in Explore

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/project/working_with_projects.md#explore-all-projects-on-an-instance) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/13786)

{{< /details >}}

We’ve streamlined the projects page in **Explore** to reduce clutter and remove redundant options that accumulated over time.
The simplified interface now focuses on two core views:

- **Active** tab: Discover projects with recent activity and ongoing development.
- **Inactive** tab: Access archived projects and those scheduled for deletion.

We’ve removed several redundant tabs:

- **Most starred** projects can be found by sorting **Active** or **Inactive** tabs by star count.
- **All** projects are available by viewing both **Active** and **Inactive** tabs.
- **Trending** tab will be fully removed in GitLab 19.0 due to limited functionality and low usage.

The cleaner design aligns with other project lists for visual consistency. You can still access all the same content through more logical organization and flexible sorting options.

## Unified DevOps and Security

### Dependency Scanning with SBOM support for Java Gradle build files

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#manifest-fallback) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/588788)

{{< /details >}}

GitLab dependency scanning by using SBOM now supports scanning Java `build.gradle` and `build.gradle.kts` build files.

Previously, dependency scanning for Java projects using Gradle required a lock file to be present.
Now, when a lock file is not available, the analyzer automatically falls back to scanning `build.gradle` and `build.gradle.kts` files, extracting and reporting only direct dependencies for vulnerability analysis.
This improvement makes it easier for Java projects using Gradle to enable dependency scanning without requiring a lock file.

To enable manifest fallback, set the `DS_ENABLE_MANIFEST_FALLBACK` CI/CD variable to `"true"`.

### Dependency scanning SBOM-based scanning extended to self-managed

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/546429)

{{< /details >}}

In GitLab 18.10, we’re extending limited availability status to self-managed instances for the new SBOM-based dependency scanning feature.

This feature was initially released in GitLab 18.5 with limited availability for GitLab.com only, behind the feature flag `dependency_scanning_sbom_scan_api` and disabled by default.

With additional improvements and fixes, we now have confidence to reliably use the new SBOM scanning internal API and enable this feature flag by default.
This internal API allows the dependency scanning analyzer to generate a dependency scanning report containing all component vulnerabilities.
Unlike the previous behavior (Beta) that processed SBOM reports after CI/CD pipeline completion, [this improved process](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#how-it-scans-an-application) generates scan results immediately during the CI/CD job, giving users instant access to vulnerability data for custom workflows.

Self-managed customers who encounter issues can disable the `dependency_scanning_sbom_scan_api` feature flag. The analyzer will then fall back to the previous behavior.

To use this feature, import the v2 dependency scanning template `Jobs/Dependency-Scanning.v2.gitlab-ci.yml`.

We welcome feedback on this feature. If you have questions, comments, or would like to engage with our team, please reach out in this [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/523458).

### License scanning support for Dart/Flutter projects using Pub package manager

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md#data-sources) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/18351)

{{< /details >}}

GitLab now supports license scanning for Dart and Flutter projects that use the `pub` package manager.
Previously, teams building with Dart or Flutter were unable to identify the licenses of their open source dependencies directly within GitLab, creating compliance blind spots for organizations with license policy requirements.

License data is sourced directly from [pub.dev](https://pub.dev), the official Dart package repository, and results are surfaced alongside other supported ecosystems.
Dart/Flutter dependency scanning and vulnerability detection were already supported.

### Conan 2.0 package registry support (Beta)

<!-- categories: Package Registry -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/packages/conan_2_repository/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/585819)

{{< /details >}}

C and C++ development teams using Conan as their package manager have long requested registry support in GitLab. Previously, the Conan package registry was experimental and only supported Conan 1.x clients, limiting adoption for teams that have migrated to the modern Conan 2.0 toolchain.

The Conan package registry now supports Conan 2.0 and has been promoted from Experimental to Beta. This release includes full v2 API compatibility, recipe revision support, improved search capabilities, and proper handling of upload policies including the `--force` flag. Teams can publish and install Conan 2.0 packages directly from GitLab using standard Conan client workflows, reducing the need for external artifact management solutions like JFrog Artifactory.

With this update, platform engineering teams managing C and C++ dependencies can consolidate their package management within GitLab alongside their source code, CI/CD pipelines, and security scanning. The Conan registry supports both project-level and instance-level endpoints, and works with personal access tokens, deploy tokens, and CI/CD job tokens for authentication.

We welcome feedback as we work toward general availability. Please share your experience in the [epic](https://gitlab.com/groups/gitlab-org/-/work_items/6816).

### Manage container virtual registries with a dedicated UI (Beta)

<!-- categories: Virtual Registry -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/packages/virtual_registry/container/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/19283)

{{< /details >}}

When the container virtual registry launched in beta last milestone, platform engineers could aggregate multiple upstream container registries — Docker Hub, Harbor, Quay, and others — behind a single pull endpoint. However, all configuration required direct API calls, meaning teams had to maintain scripts or manual curl commands to create and manage their registries, configure upstreams, and handle changes over time. This added operational overhead and made the feature inaccessible to users who weren’t comfortable working directly with the API.

Container virtual registries can now be created and managed directly from the GitLab UI. From the group-level container registry page, you can create new virtual registries, configure upstream sources with authentication credentials, edit existing configurations, and delete registries you no longer need — all without leaving GitLab or writing a single API call. The UI integrates seamlessly with the existing container registry experience, making virtual registries a first-class part of your group’s artifact management workflow.

This feature is in beta. To share feedback, please comment in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/589630).

### GitLab Helm Chart registry generally available

<!-- categories: Package Registry -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/packages/helm_repository/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/573715)

{{< /details >}}

Teams using Helm to manage Kubernetes application deployments can now rely on the GitLab Helm Chart registry for production workloads. Previously in beta, the registry is now generally available following the resolution of key architectural and reliability concerns.

The path to GA included resolving a hard limit that prevented the `index.yaml` endpoint from returning more than 1,000 charts, fixing a background indexing bug that caused newly published chart versions to be missing from the index, completing a full AppSec security review, and adding Geo replication support for Helm metadata cache, ensuring high availability for self-managed customers running GitLab Geo.

Platform and DevOps teams can publish and install Helm charts directly from GitLab using standard Helm client workflows, with support for project-level endpoints and authentication using personal access tokens, deploy tokens, and CI/CD job tokens. Now you can keep charts alongside the source code, pipelines, and security scanning that depend on them.

### Task item support in Markdown tables

<!-- categories: Markdown -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/markdown.md#task-lists-in-tables) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/21506)

{{< /details >}}

You can now use task item checkbox syntax directly in Markdown table cells.

Previously, achieving this required a combination of raw HTML and Markdown, which was
cumbersome and difficult to maintain.

This improvement makes it easier to track task completion directly within structured table
layouts in issues, epics, and other content.

### Pipeline secret detection in security configuration profiles

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/configuration/security_configuration_profiles.md)

{{< /details >}}

In GitLab 18.9, we introduced security configuration profiles with the **Secret Detection - Default** profile, starting with push protection. You use the profile to apply standardized secret scanning across hundreds of projects without touching a single CI/CD configuration file.

The **Secret Detection - Default** profile now also covers pipeline-based scanning, providing a unified control surface for secret detection across your entire development workflow.

The profile activates three scan triggers:

- **Push Protection**: Scans all Git push events and blocks pushes where secrets are detected, preventing secrets from ever entering your codebase.
- **Merge Request Pipelines**: Automatically runs a scan each time new commits are pushed to a branch with an open merge request. Results only include new vulnerabilities introduced by the merge request.
- **Branch Pipelines (default only)**: Runs automatically when changes are merged or pushed to the default branch, providing a complete view of your default branch’s secret detection posture.

Applying the profile requires no YAML configuration. The profile can be applied to a group to propagate coverage across all projects in the group, or to individual projects for more granular control.

### macOS Tahoe 26 and Xcode 26 job image

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com
- Links: [Documentation](../../ci/runners/hosted_runners/macos.md) | [Related epic](https://gitlab.com/groups/gitlab-com/gl-infra/-/work_items/1694)

{{< /details >}}

You can now create, test, and deploy applications for the newest
generations of Apple devices using macOS Tahoe 26 and Xcode 26.

With [hosted runners on macOS](../../ci/runners/hosted_runners/macos.md),
your development teams can build and deploy macOS applications faster in a secure,
on-demand build environment integrated with GitLab CI/CD.

Try it out today by using the `macos-26-xcode-26` image in your `.gitlab-ci.yml` file.

### GitLab Runner 18.10

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 18.10 today!
GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab instance.
GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s New

- [Allow k8s runner to define Pod Level Resources for build pod](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39085)
- [Add automation to update Go versions and packages for all Runner projects](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39192)

#### Bug Fixes

- [S3 cache with RoleARN returns 403 instead of 404 for non-existent cache](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39105)
- [Using helper image `gitlab-runner-helper:x86_64-v16.11.1-nanoserver21H2` results in `init-permissions` error](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/37872)
- [MacOS: LaunchAgent - Service could not initialize on M1 architecture](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/28136)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-10-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-10-stable/CHANGELOG.md).md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.10)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.10)
- [UI improvements](https://papercuts.gitlab.com/?milestone=18.10)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
