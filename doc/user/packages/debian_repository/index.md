---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Debian packages in the Package Registry **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5835) in GitLab 14.1.

WARNING:
The Debian package registry for GitLab is under development and isn't ready for production use due to
limited functionality.

Publish Debian packages in your project's Package Registry. Then install the
packages whenever you need to use them as a dependency.

Project and Group packages are supported.

For documentation of the specific API endpoints that Debian package manager
clients use, see the [Debian API documentation](../../../api/packages/debian.md).

## Enable Debian repository feature

Debian repository support is still a work in progress. It's gated behind a feature flag that's
**disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can opt to enable it.

To enable it:

```ruby
Feature.enable(:debian_packages)
```

To disable it:

```ruby
Feature.disable(:debian_packages)
```

## Build a Debian package

Creating a Debian package is documented [on the Debian Wiki](https://wiki.debian.org/Packaging).

## Create a Distribution

On the project-level, Debian packages are published using *Debian Distributions*. To publish
packages on the group level, create a distribution with the same `codename`.

To create a project-level distribution:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/<project_id>/debian_distributions?codename=unstable
```

Example response:

```json
{
  "id": 1,
  "codename": "unstable",
  "suite": null,
  "origin": null,
  "label": null,
  "version": null,
  "description": null,
  "valid_time_duration_seconds": null,
  "components": [
    "main"
  ],
  "architectures": [
    "all",
    "amd64"
  ]
}
```

More information on Debian distribution APIs:

- [Debian project distributions API](../../../api/packages/debian_project_distributions.md)
- [Debian group distributions API](../../../api/packages/debian_group_distributions.md)

## Publish a package

Once built, several files are created:

- `.deb` files: the binary packages
- `.udeb` files: lightened .deb files, used for Debian-Installer (if needed)
- `.tar.{gz,bz2,xz,...}` files: Source files
- `.dsc` file: Source metadata, and list of source files (with hashes)
- `.buildinfo` file: Used for Reproducible builds (optional)
- `.changes` file: Upload metadata, and list of uploaded files (all the above)

To upload these files, you can use `dput-ng >= 1.32` (Debian bullseye):

```shell
cat <<EOF > dput.cf
[gitlab]
method = https
fqdn = <login>:<your_access_token>@gitlab.example.com
incoming = /api/v4/projects/<project_id>/packages/debian
EOF

dput --config=dput.cf --unchecked --no-upload-log gitlab <your_package>.changes
```

## Install a package

The Debian package registry for GitLab is under development, and isn't ready for production use. You
cannot install packages from the registry. However, you can download files directly from the UI.
