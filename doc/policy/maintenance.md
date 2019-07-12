---
type: concepts
---

# GitLab Release and Maintenance Policy

GitLab has strict policies governing version naming, as well as release pace for major, minor,
patch and security releases. New releases are usually announced on the [GitLab blog](https://about.gitlab.com/blog/categories/releases/).

## Versioning

GitLab uses [Semantic Versioning](https://semver.org/) for its releases:
`(Major).(Minor).(Patch)` in a [pragmatic way](https://gist.github.com/jashkenas/cbd2b088e20279ae2c8e).

For example, for GitLab version 10.5.7:

- `10` represents the major version. The major release was 10.0.0, but often referred to as 10.0.
- `5` represents the minor version. The minor release was 10.5.0, but often referred to as 10.5.
- `7` represents the patch number.

Any part of the version number can increment into multiple digits, for example, 13.10.11.

The following table describes the version types and their release cadence:

| Version type | Description | Cadence |
|:-------------|:------------|:--------|
| Major        | For significant changes, or when any backward-incompatible changes are introduced to the public API. | Yearly. The next major release is GitLab 12.0 on June 22, 2019. Subsequent major releases will be scheduled for May 22 each year, by default. |
| Minor        | For when new backward-compatible functionality is introduced to the public API, a minor feature is introduced, or when a set of smaller features is rolled out. | Monthly on the 22nd. |
| Patch        | For backward-compatible bug fixes that fix incorrect behavior. See [Patch releases](#patch-releases). | As needed. |

## Patch releases

Patch releases usually only include bug fixes and are only done for the current
stable release. That said, in some cases, we may backport it to previous stable
release, depending on the severity of the bug.

For instance, if we release `10.1.1` with a fix for a severe bug introduced in
`10.0.0`, we could backport the fix to a new `10.0.x` patch release.

### Security releases

Security releases are a special kind of patch release that only include security
fixes and patches (see below).

Our current policy is to support one stable release at any given time, but for
medium-level security issues, we may backport security fixes to the previous two
monthly releases.

For very serious security issues, there is
[precedent](https://about.gitlab.com/2016/05/02/cve-2016-4340-patches/)
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
- Upgrade the minor version:
  - `8.9.4` -> `8.12.3`
  - `9.2.3` -> `9.5.5`

Upgrading the major version requires more attention.
We cannot guarantee that upgrading between major versions will be seamless. As previously mentioned, major versions are reserved for backwards incompatible changes.

We recommend that you first upgrade to the latest available minor version within
your major version. By doing this, you can address any deprecation messages
that could change behavior in the next major release.

Please see the table below for some examples:

| Latest stable version | Your version | Recommended upgrade path | Note |
| --------------------- | ------------ | ------------------------ | ---- |
| 9.4.5                 | 8.13.4       | `8.13.4` -> `8.17.7` -> `9.4.5`                          | `8.17.7` is the last version in version `8` |
| 10.1.4                | 8.13.4       | `8.13.4 -> 8.17.7 -> 9.5.10 -> 10.1.4`                   | `8.17.7` is the last version in version `8`, `9.5.10` is the last version in version `9` |
| 11.3.4                | 8.13.4       | `8.13.4` -> `8.17.7` -> `9.5.10` -> `10.8.7` -> `11.3.4` | `8.17.7` is the last version in version `8`, `9.5.10` is the last version in version `9`, `10.8.7` is the last version in version `10` |

More information about the release procedures can be found in our
[release documentation](https://gitlab.com/gitlab-org/release/docs). You may also want to read our
[Responsible Disclosure Policy](https://about.gitlab.com/security/disclosure/).
