---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: Protected packages
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416395) in GitLab 16.5 [with a flag](../../../administration/feature_flags.md) named `packages_protected_packages`. Disabled by default. This feature is an [experiment](../../../policy/development_stages_support.md).
- The protection rule setting **Push protected up to access level** [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/416382) to **Minimum access level for push** in GitLab 17.1.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/472655) in GitLab 17.5.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/472655) in GitLab 17.6. Feature flag `packages_protected_packages` removed.
- Conan protected packages [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/323975) in GitLab 17.6 [with a flag](../../../administration/feature_flags.md) named `packages_protected_packages_conan`. Disabled by default. This feature is an [experiment](../../../policy/development_stages_support.md).
- Maven protected packages [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/323969) in GitLab 17.9 [with a flag](../../../administration/feature_flags.md) named `packages_protected_packages_maven`. Disabled by default. This feature is an [experiment](../../../policy/development_stages_support.md).
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/516215) in GitLab 17.10 [with a flag](../../../administration/feature_flags.md) named `packages_protected_packages_delete`. Disabled by default. This feature is an [experiment](../../../policy/development_stages_support.md).
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/497082) in GitLab 17.11. Feature flag `packages_protected_packages_maven` removed.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/497811) in GitLab 17.11. Feature flag `packages_protected_packages_conan` removed.
- NuGet protected packages [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/323972) in GitLab 18.0 [with a flag](../../../administration/feature_flags.md) named `packages_protected_packages_nuget`. Disabled by default. This feature is an [experiment](../../../policy/development_stages_support.md).
- Protected Helm charts [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/323973) in GitLab 18.1 [with a flag](../../../administration/feature_flags.md) named `packages_protected_packages_helm`. Disabled by default. This feature is an [experiment](../../../policy/development_stages_support.md).
- Generic protected packages [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/323973) in GitLab 18.1 [with a flag](../../../administration/feature_flags.md) named `packages_protected_packages_generic`. Disabled by default. This feature is an [experiment](../../../policy/development_stages_support.md).

{{< /history >}}

By default, any user with at least the Developer role can create,
edit, and delete packages. Add a package protection rule to restrict
which users can make changes to your packages.

GitLab supports package protection for npm, PyPI, Maven, and Conan packages, but [epic 5574](https://gitlab.com/groups/gitlab-org/-/epics/5574) proposes to add additional features and package formats.

When a package is protected, the default behavior enforces these restrictions on the package:

| Action                                 | Minimum role or token                                                                     |
|:---------------------------------------|:----------------------------------------------------------------------------------|
| Protect a package                      | At least the Maintainer role.                                                     |
| Push a new package                     | At least the role set in [**Minimum access level for push**](#protect-a-package). |
| Push a new package with a deploy token | Any valid deploy token, only if the pushed package is not matched by a protection rule. Protected packages cannot be pushed with a deploy token. |
| Delete a package                       | At least the role set in [**Minimum access level for delete**](#protect-a-package). |

## Protect a package

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140473) in GitLab 16.9.

{{< /history >}}

Prerequisites:

- You must have at least the Maintainer role.

To protect a package:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Packages and registries**.
1. Expand **Package registry**.
1. Under **Protected packages**, select **Add protection rule**.
1. Complete the fields:
   - **Name pattern** is a package name pattern you want to protect. The pattern can include a wildcard (`*`).
   - **Package type** is the type of package to protect.
   - **Minimum access level for push** is the minimum role required to push a package matching the name pattern.
   - **Minimum access level for delete** is the minimum role required to delete a package matching the name pattern.
1. Select **Protect**.

The package protection rule is created, and appears in the settings.

### Protecting multiple packages

You can use a wildcard to protect multiple packages with the same package protection rule.
For example, you can protect all the temporary packages built during a CI/CD pipeline.

The following table contains examples of package protection rules that match multiple packages:

| Package name pattern with wildcard | Matching packages                                                           |
|------------------------------------|-----------------------------------------------------------------------------|
| `@group/package-*`                 | `@group/package-prod`, `@group/package-prod-sha123456789`                   |
| `@group/*package`                  | `@group/package`, `@group/prod-package`, `@group/prod-sha123456789-package` |
| `@group/*package*`                 | `@group/package`, `@group/prod-sha123456789-package-v1`                     |

It's possible to apply several protection rules to the same package.
If at least one protection rule applies to the package, the package is protected.

## Delete a package protection rule and unprotect a package

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140483) in GitLab 16.10.

{{< /history >}}

Prerequisites:

- You must have at least the Maintainer role.

To unprotect a package:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Packages and registries**.
1. Expand **Package registry**.
1. Under **Protected packages**, next to the protection rule you want to delete, select **Delete** ({{< icon name="remove" >}}).
1. On the confirmation dialog, select **Delete**.

The package protection rule is deleted, and does not appear in the settings.
