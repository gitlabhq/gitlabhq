---
type: concepts
---

# GitLab Release and Maintenance Policy

GitLab has strict policies governing version naming, as well as release pace for major, minor,
patch, and security releases. New releases are usually announced on the [GitLab blog](https://about.gitlab.com/releases/categories/releases/).

Our current policy is:

- Backporting bug fixes for **only the current stable release** at any given time. (See [patch releases](#patch-releases).)
- Backporting **to the previous two monthly releases in addition to the current stable release**. (See [security releases](#security-releases).)

## Versioning

GitLab uses [Semantic Versioning](https://semver.org/) for its releases:
`(Major).(Minor).(Patch)`.

For example, for GitLab version 12.10.6:

- `12` represents the major version. The major release was 12.0.0, but often referred to as 12.0.
- `10` represents the minor version. The minor release was 12.10.0, but often referred to as 12.10.
- `6` represents the patch number.

Any part of the version number can increment into multiple digits, for example, 13.10.11.

The following table describes the version types and their release cadence:

| Version type | Description | Cadence |
|:-------------|:------------|:--------|
| Major        | For significant changes, or when any backward-incompatible changes are introduced to the public API. | Yearly. The next major release is GitLab 14.0 on May 22, 2021. Subsequent major releases will be scheduled for May 22 each year, by default. |
| Minor        | For when new backward-compatible functionality is introduced to the public API, a minor feature is introduced, or when a set of smaller features is rolled out. | Monthly on the 22nd. |
| Patch        | For backward-compatible bug fixes that fix incorrect behavior. See [Patch releases](#patch-releases). | As needed. |

## Upgrade recommendations

We encourage everyone to run the [latest stable release](https://about.gitlab.com/releases/categories/releases/)
to ensure that you can easily upgrade to the most secure and feature-rich GitLab experience.
In order to make sure you can easily run the most recent stable release, we are working
hard to keep the update process simple and reliable.

If you are unable to follow our monthly release cycle, there are a couple of
cases you need to consider.

It is considered safe to jump between patch versions and minor versions within
one major version. For example, it is safe to:

- Upgrade the *minor* version. For example:

  - `12.7.5` -> `12.10.5`
  - `11.3.4` -> `11.11.1`
  - `10.6.6` -> `10.8.3`
  - `11.3.4` -> `11.11.8`
  - `10.6.6` -> `10.8.7`
  - `9.2.3` -> `9.5.5`
  - `8.9.4` -> `8.12.3`

- Upgrade the *patch* version. For example:

  - `12.0.4` -> `12.0.12`
  - `11.11.1` -> `11.11.8`
  - `10.6.3` -> `10.6.6`
  - `11.11.1` -> `11.11.8`
  - `10.6.3` -> `10.6.6`
  - `9.5.5` -> `9.5.9`
  - `8.9.2` -> `8.9.6`

NOTE **Note** Version specific changes in Omnibus GitLab Linux packages can be found in [the Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/update/README.html#version-specific-changes).

NOTE: **Note:**
Instructions are available for downloading an Omnibus GitLab Linux package locally and [manually installing](https://docs.gitlab.com/omnibus/manual_install.html) it.

### Upgrading major versions

Upgrading the *major* version requires more attention.
Backward-incompatible changes and migrations are reserved for major versions.
We cannot guarantee that upgrading between major versions will be seamless.
We suggest upgrading to the latest available *minor* version within
your major version before proceeding to the next major version.
Doing this will address any backward-incompatible changes or deprecations
to help ensure a successful upgrade to next major release.

It's also important to ensure that any background migrations have been fully completed
before upgrading to a new major version. To see the current size of the `background_migration` queue,
[Check for background migrations before upgrading](../update/README.md#checking-for-background-migrations-before-upgrading).

If your GitLab instance has any GitLab Runners associated with it, it is very
important to upgrade the GitLab Runners to match the GitLab minor version that was
upgraded to. This is to ensure [compatibility with GitLab versions](https://docs.gitlab.com/runner/#compatibility-with-gitlab-versions).

### Version 12 onward: Extra step for major upgrades

From version 12 onward, an additional step is required. More significant migrations
may occur during major release upgrades.

To ensure these are successful:

1. Increment to the first minor version (`x.0.x`) during the major version jump.
1. Proceed with upgrading to a newer release.

**For example: `11.5.x` -> `11.11.x` -> `12.0.x` -> `12.10.x` -> `13.0.x`**

### Example upgrade paths

Please see the table below for some examples:

| Target version | Your version | Recommended upgrade path | Note |
| --------------------- | ------------ | ------------------------ | ---- |
| `13.2.0`                | `11.5.0`      | `11.5.0` -> `11.11.8` -> `12.0.12` -> `12.10.6` -> `13.0.0` -> `13.2.0` | Four intermediate versions are required: the final 11.11, 12.0, and 12.10 releases, plus 13.0. |
| `13.0.1`              | `11.10.8`      | `11.10.5` -> `11.11.8` -> `12.0.12` -> `12.10.6` -> `13.0.1` | Three intermediate versions are required: `11.11`, `12.0`, and `12.10`. |
| `12.10.6`             | `11.3.4`       | `11.3.4` -> `11.11.8` -> `12.0.12` -> `12.10.6`             |  Two intermediate versions are required: `11.11` and `12.0` |
| `12.9.5.`             | `10.4.5`       | `10.4.5` -> `10.8.7` -> `11.11.8` -> `12.0.12` -> `12.9.5`   | Three intermediate versions are required: `10.8`, `11.11`, and `12.0`, then `12.9.5` |
| `12.2.5`              | `9.2.6`        | `9.2.6` -> `9.5.10` -> `10.8.7` -> `11.11.8` -> `12.0.12` -> `12.2.5` | Four intermediate versions are required: `9.5`, `10.8`, `11.11`, `12.0`, then `12.2`. |
| `11.3.4`              | `8.13.4`       | `8.13.4` -> `8.17.7` -> `9.5.10` -> `10.8.7` -> `11.3.4` | `8.17.7` is the last version in version 8, `9.5.10` is the last version in version 9, `10.8.7` is the last version in version 10. |

### Upgrades from versions earlier than 8.12

- `8.11.x` and earlier: you might have to upgrade to `8.12.0` specifically before you can
  upgrade to `8.17.7`. This was [reported in an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/207259).
- [CI changes prior to version 8.0](https://docs.gitlab.com/omnibus/update/README.html#updating-gitlab-ci-from-prior-540-to-version-714-via-omnibus-gitlab)
  when it was merged into GitLab.

### Multi-step upgrade paths with GitLab all-in-one Linux package repository

Linux package managers default to installing the latest available version of a package for installation and upgrades.
Upgrading directly to the latest major version can be problematic for older GitLab versions that require a multi-stage upgrade path.

When following an upgrade path spanning multiple versions, for each upgrade, specify the intended GitLab version number in your package manager's install or upgrade command.

Examples:

```shell
# apt-get (Ubuntu/Debian)
sudo apt-get upgrade gitlab-ee=12.0.12-ee.0
# yum (RHEL/CentOS 6 and 7)
yum install gitlab-ee-12.0.12-ee.0.el7
# dnf (RHEL/CentOS 8)
dnf install gitlab-ee-12.0.12-ee.0.el8
# zypper (SUSE)
zypper install gitlab-ee=12.0.12-ee.0
```

## Patch releases

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
consideration by raising an issue in the [release/tasks](https://gitlab.com/gitlab-org/release/tasks/-/issues/new?issuable_template=Backporting-request) issue tracker.
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
the current stable release, and two previous monthly releases.
For instance, if we release `11.2.1` with a fix for a severe bug introduced in
`11.0.0`, we could backport the fix to a new `11.0.x`, and `11.1.x` patch release.

To request backporting to more than one stable release for consideration, raise an issue in the
[release/tasks](https://gitlab.com/gitlab-org/release/tasks/-/issues/new?issuable_template=Backporting-request) issue tracker.

### Security releases

Security releases are a special kind of patch release that only include security
fixes and patches (see below) for the previous two monthly releases in addition to the current stable release.

For very serious security issues, there is
[precedent](https://about.gitlab.com/releases/2016/05/02/cve-2016-4340-patches/)
to backport security fixes to even more monthly releases of GitLab.
This decision is made on a case-by-case basis.

## More information

Check [our release posts](https://about.gitlab.com/releases/categories/releases/).

Each month, we publish either a major or minor release of GitLab. At the end
of those release posts there are three sections to look for: Deprecations, Removals, and Important notes on upgrading. These will include:

- Steps you need to perform as part of an upgrade.
  For example [8.12](https://about.gitlab.com/releases/2016/09/22/gitlab-8-12-released/#upgrade-barometer)
  required the Elasticsearch index to be recreated. Any older version of GitLab upgrading to 8.12 or higher
  would require this.
- Changes to the versions of software we support such as
  [ceasing support for IE11 in GitLab 13](https://about.gitlab.com/releases/2020/03/22/gitlab-12-9-released/#ending-support-for-internet-explorer-11).

You should check all the major and minor versions you're passing over.

More information about the release procedures can be found in our
[release documentation](https://gitlab.com/gitlab-org/release/docs). You may also want to read our
[Responsible Disclosure Policy](https://about.gitlab.com/security/disclosure/).
