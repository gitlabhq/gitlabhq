---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Managing security configuration profiles
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/19802) in GitLab 18.9 [with a feature flag](../../../administration/feature_flags/_index.md) named `security_scan_profiles_feature`. Enabled by default.
- Secret detection profile [added](https://gitlab.com/groups/gitlab-org/-/epics/19903) in GitLab 18.10.
- SAST profile [added](https://gitlab.com/groups/gitlab-org/-/epics/19951) in GitLab 18.11.
- Dependency scanning profile [introduced](https://gitlab.com/groups/gitlab-org/-/epics/19952) in GitLab 19.0 [with a feature flag](../../../administration/feature_flags/_index.md) named `security_scan_profiles_dependency_scanning`. Enabled by default.
- Dependency scanning auto-remediation profile [introduced](https://gitlab.com/groups/gitlab-org/-/work_items/604588) in GitLab 19.2 [with a feature flag](../../../administration/feature_flags/_index.md) named `security_remediation_profiles`. Enabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

Security configuration profiles are centralized settings that define how and when security scanners run across your projects.
Use security configuration profiles to manage security scanners across your organization efficiently. A profile-based approach applies best practices with minimal manual setup.

<i class="fa-youtube-play" aria-hidden="true"></i>
For an overview, see [Introducing security configuration profiles](https://www.youtube.com/watch?v=QbnLGzTEqGI).

When you apply a profile to a group, it is applied to each individual project within that group. Profiles are not attached to the group itself, and there is no inheritance between profiles or subgroups.

Use [default profiles](#default-profiles) to enable pre-configured security scanning within minutes and with minimal configuration.

## Configure security scanners

To assess and manage your profiles, use the [security inventory](../security_inventory/_index.md#view-the-security-inventory) for your group as your central dashboard.

### Review test coverage

To view a high-level status (**Enabled**, **Not Enabled**, or **Failed**) of scanners in the group like SAST, dependency scanning, and secret detection:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Security inventory**.
1. In the security inventory, review the **Test Coverage** column.

### Change individual project coverage

To configure a specific project:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Security inventory**.
1. Next to the project, select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) and select **Manage tool coverage**.
1. Turn individual scanners on or off.

### Apply a profile to multiple projects

To save time, you can apply security settings to multiple projects at once:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Security inventory**.
1. Select multiple projects or an entire subgroup to apply the settings to.
1. Select the **Bulk Action** dropdown and choose **Manage security scanners**.
1. Choose **Apply default profile to all** to standardize your security posture across the selection.

## Default profiles

GitLab provides default profiles that are preconfigured scanner settings so you can enable security scanning with minimal configuration.

### Secret detection profile

When you apply the secret detection profile, you enable the recommended baseline protection for secrets across your entire development workflow. The profile activates the following scan triggers:

- **Push protection**: Scans all Git push events and blocks pushes where secrets are detected, preventing secrets from ever entering your codebase.
- **Merge Request Pipelines**: Automatically runs a scan each time new commits are pushed to a branch with an open merge request. Results are scoped to new vulnerabilities introduced by the merge request. Targets all branches.
- **Branch Pipelines (default only)**: Runs automatically when changes are merged or pushed to the default branch, providing a complete picture of your default branch's secret detection posture. Targets all branches.

### SAST profile

When you apply the SAST profile, you enable static application security testing across your projects using the recommended configuration. The profile activates the following scan triggers:

- **Merge Request Pipelines**: Automatically runs a SAST scan each time new commits are pushed to a branch with an open merge request. Results include only new vulnerabilities introduced by the merge request. Targets all branches.
- **Branch Pipelines (default only)**: Runs automatically when changes are merged or pushed to the default branch, providing a complete picture of your default branch's SAST posture. Targets the default branch.

### Dependency scanning profile

When you enable the dependency scanning profile, your project's dependencies are scanned for known vulnerabilities using the recommended configuration. The profile activates the following scan triggers:

- **Merge Request Pipelines**: Automatically runs a dependency scan each time new commits are pushed to a branch with an open merge request. Results include only new vulnerabilities introduced by the merge request. Targets all branches.
- **Branch Pipelines (default only)**: Runs automatically when changes are merged or pushed to the default branch, providing a complete picture of your default branch's dependency vulnerability posture. Targets the default branch.

### Dependency scanning auto-remediation profile

When you enable the dependency scanning auto-remediation profile, GitLab opens merge requests
that bump vulnerable dependencies to non-vulnerable versions. For more information about this
capability, see [dependency scanning auto-remediation](../remediate/dependency_scanning_auto_remediation.md).

Prerequisites:

- The `security_remediation_profiles` [feature flag](../../../administration/feature_flags/_index.md)
  must be enabled for the project's root namespace. This flag is enabled by default in GitLab 19.2.

Use the [GitLab CLI](../../../editor_extensions/gitlab_cli/_index.md) (`glab`) to attach the
profile to a project:

```shell
glab security config enable dependency_scanning_post_processing -R <project-path>
```

For example, to enable the profile for `my-group/my-project`:

```shell
glab security config enable dependency_scanning_post_processing -R my-group/my-project
```

### View details about a profile

To view technical details about the secret detection profile:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Security inventory**.
1. Select the **Secret Detection** profile.
1. Review the following information:
   - **Analyzer type**: The type of profile (for example, **Secret Detection**, **SAST**, **Dependency Scanning**).
   - **Scan triggers**: The triggers that the profile supports (for example, **Push Protection**, **Merge Request Pipelines**, **Branch Pipelines**).
   - **Status**: Displays whether the profile is currently **Active** or **Disabled** for the current context using coverage status indicators.

## Enable scanners with the Scanner Enablement Wizard

To apply profiles to projects that lack scanner coverage, use the
[scanner enablement wizard](scanner_enablement_wizard.md). The wizard identifies uncovered projects
and lets you apply default or custom profiles across your group.

## Apply a profile with the GraphQL API

Use the GraphQL API to apply any security configuration profile, including profiles that
are not yet available in the UI. You can run these queries with the
[interactive GraphQL explorer](../../../api/graphql/_index.md#interactive-graphql-explorer),
or by sending requests directly to the `/api/graphql` endpoint.

For more information about running queries, authentication, and pagination, see
[run GraphQL API queries and mutations](../../../api/graphql/getting_started.md).

Prerequisites:

- At least the Maintainer role or the Security Manager role for the associated projects or groups.

To apply a security configuration profile:

1. Get the available profiles and their IDs for a group:

```graphql
   query {
     group(fullPath: "my-group") {
       availableSecurityScanProfiles {
         id
         name
         scanType
       }
     }
   }
```

   A default profile that is not yet saved returns a virtual ID based on its scan type.
   For example: `gid://gitlab/Security::ScanProfile/dependency_scanning_post_processing`.

   For more information, see the
   [`Group.availableSecurityScanProfiles` field](../../../api/graphql/reference/_index.md#groupavailablesecurityscanprofiles).

1. Apply the profile with the `securityScanProfileAttach` mutation, using the virtual ID or
   the real ID of the profile you want:

```graphql
   mutation {
     securityScanProfileAttach(input: {
       securityScanProfileId: "gid://gitlab/Security::ScanProfile/dependency_scanning_post_processing",
       projectIds: ["gid://gitlab/Project/123"]
     }) {
       errors
     }
   }
```

   For more information, see the
   [`securityScanProfileAttach` mutation](../../../api/graphql/reference/_index.md#mutationsecurityscanprofileattach).

1. To choose where the profile applies, set one or both of these arguments:
   - `projectIds`: Applies the profile to specific projects.
   - `groupIds`: Applies the profile to all projects in one or more groups.

   All specified projects and groups must belong to the same top-level group.
   A single mutation accepts a maximum of 100 IDs, counting project and group IDs together.

1. Check the `errors` field in the response to confirm that the profile was applied.

## Coverage status indicators

The system uses visual cues in the inventory to indicate whether your projects are protected:

- **Solid green bar**: The scanner is fully enabled and active.
- **Gray/empty bar**: The scanner is not yet configured or enabled.
- **Partial bar**: Some protection is active (for example, some triggers available in the profile are enabled, but others are not).
- **Tooltips**: Hover over any coverage bar to see the **last scan** date for pipeline-based scans and specific pipeline status.

Unlike pipeline-based scans, push protection does not have a last scan date because it runs in real time during the push process.

## Troubleshooting

When working with security configuration profiles, you might encounter the following issues.

### No last scan date appears for push protection

Push protection is event-based, not schedule-based. It intercepts secrets in real time during the `git push` process. Because it is active at the moment of the `push` command, there is no last scan date like you would expect with pipeline-based scanners.

### Scanner status is active in the dashboard but not enabled in inventory tooltip

This can occur when a project uses legacy settings while also being assigned a new profile.

To resolve this issue:

1. Check the **Security Configuration** page for the most accurate current profile state.
1. If needed, remove legacy scanner configurations from your `.gitlab-ci.yml` file to rely solely on the profile-based configuration.

> [!note]
> The inventory tooltip is being refined to reflect the combined status of both legacy and profile-based settings.

### Understanding legacy versus profile-based configuration

If you're migrating from legacy scanner configuration to profile-based configuration, note the following differences:

- Legacy configuration: Requires manual edits to your YAML files or individual project settings to enable scanners.
- Profile-based configuration: Uses a centralized system where you can apply a default profile to multiple projects at once without modifying code.

Profile-based configuration is recommended for easier management and greater consistency across projects.
