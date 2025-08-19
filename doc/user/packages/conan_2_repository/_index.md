---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Conan 2 packages in the package registry
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/519741) in GitLab 18.1 [with a flag](../../../administration/feature_flags/_index.md) named `conan_package_revisions_support`. Disabled by default.
- [Enabled on GitLab.com](https://gitlab.com/groups/gitlab-org/-/epics/14896) in GitLab 18.3. Feature flag `conan_package_revisions_support` removed.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag. For more information, see the history.

{{< /alert >}}

{{< alert type="warning" >}}

The Conan 2 package registry for GitLab is under development and isn't ready for production use due to
limited functionality. This [epic](https://gitlab.com/groups/gitlab-org/-/epics/8258) details the remaining
work and timelines to make it production ready.

{{< /alert >}}

{{< alert type="note" >}}

The Conan 2 registry is not FIPS compliant and is disabled when FIPS mode is enabled.

{{< /alert >}}

Publish Conan 2 packages in your project's package registry. Then install the
packages whenever you need to use them as a dependency.

To publish Conan 2 packages to the package registry, add the package registry as a
remote and authenticate with it.

Then you can run `conan` commands and publish your package to the
package registry.

For documentation of the specific API endpoints that the Conan 2 package manager client uses, see [Conan v2 API](../../../api/packages/conan_v2.md)

Learn how to [build a Conan 2 package](../workflows/build_packages.md#conan-2).

## Add the package registry as a Conan remote

To run `conan` commands, you must add the package registry as a Conan remote for
your project or instance. Then you can publish packages to
and install packages from the package registry.

### Add a remote for your project

Set a remote so you can work with packages in a project without
having to specify the remote name in every command.

When you set a remote for a project, the package names have to be lowercase.
Also, your commands must include the full recipe, including the user and channel,
for example, `package_name/version@user/channel`.

To add the remote:

1. In your terminal, run this command:

   ```shell
   conan remote add gitlab https://gitlab.example.com/api/v4/projects/<project_id>/packages/conan
   ```

1. Use the remote by adding `--remote=gitlab` to the end of your Conan 2 command.

   For example:

   ```shell
   conan search hello* --remote=gitlab
   ```

## Authenticate to the package registry

GitLab requires authentication to upload packages, and to install packages
from private and internal projects. (You can, however, install packages
from public projects without authentication.)

To authenticate to the package registry, you need one of the following:

- A [personal access token](../../profile/personal_access_tokens.md)
  with the scope set to `api`.
- A [deploy token](../../project/deploy_tokens/_index.md) with the
  scope set to `read_package_registry`, `write_package_registry`, or both.
- A [CI job token](#publish-a-conan-2-package-by-using-cicd).

{{< alert type="note" >}}

Packages from private and internal projects are hidden if you are not
authenticated. If you try to search or download a package from a private or internal
project without authenticating, you receive the error `unable to find the package in remote`
in the Conan 2 client.

{{< /alert >}}

### Add your credentials to the GitLab remote

Associate your token with the GitLab remote, so that you don't have to
explicitly add a token to every Conan 2 command.

Prerequisites:

- You must have an authentication token.
- The Conan remote [must be configured](#add-the-package-registry-as-a-conan-remote).

In a terminal, run this command. In this example, the remote name is `gitlab`.
Use the name of your remote.

```shell
conan remote login -p <personal_access_token or deploy_token> gitlab <gitlab_username or deploy_token_username>
```

Now when you run commands with `--remote=gitlab`, your username and password are
included in the requests.

{{< alert type="note" >}}

Because your authentication with GitLab expires on a regular basis, you may
occasionally need to re-enter your personal access token.

{{< /alert >}}

## Publish a Conan 2 package

Publish a Conan 2 package to the package registry, so that anyone who can access
the project can use the package as a dependency.

Prerequisites:

- The Conan remote [must be configured](#add-the-package-registry-as-a-conan-remote).
- [Authentication](#authenticate-to-the-package-registry) with the
  package registry must be configured.
- A local [Conan 2 package](../workflows/build_packages.md#conan-2)
  must exist.
- You must have the project ID, which is displayed on the [project overview page](../../project/working_with_projects.md#find-the-project-id).

To publish the package, use the `conan upload` command:

```shell
conan upload hello/0.1@mycompany/beta -r gitlab
```

## Publish a Conan 2 package by using CI/CD

To work with Conan 2 commands in [GitLab CI/CD](../../../ci/_index.md), you can
use `CI_JOB_TOKEN` in place of the personal access token in your commands.

You can provide the `CONAN_LOGIN_USERNAME` and `CONAN_PASSWORD` with each Conan
command in your `.gitlab-ci.yml` file. For example:

```yaml
create_package:
  image: <conan 2 image>
  stage: deploy
  script:
    - conan remote add gitlab ${CI_API_V4_URL}/projects/$CI_PROJECT_ID/packages/conan
    - conan new <package-name>/0.1
    - conan create . --channel=stable --user=mycompany
    - CONAN_LOGIN_USERNAME=ci_user CONAN_PASSWORD=${CI_JOB_TOKEN} conan upload <package-name>/0.1@mycompany/stable --remote=gitlab
  environment: production
```

Follow the [official guide](https://docs.conan.io/2.17/examples/runners/docker/basic.html) to create an appropriate Conan 2 image to use as the basis of your CI file.

### Re-publishing a package with the same recipe

When you publish a package that has the same recipe (`package-name/version@user/channel`)
as an existing package, Conan skips the upload because they are already in the server.

## Install a Conan 2 package

Install a Conan 2 package from the package registry so you can use it as a
dependency. You can install a package from the scope of your project.
If multiple packages have the same recipe, when you install
a package, the most recently-published package is retrieved.

Conan 2 packages are often installed as dependencies by using the `conanfile.txt`
file.

Prerequisites:

- The Conan remote [must be configured](#add-the-package-registry-as-a-conan-remote).
- For private and internal projects, you must configure
  [Authentication](#authenticate-to-the-package-registry)
  with the package registry.

1. Create another package following the [Conan 2 package](../workflows/build_packages.md#conan-2)
guide. In the root of your project, create a file called `conanfile.txt`.

1. Add the Conan recipe to the `[requires]` section of the file:

   ```plaintext
   [requires]
   hello/0.1@mycompany/beta
   ```

1. At the root of your project, create a `build` directory and change to that
   directory:

   ```shell
   mkdir build && cd build
   ```

1. Install the dependencies listed in `conanfile.txt`:

   ```shell
   conan install ../conanfile.txt
   ```

{{< alert type="note" >}}

If you try installing the package you created in this tutorial, the install command
has no effect because the package already exists.
Use this command to remove an existing package locally and then try again:

```shell
conan remove hello/0.1@mycompany/beta
```

{{< /alert >}}

## Remove a Conan 2 package

There are two ways to remove a Conan 2 package from the GitLab package registry.

- From the command line, using the Conan 2 client:

  ```shell
  conan remove hello/0.1@mycompany/beta --remote=gitlab
  ```

  You must explicitly include the remote in this command, otherwise the package
  is removed only from your local system cache.

  {{< alert type="note" >}}

  This command removes all recipe and binary package files from the
  package registry.

  {{< /alert >}}

- From the GitLab user interface:

  Go to your project's **Deploy > Package registry**. Remove the
  package by selecting **Remove repository** ({{< icon name="remove" >}}).

## Search for Conan 2 packages in the package registry

To search by full or partial package name, or by exact recipe, run the
`conan search` command.

- To search for all packages with a specific package name:

  ```shell
  conan search hello --remote=gitlab
  ```

- To search for a partial name, like all packages starting with `he`:

  ```shell
  conan search "he*" --remote=gitlab
  ```

The scope of your search depends on your Conan remote configuration. Your search includes all
packages in the target project, as long as you have permission to access it.

{{< alert type="note" >}}

The limit of the search results is 500 packages, and the results are sorted by the most recently published packages.

{{< /alert >}}

## Download a Conan 2 package

You can download a Conan 2 package's recipe and binaries to your local cache without using settings that use the `conan download` command.

Prerequisites:

- The Conan remote [must be configured](#add-the-package-registry-as-a-conan-remote).
- For private and internal projects, you must configure [authentication](#authenticate-to-the-package-registry) with the package registry.

### Download all binary packages

You can download all binary packages associated with a recipe from the package registry.

To download all binary packages, run the following command:

```shell
conan download hello/0.1@mycompany/beta --remote=gitlab
```

### Download recipe files

You can download only the recipe files without any binary packages.

To download recipe files, run the following command:

```shell
conan download hello/0.1@mycompany/beta --remote=gitlab --only-recipe
```

### Download a specific binary package

You can download a single binary package by referencing its package reference (known as the `package_id` in Conan 2 documentation).

To download a specific binary package, run the following command:

```shell
conan download Hello/0.1@foo+bar/stable:<package_reference> --remote=gitlab
```

## Supported CLI commands

The GitLab Conan repository supports the following Conan 2 CLI commands:

- `conan upload`: Upload your recipe and package files to the package registry.
- `conan install`: Install a Conan 2 package from the package registry, which
  includes using the `conanfile.txt` file.
- `conan download`: Download package recipes and binaries to your local cache without using settings.
- `conan search`: Search the package registry for public packages, and private
  packages you have permission to view.
- `conan list` : List existing recipes, revisions, or packages.
- `conan remove`: Delete the package from the package registry.

## Conan revisions

Conan revisions provide package immutability in the package registry. When you make changes to a recipe or a package without changing its version, Conan calculates a unique identifier (revision) to track these changes.

### Types of revisions

Conan uses two types of revisions:

- **Recipe revisions (RREV)**: Generated when a recipe is exported. By default, Conan calculates recipe revisions using the checksum hash of the recipe manifest.
- **Package revisions (PREV)**: Generated when a package is built. Conan calculates package revisions using the hash of the package contents.

### Reference revisions

You can reference packages in the following formats:

| Reference | Description |
| --- | --- |
| `lib/1.0@conan/stable` | The latest RREV for `lib/1.0@conan/stable`. |
| `lib/1.0@conan/stable#RREV` | The specific RREV for `lib/1.0@conan/stable`. |
| `lib/1.0@conan/stable#RREV:PACKAGE_REFERENCE` | A binary package that belongs to the specific RREV. |
| `lib/1.0@conan/stable#RREV:PACKAGE_REFERENCE#PREV` | A binary package revision PREV that belongs to the specific RREV. |

### Upload revisions

To upload all revisions and their binaries to the GitLab package registry:

```shell
conan upload "hello/0.1@mycompany/beta#*" --remote=gitlab
```

When you upload multiple revisions, they are uploaded from oldest to newest. The relative order is preserved in the registry.

### List revisions

To list all revisions of a specific recipe in Conan 2:

```shell
conan list "hello/0.1@mycompany/beta#*" --remote=gitlab
```

This command displays all available revisions for the specified recipe along with their revision hashes and creation dates.

To get detailed information about a specific revision:

```shell
conan list "hello/0.1@mycompany/beta#revision_hash:*#*" --remote=gitlab
```

This command shows you the specific binary packages and the package revisions available for that revision.

### Delete packages with revisions

You can delete packages at different levels of granularity:

#### Delete a specific recipe revision

To delete a specific recipe revision and all its associated binary packages:

```shell
conan remove "hello/0.1@mycompany/beta#revision_hash" --remote=gitlab
```

#### Delete packages for a specific recipe revision

To delete all packages associated with a specific recipe revision:

```shell
conan remove "hello/0.1@mycompany/beta#revision_hash:*" --remote=gitlab
```

#### Delete a specific package in a revision

To delete a specific package in a recipe revision, you can use:

```shell
conan remove "package_name/version@user/channel#revision_hash:package_id" --remote=gitlab
```

### Immutable revisions workflow

Revisions are designed to be immutable. When you modify a recipe or its source code:

- A new recipe revision is created when you export a recipe.
- Any existing binaries that belong to the previous recipe revision are not included. You must build new binaries for the new recipe revision.
- When you install a package, Conan 2 automatically retrieves the latest revision unless you specify a revision.

For package binaries, you should include only one package revision per recipe revision and package reference (known as the `package_id` in Conan 2 documentation). Multiple package revisions for the same recipe revision and package ID indicate that a package was rebuilt unnecessarily.
