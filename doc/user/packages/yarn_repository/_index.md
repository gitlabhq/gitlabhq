---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Publish packages with Yarn
---

You can publish and install packages with [Yarn 1 (Classic)](https://classic.yarnpkg.com) and [Yarn 2+](https://yarnpkg.com).

To find the Yarn version used in the deployment container, run `yarn --version` in the `script` block of the CI/CD
script job block that is responsible for calling `yarn publish`. The Yarn version is shown in the pipeline output.

## Authenticating to the package registry

You need a token to interact with the package registry. Different tokens are available depending on what you're trying to
achieve. For more information, review the [guidance on tokens](../package_registry/supported_functionality.md#authenticate-with-the-registry).

- If your organization uses two-factor authentication (2FA), you must use a
  [personal access token](../../profile/personal_access_tokens.md) with the scope set to `api`.
- If you publish a package with CI/CD pipelines, you can use a [CI/CD job token](../../../ci/jobs/ci_job_token.md) with
  private runners. You can also [register a variable](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token) for instance runners.

### Configure Yarn for publication

To configure Yarn to publish to the package registry, edit your `.yarnrc.yml` file.
You can find this file in root directory of your project, in the same place as the `package.json` file.

- Edit `.yarnrc.yml` and add the following configuration:

  ```yaml
  npmScopes:
    <my-org>:
      npmPublishRegistry: 'https://<domain>/api/v4/projects/<project_id>/packages/npm/'
      npmAlwaysAuth: true
      npmAuthToken: '<token>'
  ```

  In this configuration:

  - Replace `<my-org>` with your organization scope. Do not include the `@` symbol.
  - Replace `<domain>` with your domain name.
  - Replace `<project_id>` with your project's ID, which you can find on the [project overview page](../../project/working_with_projects.md#find-the-project-id).
  - Replace `<token>` with a deployment token, group access token, project access token, or personal access token.

In Yarn Classic, scoped registries with `publishConfig["@scope:registry"]` are not supported. See [Yarn pull request 7829](https://github.com/yarnpkg/yarn/pull/7829) for more information.
Instead, set `publishConfig` to `registry` in your `package.json` file.

## Publish a package

You can publish a package from the command line, or with GitLab CI/CD.

### With the command line

To publish a package manually:

- Run the following command:

  ```shell
  # Yarn 1 (Classic)
  yarn publish

  # Yarn 2+
  yarn npm publish
  ```

### With CI/CD

You can publish a package automatically with instance runners (default) or private runners (advanced).
You can use pipeline variables when you publish with CI/CD.

{{< tabs >}}

{{< tab title="Instance runners" >}}

1. Create an authentication token for your project or group:

   1. On the left sidebar, select **Search or go to** and find your project or group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
   1. On the left sidebar, select **Settings** > **Repository** > **Deploy Tokens**.
   1. Create a deployment token with `read_package_registry` and `write_package_registry` scopes and copy the generated token.
   1. On the left sidebar, select **Settings** > **CI/CD** > **Variables**.
   1. Select `Add variable` and use the following settings:

   | Field              | Value                        |
   |--------------------|------------------------------|
   | key                | `NPM_AUTH_TOKEN`             |
   | value              | `<DEPLOY-TOKEN>` |
   | type               | Variable                     |
   | Protected variable | `CHECKED`                    |
   | Mask variable      | `CHECKED`                    |
   | Expand variable    | `CHECKED`                    |

1. Optional. To use protected variables:

   1. Go to the repository that contains the Yarn package source code.
   1. On the left sidebar, select **Settings** > **Repository**.
      - If you are building from branches with tags, select **Protected Tags** and add `v*` (wildcard) for semantic versioning.
      - If you are building from branches without tags, select **Branch rules**.

1. Add the `NPM_AUTH_TOKEN` you created to the `.yarnrc.yml` configuration
in your package project root directory where `package.json` is found:

   ```yaml
   npmScopes:
     <my-org>:
       npmPublishRegistry: '${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/npm/'
       npmAlwaysAuth: true
       npmAuthToken: '${NPM_AUTH_TOKEN}'
   ```

   In this configuration, replace `<my-org>` with your organization scope, excluding the `@` symbol.

{{< /tab >}}

{{< tab title="Private runners" >}}

1. Add your `CI_JOB_TOKEN` to the `.yarnrc.yml` configuration in the root directory of your package project, where `package.json` is located:

   ```yaml
   npmScopes:
     <my-org>:
       npmPublishRegistry: '${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/npm/'
       npmAlwaysAuth: true
       npmAuthToken: '${CI_JOB_TOKEN}'
   ```

   In this configuration, replace `<my-org>` with your organization scope, excluding the `@` symbol.

1. In the GitLab project with your `.yarnrc.yml`, edit or create a `.gitlab-ci.yml` file.
For example, to trigger only on any tag push:

   In Yarn 1:

   ```yaml
   image: node:lts

   stages:
     - deploy

   rules:
   - if: $CI_COMMIT_TAG

   deploy:
     stage: deploy
     script:
       - yarn publish
   ```

   In Yarn 2 and higher:

   ```yaml
   image: node:lts

   stages:
     - deploy

   rules:
     - if: $CI_COMMIT_TAG

   deploy:
     stage: deploy
     before_script:
       - corepack enable
       - yarn set version stable
     script:
       - yarn npm publish
   ```

When the pipeline runs, your package is added to the package registry.

{{< /tab >}}

{{< /tabs >}}

## Install a package

You can install from an instance or project. If multiple packages have the same name and version,
only the most recently published package is retrieved when you install a package.

### Scoped package names

To install from an instance, a package must be named with a [scope](https://docs.npmjs.com/misc/scope/).
You can set up the scope for your package in the `.yarnrc.yml` file and with the `publishConfig` option in the `package.json`.
You don't need to follow package naming conventions if you install from a project or group.

A package scope begins with a `@` and follows the format `@owner/package-name`:

- The `@owner` is the top-level project that hosts the packages, not the root of the project with the package source code.
- The package name can be anything.

For example:

| Project URL                                                       | Package registry     | Organization scope | Full package name           |
|-------------------------------------------------------------------|----------------------|--------------------|-----------------------------|
| `https://gitlab.com/<my-org>/<group-name>/<package-name-example>` | Package Name Example | `@my-org`          | `@my-org/package-name`      |
| `https://gitlab.com/<example-org>/<group-name>/<project-name>`    | Project Name         | `@example-org`     | `@example-org/project-name` |

### Install from the instance

If you're working with many packages in the same organization scope, consider installing from the instance.

1. Configure your organization scope. In your `.yarnrc.yml` file, add the following:

   ```yaml
   npmScopes:
    <my-org>:
      npmRegistryServer: 'https://<domain_name>/api/v4/packages/npm'
   ```

   - Replace `<my-org>` with the root level group of the project you're installing to the package from excluding the `@` symbol.
   - Replace `<domain_name>` with your domain name, for example, `gitlab.com`.

1. Optional. If your package is private, you must configure access to the package registry:

   ```yaml
   npmRegistries:
     //<domain_name>/api/v4/packages/npm:
       npmAlwaysAuth: true
       npmAuthToken: '<token>'
   ```

   - Replace `<domain_name>` with your domain name, for example, `gitlab.com`.
   - Replace `<token>` with a deployment token (recommended), group access token, project access token, or personal access token.

1. [Install the package with Yarn](#install-with-yarn).

### Install from a group or project

If you have a one-off package, you can install it from a group or project.

{{< tabs >}}

{{< tab title="From a group" >}}

1. Configure the group scope. In your `.yarnrc.yml` file, add the following:

   ```yaml
   npmScopes:
     <my-org>:
       npmRegistryServer: 'https://<domain_name>/api/v4/groups/<group_id>/-/packages/npm'
   ```

   - Replace `<my-org>` with the top-level group that contains the group you want to install from. Exclude the `@` symbol.
   - Replace `<domain_name>` with your domain name, for example, `gitlab.com`.
   - Replace `<group_id>` with your group ID, found on the [group overview page](../../group/_index.md#find-the-group-id).

1. Optional. If your package is private, you must set the registry:

   ```yaml
   npmRegistries:
     //<domain_name>/api/v4/groups/<group_id>/-/packages/npm:
       npmAlwaysAuth: true
       npmAuthToken: "<token>"
   ```

   - Replace `<domain_name>` with your domain name, for example, `gitlab.com`.
   - Replace `<token>` with a deployment token (recommended), group access token, project access token, or personal access token.
   - Replace `<group_id>` with your group ID, found on the [group overview page](../../group/_index.md#find-the-group-id).

1. [Install the package with Yarn](#install-with-yarn).

{{< /tab >}}

{{< tab title="From a project" >}}

1. Configure the project scope. In your `.yarnrc.yml` file, add the following:

   ```yaml
   npmScopes:
    <my-org>:
      npmRegistryServer: "https://<domain_name>/api/v4/projects/<project_id>/packages/npm"
   ```

   - Replace `<my-org>` with the top-level group that contains the project you want to install from. Exclude the `@` symbol.
   - Replace `<domain_name>` with your domain name, for example, `gitlab.com`.
   - Replace `<project_id>` with your project ID, found on the [project overview page](../../project/working_with_projects.md#find-the-project-id).

1. Optional. If your package is private, you must set the registry:

   ```yaml
   npmRegistries:
     //<domain_name>/api/v4/projects/<project_id>/packages/npm:
       npmAlwaysAuth: true
       npmAuthToken: "<token>"
   ```

   - Replace `<domain_name>` with your domain name, for example, `gitlab.com`.
   - Replace `<token>` with a deployment token (recommended), group access token, project access token, or personal access token.
   - Replace `<project_id>` with your project ID, found on the [project overview page](../../project/working_with_projects.md#find-the-project-id).

1. [Install the package with Yarn](#install-with-yarn).

{{< /tab >}}

{{< /tabs >}}

### Install with Yarn

{{< tabs >}}

{{< tab title="Yarn 2 or later" >}}

- Run `yarn add` either from the command line, or from a CI/CD pipeline:

```shell
yarn add @scope/my-package
```

{{< /tab >}}

{{< tab title="Yarn Classic" >}}

Yarn Classic requires both a `.npmrc` and a `.yarnrc` file.
See [Yarn issue 4451](https://github.com/yarnpkg/yarn/issues/4451#issuecomment-753670295) for more information.

1. Place your credentials in the `.npmrc` file, and the scoped registry in the `.yarnrc` file:

   ```shell
   # .npmrc
   ## For the instance
   //<domain_name>/api/v4/packages/npm/:_authToken='<token>'
   ## For the group
   //<domain_name>/api/v4/groups/<group_id>/-/packages/npm/:_authToken='<token>'
   ## For the project
   //<domain_name>/api/v4/projects/<project_id>/packages/npm/:_authToken='<token>'

   # .yarnrc
   ## For the instance
   '@scope:registry' 'https://<domain_name>/api/v4/packages/npm/'
   ## For the group
   '@scope:registry' 'https://<domain_name>/api/v4/groups/<group_id>/-/packages/npm/'
   ## For the project
   '@scope:registry' 'https://<domain_name>/api/v4/projects/<project_id>/packages/npm/'
   ```

1. Run `yarn add` either from the command line, or from a CI/CD pipeline:

   ```shell
   yarn add @scope/my-package
   ```

{{< /tab >}}

{{< /tabs >}}

## Related topics

- [npm package registry documentation](../npm_registry/_index.md#helpful-hints)
- [Yarn Migration Guide](https://yarnpkg.com/migration/guide)
- [Build a Yarn package](../workflows/build_packages.md#yarn)

## Troubleshooting

### Error running Yarn with the package registry for the npm registry

If you are using [Yarn](https://classic.yarnpkg.com/en/) with the npm registry, you may get an error message like:

```shell
yarn install v1.15.2
warning package.json: No license field
info No lockfile found.
warning XXX: No license field
[1/4] 🔍  Resolving packages...
[2/4] 🚚  Fetching packages...
error An unexpected error occurred: "https://gitlab.example.com/api/v4/projects/XXX/packages/npm/XXX/XXX/-/XXX/XXX-X.X.X.tgz: Request failed \"404 Not Found\"".
info If you think this is a bug, please open a bug report with the information provided in "/Users/XXX/gitlab-migration/module-util/yarn-error.log".
info Visit https://classic.yarnpkg.com/en/docs/cli/install for documentation about this command
```

In this case, the following commands create a file called `.yarnrc` in the current directory. Make sure to be in either your user home directory for global configuration or your project root for per-project configuration:

```shell
yarn config set '//gitlab.example.com/api/v4/projects/<project_id>/packages/npm/:_authToken' '<token>'
yarn config set '//gitlab.example.com/api/v4/packages/npm/:_authToken' '<token>'
```

### `yarn install` fails to clone repository as a dependency

If you use `yarn install` from a Dockerfile, when you build the Dockerfile you might get an error like this:

```plaintext
...
#6 8.621 fatal: unable to access 'https://gitlab.com/path/to/project/': Problem with the SSL CA cert (path? access rights?)
#6 8.621 info Visit https://yarnpkg.com/en/docs/cli/install for documentation about this command.
#6 ...
```

To resolve this issue, [add an exclamation mark (`!`)](https://docs.docker.com/build/building/context/#negating-matches) to every Yarn-related path in your [.dockerignore](https://docs.docker.com/build/building/context/#dockerignore-files) file.

```dockerfile
**

!./package.json
!./yarn.lock
...
```
