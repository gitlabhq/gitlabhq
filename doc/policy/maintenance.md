---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab release and maintenance policy
description: Version support, release cadence, and backporting polices.
---

The Delivery Group are the owners of the maintenance policy and must approve any requested updates. This follows our DRI model and is in place to ensure predictability for customers.

GitLab has strict policies governing version naming, as well as release pace for major, minor,
patch releases. New releases are announced on the [GitLab blog](https://about.gitlab.com/releases/categories/releases/).

Our current policy is:

- Backporting bug fixes for **only the current stable release** at any given time - see [patch releases](#patch-releases) below.
- Backporting security fixes **to the previous two monthly releases in addition to the current stable release**. In some circumstances (outlined in [patch releases](#patch-releases) below) we may address a security vulnerability to the current stable release only or in the regular monthly release process, with no backports.

In rare cases, release managers may make an exception and backport to more than
the last two monthly releases. See
[Backporting to older releases](#backporting-to-older-releases) for more information.

## Versioning

GitLab uses [Semantic Versioning](https://semver.org/) for its releases:
`(Major).(Minor).(Patch)`.

For example, for GitLab version 18.3.2:

- `18` represents the major version. The major release was 18.0.0 but often referred to as 18.0.
- `3` represents the minor version. The minor release was 18.3.0 but often referred to as 18.3.
- `2` represents the patch number.

Any part of the version number can increment into multiple digits, for example, 18.3.11.

The following table describes the version types and their release cadence:

| Version type | Description | Cadence |
|:-------------|:------------|:--------|
| Major        | For significant changes, or when any backward-incompatible changes are introduced to the public API. | Yearly. The next major release is GitLab 19.0, scheduled for May 21, 2026. GitLab [schedules major releases](https://about.gitlab.com/releases/) for May each year, by default. |
| Minor        | For when new backward-compatible functionality is introduced to the public API, a minor feature is introduced, or when a set of smaller features is rolled out. | Monthly, scheduled for the third Thursday of each month. |
| Patch        | For backward-compatible bug fixes that fix incorrect behavior. See [Patch releases](#patch-releases). | Twice monthly, scheduled for the Wednesday the week before and the Wednesday the week after the monthly minor release. |

<!-- Do not edit the following section without consulting the Technical Writing team -->

<!-- vale gitlab_base.CurrentStatus = NO -->

## Maintained versions

The following GitLab release versions are currently maintained:

{{< maintained-versions >}}

<!-- vale gitlab_base.CurrentStatus = YES -->

<!-- END -->

{{< alert type="note" >}}

For GitLab team members looking for maintained versions for the upcoming patch release, refer to the [`Release Versions` panel](https://dashboards.gitlab.net/goto/h228fPEHR?orgId=1)
under the `Patch Release Information` section in the internal `delivery: Release Information` Grafana dashboard.
When the active monthly release date is prior to the active patch release date, the versions are different from the maintained versions list above.

Bug fix backports are maintained for the current (first) version, and security fix backports are maintained for all versions.

{{< /alert >}}

## Upgrade recommendations

We encourage everyone to run the [latest stable release](https://about.gitlab.com/releases/categories/releases/)
to ensure that you can upgrade to the most secure and feature-rich GitLab experience.
To make sure you can run the most recent stable release, we are working
hard to keep the update process reliable.

If you are unable to follow our monthly release cycle, there are a couple of
cases you must consider. Follow the
[upgrade paths guide](../update/upgrade_paths.md) to safely upgrade
between versions.

Version-specific change documentation for Linux packages is available for:

- [GitLab 17](../update/versions/gitlab_17_changes.md)
- [GitLab 16](../update/versions/gitlab_16_changes.md)
- [GitLab 15](../update/versions/gitlab_15_changes.md)

Instructions are available for downloading the Linux package locally and [manually installing](../update/package/_index.md#upgrade-with-a-downloaded-package) it.

A step-by-step guide to [upgrading the Linux package-bundled PostgreSQL is documented separately](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server).

## Upgrading major versions

Backward-incompatible changes and migrations are reserved for major versions. For more information, see
[Create a GitLab upgrade plan](../update/plan_your_upgrade.md).

## Patch releases

Patch releases include **bug fixes** for the current stable released version of
GitLab and **security fixes** to the previous two monthly releases in addition to the current stable release.

These policies are in place because:

1. GitLab has Community and Enterprise distributions, doubling the amount of work
   necessary to test/release the software.
1. Backporting to older releases creates a high development, quality assurance,
   and support cost.
1. Supporting parallel version discourages incremental upgrades which over time accumulate in
   complexity and create upgrade challenges for all users. GitLab has a dedicated team ensuring that
   incremental upgrades (and installations) are as simple as possible.
1. The number of changes created in the GitLab application is high, which contributes to backporting complexity to older releases. In several cases, backporting has to go through the same
   review process a new change goes through.
1. Ensuring that tests pass on the older release is a considerable challenge in some cases, and as such is very time-consuming.

Including new features in a patch release is not possible as that would break [Semantic Versioning](https://semver.org/).
Breaking [Semantic Versioning](https://semver.org/) has the following consequences for users that
have to adhere to various internal requirements (for example, org. compliance, verifying new features, and similar):

1. Inability to quickly upgrade to leverage bug fixes included in patch versions.
1. Inability to quickly upgrade to leverage security fixes included in patch versions.
1. Requirements consisting of extensive testing for not only stable GitLab release, but every patch version.

For highly severe security issues, there is
[precedent](https://about.gitlab.com/releases/2016/05/02/cve-2016-4340-patches/)
to backport security fixes to even more previous GitLab release versions.
This decision is made on a case-by-case basis.

In some circumstances, we may choose to address a vulnerability using the regular monthly release process by
updating the active and current stable releases only, with no backports. Factors influencing this decision include
the very low likelihood of exploitation, the low impact of the vulnerability, the complexity of security fixes and
the eventual risk to stability. We always address high and critical security issues with a patch release.

### Backporting to older releases

Backporting to more than one stable release is usually reserved for [security fixes](#patch-releases).
In some cases, however, we may need to backport a bug fix to more than one stable
release, depending on the severity of the bug.

The decision on whether backporting a change is performed is done at the discretion of the
[current release managers](https://about.gitlab.com/community/release-managers/),
based on **all** of the following:

1. Estimated severity of the bug:
   Highest possible impact to users based on the current definition of severity.
1. Estimated priority of the bug:
   Immediate impact on all impacted users based on the previous estimated severity.
1. Potentially incurring data loss and/or security breach.
1. Potentially affecting one or more strategic accounts due to a proven inability by the user to upgrade to the current stable version.

If **all** the items in the previous list are satisfied, the backport releases can be created for
the current stable release, and two previous monthly releases. In rare cases a release manager may grant an exception to backport to more than two previous monthly releases.
For instance, if we release `13.2.1` with a fix for a severe bug introduced in
`13.0.0`, we could backport the fix to a new `13.0.x`, and `13.1.x` patch release.

Severity 3 and lower
requests are automatically turned down.

To request backporting to more than one stable release for consideration, raise an issue in the
[release/tasks](https://gitlab.com/gitlab-org/release/tasks/-/issues/new?issuable_template=Backporting-request) issue tracker.

## More information

You may also want to read our:

- [Release documentation](https://gitlab.com/gitlab-org/release/docs) describing release procedures
- Deprecation guidelines in the development documentation.
- [Responsible Disclosure Policy](https://about.gitlab.com/security/disclosure/)
