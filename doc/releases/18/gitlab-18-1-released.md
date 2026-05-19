---
stage: Release Notes
group: Monthly Release
date: 2025-06-19
title: "GitLab 18.1 release notes"
description: "GitLab 18.1 released with Maven virtual registry now available in beta"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On June 19, 2025, GitLab 18.1 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Chaitanya Sonwane

Chaitanya Sonwane drives GitLab’s security capabilities through consistent authentication
improvements.
[With 13 merged contributions in 2025](https://contributors.gitlab.com/users/chaitanyason9?fromDate=2025-01-01&toDate=2025-12-31), his work enhanced credential inventory filtering, service account management, and work items usability.
He previously delivered a [key feature in GitLab 17.11](https://about.gitlab.com/releases/2025/04/17/gitlab-17-11-released/#token-statistics-for-service-account-management) with token statistics for service accounts, which provides “at a glance” information that makes it easier to manage service accounts.
Chaitanya is now [improving work item list sort settings to be context specific](https://gitlab.com/gitlab-org/gitlab/-/issues/503587), further enhancing the user experience in GitLab’s Product Planning.

Chaitanya’s work directly strengthens security for GitLab organizations and
provides better visibility into service account usage across projects.
Teams can now track and rotate credentials more effectively.
This reduces the risk of orphaned or forgotten credentials that create security
vulnerabilities.

“Chaitanya’s contributions to the credential inventory and service accounts are both very
valuable contributions in the security space,” says [Eduardo Sanz-Garcia](https://gitlab.com/eduardosanz), Senior Frontend Engineer for the Authentication group, Software Supply Chain Security stage.
Eduardo supported the nomination from GitLab’s Authentication team.

“Chaitanya was instrumental in the implementation of the token statistics concept,” Eduardo adds.
“His credential inventory work delivered a highly requested feature to enhance the tractability and monitoring of credentials.
This was a great contribution!”

Chaitanya is a Software Engineer at TATA AIG.
He proactively tackles security issues and follows up consistently on improvements to his own
contributions.

Thanks to Chaitanya for contributing to GitLab’s security foundation and the rest of the product!

## Primary features

### Maven virtual registry now available in beta

<!-- categories: Virtual Registry -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/packages/virtual_registry/maven/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/14137)

{{< /details >}}

The Maven virtual registry simplifies Maven dependency management in GitLab. Without the Maven virtual registry, you must configure each project to access dependencies from Maven Central, private repositories, or the GitLab package registry. This approach slows builds with sequential repository queries and complicates security auditing and compliance reporting.

The Maven virtual registry addresses these issues by aggregating multiple upstream repositories behind a single endpoint. Platform engineers can configure Maven Central, private registries, and GitLab package registries through one URL. Intelligent caching improves build performance and integrates with GitLab’s authentication systems. Organizations benefit from reduced configuration overhead, faster builds, and centralized access control for improved security and compliance.

The Maven virtual registry is currently available in beta for GitLab Premium and Ultimate customers on both GitLab.com and GitLab Self-Managed. The GA release will include additional capabilities, such as a web-based user interface for registry configuration, shareable upstream functionality, lifecycle policies for cache management, and enhanced analytics. Current beta limitations include a maximum of 20 virtual registries per top-level groups and 20 upstreams per virtual registry, with API-only configuration available during the beta period.

We invite enterprise customers to participate in the Maven virtual registry beta program to help shape the final release. Beta participants will receive early access to the capabilities, direct engagement with GitLab product teams, and priority support during evaluation. To join the beta program, express interest and provide your use case details in [issue 498139](https://gitlab.com/gitlab-org/gitlab/-/issues/498139), and share feedback and suggestions in [issue 543045](https://gitlab.com/gitlab-org/gitlab/-/issues/543045).

### Duo Code Review is now generally available

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Add-ons: Duo Enterprise
- Links: [Documentation](../../user/project/merge_requests/duo_in_merge_requests.md)

{{< /details >}}

Duo Code Review is now generally available and ready for production use. This AI-powered code review assistant transforms the traditional code review process by providing intelligent, automated feedback on your merge requests. It helps identify potential bugs, security vulnerabilities, and code quality issues before human reviewers get involved, making the entire review process more efficient and thorough. It includes:

- **Automated initial review**: Duo Code Review analyzes your code changes and provides comprehensive feedback on potential issues, improvements, and best practices.
- **Interactive refinement**: Mention `@GitLabDuo` in merge request comments to get targeted feedback on specific changes or questions.
- **Actionable suggestions**: Many suggestions can be applied directly from your browser, streamlining the improvement process.
- **Context-aware analysis**: Leverages understanding of the changed files to provide relevant, project-specific recommendations.

To request a code review:

- In your merge request, add `@GitLabDuo` as a reviewer using the `/assign_reviewer @GitLabDuo` quick action, or assign GitLab Duo directly as a reviewer.
- Mention `@GitLabDuo` in comments to ask specific questions or request focused feedback on any discussion thread.
- Enable automatic reviews in your project settings to have GitLab Duo automatically review all new merge requests.

Duo Code Review helps teams maintain higher code quality standards while reducing the time spent on manual review cycles. By catching issues early and providing educational feedback, it serves as both a quality gate and a learning tool for development teams.

**[Watch an overview](https://www.youtube.com/watch?v=FlHqfMMfbzQ) of Duo Code Review in action from our beta release.

Share your experience and feedback in [issue 517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386) to help us continue improving this feature.

### Compromised password detection for native GitLab credentials

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/profile/user_passwords.md#compromised-password-detection) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/549865)

{{< /details >}}

GitLab.com now performs a secure check of your account credentials when you sign in to GitLab.com.
If your password is part of a known leak, GitLab displays a banner and sends you an email notification.
These notifications include instructions for how to update your credentials.

For maximum security, GitLab recommends using a unique, strong password for GitLab, enabling two-factor authentication, and regularly reviewing your account activity.

Note: This feature is only available for native GitLab usernames and passwords. SSO credentials are not checked.

### Achieve [SLSA](https://slsa.dev/) Level 1 compliance with CI/CD components

<!-- categories: Artifact Security -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../ci/pipeline_security/slsa/_index.md#sign-and-verify-slsa-provenance-with-a-cicd-component) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/15859)

{{< /details >}}

You can now achieve SLSA Level 1 compliance using GitLab’s new CI/CD components for signing and verifying SLSA-compliant
[artifact provenance metadata](../../ci/runners/configure_runners.md#artifact-provenance-metadata) generated by GitLab Runner. The components wrap [Sigstore Cosign functionality](../../ci/yaml/signing_examples.md)
in reusable modules that can be easily integrated into CI/CD workflows.

## Scale and Deployments

### Multiple matches per file in code search

<!-- categories: Code Search -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../integration/zoekt/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13127)

{{< /details >}}

Exact code search (in beta) now consolidates multiple search results from the same file into a single view. This improvement:

- Preserves context between adjacent matches instead of displaying isolated lines.
- Reduces visual clutter by eliminating duplicate content when matches are close together.
- Enhances navigation by clearly showing the number of matches per file.
- Improves readability by displaying code as you would see it in your editor.

With this change, finding and understanding code patterns across your repositories is now more efficient.

### New `accessLevels` argument for `projectMembers` in GraphQL API

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../api/graphql/reference/_index.md#projectprojectmembers) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/541386)

{{< /details >}}

We’re excited to announce the addition of the `accessLevels` argument to the `projectMembers` field in our GraphQL API.
Use this argument to filter project members by access level directly from an API call.
Previously, you had to fetch an entire list of project members and apply filters locally, which added significant computational overhead.
Now, analyzing project permissions and generating ownership graphs is faster and more resource-efficient.
This enhancement is particularly valuable to organizations managing large-scale deployments with complex permission structures.

## Unified DevOps and Security

### DAST detection parity with secret detection default rules

<!-- categories: DAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/dast/browser/checks/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/549990)

{{< /details >}}

The DAST analyzer now automatically ingests the same default secret detection rules that are used by GitLab’s Secret Detection analyzer. This improvement ensures consistency in the types of secrets detected by both.

### Define a `Name` for external custom controls

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/compliance/compliance_frameworks/_index.md#external-controls) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/527007)

{{< /details >}}

Previously, you couldn’t define a name for an external custom control when creating a custom compliance framework,
which made it difficult to identify external controls when listed alongside GitLab controls.

We’ve now added a `Name` field as part of the workflow when defining an external custom control, so you can
create multiple external custom controls and clearly define each one with its own unique name.

### Pagination for requirements in compliance frameworks UI

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/compliance/compliance_frameworks/_index.md#add-requirements) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/531039)

{{< /details >}}

When creating a compliance framework, you can specify a maximum of 50 requirements.

However, it becomes very difficult to navigate a compliance framework with this many requirements because they
consume a lot of space in the user interface.

In this release, we have introduced pagination for requirements to make it easier for users to navigate, find, and
select requirements when there is a large number of them attached to a compliance framework.

### UI performance and filtering improvements for compliance center

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/compliance/compliance_center/_index.md)

{{< /details >}}

We have continued to improve the UI performance and filtering options provided by the compliance center. In this
release, we have:

- Improved the UI speed and performance of the **Edit Framework** page, especially where there are many requirements and projects on the page.
- Introduced new filtering options so that you can group by requirement, project, or framework in the **Compliance status report** tab in the compliance center.

By delivering these improvements, we continue to ensure that the compliance center and associated functions
continue to perform at scale for customers who regularly use the compliance center.

### Control status pop-up in the compliance status report

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/compliance/compliance_center/compliance_status_report.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/521757)

{{< /details >}}

Controls in the compliance status report have three different statuses:

- Pass
- Fail
- Pending

No matter the number of controls that are attached to the requirement, if at least one control was ‘pending’, the
entire requirement row was shown as ‘pending’ as well. This deviated from the established UX pattern for visualizing
failed controls, where the requirement would show the number of controls associated with the requirement, even
when there was at least one control that fails.

To provide further context and information for ‘pending’ controls, we now provide a hover over pop-up on the
requirement row status, with the status of each control listed. You can now understand which controls are pending,
and which are potentially succeeding and failing, rather than just seeing a single status for ‘pending’.

### Enhanced merge request review experience with review panel

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../user/project/merge_requests/reviews/_index.md#submit-a-review) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/525841)

{{< /details >}}

When you review a merge request, it can be valuable to see all of the comments and feedback you’ve provided before you submit your review. Previously, this experience was fragmented between the final comment and an additional pop-up to see your pending comments, making it hard to get the complete overview.

When conducting code reviews, you can now access a dedicated drawer that consolidates all your pending draft comments in one organized view. The enhanced review panel moves the review submission interface to a more accessible location, and provides a numbered badge showing your pending comment count. When you open the panel, you’ll see all your draft comments organized in a scrollable list, making it easier to review and manage your feedback before submitting.

### Enhanced CODEOWNERS file validation with permission checks

<!-- categories: Source Code Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../user/project/codeowners/troubleshooting.md#validate-your-codeowners-file) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/15598)

{{< /details >}}

GitLab now provides enhanced validation for CODEOWNERS files that goes beyond basic syntax checking. When viewing a CODEOWNERS file, GitLab automatically runs comprehensive validations to help you identify both syntax and permission issues before they affect your merge request workflows.

The enhanced validation checks the first 200 unique user and group references in your CODEOWNERS file, and verifies that:

- All referenced users and groups have access to the project.
- Users have the necessary permissions to approve merge requests.
- Groups have at least Developer-level access or higher.
- Groups contain at least one user with merge request approval permissions.

This proactive validation helps prevent approval workflow disruptions by catching configuration issues early, ensuring your Code Owners can actually fulfill their review responsibilities when merge requests are created.

### Custom workspace initialization with `postStart` events

<!-- categories: Workspaces -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/workspace/_index.md#user-defined-poststart-events)

{{< /details >}}

GitLab workspace now supports custom `postStart` events in your devfile, allowing you to define commands that automatically execute after workspace startup. Use these events to:

- Set up development dependencies.
- Configure your environment.
- Run initialization scripts that prepare your project for immediate productivity without manual intervention.

### View downstream pipeline job logs in VS Code

<!-- categories: Editor Extensions -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](https://docs.gitlab.com/editor_extensions/visual_studio_code/cicd/) | [Related issue](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1895)

{{< /details >}}

The GitLab Workflow extension for VS Code now displays job logs from downstream pipelines directly in your editor. Previously, viewing logs from child pipelines required switching to the GitLab web interface.

This feature was developed through the [GitLab Co-create program](https://about.gitlab.com/community/co-create/). Special thanks to Tim Ryan for making this contribution!

### View inactive personal access tokens

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/profile/personal_access_tokens.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/425053)

{{< /details >}}

GitLab automatically deactivates access tokens after they expire or are revoked. You can now review these inactive tokens. Previously, access tokens were no longer visible after they became inactive. This change enhances traceability and security of these token types.

### Epic support for GitLab Query Language views Beta

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/glql/fields.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/issues/30)

{{< /details >}}

We’ve made a significant improvement to GitLab Query Language (GLQL) views. You can now use epic as a type in your queries to search for epics across groups, and query by parent epic!

This is a huge step forward for our planning and tracking capabilities, making it easier than ever to query and organize at the epic level.

### PHP support for Advanced SAST

<!-- categories: SAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/sast/gitlab_advanced_sast.md#supported-languages) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/14273)

{{< /details >}}

We have added PHP support to GitLab Advanced SAST.
To use this new cross-file, cross-function scanning support, [enable Advanced SAST](../../user/application_security/sast/gitlab_advanced_sast.md#turn-on-gitlab-advanced-sast).
If you have already enabled Advanced SAST, PHP support is automatically activated.

To see which types of vulnerabilities Advanced SAST detects in each language, see the [Advanced SAST coverage page](../../user/application_security/sast/advanced_sast_coverage.md).

### Filter by component version in the dependency list

<!-- categories: Dependency Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/dependency_list/_index.md#filter-dependency-list) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16431)

{{< /details >}}

The dependency lists now supports filtering by a component’s version number. You can select multiple versions
(for example, `version=1.1,1.2,1.4` ) but ranges are not supported. This feature is available in both groups and projects.

### Variable precedence controls in pipeline execution policies

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/policies/pipeline_execution_policies.md#variables_override-type) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16430)

{{< /details >}}

Security teams often strike a delicate balance between security assurance and developer experience. It’s critical to ensure security scans are properly enforced, but security analyzers can require specific inputs from development teams to properly execute. With variable precedence controls, security teams now have granular control over how variables are handled in pipeline execution policies through the new `variables_override` configuration option.

Using this new configuration, you can now:

- Enforce container scanning policies that allow project-specific container image paths (`CS_IMAGE`).
- Allow lower risk variables like `SAST_EXCLUDED_PATHS` while blocking high risk variables like `SAST_DISABLED`.
- Define globally shared credentials that are secured (masked or hidden) with global CI/CD variables, such as `AWS_CREDENTIALS`, while allowing project-specific overrides where appropriate through project-level CI/CD variables.

This powerful feature supports two approaches:

- **Lock variables by default** (`allow: false`): Lock all variables except specific ones you list as exceptions.
- **Allow variables by default** (`allow: true`): Allow variables to be customized, but restrict critical risks by listing them as exceptions.

To improve traceability and troubleshooting when a pipeline execution policy is the source of an CI/CD job, we’re also introducing job logs to help developers and security teams identify the jobs executed by a policy. The job logs provide details on the impact of variable overrides to help you understand if variables are overridden or locked by policies.

**Real-world impact**

This enhancement bridges the gap between security requirements and flexibility for developers:

- Security teams can enforce standardized scanning while allowing project-specific customizations.
- Developers maintain control over project-specific variables without requesting policy exceptions.
- Organizations can implement consistent security policies without disrupting development workflows.

By solving this critical variable control challenge, GitLab enables organizations to implement robust security policies without sacrificing the flexibility teams need to deliver software efficiently.

### Filter for bot and human users

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../administration/moderate_users.md#view-users-by-type) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/541186)

{{< /details >}}

Established GitLab instances can often have large numbers of human and bot users. You can now filter the users list in the Admin area by user type. Filtering users can help you:

- Quickly identify and manage human users separately from automated accounts.
- Perform targeted administrative actions on specific user types.
- Simplify user auditing and management workflows.

### [ORCID](https://orcid.org/) identifier in user profile

<!-- categories: User Profile -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/profile/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/23543)

{{< /details >}}

GitLab now supports ORCID identifiers in user profiles, making GitLab more accessible and valuable for researchers and the academic community. [ORCID](https://orcid.org/) (Open Researcher and Contributor ID) provides researchers with a persistent digital identifier that distinguishes them from other researchers and supports automated linkages between researchers and their professional activities, ensuring their work is properly recognized.

This feature was developed as a community contribution by Thomas Labalette and Erwan Hivin, master students at Artois University, under the supervision of [Daniel Le Berre](https://www.ouvrirlascience.fr/appointment-of-daniel-le-berre-as-the-national-coordinator-for-higher-education-and-research-software-forges-in-france/), addressing a long-standing request from the academic community.

### Subscribe to service account pipeline notifications

<!-- categories: System Access -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/profile/notifications.md#notifications-about-failed-pipeline-that-doesnt-exist) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/515629)

{{< /details >}}

You can now subscribe to notifications for pipeline events triggered by service accounts. Notifications are sent when the pipeline passes, fails, or is fixed. Previously, these notifications were only sent to the service account’s email address if the service account has a valid custom email address.

Thank you [Densett](https://gitlab.com/[Densett](https://gitlab.com/Densett)), [Gilles Dehaudt](https://gitlab.com/tonton1728), [Lenain](https://gitlab.com/lenaing), [Geoffrey McQuat](https://gitlab.com/gmcquat), and [Raphaël Bihoré](https://gitlab.com/rbihore) for your contribution!

### Increased SAST coverage for Duo Vulnerability Resolution

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/vulnerabilities/_index.md#supported-vulnerabilities-for-vulnerability-resolution) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/534307)

{{< /details >}}

Previously, you had to manually resolve detected vulnerabilities with these Common Weakness Enumeration (CWE) identifiers:

- CWE-78 (Command Injection)
- CWE-89 (SQL Injection)

Now, Duo Vulnerability Resolution can automatically fix these vulnerabilities.

### GitLab Runner 18.1

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 18.1 today! GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### Bug Fixes

- [If you upgrade to GitLab 17.10 or 17.11, runners might receive a `404` response when they request jobs](https://gitlab.com/gitlab-org/gitlab/-/issues/543351).

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-1-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-1-stable/CHANGELOG.md).md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.1)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.1)
- [UI improvements](https://papercuts.gitlab.com/?milestone=18.1)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
