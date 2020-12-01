---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# NPM packages in the Package Registry

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5934) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.7.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) to GitLab Core in 13.3.

Publish NPM packages in your project's Package Registry. Then install the
packages whenever you need to use them as a dependency.

Only [scoped](https://docs.npmjs.com/misc/scope) packages are supported.

## Build an NPM package

This section covers how to install NPM or Yarn and build a package for your
JavaScript project.

If you already use NPM and know how to build your own packages, go to
the [next section](#authenticate-to-the-package-registry).

### Install NPM

Install Node.js and NPM in your local development environment by following
the instructions at [npmjs.com](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm).

When installation is complete, verify you can use NPM in your terminal by
running:

```shell
npm --version
```

The NPM version is shown in the output:

```plaintext
6.10.3
```

### Install Yarn

As an alternative to NPM, you can install Yarn in your local environment by following the
instructions at [yarnpkg.com](https://classic.yarnpkg.com/en/docs/install).

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

## Use the GitLab endpoint for NPM packages

To use the GitLab endpoint for NPM packages, choose an option:

- **Project-level**: Use when you have few NPM packages and they are not in
  the same GitLab group.
- **Instance-level**: Use when you have many NPM packages in different
  GitLab groups or in their own namespace. Be sure to comply with the [package naming convention](#package-naming-convention).

Some features such as [publishing](#publish-an-npm-package) a package is only available on the project-level endpoint.

## Authenticate to the Package Registry

To authenticate to the Package Registry, you must use one of the following:

- A [personal access token](../../../user/profile/personal_access_tokens.md)
  (required for two-factor authentication (2FA)), with the scope set to `api`.
- A [deploy token](../../project/deploy_tokens/index.md), with the scope set to `read_package_registry`, `write_package_registry`, or both.
- It's not recommended, but you can use [OAuth tokens](../../../api/oauth2.md#resource-owner-password-credentials-flow).
  Standard OAuth tokens cannot authenticate to the GitLab NPM Registry. You must use a personal access token with OAuth headers.
- A [CI job token](#authenticate-with-a-ci-job-token).

### Authenticate with a personal access token or deploy token

To authenticate with the Package Registry, you need a [personal access token](../../profile/personal_access_tokens.md) or [deploy token](../../project/deploy_tokens/index.md).

#### Project-level NPM endpoint

To use the [project-level](#use-the-gitlab-endpoint-for-npm-packages) NPM endpoint, set your NPM configuration:

```shell
# Set URL for your scoped packages.
# For example package with name `@foo/bar` will use this URL for download
npm config set @foo:registry https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/npm/

# Add the token for the scoped packages URL. Replace <your_project_id>
# with the project where your package is located.
npm config set '//gitlab.example.com/api/v4/projects/<your_project_id>/packages/npm/:_authToken' "<your_token>"
```

- `<your_project_id>` is your project ID, found on the project's home page.
- `<your_token>` is your personal access token or deploy token.
- Replace `gitlab.example.com` with your domain name.

You should now be able to publish and install NPM packages in your project.

If you encounter an error with [Yarn](https://classic.yarnpkg.com/en/), view
[troubleshooting steps](#troubleshooting).

#### Instance-level NPM endpoint

To use the [instance-level](#use-the-gitlab-endpoint-for-npm-packages) NPM endpoint, set your NPM configuration:

```shell
# Set URL for your scoped packages.
# For example package with name `@foo/bar` will use this URL for download
npm config set @foo:registry https://gitlab.example.com/api/v4/packages/npm/

# Add the token for the scoped packages URL. This will allow you to download
# `@foo/` packages from private projects.
npm config set '//gitlab.example.com/api/v4/packages/npm/:_authToken' "<your_token>"
```

- `<your_token>` is your personal access token or deploy token.
- Replace `gitlab.example.com` with your domain name.

You should now be able to publish and install NPM packages in your project.

If you encounter an error with [Yarn](https://classic.yarnpkg.com/en/), view
[troubleshooting steps](#troubleshooting).

### Authenticate with a CI job token

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/9104) in GitLab Premium 12.5.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) to GitLab Core in 13.3.

If you're using NPM with GitLab CI/CD, a CI job token can be used instead of a personal access token or deploy token.
The token inherits the permissions of the user that generates the pipeline.

#### Project-level NPM endpoint

To use the [project-level](#use-the-gitlab-endpoint-for-npm-packages) NPM endpoint, add a corresponding section to your `.npmrc` file:

```ini
@foo:registry=https://gitlab.example.com/api/v4/projects/${CI_PROJECT_ID}/packages/npm/
//gitlab.example.com/api/v4/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=${CI_JOB_TOKEN}
```

#### Instance-level NPM endpoint

To use the [instance-level](#use-the-gitlab-endpoint-for-npm-packages) NPM endpoint, add a corresponding section to your `.npmrc` file:

```ini
@foo:registry=https://gitlab.example.com/api/v4/packages/npm/
//gitlab.example.com/api/v4/packages/npm/:_authToken=${CI_JOB_TOKEN}
```

#### Use variables to avoid hard-coding auth token values

To avoid hard-coding the `authToken` value, you may use a variable in its place:

```shell
npm config set '//gitlab.example.com/api/v4/projects/<your_project_id>/packages/npm/:_authToken' "${NPM_TOKEN}"
npm config set '//gitlab.example.com/api/v4/packages/npm/:_authToken' "${NPM_TOKEN}"
```

Then, you can run `npm publish` either locally or by using GitLab CI/CD.

- **Locally:** Export `NPM_TOKEN` before publishing:

  ```shell
  NPM_TOKEN=<your_token> npm publish
  ```

- **GitLab CI/CD:** Set an `NPM_TOKEN` [variable](../../../ci/variables/README.md)
  under your project's **Settings > CI/CD > Variables**.

## Package naming convention

Your NPM package name must be in the format of `@scope:package-name`.

- The `@scope` is the root namespace of the GitLab project. It must match exactly, including the case.
- The `package-name` can be whatever you want.

For example, if your project is `https://gitlab.example.com/my-org/engineering-group/team-amazing/analytics`,
the root namespace is `my-org`. When you publish a package, it must have `my-org` as the scope.

| Project                | Package                 | Supported |
| ---------------------- | ----------------------- | --------- |
| `my-org/bar`           | `@my-org/bar`           | Yes       |
| `my-org/bar/baz`       | `@my-org/baz`           | Yes       |
| `My-org/Bar/baz`       | `@My-org/Baz`           | Yes       |
| `my-org/bar/buz`       | `@my-org/anything`      | Yes       |
| `gitlab-org/gitlab`    | `@gitlab-org/gitlab`    | Yes       |
| `gitlab-org/gitlab`    | `@foo/bar`              | No        |

In GitLab, this regex validates all package names from all package managers:

```plaintext
/\A\@?(([\w\-\.\+]*)\/)*([\w\-\.]+)@?(([\w\-\.\+]*)\/)*([\w\-\.]*)\z/
```

This regex allows almost all of the characters that NPM allows, with a few exceptions (for example, `~` is not allowed).

The regex also allows for capital letters, while NPM does not. Capital letters are needed because the scope must be
identical to the root namespace of the project.

CAUTION: **Caution:**
When you update the path of a user or group, or transfer a subgroup or project,
you must remove any NPM packages first. You cannot update the root namespace
of a project with NPM packages. Make sure you update your `.npmrc` files to follow
the naming convention and run `npm publish` if necessary.

## Publish an NPM package

Prerequisites:

- [Authenticate](#authenticate-to-the-package-registry) to the Package Registry.
- Set a [project-level NPM endpoint](#use-the-gitlab-endpoint-for-npm-packages).

To upload an NPM package to your project, run this command:

```shell
npm publish
```

To view the package, go to your project's **Packages & Registries**.

If you try to publish a package [with a name that already exists](#publishing-packages-with-the-same-name-or-version) within
a given scope, you get a `403 Forbidden!` error.

## Publish an NPM package by using CI/CD

Prerequisites:

- [Authenticate](#authenticate-to-the-package-registry) to the Package Registry.
- Set a [project-level NPM endpoint](#use-the-gitlab-endpoint-for-npm-packages).

To work with NPM commands within [GitLab CI/CD](../../../ci/README.md), you can use
`CI_JOB_TOKEN` in place of the personal access token or deploy token in your commands.

An example `.gitlab-ci.yml` file for publishing NPM packages:

```yaml
image: node:latest

stages:
  - deploy

deploy:
  stage: deploy
  script:
    - echo "//gitlab.example.com/api/v4/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=${CI_JOB_TOKEN}">.npmrc
    - npm publish
```

See the
[Publish NPM packages to the GitLab Package Registry using semantic-release](../../../ci/examples/semantic-release.md)
step-by-step guide and demo project for a complete example.

## Publishing packages with the same name or version

You cannot publish a package if a package of the same name and version already exists.
You must delete the existing package first.

This aligns with npmjs.org's behavior. However, npmjs.org does not ever let you publish
the same version more than once, even if it has been deleted.

## Install a package

NPM packages are commonly-installed by using the `npm` or `yarn` commands
in a JavaScript project.

1. Set the URL for scoped packages by running:

   ```shell
   npm config set @foo:registry https://gitlab.example.com/api/v4/packages/npm/
   ```

   Replace `@foo` with your scope.

1. Ensure [authentication](#authenticate-to-the-package-registry) is configured.

1. In your project, to install a package, run:

   ```shell
   npm install @my-project-scope/my-package
   ```

   Or if you're using Yarn:

   ```shell
   yarn add @my-project-scope/my-package
   ```

In [GitLab 12.9 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/55344),
when an NPM package is not found in the Package Registry, the request is forwarded to [npmjs.com](https://www.npmjs.com/).

Administrators can disable this behavior in the [Continuous Integration settings](../../admin_area/settings/continuous_integration.md).

### Install NPM packages from other organizations

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

### NPM dependencies metadata

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/11867) in GitLab Premium 12.6.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) to GitLab Core in 13.3.

In GitLab 12.6 and later, packages published to the Package Registry expose the following attributes to the NPM client:

- name
- version
- dist-tags
- dependencies
  - dependencies
  - devDependencies
  - bundleDependencies
  - peerDependencies
  - deprecated

## Add NPM distribution tags

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/9425) in GitLab Premium 12.8.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) to GitLab Core in 13.3.

You can add [distribution tags](https://docs.npmjs.com/cli/dist-tag) to newly-published packages.
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

Due to a bug in NPM 6.9.0, deleting distribution tags fails. Make sure your NPM version is 6.9.1 or later.

## Troubleshooting

### Error running Yarn with NPM registry

If you are using [Yarn](https://classic.yarnpkg.com/en/) with the NPM registry, you may get
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

### `npm publish` targets default NPM registry (`registry.npmjs.org`)

Ensure that your package scope is set consistently in your `package.json` and `.npmrc` files.

For example, if your project name in GitLab is `foo/my-package`, then your `package.json` file
should look like:

```json
{
  "name": "@foo/my-package",
  "version": "1.0.0",
  "description": "Example package for GitLab NPM registry",
}
```

And the `.npmrc` file should look like:

```ini
//gitlab.example.com/api/v4/projects/<your_project_id>/packages/npm/:_authToken=<your_token>
//gitlab.example.com/api/v4/packages/npm/:_authToken=<your_token>
@foo:registry=https://gitlab.example.com/api/v4/packages/npm/
```

### `npm install` returns `Error: Failed to replace env in config: ${NPM_TOKEN}`

You do not need a token to run `npm install` unless your project is private. The token is only required to publish. If the `.npmrc` file was checked in with a reference to `$NPM_TOKEN`, you can remove it. If you prefer to leave the reference in, you must set a value prior to running `npm install` or set the value by using [GitLab environment variables](../../../ci/variables/README.md):

```shell
NPM_TOKEN=<your_token> npm install
```

### `npm install` returns `npm ERR! 403 Forbidden`

If you get this error, ensure that:

- Your token is not expired and has appropriate permissions.
- [Your token does not begin with `-`](https://gitlab.com/gitlab-org/gitlab/-/issues/235473).
- A package with the same name doesn't already exist within the given scope.
- The scoped packages URL includes a trailing slash:
  - Correct: `//gitlab.example.com/api/v4/packages/npm/`
  - Incorrect: `//gitlab.example.com/api/v4/packages/npm`
