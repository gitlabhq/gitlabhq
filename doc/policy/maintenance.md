---
type: concepts
---

# GitLab Release and Maintenance Policy

GitLab has strict policies governing version naming, as well as release pace for major, minor,
patch and security releases. New releases are usually announced on the [GitLab blog](https://about.gitlab.com/blog/categories/releases/).

## Versioning

GitLab uses [Semantic Versioning](https://semver.org/) for its releases:
`(Major).(Minor).(Patch)`.

For example, for GitLab version 10.5.7:

- `10` represents the major version. The major release was 10.0.0, but often referred to as 10.0.
- `5` represents the minor version. The minor release was 10.5.0, but often referred to as 10.5.
- `7` represents the patch number.

Any part of the version number can increment into multiple digits, for example, 13.10.11.

The following table describes the version types and their release cadence:

| Version type | Description | Cadence |
|:-------------|:------------|:--------|
| Major        | For significant changes, or when any backward-incompatible changes are introduced to the public API. | Yearly. The next major release is GitLab 13.0 on May 22, 2020. Subsequent major releases will be scheduled for May 22 each year, by default. |
| Minor        | For when new backward-compatible functionality is introduced to the public API, a minor feature is introduced, or when a set of smaller features is rolled out. | Monthly on the 22nd. |
| Patch        | For backward-compatible bug fixes that fix incorrect behavior. See [Patch releases](#patch-releases). | As needed. |

## Patch releases

Our current policy is to support **only the current stable release** at any given time.

Patch releases **only include bug fixes** for the current stable released version of
GitLab.

These two policies are in place because:

1. GitLab has Community and Enterprise distributions, doubling the amount of work
necessary to test/release the software.
1. Backporting to more than one release creates a high development, quality assurance,
and support cost.
1. Supporting parallel version discourages incremental upgrades which over time accumulate in
complexity and create upgrade challenges for all users. GitLab has a dedicated team ensuring that
incremental upgrades (and installations) are as simple as possible.
1. The number of changes created in the GitLab application is high, which contributes to backporting complexity to older releases. In number of cases, backporting has to go through the same
review process a new change goes through.
1. Ensuring that tests pass on older release is a considerable challenge in some cases, and as such is very time consuming.

Including new features in patch releases is not possible as that would break [Semantic Versioning](https://semver.org/).
Breaking [Semantic Versioning](https://semver.org/) has the following consequences for users that
have to adhere to various internal requirements (for example, org. compliance, verifying new features, and similar):

1. Inability to quickly upgrade to leverage bug fixes included in patch versions.
1. Inability to quickly upgrade to leverage security fixes included in patch versions.
1. Requirements consisting of extensive testing for not only stable GitLab release, but every patch version.

In cases where a strategic user has a requirement to test a feature before it is
officially released, we can offer to create a Release Candidate (RC) version that will
include the specific feature. This should be needed only in extreme cases, and can be requested for
consideration by raising an issue in the [release/tasks](https://gitlab.com/gitlab-org/release/tasks/issues/new?issuable_template=Backporting-request) issue tracker.
It is important to note that the Release Candidate will also contain other features and changes as
it is not possible to easily isolate a specific feature (similar reasons as noted above). The
Release Candidate will be no different than any code that is deployed to GitLab.com or is publicly
accessible.

### Backporting to older releases

Backporting to more than one stable release is reserved for [security releases](#security-releases).
In some cases however, we may need to backport *a bug fix* to more than one stable
release, depending on the severity of the bug.

The decision on whether backporting a change will be performed is done at the discretion of the
[current release managers](https://about.gitlab.com/community/release-managers/), similar to what is
described in the [managing bugs](https://gitlab.com/gitlab-org/gitlab/blob/master/PROCESS.md#managing-bugs) process,
based on *all* of the following:

1. Estimated [severity](../development/contributing/issue_workflow.md#severity-labels) of the bug:
   Highest possible impact to users based on the current definition of severity.

1. Estimated [priority](../development/contributing/issue_workflow.md#priority-labels) of the bug:
   Immediate impact on all impacted users based on the above estimated severity.

1. Potentially incurring data loss and/or security breach.

1. Potentially affecting one or more strategic accounts due to a proven inability by the user to upgrade to the current stable version.

If *all* of the above are satisfied, the backport releases can be created for
the current stable stable release, and two previous monthly releases.
For instance, if we release `11.2.1` with a fix for a severe bug introduced in
`11.0.0`, we could backport the fix to a new `11.0.x`, and `11.1.x` patch release.

To request backporting to more than one stable release for consideration, raise an issue in the
[release/tasks](https://gitlab.com/gitlab-org/release/tasks/issues/new?issuable_template=Backporting-request) issue tracker.

### Security releases

Security releases are a special kind of patch release that only include security
fixes and patches (see below).

Our current policy is to backport security fixes to the previous two
monthly releases in addition to the current stable release.

For very serious security issues, there is
[precedent](https://about.gitlab.com/blog/2016/05/02/cve-2016-4340-patches/)
to backport security fixes to even more monthly releases of GitLab.
This decision is made on a case-by-case basis.

## Upgrade recommendations

We encourage everyone to run the [latest stable release](https://about.gitlab.com/blog/categories/releases/) to ensure that you can
easily upgrade to the most secure and feature-rich GitLab experience. In order
to make sure you can easily run the most recent stable release, we are working
hard to keep the update process simple and reliable.

If you are unable to follow our monthly release cycle, there are a couple of
cases you need to consider.

It is considered safe to jump between patch versions and minor versions within
one major version. For example, it is safe to:

- Upgrade the patch version:
  - `8.9.0` -> `8.9.7`
  - `8.9.0` -> `8.9.1`
  - `8.9.2` -> `8.9.6`
  - `9.5.5` -> `9.5.9`
  - `10.6.3` -> `10.6.6`
  - `11.11.1` -> `11.11.8`
  - `12.0.4` -> `12.0.9`
- Upgrade the minor version:
  - `8.9.4` -> `8.12.3`
  - `9.2.3` -> `9.5.5`
  - `10.6.6` -> `10.8.7`
  - `11.3.4` -> `11.11.8`

Upgrading the major version requires more attention.
We cannot guarantee that upgrading between major versions will be seamless. As previously mentioned, major versions are reserved for backwards incompatible changes.
We recommend that you first upgrade to the latest available minor version within
your major version. By doing this, you can address any deprecation messages
that could change behavior in the next major release.
To ensure background migrations are successful, increment by one minor version during the version jump before installing newer releases.

For example: `11.11.x` -> `12.0.x`
Please see the table below for some examples:

| Latest stable version | Your version | Recommended upgrade path | Note |
| --------------------- | ------------ | ------------------------ | ---- |
| 9.4.5                 | 8.13.4       | `8.13.4` -> `8.17.7` -> `9.4.5`                          | `8.17.7` is the last version in version `8` |
| 10.1.4                | 8.13.4       | `8.13.4 -> 8.17.7 -> 9.5.10 -> 10.1.4`                   | `8.17.7` is the last version in version `8`, `9.5.10` is the last version in version `9` |
| 11.3.4                | 8.13.4       | `8.13.4` -> `8.17.7` -> `9.5.10` -> `10.8.7` -> `11.3.4` | `8.17.7` is the last version in version `8`, `9.5.10` is the last version in version `9`, `10.8.7` is the last version in version `10` |
| 12.5.8                | 11.3.4       | `11.3.4` -> `11.11.8` -> `12.0.9` -> `12.5.8`            | `11.11.8` is the last version in version `11` |

To check the size of `background_migration` queue and to learn more about background migrations
see [Upgrading without downtime](../update/README.md#upgrading-without-downtime).

More information about the release procedures can be found in our
[release documentation](https://gitlab.com/gitlab-org/release/docs). You may also want to read our
[Responsible Disclosure Policy](https://about.gitlab.com/security/disclosure/).
