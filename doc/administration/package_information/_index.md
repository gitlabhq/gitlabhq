---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Package information
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

The Linux package is bundled with all dependencies required for GitLab
to function correctly. More details can be found
at [bundling dependencies document](omnibus_packages.md).

## Package Version

The released package versions are in the format `MAJOR.MINOR.PATCH-EDITION.OMNIBUS_RELEASE`

| Component           | Meaning                                                                                                                                   | Example  |
|:--------------------|:------------------------------------------------------------------------------------------------------------------------------------------|:---------|
| `MAJOR.MINOR.PATCH` | The GitLab version this corresponds to.                                                                                                   | `13.3.0` |
| `EDITION`           | The edition of GitLab this corresponds to.                                                                                                | `ee`     |
| `OMNIBUS_RELEASE`   | The Linux package release. Usually, this is `0`. We increment this if we need to build a new package without changing the GitLab version. | `0`      |

## Licenses

See [licensing](licensing.md)

## Defaults

The Linux package requires various configuration to get the components
in working order. If the configuration is not provided, the package uses
the default values assumed in the package.

These defaults are noted in the package [defaults document](defaults.md).

## Checking the versions of bundled software

After the Linux package is installed, you can find the version of
GitLab and all bundled libraries in `/opt/gitlab/version-manifest.txt`.

If you don't have the package installed, you can always check the Linux package
[source repository](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master), specifically the
[configuration directory](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/config).

For example, if you examine the `8-6-stable` branch, you can conclude that
8.6 packages were running [Ruby 2.1.8](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/8-6-stable/config/projects/gitlab.rb#L48).
Or, that 8.5 packages were bundled with [NGINX 1.9.0](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/8-5-stable/config/software/nginx.rb#L20).

## Signatures of GitLab, Inc. provided packages

Documentation on package signatures can be found at [Signed Packages](signed_packages.md)

## Checking for newer configuration options on upgrade

The `/etc/gitlab/gitlab.rb` configuration file is created when the Linux package is initially installed.
To avoid accidental overwrites of user configuration, the `/etc/gitlab/gitlab.rb` configuration file is not updated
with new configuration when the Linux package installation is upgraded.

New configuration options are noted in the
[`gitlab.rb.template` file](https://gitlab.com/gitlab-org/omnibus-gitlab/raw/master/files/gitlab-config-template/gitlab.rb.template).

The Linux package also provides a convenience command which
compares the existing user configuration with the latest version of the
template contained in the package.

To view a diff between your configuration file and the latest version, run:

```shell
sudo gitlab-ctl diff-config
```

WARNING:
If you are pasting the output of this command into your
`/etc/gitlab/gitlab.rb` configuration file, omit any leading `+` and `-`
characters on each line.

## Init system detection

The Linux package attempts to query the underlying system to
check which init system it uses.
This manifests itself as a `WARNING` during the `sudo gitlab-ctl reconfigure`
run.

Depending on the init system, this `WARNING` can be one of:

```plaintext
/sbin/init: unrecognized option '--version'
```

when the underlying init system *is not* upstart.

```plaintext
  -.mount loaded active mounted   /
```

when the underlying init system *IS* systemd.

These warnings _can be safely ignored_. They are not suppressed because this
allows everyone to debug possible detection issues faster.
