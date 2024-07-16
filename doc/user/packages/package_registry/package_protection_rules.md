---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Protected packages

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416395) in GitLab 16.5 [with a flag](../../../administration/feature_flags.md) named `packages_protected_packages`. Disabled by default. This feature is an [experiment](../../../policy/experiment-beta-support.md).
> - **Push protected up to access level** setting [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/416382) to **Minimum access level for push** in GitLab 17.1.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

By default, any user with at least the Developer role can create,
edit, and delete packages. Add a package protection rule to restrict
which users can make changes to your packages.

When a package is protected, the default behavior enforces these restrictions on the package:

| Action                                   | Who can do it                                                                     |
|:-----------------------------------------|:----------------------------------------------------------------------------------|
| Protect a package                        | At least the Maintainer role.                                                     |
| Push a new package                       | At least the role set in [**Minimum access level for push**](#protect-a-package). |
| Push a new package with a deploy token | Any user with a valid deploy token, even if a package is protected. |

## Protect a package

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140473) in GitLab 16.9.

Prerequisites:

- You must have at least the Maintainer role.

To protect a package:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Packages and registries**.
1. Under **Protected packages**, select **Add protection rule**.
1. Complete the fields:
   - **Name pattern** is a package name pattern you want to protect. The pattern can include a wildcard (`*`).
   - **Package type** is the type of package to protect.
   - **Minimum access level for push** is the minimum role required to push a package matching the name pattern.
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

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140483) in GitLab 16.10.

Prerequisites:

- You must have at least the Maintainer role.

To unprotect a package:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Packages and registries**.
1. Under **Protected packages**, next to the protection rule you want to delete, select **Delete** (**{remove}**).
1. On the confirmation dialog, select **Delete**.

The package protection rule is deleted, and does not appear in the settings.
