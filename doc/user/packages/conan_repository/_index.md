---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Conan packages in the package registry
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated
**Status:** Experiment

WARNING:
The Conan package registry for GitLab is under development and isn't ready for production use due to
limited functionality. This [epic](https://gitlab.com/groups/gitlab-org/-/epics/6816) details the remaining
work and timelines to make it production ready.

NOTE:
The Conan registry is not FIPS compliant and is disabled when [FIPS mode](../../../development/fips_gitlab.md) is enabled.

Publish Conan packages in your project's package registry. Then install the
packages whenever you need to use them as a dependency.

To publish Conan packages to the package registry, add the package registry as a
remote and authenticate with it.

Then you can run `conan` commands and publish your package to the
package registry.

For documentation of the specific API endpoints that the Conan package manager
client uses, see the [Conan API documentation](../../../api/packages/conan.md).

Learn how to [build a Conan package](../workflows/build_packages.md#conan).

## Add the package registry as a Conan remote

To run `conan` commands, you must add the package registry as a Conan remote for
your project or instance. Then you can publish packages to
and install packages from the package registry.

### Add a remote for your project

Set a remote so you can work with packages in a project without
having to specify the remote name in every command.

When you set a remote for a project, there are no restrictions to your package names.
However, your commands must include the full recipe, including the user and channel,
for example, `package_name/version@user/channel`.

To add the remote:

1. In your terminal, run this command:

   ```shell
   conan remote add gitlab https://gitlab.example.com/api/v4/projects/<project_id>/packages/conan
   ```

1. Use the remote by adding `--remote=gitlab` to the end of your Conan command.

   For example:

   ```shell
   conan search Hello* --remote=gitlab
   ```

### Add a remote for your instance

Use a single remote to access packages across your entire GitLab instance.

However, when using this remote, you must follow these
[package naming restrictions](#package-recipe-naming-convention-for-instance-remotes).

To add the remote:

1. In your terminal, run this command:

   ```shell
   conan remote add gitlab https://gitlab.example.com/api/v4/packages/conan
   ```

1. Use the remote by adding `--remote=gitlab` to the end of your Conan command.

   For example:

   ```shell
   conan search 'Hello*' --remote=gitlab
   ```

#### Package recipe naming convention for instance remotes

The standard Conan recipe convention is `package_name/version@user/channel`, but
if you're using an [instance remote](#add-a-remote-for-your-instance), the
recipe `user` must be the plus sign (`+`) separated project path.

Example recipe names:

| Project                | Package                                        | Supported |
| ---------------------- | ---------------------------------------------- | --------- |
| `foo/bar`              | `my-package/1.0.0@foo+bar/stable`              | Yes       |
| `foo/bar-baz/buz`      | `my-package/1.0.0@foo+bar-baz+buz/stable`      | Yes       |
| `gitlab-org/gitlab-ce` | `my-package/1.0.0@gitlab-org+gitlab-ce/stable` | Yes       |
| `gitlab-org/gitlab-ce` | `my-package/1.0.0@foo/stable`                  | No        |

[Project remotes](#add-a-remote-for-your-project) have a more flexible naming
convention.

## Authenticate to the package registry

GitLab requires authentication to upload packages, and to install packages
from private and internal projects. (You can, however, install packages
from public projects without authentication.)

To authenticate to the package registry, you need one of the following:

- A [personal access token](../../profile/personal_access_tokens.md)
  with the scope set to `api`.
- A [deploy token](../../project/deploy_tokens/_index.md) with the
  scope set to `read_package_registry`, `write_package_registry`, or both.
- A [CI job token](#publish-a-conan-package-by-using-cicd).

NOTE:
Packages from private and internal projects are hidden if you are not
authenticated. If you try to search or download a package from a private or internal
project without authenticating, you receive the error `unable to find the package in remote`
in the Conan client.

### Add your credentials to the GitLab remote

Associate your token with the GitLab remote, so that you don't have to
explicitly add a token to every Conan command.

Prerequisites:

- You must have an authentication token.
- The Conan remote [must be configured](#add-the-package-registry-as-a-conan-remote).

In a terminal, run this command. In this example, the remote name is `gitlab`.
Use the name of your remote.

```shell
conan user <gitlab_username or deploy_token_username> -r gitlab -p <personal_access_token or deploy_token>
```

Now when you run commands with `--remote=gitlab`, your username and password are
included in the requests.

NOTE:
Because your authentication with GitLab expires on a regular basis, you may
occasionally need to re-enter your personal access token.

### Set a default remote for your project (optional)

If you want to interact with the GitLab package registry without having to
specify a remote, you can tell Conan to always use the package registry for your
packages.

In a terminal, run this command:

```shell
conan remote add_ref Hello/0.1@mycompany/beta gitlab
```

NOTE:
The package recipe includes the version, so the default remote for
`Hello/0.1@user/channel` doesn't work for `Hello/0.2@user/channel`.

If you don't set a default user or remote, you can still include the user and
remote in your commands:

```shell
CONAN_LOGIN_USERNAME=<gitlab_username or deploy_token_username> CONAN_PASSWORD=<personal_access_token or deploy_token> <conan command> --remote=gitlab
```

## Publish a Conan package

Publish a Conan package to the package registry, so that anyone who can access
the project can use the package as a dependency.

Prerequisites:

- The Conan remote [must be configured](#add-the-package-registry-as-a-conan-remote).
- [Authentication](#authenticate-to-the-package-registry) with the
  package registry must be configured.
- A local [Conan package](https://docs.conan.io/en/latest/creating_packages/getting_started.html)
  must exist.
  - For an instance remote, the package must meet the [naming convention](#package-recipe-naming-convention-for-instance-remotes).
- You must have the project ID, which is displayed on the [project overview page](../../project/working_with_projects.md#access-a-project-by-using-the-project-id).

To publish the package, use the `conan upload` command:

```shell
conan upload Hello/0.1@mycompany/beta --all
```

## Publish a Conan package by using CI/CD

To work with Conan commands in [GitLab CI/CD](../../../ci/_index.md), you can
use `CI_JOB_TOKEN` in place of the personal access token in your commands.

You can provide the `CONAN_LOGIN_USERNAME` and `CONAN_PASSWORD` with each Conan
command in your `.gitlab-ci.yml` file. For example:

```yaml
create_package:
  image: conanio/gcc7
  stage: deploy
  script:
    - conan remote add gitlab ${CI_API_V4_URL}/projects/$CI_PROJECT_ID/packages/conan
    - conan new <package-name>/0.1 -t
    - conan create . <group-name>+<project-name>/stable
    - CONAN_LOGIN_USERNAME=ci_user CONAN_PASSWORD=${CI_JOB_TOKEN} conan upload <package-name>/0.1@<group-name>+<project-name>/stable --all --remote=gitlab
  environment: production
```

Additional Conan images to use as the basis of your CI file are available in the
[Conan docs](https://docs.conan.io/en/latest/howtos/run_conan_in_docker.html#available-docker-images).

### Re-publishing a package with the same recipe

When you publish a package that has the same recipe (`package-name/version@user/channel`)
as an existing package, the duplicate files are uploaded successfully and
are accessible through the UI. However, when the package is installed,
only the most recently-published package is returned.

## Install a Conan package

Install a Conan package from the package registry so you can use it as a
dependency. You can install a package from the scope of your instance or your project.
If multiple packages have the same recipe, when you install
a package, the most recently-published package is retrieved.

Conan packages are often installed as dependencies by using the `conanfile.txt`
file.

Prerequisites:

- The Conan remote [must be configured](#add-the-package-registry-as-a-conan-remote).
- For private and internal projects, you must configure
  [Authentication](#authenticate-to-the-package-registry)
  with the package registry.

1. In the project where you want to install the package as a dependency, open
   `conanfile.txt`. Or, in the root of your project, create a file called
   `conanfile.txt`.

1. Add the Conan recipe to the `[requires]` section of the file:

   ```plaintext
   [requires]
   Hello/0.1@mycompany/beta

   [generators]
   cmake
   ```

1. At the root of your project, create a `build` directory and change to that
   directory:

   ```shell
   mkdir build && cd build
   ```

1. Install the dependencies listed in `conanfile.txt`:

   ```shell
   conan install .. <options>
   ```

NOTE:
If you try installing the package you created in this tutorial, the install command
has no effect because the package already exists.
Delete `~/.conan/data` to clean up the packages stored in the cache.

## Remove a Conan package

There are two ways to remove a Conan package from the GitLab package registry.

- From the command line, using the Conan client:

  ```shell
  conan remove Hello/0.2@user/channel --remote=gitlab
  ```

  You must explicitly include the remote in this command, otherwise the package
  is removed only from your local system cache.

  NOTE:
  This command removes all recipe and binary package files from the
  package registry.

- From the GitLab user interface:

  Go to your project's **Deploy > Package Registry**. Remove the
  package by selecting **Remove repository** (**{remove}**).

## Search for Conan packages in the package registry

To search by full or partial package name, or by exact recipe, run the
`conan search` command.

- To search for all packages with a specific package name:

  ```shell
  conan search Hello --remote=gitlab
  ```

- To search for a partial name, like all packages starting with `He`:

  ```shell
  conan search He* --remote=gitlab
  ```

The scope of your search depends on your Conan remote configuration:

- If you have a remote configured for your [instance](#add-a-remote-for-your-instance), your search includes
  all projects you have permission to access. This includes your private projects
  as well as all public projects.

- If you have a remote configured for a [project](#add-a-remote-for-your-project), your search includes all
  packages in the target project, as long as you have permission to access it.

NOTE:
The limit of the search results is 500 packages, and the results are sorted by the most recently published packages.

## Fetch Conan package information from the package registry

The `conan info` command returns information about a package:

```shell
conan info Hello/0.1@mycompany/beta
```

## Supported CLI commands

The GitLab Conan repository supports the following Conan CLI commands:

- `conan upload`: Upload your recipe and package files to the package registry.
- `conan install`: Install a Conan package from the package registry, which
  includes using the `conanfile.txt` file.
- `conan search`: Search the package registry for public packages, and private
  packages you have permission to view.
- `conan info`: View the information on a given package from the package registry.
- `conan remove`: Delete the package from the package registry.

## Troubleshooting

### Make output verbose

For more verbose output when troubleshooting a Conan issue:

```shell
export CONAN_TRACE_FILE=/tmp/conan_trace.log # Or SET in windows
conan <command>
```

You can find more logging tips in the [Conan documentation](https://docs.conan.io/en/latest/mastering/logging.html).

### SSL Errors

If you are using a self-signed certificate, there are two methods to manage SSL errors with Conan:

- Use the `conan remote` command to disable the SSL verification.
- Append your server `crt` file to the `cacert.pem` file.

Read more about this in the [Conan Documentation](https://docs.conan.io/en/latest/howtos/use_tls_certificates.html).
