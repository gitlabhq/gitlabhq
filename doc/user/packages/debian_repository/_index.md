---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Debian packages in the package registry
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed
**Status:** Experiment

> - [Deployed behind a feature flag](../../feature_flags.md), disabled by default.

WARNING:
The Debian package registry for GitLab is under development and isn't ready for production use. This [epic](https://gitlab.com/groups/gitlab-org/-/epics/6057) details the remaining
work and timelines to make it production ready. Support for [Debian packages is an experiment](../package_registry/supported_package_managers.md), and has known security vulnerabilities.

Publish Debian packages in your project's package registry. Then install the
packages whenever you need to use them as a dependency.

Project and Group packages are supported.

For documentation of the specific API endpoints that Debian package manager
clients use, see the [Debian API documentation](../../../api/packages/debian.md).

Prerequisites:

- The `dpkg-deb` binary must be installed on the GitLab instance.
  This binary is usually provided by the [`dpkg` package](https://wiki.debian.org/Teams/Dpkg/Downstream),
  installed by default on Debian and derivatives.
- Support for compression algorithm ZStandard requires version `dpkg >= 1.21.18`
  from Debian 12 Bookworm or `dpkg >= 1.19.0.5ubuntu2` from Ubuntu
  18.04 Bionic Beaver.

## Enable the Debian API

Debian repository support is still a work in progress. It's gated behind a feature flag that's
**disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can opt to enable it.

WARNING:
Understand the [stability and security risks of enabling features still in development](../../../administration/feature_flags.md#risks-when-enabling-features-still-in-development).

To enable it:

```ruby
Feature.enable(:debian_packages)
```

To disable it:

```ruby
Feature.disable(:debian_packages)
```

## Enable the Debian group API

The Debian group repository is also behind a second feature flag that is disabled by default.

WARNING:
Understand the [stability and security risks of enabling features still in development](../../../administration/feature_flags.md#risks-when-enabling-features-still-in-development).

To enable it:

```ruby
Feature.enable(:debian_group_packages)
```

To disable it:

```ruby
Feature.disable(:debian_group_packages)
```

## Build a Debian package

Creating a Debian package is documented [on the Debian Wiki](https://wiki.debian.org/Packaging).

## Authenticate to the Debian endpoints

Authentication methods differs between [distributions APIs](#authenticate-to-the-debian-distributions-apis)
and [package repositories](#authenticate-to-the-debian-package-repositories).

### Authenticate to the Debian distributions APIs

To create, read, update, or delete a distribution, you need one of the following:

- [Personal access token](../../../api/rest/authentication.md#personalprojectgroup-access-tokens),
  using `--header "PRIVATE-TOKEN: <personal_access_token>"`
- [Deploy token](../../project/deploy_tokens/_index.md)
  using `--header "Deploy-Token: <deploy_token>"`
- [CI/CD job token](../../../ci/jobs/ci_job_token.md)
  using `--header "Job-Token: <job_token>"`

### Authenticate to the Debian Package Repositories

To publish a package, or install a private package, you need to use basic authentication,
with one of the following:

- [Personal access token](../../../api/rest/authentication.md#personalprojectgroup-access-tokens),
  using `<username>:<personal_access_token>`
- [Deploy token](../../project/deploy_tokens/_index.md)
  using `<deploy_token_name>:<deploy_token>`
- [CI/CD job token](../../../ci/jobs/ci_job_token.md)
  using `gitlab-ci-token:<job_token>`

## Create a Distribution

At the project level, Debian packages are published with **Debian distributions**. At the
group level, Debian packages are aggregated from the projects in the group provided that:

- The project visibility is set to `public`.
- The Debian `codename` for the group matches the Debian `codename` for the project.

To create a project-level distribution using a personal access token:

```shell
curl --fail-with-body --request POST --header "PRIVATE-TOKEN: <personal_access_token>" \
  "https://gitlab.example.com/api/v4/projects/<project_id>/debian_distributions?codename=<codename>"
```

Example response with `codename=sid`:

```json
{
  "id": 1,
  "codename": "sid",
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
- `.ddeb` files: Ubuntu debug .deb files (if needed)
- `.tar.{gz,bz2,xz,...}` files: Source files
- `.dsc` file: Source metadata, and list of source files (with hashes)
- `.buildinfo` file: Used for Reproducible builds (optional)
- `.changes` file: Upload metadata, and list of uploaded files (all the above)

To upload these files, you can use `dput-ng >= 1.32` (Debian bullseye).
`<username>` and `<password>` are defined
[as above](#authenticate-to-the-debian-package-repositories):

```shell
cat <<EOF > dput.cf
[gitlab]
method = https
fqdn = <username>:<password>@gitlab.example.com
incoming = /api/v4/projects/<project_id>/packages/debian
EOF

dput --config=dput.cf --unchecked --no-upload-log gitlab <your_package>.changes
```

## Upload a package with explicit distribution and component

> - Upload with explicit distribution and component [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101838) in GitLab 15.9.

When you don't have access to `.changes` file, you can directly upload a `.deb` by passing
distribution `codename` and target `component` as parameters with
your [credentials](#authenticate-to-the-debian-package-repositories).
For example, to upload to component `main` of distribution `sid` using a personal access token:

```shell
curl --fail-with-body --request PUT --user "<username>:<personal_access_token>" \
  "https://gitlab.example.com/api/v4/projects/<project_id>/packages/debian/your.deb?distribution=sid&component=main" \
  --upload-file  /path/to/your.deb
```

## Install a package

To install a package:

1. Configure the repository:

   If you are using a private project, add your [credentials](#authenticate-to-the-debian-package-repositories) to your apt configuration:

   ```shell
   echo 'machine gitlab.example.com login <username> password <password>' \
     | sudo tee /etc/apt/auth.conf.d/gitlab_project.conf
   ```

   Download your distribution key using your [credentials](#authenticate-to-the-debian-distributions-apis):

   ```shell
   sudo mkdir -p /usr/local/share/keyrings
   curl --fail-with-body --header "PRIVATE-TOKEN: <your_access_token>" \
        "https://gitlab.example.com/api/v4/projects/<project_id>/debian_distributions/<codename>/key.asc" \
        | \
        gpg --dearmor \
        | \
        sudo tee /usr/local/share/keyrings/<codename>-archive-keyring.gpg \
        > /dev/null
   ```

   Add your project as a source:

   ```shell
   echo 'deb [ signed-by=/usr/local/share/keyrings/<codename>-archive-keyring.gpg ] https://gitlab.example.com/api/v4/projects/<project_id>/packages/debian <codename> <component1> <component2>' \
     | sudo tee /etc/apt/sources.list.d/gitlab_project.list
   sudo apt-get update
   ```

1. Install the package:

   ```shell
   sudo apt-get -y install -t <codename> <package-name>
   ```

## Download a source package

To download a source package:

1. Configure the repository:

   If you are using a private project, add your [credentials](#authenticate-to-the-debian-package-repositories) to your apt configuration:

   ```shell
   echo 'machine gitlab.example.com login <username> password <password>' \
     | sudo tee /etc/apt/auth.conf.d/gitlab_project.conf
   ```

   Download your distribution key using your [credentials](#authenticate-to-the-debian-distributions-apis):

   ```shell
   sudo mkdir -p /usr/local/share/keyrings
   curl --fail-with-body --header "PRIVATE-TOKEN: <your_access_token>" \
        "https://gitlab.example.com/api/v4/projects/<project_id>/debian_distributions/<codename>/key.asc" \
        | \
        gpg --dearmor \
        | \
        sudo tee /usr/local/share/keyrings/<codename>-archive-keyring.gpg \
        > /dev/null
   ```

   Add your project as a source:

   ```shell
   echo 'deb-src [ signed-by=/usr/local/share/keyrings/<codename>-archive-keyring.gpg ] https://gitlab.example.com/api/v4/projects/<project_id>/packages/debian <codename> <component1> <component2>' \
     | sudo tee /etc/apt/sources.list.d/gitlab_project-sources.list
   sudo apt-get update
   ```

1. Download the source package:

   ```shell
   sudo apt-get source -t <codename> <package-name>
   ```
