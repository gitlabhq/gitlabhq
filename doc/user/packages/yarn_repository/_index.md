---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Publish packages with Yarn
---

You can publish packages with [Yarn 1 (Classic)](https://classic.yarnpkg.com) and [Yarn 2+](https://yarnpkg.com).

To find the Yarn version used in the deployment container, run `yarn --version` in the `script` block of the CI
script job block that is responsible for calling `yarn publish`. The Yarn version is shown in the pipeline output.

Learn how to build a [Yarn](../workflows/build_packages.md#yarn) package.

You can use the Yarn documentation to get started with
[Yarn Classic](https://classic.yarnpkg.com/en/docs/getting-started) and
[Yarn 2+](https://yarnpkg.com/getting-started).

## Publish to GitLab package registry

You can use Yarn to publish to the GitLab package registry.

### Authentication to the package registry

You need a token to publish a package. Different tokens are available depending on what you're trying to
achieve. For more information, review the [guidance on tokens](../package_registry/_index.md#authenticate-with-the-registry).

- If your organization uses two-factor authentication (2FA), you must use a
  personal access token with the scope set to `api`.
- If you publish a package via CI/CD pipelines, you can use a CI job token in
  private runners or you can register a variable for instance runners.

### Publish configuration

To publish, set the following configuration in `.yarnrc.yml`. This file should be
located in the root directory of your package project source where `package.json` is found.

```yaml
npmScopes:
  <my-org>:
    npmPublishRegistry: 'https://<your_domain>/api/v4/projects/<your_project_id>/packages/npm/'
    npmAlwaysAuth: true
    npmAuthToken: '<your_token>'
```

In this configuration:

- Replace `<my-org>` with your organization scope, excluding the `@` symbol.
- Replace `<your_domain>` with your domain name.
- Replace `<your_project_id>` with your project's ID, which you can find on the [project overview page](../../project/working_with_projects.md#access-a-project-by-using-the-project-id).
- Replace `<your_token>` with a deployment token, group access token, project access token, or personal access token.

Scoped registry does not work in Yarn Classic in `package.json` file, based on
this [issue](https://github.com/yarnpkg/yarn/pull/7829).
Therefore, under `publishConfig` there should be `registry` and not `@scope:registry` for Yarn Classic.
You can publish using your command line or a CI/CD pipeline to the GitLab package registry.

### Publishing via the command line - Manual Publish

```shell
# Yarn 1 (Classic)
yarn publish

# Yarn 2+
yarn npm publish
```

Your package should now publish to the package registry.

### Publishing via a CI/CD pipeline - Automated Publish

You can use pipeline variables when you use this method.

You can use **instance runners** *(Default)* or **Private Runners** (Advanced).

#### Instance runners

To create an authentication token for your project or group:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. On the left sidebar, select **Settings > Repository > Deploy Tokens**.
1. Create a deployment token with `read_package_registry` and `write_package_registry` scopes and copy the generated token.
1. On the left sidebar, select **Settings > CI/CD > Variables**.
1. Select `Add variable` and use the following settings:

| Field              | Value                        |
|--------------------|------------------------------|
| key                | `NPM_AUTH_TOKEN`             |
| value              | `<DEPLOY-TOKEN-FROM-STEP-3>` |
| type               | Variable                     |
| Protected variable | `CHECKED`                    |
| Mask variable      | `CHECKED`                    |
| Expand variable    | `CHECKED`                    |

To use any **Protected variable**:

   1. Go to the repository that contains the Yarn package source code.
   1. On the left sidebar, select **Settings > Repository**.
      - If you are building from branches with tags, select **Protected Tags** and add `v*` (wildcard) for semantic versioning.
      - If you are building from branches without tags, select **Protected Branches**.

Then add the `NPM_AUTH_TOKEN` created above, to the `.yarnrc.yml` configuration
in your package project root directory where `package.json` is found:

```yaml
npmScopes:
  <my-org>:
    npmPublishRegistry: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/npm/"
    npmAlwaysAuth: true
    npmAuthToken: "${NPM_AUTH_TOKEN}"
```

In this configuration, replace `<my-org>` with your organization scope, excluding the `@` symbol.

#### Private runners

Add the `CI_JOB_TOKEN` to the `.yarnrc.yml` configuration in your package project
root directory where `package.json` is found:

```yaml
npmScopes:
  <my-org>:
    npmPublishRegistry: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/npm/"
    npmAlwaysAuth: true
    npmAuthToken: "${CI_JOB_TOKEN}"
```

In this configuration, replace `<my-org>` with your organization scope, excluding the `@` symbol.

To publish the package using CI/CD pipeline, In the GitLab project that houses
your `.yarnrc.yml`, edit or create a `.gitlab-ci.yml` file. For example to trigger
only on any tag push:

```yaml
# Yarn 1
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

```yaml
# Yarn 2+
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

Your package should now publish to the package registry when the pipeline runs.

## Install a package

NOTE:
If multiple packages have the same name and version, the most recently-published
package is retrieved when you install a package.

You can use one of two API endpoints to install packages:

- **Instance-level**: Best used when working with many packages in an organization scope.

- If you plan to install a package through the [instance level](#install-from-the-instance-level),
  then you must name your package with a [scope](https://docs.npmjs.com/misc/scope/).
  Scoped packages begin with a `@` and have the `@owner/package-name` format. You can set up
  the scope for your package in the `.yarnrc.yml` file and by using the `publishConfig`
  option in the `package.json`.

- The value used for the `@scope` is the organization root (top-level project) `...com/my-org`
  *(@my-org)* that hosts the packages, not the root of the project with the package's source code.
- The scope is always lowercase.
- The package name can be anything you want `@my-org/any-name`.

- **Project-level**: For when you have a one-off package.

If you plan to install a package through the [project level](#install-from-the-project-level),
you do not have to adhere to the naming convention.

| Project URL                                                       | Package registry     | Organization Scope | Full package name           |
|-------------------------------------------------------------------|----------------------|--------------------|-----------------------------|
| `https://gitlab.com/<my-org>/<group-name>/<package-name-example>` | Package Name Example | `@my-org`          | `@my-org/package-name`      |
| `https://gitlab.com/<example-org>/<group-name>/<project-name>`    | Project Name         | `@example-org`     | `@example-org/project-name` |

You can install from the instance level or from the project level.

The configurations for `.yarnrc.yml` can be added per package consuming project
root where `package.json` is located, or you can use a global
configuration located in your system user home directory.

### Install from the instance level

Use these steps for global configuration in the `.yarnrc.yml` file:

1. [Configure organization scope](#configure-organization-scope).
1. [Set the registry](#set-the-registry).

#### Configure organization scope

```yaml
npmScopes:
 <my-org>:
   npmRegistryServer: "https://<your_domain_name>/api/v4/packages/npm"
```

- Replace `<my-org>` with the root level group of the project you're installing to the package from excluding the `@` symbol.
- Replace `<your_domain_name>` with your domain name, for example, `gitlab.com`.

#### Set the registry

Skip this step if your package is public not private.

```yaml
  npmRegistries:
    //<your_domain_name>/api/v4/packages/npm:
      npmAlwaysAuth: true
      npmAuthToken: "<your_token>"
```

- Replace `<your_domain_name>` with your domain name, for example, `gitlab.com`.
- Replace `<your_token>` with a deployment token (recommended), group access token, project access token, or personal access token.

### Install from the project level

Use these steps for each project in the `.yarnrc.yml` file:

1. [Configure project scope](#configure-project-scope).
1. [Set the registry](#set-the-registry-project-level).

#### Configure project scope

  ```yaml
  npmScopes:
    <my-org>:
      npmRegistryServer: "https://<your_domain_name>/api/v4/projects/<your_project_id>/packages/npm"
```

- Replace `<my-org>` with the root level group of the project you're installing to the package from excluding the `@` symbol.
- Replace `<your_domain_name>` with your domain name, for example, `gitlab.com`.
- Replace `<your_project_id>` with your project ID, found on the [project overview page](../../project/working_with_projects.md#access-a-project-by-using-the-project-id).

#### Set the registry (project level)

Skip this step if your package is public not private.

```yaml
npmRegistries:
  //<your_domain_name>/api/v4/projects/<your_project_id>/packages/npm:
    npmAlwaysAuth: true
    npmAuthToken: "<your_token>"
```

- Replace `<your_domain_name>` with your domain name, for example, `gitlab.com`.
- Replace `<your_token>` with a deployment token (recommended), group access token, project access token, or personal access token.
- Replace `<your_project_id>` with your project ID, found on the [project overview page](../../project/working_with_projects.md#access-a-project-by-using-the-project-id).

### Install the package

For Yarn 2+, use `yarn add` either in the command line or in the CI/CD pipelines to install your packages:

```shell
yarn add @scope/my-package
```

#### For Yarn Classic

The Yarn Classic setup, requires both `.npmrc` and `.yarnrc` files as
[mentioned in issue](https://github.com/yarnpkg/yarn/issues/4451#issuecomment-753670295):

- Place credentials in the `.npmrc` file.
- Place the scoped registry in the `.yarnrc` file.

```shell
# .npmrc
//<your_domain_name>/api/v4/projects/<your_project_id>/packages/npm/:_authToken="<your_token>"

# .yarnrc
"@scope:registry" "https://<your_domain_name>/api/v4/projects/<your_project_id>/packages/npm/"
```

Then you can use `yarn add` to install your packages.

## Related topics

- [npm documentation](../npm_registry/_index.md#helpful-hints)
- [Yarn Migration Guide](https://yarnpkg.com/migration/guide)

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

In this case, the following commands creates a file called `.yarnrc` in the current directory. Make sure to be in either your user home directory for global configuration or your project root for per-project configuration:

```shell
yarn config set '//gitlab.example.com/api/v4/projects/<your_project_id>/packages/npm/:_authToken' "<your_token>"
yarn config set '//gitlab.example.com/api/v4/packages/npm/:_authToken' "<your_token>"
```

### `yarn install` fails to clone repository as a dependency

If you use `yarn install` from a Dockerfile, when you build the Dockerfile you might get an error like this:

```log
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
