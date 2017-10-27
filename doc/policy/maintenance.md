# GitLab Maintenance Policy

## Versioning

GitLab follows the [Semantic Versioning](http://semver.org/) for its releases:
`(Major).(Minor).(Patch)` in a [pragmatic way].

- **Major version**: Whenever there is something significant or any backwards
  incompatible changes are introduced to the public API.
- **Minor version**: When new, backwards compatible functionality is introduced
  to the public API or a minor feature is introduced, or when a set of smaller
  features is rolled out.
- **Patch number**: When backwards compatible bug fixes are introduced that fix
  incorrect behavior.

For example, for GitLab version 10.5.7:

* `10` represents major version
* `5` represents minor version
* `7` represents patch number

## Security releases

The current stable release will receive security patches and bug fixes
(eg. `8.9.0` -> `8.9.1`).

Feature releases will mark the next supported stable
release where the minor version is increased numerically by increments of one
(eg. `8.9 -> 8.10`).

Our current policy is to support one stable release at any given time.
For medium-level security issues, we may consider backporting to the previous two
monthly releases.

For very serious security issues, there is [precedent](https://about.gitlab.com/2016/05/02/cve-2016-4340-patches/)
to backport security fixes to even more monthly releases of GitLab. This decision
is made on a case-by-case basis.

## Version support

We encourage everyone to run the latest stable release to ensure that you can
easily upgrade to the most secure and feature-rich GitLab experience. In order
to make sure you can easily run the most recent stable release, we are working
hard to keep the update process simple and reliable.

If you are unable to follow our monthly release cycle, there are a couple of
cases you need to consider.

It is considered safe to jump between patch versions and minor versions within
one major version. For example, it is safe to:

* Upgrade the patch version:
  * `8.9.0` -> `8.9.7`
  * `8.9.0` -> `8.9.1`
  * `8.9.2` -> `8.9.6`
* Upgrade the minor version:
  * `8.9.4` -> `8.12.3`
  * `9.2.3` -> `9.5.5`

Upgrading the major version requires more attention.
We cannot guarantee that upgrading between major versions will be seamless. As previously mentioned, major versions are reserved for backwards incompatible changes.

We recommend that you first upgrade to the latest available minor version within
your major version. By doing this, you can address any deprecation messages
that could possibly change behaviour in the next major release.

Please see the table below for some examples:

| Latest stable version | Your version | Recommended upgrade path | Note |
| -------------- | ------------ | ------------------------ | ---------------- |
| 9.4.5   | 8.13.4   | `8.13.4` -> `8.17.7` -> `9.4.5`     | `8.17.7` is the last version in version `8` |
| 10.1.4   | 8.13.4   | `8.13.4` -> `8.17.7` -> `9.5.8` -> `10.1.4` | `8.17.7` is the last version in version `8`, `9.5.8` is the last version in version `9` |
|

More information about the release procedures can be found in our
[release-tools documentation][rel]. You may also want to read our
[Responsible Disclosure Policy][disclosure].

[rel]: https://gitlab.com/gitlab-org/release-tools/blob/master/doc/
[disclosure]: https://about.gitlab.com/disclosure/
[pragmatic way]: https://gist.github.com/jashkenas/cbd2b088e20279ae2c8e
