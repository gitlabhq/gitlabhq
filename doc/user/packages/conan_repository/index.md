---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Conan packages in the Package Registry **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/8248) in GitLab Premium 12.6.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) to GitLab Free in 13.3.

Publish Conan packages in your project's Package Registry. Then install the
packages whenever you need to use them as a dependency.

To publish Conan packages to the Package Registry, add the Package Registry as a
remote and authenticate with it.

Then you can run `conan` commands and publish your package to the
Package Registry.

For documentation of the specific API endpoints that the Conan package manager
client uses, see the [Conan API documentation](../../../api/packages/conan.md).

## Build a Conan package

This section explains how to install Conan and build a package for your C/C++
project.

If you already use Conan and know how to build your own packages, go to the
[next section](#add-the-package-registry-as-a-conan-remote).

### Install Conan

Download the Conan package manager to your local development environment by
following the instructions at [conan.io](https://conan.io/downloads.html).

When installation is complete, verify you can use Conan in your terminal by
running:

```shell
conan --version
```

The Conan version is printed in the output:

```plaintext
Conan version 1.20.5
```

### Install CMake

When you develop with C++ and Conan, you can select from many available
compilers. This example uses the CMake build system generator.

To install CMake:

- For Mac, use [Homebrew](https://brew.sh/) and run `brew install cmake`.
- For other operating systems, follow the instructions at [cmake.org](https://cmake.org/install/).

When installation is complete, verify you can use CMake in your terminal by
running:

```shell
cmake --version
```

The CMake version is printed in the output.

### Create a project

To test the Package Registry, you need a C++ project. If you don't already have
one, you can clone the Conan [hello world starter project](https://github.com/conan-io/hello).

### Build a package

To build a package:

1. Open a terminal and navigate to your project's root folder.
1. Generate a new recipe by running `conan new` with a package name and version:

   ```shell
   conan new Hello/0.1 -t
   ```

1. Create a package for the recipe by running `conan create` with the Conan user
   and channel:

   ```shell
   conan create . mycompany/beta
   ```

   NOTE:
   If you use an [instance remote](#add-a-remote-for-your-instance), you must
   follow a specific [naming convention](#package-recipe-naming-convention-for-instance-remotes).

A package with the recipe `Hello/0.1@mycompany/beta` is created.

For more details about creating and managing Conan packages, see the
[Conan documentation](https://docs.conan.io/en/latest/creating_packages.html).

## Add the Package Registry as a Conan remote

To run `conan` commands, you must add the Package Registry as a Conan remote for
your project or instance. Then you can publish packages to
and install packages from the Package Registry.

### Add a remote for your project

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/11679) in GitLab 13.4.

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

| Project                            | Package                                         | Supported |
| ---------------------------------- | ----------------------------------------------- | --------- |
| `foo/bar`                          | `my-package/1.0.0@foo+bar/stable`               | Yes       |
| `foo/bar-baz/buz`                  | `my-package/1.0.0@foo+bar-baz+buz/stable`       | Yes       |
| `gitlab-org/gitlab-ce`             | `my-package/1.0.0@gitlab-org+gitlab-ce/stable`  | Yes       |
| `gitlab-org/gitlab-ce`             | `my-package/1.0.0@foo/stable`                   | No        |

[Project remotes](#add-a-remote-for-your-project) have a more flexible naming
convention.

## Authenticate to the Package Registry

GitLab requires authentication to upload packages, and to install packages
from private and internal projects. (You can, however, install packages
from public projects without authentication.)

To authenticate to the Package Registry, you need one of the following:

- A [personal access token](../../../user/profile/personal_access_tokens.md)
  with the scope set to `api`.
- A [deploy token](../../project/deploy_tokens/index.md) with the
  scope set to `read_package_registry`, `write_package_registry`, or both.
- A [CI job token](#publish-a-conan-package-by-using-cicd).

NOTE:
Packages from private and internal projects are hidden if you are not
authenticated. If you try to search or download a package from a private or internal project without authenticating, you will receive the error `unable to find the package in remote` in the Conan client.

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

Alternatively, you can explicitly include your credentials in any given command.
For example:

```shell
CONAN_LOGIN_USERNAME=<gitlab_username or deploy_token_username> CONAN_PASSWORD=<personal_access_token or deploy_token> conan upload Hello/0.1@mycompany/beta --all --remote=gitlab
```

NOTE:
Because your authentication with GitLab expires on a regular basis, you may
occasionally need to re-enter your personal access token.

### Set a default remote for your project (optional)

If you want to interact with the GitLab Package Registry without having to
specify a remote, you can tell Conan to always use the Package Registry for your
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
`CONAN_LOGIN_USERNAME=<gitlab_username or deploy_token_username> CONAN_PASSWORD=<personal_access_token or deploy_token> <conan command> --remote=gitlab
```

## Publish a Conan package

Publish a Conan package to the Package Registry, so that anyone who can access
the project can use the package as a dependency.

Prerequisites:

- The Conan remote [must be configured](#add-the-package-registry-as-a-conan-remote).
- [Authentication](#authenticate-to-the-package-registry) with the
  Package Registry must be configured.
- A local [Conan package](https://docs.conan.io/en/latest/creating_packages/getting_started.html)
  must exist.
  - For an instance remote, the package must meet the [naming convention](#package-recipe-naming-convention-for-instance-remotes).
- You must have the project ID, which is on the project's homepage.

To publish the package, use the `conan upload` command:

```shell
conan upload Hello/0.1@mycompany/beta --all
```

## Publish a Conan package by using CI/CD

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/11678) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.7.

To work with Conan commands in [GitLab CI/CD](../../../ci/index.md), you can
use `CI_JOB_TOKEN` in place of the personal access token in your commands.

You can provide the `CONAN_LOGIN_USERNAME` and `CONAN_PASSWORD` with each Conan
command in your `.gitlab-ci.yml` file. For example:

```yaml
image: conanio/gcc7

create_package:
  stage: deploy
  script:
    - conan remote add gitlab ${CI_API_V4_URL}/projects/$CI_PROJECT_ID/packages/conan
    - conan new <package-name>/0.1 -t
    - conan create . <group-name>+<project-name>/stable
    - CONAN_LOGIN_USERNAME=ci_user CONAN_PASSWORD=${CI_JOB_TOKEN} conan upload <package-name>/0.1@<group-name>+<project-name>/stable --all --remote=gitlab
```

Additional Conan images to use as the basis of your CI file are available in the
[Conan docs](https://docs.conan.io/en/latest/howtos/run_conan_in_docker.html#available-docker-images).

### Re-publishing a package with the same recipe

When you publish a package that has the same recipe (`package-name/version@user/channel`)
as an existing package, the duplicate files are uploaded successfully and
are accessible through the UI. However, when the package is installed,
only the most recently-published package is returned.

## Install a Conan package

Install a Conan package from the Package Registry so you can use it as a
dependency. You can install a package from the scope of your instance or your project.
If multiple packages have the same recipe, when you install
a package, the most recently-published package is retrieved.

WARNING:
Project-level packages [cannot be downloaded currently](https://gitlab.com/gitlab-org/gitlab/-/issues/270129).

Conan packages are often installed as dependencies by using the `conanfile.txt`
file.

Prerequisites:

- The Conan remote [must be configured](#add-the-package-registry-as-a-conan-remote).
- For private and internal projects, you must configure
  [Authentication](#authenticate-to-the-package-registry)
  with the Package Registry.

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
If you try to install the package you just created in this tutorial, the package
already exists on your local computer, so this command has no effect.

## Remove a Conan package

There are two ways to remove a Conan package from the GitLab Package Registry.

- From the command line, using the Conan client:

  ```shell
  conan remove Hello/0.2@user/channel --remote=gitlab
  ```

  You must explicitly include the remote in this command, otherwise the package
  is removed only from your local system cache.

  NOTE:
  This command removes all recipe and binary package files from the
  Package Registry.

- From the GitLab user interface:

  Go to your project's **Packages & Registries > Package Registry**. Remove the
  package by clicking the red trash icon.

## Search for Conan packages in the Package Registry

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

The scope of your search includes all projects you have permission to access.
This includes your private projects as well as all public projects.

## Fetch Conan package information from the Package Registry

The `conan info` command returns information about a package:

```shell
conan info Hello/0.1@mycompany/beta
```

## Supported CLI commands

The GitLab Conan repository supports the following Conan CLI commands:

- `conan upload`: Upload your recipe and package files to the Package Registry.
- `conan install`: Install a Conan package from the Package Registry, which
  includes using the `conanfile.txt` file.
- `conan search`: Search the Package Registry for public packages, and private
  packages you have permission to view.
- `conan info`: View the information on a given package from the Package Registry.
- `conan remove`: Delete the package from the Package Registry.
