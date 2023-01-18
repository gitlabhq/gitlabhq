---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Debian packages in the Package Registry **(FREE)**

> - Debian API [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/42670) in GitLab 13.5.
> - Debian group API [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66188) in GitLab 14.2.
> - [Deployed behind a feature flag](../../feature_flags.md), disabled by default.

WARNING:
The Debian package registry for GitLab is under development and isn't ready for production use due to
limited functionality. This [epic](https://gitlab.com/groups/gitlab-org/-/epics/6057) details the remaining
work and timelines to make it production ready.

NOTE:
The Debian registry is not FIPS compliant and is disabled when [FIPS mode](../../../development/fips_compliance.md) is enabled.

Publish Debian packages in your project's Package Registry. Then install the
packages whenever you need to use them as a dependency.

Project and Group packages are supported.

For documentation of the specific API endpoints that Debian package manager
clients use, see the [Debian API documentation](../../../api/packages/debian.md).

## Enable the Debian API **(FREE SELF)**

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

## Enable the Debian group API **(FREE SELF)**

The Debian group repository is also behind a second feature flag that is disabled by default.

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

## Authenticate to the Package Registry

To create a distribution, publish a package, or install a private package, you need one of the
following:

- [Personal access token](../../../api/rest/index.md#personalprojectgroup-access-tokens)
- [CI/CD job token](../../../ci/jobs/ci_job_token.md)
- [Deploy token](../../project/deploy_tokens/index.md)

## Create a Distribution

On the project-level, Debian packages are published using *Debian Distributions*. To publish
packages on the group level, create a distribution with the same `codename`.

To create a project-level distribution:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/<project_id>/debian_distributions?codename=<codename>"
```

Example response with `codename=unstable`:

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
fqdn = <username>:<your_access_token>@gitlab.example.com
incoming = /api/v4/projects/<project_id>/packages/debian
EOF

dput --config=dput.cf --unchecked --no-upload-log gitlab <your_package>.changes
```

## Install a package

To install a package:

1. Configure the repository:

    If you are using a private project, add your [credentials](#authenticate-to-the-package-registry) to your apt configuration:

    ```shell
    echo 'machine gitlab.example.com login <username> password <your_access_token>' \
      | sudo tee /etc/apt/auth.conf.d/gitlab_project.conf
    ```

    Download your distribution key:

    ```shell
    sudo mkdir -p /usr/local/share/keyrings
    curl --header "PRIVATE-TOKEN: <your_access_token>" \
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

    If you are using a private project, add your [credentials](#authenticate-to-the-package-registry) to your apt configuration:

    ```shell
    echo 'machine gitlab.example.com login <username> password <your_access_token>' \
      | sudo tee /etc/apt/auth.conf.d/gitlab_project.conf
    ```

    Download your distribution key:

    ```shell
    sudo mkdir -p /usr/local/share/keyrings
    curl --header "PRIVATE-TOKEN: <your_access_token>" \
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
