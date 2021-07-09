---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# npm packages in the Package Registry **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5934) in GitLab Premium 11.7.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) to GitLab Free in 13.3.

Publish npm packages in your project's Package Registry. Then install the
packages whenever you need to use them as a dependency.

Only [scoped](https://docs.npmjs.com/misc/scope/) packages are supported.

For documentation of the specific API endpoints that the npm package manager
client uses, see the [npm API documentation](../../../api/packages/npm.md).

## Build an npm package

This section covers how to install npm or Yarn and build a package for your
JavaScript project.

If you already use npm and know how to build your own packages, go to
the [next section](#authenticate-to-the-package-registry).

### Install npm

Install Node.js and npm in your local development environment by following
the instructions at [npmjs.com](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm/).

When installation is complete, verify you can use npm in your terminal by
running:

```shell
npm --version
```

The npm version is shown in the output:

```plaintext
6.10.3
```

### Install Yarn

As an alternative to npm, you can install Yarn in your local environment by following the
instructions at [classic.yarnpkg.com](https://classic.yarnpkg.com/en/docs/install).

When installation is complete, verify you can use Yarn in your terminal by
running:

```shell
yarn --version
```

The Yarn version is shown in the output:

```plaintext
1.19.1
```

### Create a project

To create a project:

1. Create an empty directory.
1. Go to the directory and initialize an empty package by running:

   ```shell
   npm init
   ```

   Or if you're using Yarn:

   ```shell
   yarn init
   ```

1. Enter responses to the questions. Ensure the **package name** follows
   the [naming convention](#package-naming-convention) and is scoped to the
   project or group where the registry exists.

A `package.json` file is created.

## Use the GitLab endpoint for npm packages

To use the GitLab endpoint for npm packages, choose an option:

- **Project-level**: Use when you have few npm packages and they are not in
  the same GitLab group. The [package naming convention](#package-naming-convention) is not enforced at this level.
  Instead, you should use a [scope](https://docs.npmjs.com/cli/v6/using-npm/scope/) for your package.
  When you use a scope, the registry URL is [updated](#authenticate-to-the-package-registry) only for that scope.
- **Instance-level**: Use when you have many npm packages in different
  GitLab groups or in their own namespace. Be sure to comply with the [package naming convention](#package-naming-convention).

Some features such as [publishing](#publish-an-npm-package) a package is only available on the project-level endpoint.

## Authenticate to the Package Registry

You must authenticate with the Package Registry when the project
is private. Public projects do not require authentication.

To authenticate, use one of the following:

- A [personal access token](../../../user/profile/personal_access_tokens.md)
  (required for two-factor authentication (2FA)), with the scope set to `api`.
- A [deploy token](../../project/deploy_tokens/index.md), with the scope set to `read_package_registry`, `write_package_registry`, or both.
- It's not recommended, but you can use [OAuth tokens](../../../api/oauth2.md#resource-owner-password-credentials-flow).
  Standard OAuth tokens cannot authenticate to the GitLab npm Registry. You must use a personal access token with OAuth headers.
- A [CI job token](#authenticate-with-a-ci-job-token).
- Your npm package name must be in the format of [`@scope/package-name`](#package-naming-convention).
  It must match exactly, including the case.

### Authenticate with a personal access token or deploy token

To authenticate with the Package Registry, you need a [personal access token](../../profile/personal_access_tokens.md) or [deploy token](../../project/deploy_tokens/index.md).

#### Project-level npm endpoint

To use the [project-level](#use-the-gitlab-endpoint-for-npm-packages) npm endpoint, set your npm configuration:

```shell
# Set URL for your scoped packages.
# For example package with name `@foo/bar` will use this URL for download
npm config set @foo:registry https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/npm/

# Add the token for the scoped packages URL. Replace <your_project_id>
# with the project where your package is located.
npm config set -- '//gitlab.example.com/api/v4/projects/<your_project_id>/packages/npm/:_authToken' "<your_token>"
```

- `<your_project_id>` is your project ID, found on the project's home page.
- `<your_token>` is your personal access token or deploy token.
- Replace `gitlab.example.com` with your domain name.

You should now be able to publish and install npm packages in your project.

If you encounter an error with [Yarn](https://classic.yarnpkg.com/en/), view
[troubleshooting steps](#troubleshooting).

#### Instance-level npm endpoint

To use the [instance-level](#use-the-gitlab-endpoint-for-npm-packages) npm endpoint, set your npm configuration:

```shell
# Set URL for your scoped packages.
# For example package with name `@foo/bar` will use this URL for download
npm config set @foo:registry https://gitlab.example.com/api/v4/packages/npm/

# Add the token for the scoped packages URL. This will allow you to download
# `@foo/` packages from private projects.
npm config set -- '//gitlab.example.com/api/v4/packages/npm/:_authToken' "<your_token>"
```

- `<your_token>` is your personal access token or deploy token.
- Replace `gitlab.example.com` with your domain name.

You should now be able to install npm packages in your project.

If you encounter an error with [Yarn](https://classic.yarnpkg.com/en/), view
[troubleshooting steps](#troubleshooting).

### Authenticate with a CI job token

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/9104) in GitLab Premium 12.5.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) to GitLab Free in 13.3.

If you're using npm with GitLab CI/CD, a CI job token can be used instead of a personal access token or deploy token.
The token inherits the permissions of the user that generates the pipeline.

#### Project-level npm endpoint

To use the [project-level](#use-the-gitlab-endpoint-for-npm-packages) npm endpoint, add a corresponding section to your `.npmrc` file:

```ini
@foo:registry=https://gitlab.example.com/api/v4/projects/${CI_PROJECT_ID}/packages/npm/
//gitlab.example.com/api/v4/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=${CI_JOB_TOKEN}
```

#### Instance-level npm endpoint

To use the [instance-level](#use-the-gitlab-endpoint-for-npm-packages) npm endpoint, add a corresponding section to your `.npmrc` file:

```ini
@foo:registry=https://gitlab.example.com/api/v4/packages/npm/
//gitlab.example.com/api/v4/packages/npm/:_authToken=${CI_JOB_TOKEN}
```

#### Use variables to avoid hard-coding auth token values

To avoid hard-coding the `authToken` value, you may use a variable in its place:

```shell
npm config set -- '//gitlab.example.com/api/v4/projects/<your_project_id>/packages/npm/:_authToken' "${NPM_TOKEN}"
npm config set -- '//gitlab.example.com/api/v4/packages/npm/:_authToken' "${NPM_TOKEN}"
```

Then, you can run `npm publish` either locally or by using GitLab CI/CD.

- **Locally:** Export `NPM_TOKEN` before publishing:

  ```shell
  NPM_TOKEN=<your_token> npm publish
  ```

- **GitLab CI/CD:** Set an `NPM_TOKEN` [CI/CD variable](../../../ci/variables/index.md)
  under your project's **Settings > CI/CD > Variables**.

## Package naming convention

When you use the [instance-level endpoint](#use-the-gitlab-endpoint-for-npm-packages), only the packages with names in the format of `@scope/package-name` are available.

- The `@scope` is the root namespace of the GitLab project. To follow npm's convention, it should be
  lowercase. However, the GitLab package registry allows for uppercase. Before GitLab 13.10, the
  `@scope` had to be a case-sensitive match of the GitLab project's root namespace. This was
  problematic because the npm public registry does not allow uppercase letters. GitLab 13.10 relaxes
  this requirement and translates uppercase in the GitLab `@scope` to lowercase for npm. For
  example, a package `@MyScope/package-name` in GitLab becomes `@myscope/package-name` for npm.
- The `package-name` can be whatever you want.

For example, if your project is `https://gitlab.example.com/my-org/engineering-group/team-amazing/analytics`,
the root namespace is `my-org`. When you publish a package, it must have `my-org` as the scope.

| Project                | Package                 | Supported |
| ---------------------- | ----------------------- | --------- |
| `my-org/bar`           | `@my-org/bar`           | Yes       |
| `my-org/bar/baz`       | `@my-org/baz`           | Yes       |
| `My-Org/Bar/baz`       | `@my-org/Baz`           | Yes       |
| `My-Org/Bar/baz`       | `@My-Org/Baz`           | Yes       |
| `my-org/bar/buz`       | `@my-org/anything`      | Yes       |
| `gitlab-org/gitlab`    | `@gitlab-org/gitlab`    | Yes       |
| `gitlab-org/gitlab`    | `@foo/bar`              | No        |

In GitLab, this regex validates all package names from all package managers:

```plaintext
/\A\@?(([\w\-\.\+]*)\/)*([\w\-\.]+)@?(([\w\-\.\+]*)\/)*([\w\-\.]*)\z/
```

This regex allows almost all of the characters that npm allows, with a few exceptions (for example, `~` is not allowed).

The regex also allows for capital letters, while npm does not.

WARNING:
When you update the path of a user or group, or transfer a subgroup or project,
you must remove any npm packages first. You cannot update the root namespace
of a project with npm packages. Make sure you update your `.npmrc` files to follow
the naming convention and run `npm publish` if necessary.

## Publish an npm package

Prerequisites:

- [Authenticate](#authenticate-to-the-package-registry) to the Package Registry.
- Set a [project-level npm endpoint](#use-the-gitlab-endpoint-for-npm-packages).

To upload an npm package to your project, run this command:

```shell
npm publish
```

To view the package, go to your project's **Packages & Registries**.

You can also define `"publishConfig"` for your project in `package.json`. For example:

```json
{
"publishConfig": { "@foo:registry":" https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/npm/" }
}
```

This forces the package to publish only to the specified registry.

If you try to publish a package [with a name that already exists](#publishing-packages-with-the-same-name-or-version) within
a given scope, you get a `403 Forbidden!` error.

## Publish an npm package by using CI/CD

Prerequisites:

- [Authenticate](#authenticate-to-the-package-registry) to the Package Registry.
- Set a [project-level npm endpoint](#use-the-gitlab-endpoint-for-npm-packages).
- Your npm package name must be in the format of [`@scope/package-name`](#package-naming-convention).
  It must match exactly, including the case. This is different than the
  npm naming convention, but it is required to work with the GitLab Package Registry.

To work with npm commands within [GitLab CI/CD](../../../ci/index.md), you can use
`CI_JOB_TOKEN` in place of the personal access token or deploy token in your commands.

An example `.gitlab-ci.yml` file for publishing npm packages:

```yaml
image: node:latest

stages:
  - deploy

deploy:
  stage: deploy
  script:
    - echo "//${CI_SERVER_HOST}/api/v4/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=${CI_JOB_TOKEN}">.npmrc
    - npm publish
```

See the
[Publish npm packages to the GitLab Package Registry using semantic-release](../../../ci/examples/semantic-release.md)
step-by-step guide and demo project for a complete example.

## Configure the GitLab npm registry with Yarn 2

You can get started with Yarn 2 by following the [Yarn documentation](https://yarnpkg.com/getting-started/install/).

To publish and install with the project-level npm endpoint, set the following configuration in
`.yarnrc.yml`:

```yaml
npmScopes:
  foo:
    npmRegistryServer: "https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/npm/"
    npmPublishRegistry: "https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/npm/"

npmRegistries:
  //gitlab.example.com/api/v4/projects/<your_project_id>/packages/npm/:
    npmAlwaysAuth: true
    npmAuthToken: "<your_token>"
```

For the instance-level npm endpoint, use this Yarn 2 configuration in `.yarnrc.yml`:

```yaml
npmScopes:
  foo:
    npmRegistryServer: "https://gitlab.example.com/api/v4/packages/npm/"

npmRegistries:
  //gitlab.example.com/api/v4/packages/npm/:
    npmAlwaysAuth: true
    npmAuthToken: "<your_token>"
```

In this configuration:

- Replace `<your_token>` with your personal access token or deploy token.
- Replace `<your_project_id>` with your project's ID, which you can find on the project's home page.
- Replace `gitlab.example.com` with your domain name.
- Your scope is `foo`, without `@`.

## Publishing packages with the same name or version

You cannot publish a package if a package of the same name and version already exists.
You must delete the existing package first.

This aligns with npmjs.org's behavior. However, npmjs.org does not ever let you publish
the same version more than once, even if it has been deleted.

## Install a package

npm packages are commonly-installed by using the `npm` or `yarn` commands
in a JavaScript project. You can install a package from the scope of a project or instance.

If multiple packages have the same name and version, when you install a package, the most recently-published package is retrieved.

1. Set the URL for scoped packages by running:

   ```shell
   npm config set @foo:registry https://gitlab.example.com/api/v4/packages/npm/
   ```

   Replace `@foo` with your scope.

1. Ensure [authentication](#authenticate-to-the-package-registry) is configured.

1. To install a package in your project, run:

   ```shell
   npm install @my-scope/my-package
   ```

   Or if you're using Yarn:

   ```shell
   yarn add @my-scope/my-package
   ```

In [GitLab 12.9 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/55344),
when an npm package is not found in the Package Registry, the request is forwarded to [npmjs.com](https://www.npmjs.com/).

Administrators can disable this behavior in the [Continuous Integration settings](../../admin_area/settings/continuous_integration.md).

### Install npm packages from other organizations

You can route package requests to organizations and users outside of GitLab.

To do this, add lines to your `.npmrc` file. Replace `my-org` with the namespace or group that owns your project's repository,
and use your organization's URL. The name is case-sensitive and must match the name of your group or namespace exactly.

```shell
@foo:registry=https://gitlab.example.com/api/v4/packages/npm/
//gitlab.example.com/api/v4/packages/npm/:_authToken= "<your_token>"
//gitlab.example.com/api/v4/projects/<your_project_id>/packages/npm/:_authToken= "<your_token>"

@my-other-org:registry=https://gitlab.example.com/api/v4/packages/npm/
//gitlab.example.com/api/v4/packages/npm/:_authToken= "<your_token>"
//gitlab.example.com/api/v4/projects/<your_project_id>/packages/npm/:_authToken= "<your_token>"
```

### npm dependencies metadata

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/11867) in GitLab Premium 12.6.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) to GitLab Free in 13.3.

In GitLab 12.6 and later, packages published to the Package Registry expose the following attributes to the npm client:

- name
- version
- dist-tags
- dependencies
  - dependencies
  - devDependencies
  - bundleDependencies
  - peerDependencies
  - deprecated

## Add npm distribution tags

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/9425) in GitLab Premium 12.8.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) to GitLab Free in 13.3.

You can add [distribution tags](https://docs.npmjs.com/cli/dist-tag/) to newly-published packages.
Tags are optional and can be assigned to only one package at a time.

When you publish a package without a tag, the `latest` tag is added by default.
When you install a package without specifying the tag or version, the `latest` tag is used.

Examples of the supported `dist-tag` commands:

```shell
npm publish @scope/package --tag               # Publish a package with new tag
npm dist-tag add @scope/package@version my-tag # Add a tag to an existing package
npm dist-tag ls @scope/package                 # List all tags under the package
npm dist-tag rm @scope/package@version my-tag  # Delete a tag from the package
npm install @scope/package@my-tag              # Install a specific tag
```

You cannot use your `CI_JOB_TOKEN` or deploy token with the `npm dist-tag` commands.
View [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/258835) for details.

Due to a bug in npm 6.9.0, deleting distribution tags fails. Make sure your npm version is 6.9.1 or later.

## Troubleshooting

When troubleshooting npm issues, first run the same command with the `--verbose` flag to confirm
what registry you are hitting.

To improve performance, npm caches files related to a package. Note that npm doesn't remove data by
itself. The cache grows as new packages are installed. If you encounter issues, clear the cache with
this command:

```shell
npm cache clean --force
```

### Error running Yarn with the Package Registry for npm registry

If you are using [Yarn](https://classic.yarnpkg.com/en/) with the npm registry, you may get
an error message like:

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

In this case, try adding this to your `.npmrc` file (and replace `<your_token>`
with your personal access token or deploy token):

```plaintext
//gitlab.example.com/api/v4/projects/:_authToken=<your_token>
```

You can also use `yarn config` instead of `npm config` when setting your auth-token dynamically:

```shell
yarn config set '//gitlab.example.com/api/v4/projects/<your_project_id>/packages/npm/:_authToken' "<your_token>"
yarn config set '//gitlab.example.com/api/v4/packages/npm/:_authToken' "<your_token>"
```

### `npm publish` targets default npm registry (`registry.npmjs.org`)

Ensure that your package scope is set consistently in your `package.json` and `.npmrc` files.

For example, if your project name in GitLab is `foo/my-package`, then your `package.json` file
should look like:

```json
{
  "name": "@foo/my-package",
  "version": "1.0.0",
  "description": "Example package for GitLab npm registry",
}
```

And the `.npmrc` file should look like:

```ini
//gitlab.example.com/api/v4/projects/<your_project_id>/packages/npm/:_authToken=<your_token>
//gitlab.example.com/api/v4/packages/npm/:_authToken=<your_token>
@foo:registry=https://gitlab.example.com/api/v4/packages/npm/
```

### `npm install` returns `Error: Failed to replace env in config: ${npm_TOKEN}`

You do not need a token to run `npm install` unless your project is private. The token is only required to publish. If the `.npmrc` file was checked in with a reference to `$npm_TOKEN`, you can remove it. If you prefer to leave the reference in, you must set a value prior to running `npm install` or set the value by using [GitLab CI/CD variables](../../../ci/variables/index.md):

```shell
NPM_TOKEN=<your_token> npm install
```

### `npm install` returns `npm ERR! 403 Forbidden`

If you get this error, ensure that:

- Your token is not expired and has appropriate permissions.
- A package with the same name or version doesn't already exist within the given scope.
- Your NPM package name does not contain a dot `.`. This is a [known issue](https://gitlab.com/gitlab-org/gitlab-ee/issues/10248)
  in GitLab 11.9 and earlier.
- The scoped packages URL includes a trailing slash:
  - Correct: `//gitlab.example.com/api/v4/packages/npm/`
  - Incorrect: `//gitlab.example.com/api/v4/packages/npm`

### `npm publish` returns `npm ERR! 400 Bad Request`

If you get this error, one of the following problems could be causing it.

#### Package name does not meet the naming convention

Your package name may not meet the
[`@scope/package-name` package naming convention](#package-naming-convention).

Ensure the name meets the convention exactly, including the case.
Then try to publish again.

#### Package already exists

Your package has already been published to another project in the same
root namespace and therefore cannot be published again using the same name.

This is also true even if the prior published package shares the same name,
but not the version.

### `npm publish` returns `npm ERR! 500 Internal Server Error - PUT`

This is a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/238950) in GitLab
13.3.x and later. The error in the logs will appear as:

```plaintext
>NoMethodError - undefined method `preferred_language' for #<Rack::Response
```

This might be accompanied by another error:

```plaintext
>Errno::EACCES","exception.message":"Permission denied
```

This is usually a permissions issue with either:

- `'packages_storage_path'` default `/var/opt/gitlab/gitlab-rails/shared/packages/`.
- The remote bucket if [object storage](../../../administration/packages/#using-object-storage)
  is used.

In the latter case, ensure the bucket exists and GitLab has write access to it.

## Supported CLI commands

The GitLab npm repository supports the following commands for the npm CLI (`npm`) and yarn CLI
(`yarn`):

- `npm install`: Install npm packages.
- `npm publish`: Publish an npm package to the registry.
- `npm dist-tag add`: Add a dist-tag to an npm package.
- `npm dist-tag ls`: List dist-tags for a package.
- `npm dist-tag rm`: Delete a dist-tag.
- `npm ci`: Install npm packages directly from your `package-lock.json` file.
- `npm view`: Show package metadata.
- `yarn add`: Install an npm package.
- `yarn update`: Update your dependencies.
