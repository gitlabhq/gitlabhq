# GitLab Maintenance Policy

GitLab is a fast moving and evolving project. We currently don't have the resources to support many releases concurrently. We support exactly one stable release at any given time.

GitLab follows the [Semantic Versioning](http://semver.org/) for its releases: `(Major).(Minor).(Patch)`.

- **Major version**: Whenever there is something significant or any backwards incompatible changes are introduced to the public API.
- **Minor version**: When new, backwards compatible functionality is introduced to the public API or a minor feature is introduced, or when a set of smaller features is rolled out.
- **Patch number**: When backwards compatible bug fixes are introduced that fix incorrect behavior.

The current stable release will receive security patches and bug fixes (eg. `5.0` -> `5.0.1`).  Feature releases will mark the next supported stable release where the minor version is increased numerically by increments of one (eg. `5.0 -> 5.1`).

We encourage everyone to run the latest stable release to ensure that you can easily upgrade to the most secure and feature rich GitLab experience. In order to make sure you can easily run the most recent stable release, we are working hard to keep the update process simple and reliable.

More information about the release procedures can be found in the doc/release directory.
