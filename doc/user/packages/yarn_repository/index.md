---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Publish packages with Yarn

Publish npm packages in your project's Package Registry using Yarn. Then install the
packages whenever you need to use them as a dependency.

Learn how to build a [yarn](../workflows/build_packages.md#yarn) package.

You can get started with Yarn 2 by following the [Yarn documentation](https://yarnpkg.com/getting-started/install/).

## Publish to GitLab Package Registry

### Authentication to the Package Registry

You need a token to publish a package. Different tokens are available depending on what you're trying to
achieve. For more information, review the [guidance on tokens](../../../user/packages/package_registry/index.md#authenticate-with-the-registry).

- If your organization uses two-factor authentication (2FA), you must use a personal access token with the scope set to `api`.
- If you publish a package via CI/CD pipelines, you must use a CI job token.

Create a token and save it to use later in the process.

### Naming convention

Depending on how you install the package, you may need to adhere to the naming convention.

You can use one of two API endpoints to install packages:

- **Instance-level**: Use when you have many npm packages in different GitLab groups or in their own namespace.
- **Project-level**: Use when you have a few npm packages, and they are not in the same GitLab group.

If you plan to install a package through the [project level](#install-from-the-project-level), you do not have to
adhere to the naming convention.

If you plan to install a package through the [instance level](#install-from-the-instance-level), then you must name
your package with a [scope](https://docs.npmjs.com/misc/scope/). Scoped packages begin with a `@` and have the
`@owner/package-name` format. You can set up the scope for your package in the `.yarnrc.yml` file and by using the
`publishConfig` option in the `package.json`.

- The value used for the `@scope` is the root of the project that hosts the packages and not the root
  of the project with the package's source code. The scope should be lowercase.
- The package name can be anything you want

| Project URL                                             | Package Registry in | Scope     | Full package name      |
| ------------------------------------------------------- | ------------------- | --------- | ---------------------- |
| `https://gitlab.com/my-org/engineering-group/analytics` | Analytics           | `@my-org` | `@my-org/package-name` |

### Configuring `.yarnrc.yml` to publish from the project level

To publish with the project-level npm endpoint, set the following configuration in
`.yarnrc.yml`:

```yaml
npmScopes:
  foo:
    npmRegistryServer: 'https://<your_domain>/api/v4/projects/<your_project_id>/packages/npm/'
    npmPublishRegistry: 'https://<your_domain>/api/v4/projects/<your_project_id>/packages/npm/'

npmRegistries:
  //gitlab.example.com/api/v4/projects/<your_project_id>/packages/npm/:
    npmAlwaysAuth: true
    npmAuthToken: '<your_token>'
```

In this configuration:

- Replace `<your_domain>` with your domain name.
- Replace `<your_project_id>` with your project's ID, which you can find on the project's home page.
- Replace `<your_token>` with a deploy token, group access token, project access token, or personal access token.

### Configuring `.yarnrc.yml` to publish from the instance level

For the instance-level npm endpoint, use this Yarn 2 configuration in `.yarnrc.yml`:

```yaml
npmScopes:
  <scope>:
    npmRegistryServer: 'https://<your_domain>/api/v4/packages/npm/'

npmRegistries:
  //gitlab.example.com/api/v4/packages/npm/:
    npmAlwaysAuth: true
    npmAuthToken: '<your_token>'
```

In this configuration:

- Replace `<your_domain>` with your domain name.
- Your scope is `<scope>`, without `@`.
- Replace `<your_token>` with a deploy token, group access token, project access token, or personal access token.

### Publishing a package via the command line

Publish a package:

```shell
npm publish
```

Your package should now publish to the Package Registry.

### Publishing via a CI/CD pipeline

In the GitLab project that houses your `yarnrc.yml`, edit or create a `.gitlab-ci.yml` file. For example:

```yaml
image: node:latest

stages:
  - deploy

deploy:
  stage: deploy
  script:
    - npm publish
```

Your package should now publish to the Package Registry when the pipeline runs.

## Install a package

If multiple packages have the same name and version, the most recently-published package is retrieved when you install a package.

You can install a package from a GitLab project or instance:

- **Instance-level**: Use when you have many npm packages in different GitLab groups or in their own namespace.
- **Project-level**: Use when you have a few npm packages, and they are not in the same GitLab group.

### Install from the instance level

WARNING:
You must use packages published with the scoped [naming convention](#naming-convention) when you install a package from the instance level.

1. Authenticate to the Package Registry

   If you install a package from a private project, you must authenticate to the Package Registry. Skip this step if the project is not private.

   ```shell
   npm config set -- //your_domain_name/api/v4/packages/npm/:_authToken=your_token
   ```

   - Replace `your_domain_name` with your domain name, for example, `gitlab.com`.
   - Replace `your_token` with a deploy token, group access token, project access token, or personal access token.

1. Set the registry

   ```shell
   npm config set @scope:registry https://your_domain_name.com/api/v4/packages/npm/
   ```

   - Replace `@scope` with the [root level group](#naming-convention) of the project you're installing to the package from.
   - Replace `your_domain_name` with your domain name, for example, `gitlab.com`.
   - Replace `your_token` with a deploy token, group access token, project access token, or personal access token.

1. Install the package

   ```shell
   yarn add @scope/my-package
   ```

### Install from the project level

1. Authenticate to the Package Registry

   If you install a package from a private project, you must authenticate to the Package Registry. Skip this step if the project is not private.

   ```shell
   npm config set -- //your_domain_name/api/v4/projects/your_project_id/packages/npm/:_authToken=your_token
   ```

   - Replace `your_domain_name` with your domain name, for example, `gitlab.com`.
   - Replace `your_project_id` is your project ID, found on the project's home page.
   - Replace `your_token` with a deploy token, group access token, project access token, or personal access token.

1. Set the registry

   ```shell
   npm config set @scope:registry=https://your_domain_name/api/v4/projects/your_project_id/packages/npm/
   ```

   - Replace `@scope` with the [root level group](#naming-convention) of the project you're installing to the package from.
   - Replace `your_domain_name` with your domain name, for example, `gitlab.com`.
   - Replace `your_project_id` is your project ID, found on the project's home page.

1. Install the package

   ```shell
   yarn add @scope/my-package
   ```

## Helpful hints

For full helpful hints information, refer to the [npm documentation](../npm_registry/index.md#helpful-hints).

### Supported CLI commands

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

## Troubleshooting

For full troubleshooting information, refer to the [npm documentation](../npm_registry/index.md#troubleshooting).

### Error running Yarn with the Package Registry for the npm registry

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
