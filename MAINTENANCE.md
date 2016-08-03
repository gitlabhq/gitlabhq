# GitLab Maintenance Policy

GitLab follows the [Semantic Versioning](http://semver.org/) for its releases:
`(Major).(Minor).(Patch)` in a [pragmatic way].

- **Major version**: Whenever there is something significant or any backwards
  incompatible changes are introduced to the public API.
- **Minor version**: When new, backwards compatible functionality is introduced
  to the public API or a minor feature is introduced, or when a set of smaller
  features is rolled out.
- **Patch number**: When backwards compatible bug fixes are introduced that fix
  incorrect behavior.

The current stable release will receive security patches and bug fixes
(eg. `8.9.0` -> `8.9.1`). Feature releases will mark the next supported stable
release where the minor version is increased numerically by increments of one
(eg. `8.9 -> 8.10`).

Our current policy is to support one stable release at any given time, but for
medium-level security issues, we may consider [backporting to the previous two
monthly releases][rel-sec].

We encourage everyone to run the latest stable release to ensure that you can
easily upgrade to the most secure and feature-rich GitLab experience. In order
to make sure you can easily run the most recent stable release, we are working
hard to keep the update process simple and reliable.

More information about the release procedures can be found in our
[release-tools documentation][rel]. You may also want to read our
[Responsible Disclosure Policy][disclosure].

[rel-sec]: https://gitlab.com/gitlab-org/release-tools/blob/master/doc/security.md#backporting
[rel]: https://gitlab.com/gitlab-org/release-tools/blob/master/doc/
[disclosure]: https://about.gitlab.com/disclosure/
[pragmatic way]: https://gist.github.com/jashkenas/cbd2b088e20279ae2c8e
