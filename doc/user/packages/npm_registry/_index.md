---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: npm packages in the package registry
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Node Package Manager (npm) is the default package manager for JavaScript and Node.js. Developers use npm to share and reuse code, manage dependencies, and streamline project workflows. In GitLab, npm packages play a crucial role in the software development lifecycle.

For documentation of the specific API endpoints that the npm package manager client uses, see the [npm API documentation](../../../api/packages/npm.md).

Learn how to build an [npm](../workflows/build_packages.md#npm) or [yarn](../workflows/build_packages.md#yarn) package.

Watch a [video demo](https://youtu.be/yvLxtkvsFDA) of how to publish npm packages to the GitLab package registry.

## Authenticate to the package registry

You must authenticate to the package registry to publish or install a package from a private project or a private group.
You don't need to authenticate if the project or the group is public.
If the project is internal, you must be a registered user on the GitLab instance.
An anonymous user cannot pull packages from an internal project.

To authenticate, you can use:

- A [personal access token](../../profile/personal_access_tokens.md)
  with the scope set to `api`.
- A [deploy token](../../project/deploy_tokens/_index.md) with the scope set to
  `read_package_registry`, `write_package_registry`, or both.
- A [CI/CD job token](../../../ci/jobs/ci_job_token.md).

If your organization uses two-factor authentication (2FA), you must use a personal access token with the scope set to `api`.
If you want to publish a package with a CI/CD pipeline, you must use a CI/CD job token.
For more information, review the [guidance on tokens](../package_registry/_index.md#authenticate-with-the-registry).

Do not use authentication methods other than the methods documented here. Undocumented authentication methods might be removed in the future.

### With the `.npmrc` file

Create or edit the `.npmrc` file in the same directory as your `package.json`. Include the following lines in the `.npmrc` file:

```shell
  //<domain_name>/api/v4/projects/<project_id>/packages/npm/:_authToken="${NPM_TOKEN}"
```

WARNING:
Never hardcode GitLab tokens (or any tokens) directly in `.npmrc` files or any other files that can
be committed to a repository.

For example:

::Tabs

:::TabTitle For an instance

```shell
//<domain_name>/api/v4/packages/npm/:_authToken="${NPM_TOKEN}"
```

Replace `<domain_name>` with your domain name. For example, `gitlab.com`.

:::TabTitle For a group

```shell
//<domain_name>/api/v4/groups/<group_id>/-/packages/npm/:_authToken="${NPM_TOKEN}"
```

Make sure to replace:

- `<domain_name>` with your domain name. For example, `gitlab.com`.
- `<group_id>` with the group ID from the group home page.

:::TabTitle For a project

```shell
//<domain_name>/api/v4/projects/<project_id>/packages/npm/:_authToken="${NPM_TOKEN}"
```

Make sure to replace:

- `<domain_name>` with your domain name. For example, `gitlab.com`.
- `<project_id>` with the project ID from the [project overview page](../../project/working_with_projects.md#access-a-project-by-using-the-project-id).

::EndTabs

### With `npm config set`

To do this:

```shell
npm config set -- //<domain_name>/:_authToken=<token>
```

Depending on your npm version, you might need to make changes to the URL:

- On npm version 7 or earlier, use the full URL to the endpoint.
- On version 8 and later, for the `_authToken` parameter, you can [use a URI fragment instead of a full URL](https://docs.npmjs.com/cli/v8/configuring-npm/npmrc/?v=true#auth-related-configuration). [Group-specific endpoints](https://gitlab.com/gitlab-org/gitlab/-/issues/299834)
are not supported.

For example:

::Tabs

:::TabTitle For an instance

```shell
npm config set -- //<domain_name>/api/v4/packages/npm/:_authToken=<token>
```

Make sure to replace:

- `<domain_name>` with your domain name. For example, `gitlab.com`.
- `<token>` with your deploy token, group access token, project access token, or personal access token.

:::TabTitle For a group

```shell
npm config set -- //<domain_name>/api/v4/groups/<group_id>/-/packages/npm/:_authToken=<token>
```

Make sure to replace:

- `<domain_name>` with your domain name. For example, `gitlab.com`.
- `<group_id>` with the group ID from the group home page.
- `<token>` with your deploy token, group access token, project access token, or personal access token.

:::TabTitle For a project

```shell
npm config set -- //<domain_name>/api/v4/projects/<project_id>/packages/npm/:_authToken=<token>
```

Make sure to replace:

- `<domain_name>` with your domain name. For example, `gitlab.com`.
- `<project_id>` with the project ID from the [project overview page](../../project/working_with_projects.md#access-a-project-by-using-the-project-id).
- `<token>` with your deploy token, group access token, project access token, or personal access token.

::EndTabs

## Set up the registry URL

To publish or install packages from the GitLab package registry, you need to configure npm to use the correct registry URL. The configuration method and URL structure depend on whether you're publishing or installing packages.

Before configuring the registry URL, it's important to understand the scope of different configuration methods:

- `.npmrc` file: Configuration is local to the folder containing the file.
- `npm config set` command: This modifies the global npm configuration and affects all npm commands run on your system.
- `publishConfig` in `package.json`: This configuration is specific to the package and only applies when publishing that package.

WARNING:
Running `npm config set` changes the global npm configuration. The change affects all npm commands
run on your system, regardless of the current working directory. Be cautious when using this method,
especially on shared systems.

### For publishing packages

When publishing packages, use the project endpoint:

```shell
https://gitlab.example.com/api/v4/projects/<project_id>/packages/npm/
```

Replace `gitlab.example.com` with your GitLab instance's domain and `<project_id>` with your project's ID.
To configure this URL, use one of these methods:

::Tabs

:::TabTitle `.npmrc` file

Create or edit the `.npmrc` file in your project root:

```plaintext
@scope:registry=https://gitlab.example.com/api/v4/projects/<project_id>/packages/npm/ //gitlab.example.com/api/v4/projects/<project_id>/packages/npm/:_authToken="${NPM_TOKEN}"
```

:::TabTitle `npm config`

Use the `npm config set` command:

```shell
npm config set @scope:registry=https://gitlab.example.com/api/v4/projects/<project_id>/packages/npm/
```

:::TabTitle `package.json`

Add a `publishConfig` section to your `package.json`:

```shell
{
  "publishConfig": {
    "@scope:registry": "https://gitlab.example.com/api/v4/projects/<project_id>/packages/npm/"
  }
}
```

::EndTabs

Replace `@scope` with your package's scope.

### For installing packages

When you install packages, you can use project, group, or instance endpoints. The URL structure varies accordingly.
To configure these URLs, use one of these methods:

::Tabs

:::TabTitle `.npmrc` file

Create or edit the `.npmrc` file in your project root. Use the appropriate URL based on your needs:

- For a project:

  ```shell
  @scope:registry=https://gitlab.example.com/api/v4/projects/<project_id>/packages/npm/
  ```

- For a group:

  ```shell
  @scope:registry=https://gitlab.example.com/api/v4/groups/<group_id>/-/packages/npm/
  ```

- For an instance:

  ```shell
  @scope:registry=https://gitlab.example.com/api/v4/packages/npm/
  ```

:::TabTitle `npm config`

Use the `npm config set` command with the appropriate URL:

- For a project:

  ```shell
  npm config set @scope:registry=https://gitlab.example.com/api/v4/projects/<project_id>/packages/npm/
  ```

- For a group:

  ```shell
  npm config set @scope:registry=https://gitlab.example.com/api/v4/groups/<group_id>/-/packages/npm/
  ```

- For an instance:

  ```shell
  npm config set @scope:registry=https://gitlab.example.com/api/v4/packages/npm/
  ```

::EndTabs

Replace `gitlab.example.com`, `<project_id>`, `<group_id>`, and `@scope` with the appropriate values for your GitLab instance and package.

After you configure your registry URL, you can authenticate to the package registry.

## Publish to GitLab package registry

To publish an npm package to the GitLab package registry, you must be
[authenticated](#authenticate-to-the-package-registry).

### Naming convention

Depending on how the package is installed, you might need to adhere to the naming convention.

You can use one of three API endpoints to install packages:

- **Instance**: Use when you have many npm packages in different GitLab groups or in their own namespace.
- **Group**: Use when you have many npm packages in different projects under the same group or subgroup.
- **Project**: Use when you have few npm packages and they are not in the same GitLab group.

If you plan to install a package from a [project](#install-from-a-project) or [group](#install-from-a-group),
then you do not have to adhere to the naming convention.

If you plan to install a package from an [instance](#install-from-an-instance), then you must name your package
with a [scope](https://docs.npmjs.com/misc/scope/). Scoped packages begin with a `@` have the format of
`@owner/package-name`. You can set up the scope for your package in the `.npmrc` file and by using the `publishConfig`
option in the `package.json`.

- The value used for the `@scope` is the root of the project that is hosting the packages and not the root
  of the project with the source code of the package itself. The scope should be lowercase.
- The package name can be anything you want.

| Project URL                                             | Package registry in | Scope     | Full package name      |
| ------------------------------------------------------- | ------------------- | --------- | ---------------------- |
| `https://gitlab.com/my-org/engineering-group/analytics` | Analytics           | `@my-org` | `@my-org/package-name` |

Make sure that the name of your package in the `package.json` file matches this convention:

```shell
"name": "@my-org/package-name"
```

### Publish a package with the command line

After you [configure authentication](#authenticate-to-the-package-registry), publish the NPM package with:

```shell
npm publish
```

If you're using an `.npmrc` file for authentication, set the expected environment variables:

```shell
NPM_TOKEN=<token> npm publish
```

If the uploaded package has more than one `package.json` file, only the first one found is used, and the others are ignored.

### Publish a package with a CI/CD pipeline

When publishing by using a CI/CD pipeline, you can use the
[predefined variables](../../../ci/variables/predefined_variables.md) `${CI_PROJECT_ID}` and `${CI_JOB_TOKEN}`
to authenticate with your project's package registry. GitLab uses these variables to create a `.npmrc` file
for authentication during execution of your CI/CD job.

NOTE:
When you generate the `.npmrc` file, do not specify the port after `${CI_SERVER_HOST}` if it is a default port.
`http` URLs default to `80`, and `https` URLs default to `443`.

In the GitLab project containing your `package.json`, edit or create a `.gitlab-ci.yml` file. For example:

```yaml
default:
  image: node:latest

stages:
  - deploy

publish-npm:
  stage: deploy
  script:
    - echo "@scope:registry=https://${CI_SERVER_HOST}/api/v4/projects/${CI_PROJECT_ID}/packages/npm/" > .npmrc
    - echo "//${CI_SERVER_HOST}/api/v4/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=${CI_JOB_TOKEN}" >> .npmrc
    - npm publish
```

Replace `@scope` with the [scope](https://docs.npmjs.com/cli/v10/using-npm/scope/) of the package that is being published.

Your package is published to the package registry when the `publish-npm` job in your pipeline runs.

## Install a package

If multiple packages have the same name and version, when you install a package, the most recently published package is retrieved.

You can install a package from a GitLab project, group, or instance:

- **Instance**: Use when you have many npm packages in different GitLab groups or in their own namespace.
- **Group**: Use when you have many npm packages in different projects in the same GitLab group.
- **Project**: Use when you have few npm packages and they are not in the same GitLab group.

### Install from an instance

Prerequisites:

- The package was published according to the scoped [naming convention](#naming-convention).

1. [Authenticate to the package registry](#authenticate-to-the-package-registry).
1. Set the registry:

   ```shell
   npm config set @scope:registry https://<domain_name>.com/api/v4/packages/npm/
   ```

   - Replace `@scope` with the [top-level group](#naming-convention) of the project you're installing to the package from.
   - Replace `<domain_name>` with your domain name, for example `gitlab.com`.

1. Install the package:

   ```shell
   npm install @scope/my-package
   ```

### Install from a group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/299834) in GitLab 16.0 [with a flag](../../../administration/feature_flags.md) named `npm_group_level_endpoints`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121837) in GitLab 16.1. Feature flag `npm_group_level_endpoints` removed.

1. [Authenticate to the package registry](#authenticate-to-the-package-registry).
1. Set the registry:

   ```shell
   npm config set @scope:registry=https://<domain_name>/api/v4/groups/<group_id>/-/packages/npm/
   ```

   - Replace `@scope` with the [top-level group](#naming-convention) of the group you're installing to the package from.
   - Replace `<domain_name>` with your domain name, for example, `gitlab.com`.
   - Replace `<group_id>` with your group ID, found on the group's home page.

1. Install the package:

   ```shell
   npm install @scope/my-package
   ```

### Install from a project

1. [Authenticate to the package registry](#authenticate-to-the-package-registry).
1. Set the registry:

   ```shell
   npm config set @scope:registry=https://<domain_name>/api/v4/projects/<project_id>/packages/npm/
   ```

   - Replace `@scope` with the [top-level group](#naming-convention) of the project you're installing to the package from.
   - Replace `<domain_name>` with your domain name, for example, `gitlab.com`.
   - Replace `<project_id>` with your project ID, found on the [project overview page](../../project/working_with_projects.md#access-a-project-by-using-the-project-id).

1. Install the package:

   ```shell
   npm install @scope/my-package
   ```

### Package forwarding to npmjs.com

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/55344) in GitLab 12.9.
> - Required role [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/370471) from Maintainer to Owner in GitLab 17.0.

When an npm package is not found in the package registry, GitLab responds with an HTTP redirect so the requesting client can resend the request to [npmjs.com](https://www.npmjs.com/).

Administrators can disable this behavior in the [Continuous Integration settings](../../../administration/settings/continuous_integration.md).

Group owners can disable this behavior in the group **Packages and registries** settings.

Improvements are tracked in [epic 3608](https://gitlab.com/groups/gitlab-org/-/epics/3608).

## Deprecate a package

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/396763) in GitLab 16.0.

You can deprecate a package so that a deprecation warning displays when the package is fetched.

Prerequisites:

- You have the necessary [permissions](../../permissions.md) to delete a package.
- You are [authenticated to the package registry](#authenticate-to-the-package-registry).

From the command line, run:

```shell
npm deprecate @scope/package "Deprecation message"
```

The CLI also accepts version ranges for `@scope/package`. For example:

```shell
npm deprecate @scope/package "All package versions are deprecated"
npm deprecate @scope/package@1.0.1 "Only version 1.0.1 is deprecated"
npm deprecate @scope/package@"< 1.0.5" "All package versions less than 1.0.5 are deprecated"
```

When a package is deprecated, its status will be updated to `deprecated`.

### Remove deprecation warning

To remove a package's deprecation warning, specify `""` (an empty string) for the message. For example:

```shell
npm deprecate @scope/package ""
```

When a package's deprecation warning is removed, its status will be updated to `default`.

## Helpful hints

### Install npm packages from other organizations

You can route package requests to organizations and users outside of GitLab.

To do this, add lines to your `.npmrc` file. Replace `@my-other-org` with the namespace or group that owns your project's repository,
and use your organization's URL. The name is case-sensitive and must match the name of your group or namespace exactly.

```shell
@scope:registry=https://my_domain_name.com/api/v4/packages/npm/
@my-other-org:registry=https://my_domain_name.example.com/api/v4/packages/npm/
```

### npm metadata

The GitLab package registry exposes the following attributes to the npm client.
These are similar to the [abbreviated metadata format](https://github.com/npm/registry/blob/main/docs/responses/package-metadata.md#abbreviated-version-object):

- `name`
- `versions`
  - `name`
  - `version`
  - `deprecated`
  - `dependencies`
  - `devDependencies`
  - `bundleDependencies`
  - `peerDependencies`
  - `bin`
  - `directories`
  - `dist`
  - `engines`
  - `_hasShrinkwrap`
  - `hasInstallScript`: `true` if this version has the install scripts.

### Add npm distribution tags

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

#### From CI/CD

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/258835) in GitLab 15.10.

You can use a [`CI_JOB_TOKEN`](../../../ci/jobs/ci_job_token.md) or [deploy token](../../project/deploy_tokens/_index.md)
to run `npm dist-tag` commands in a GitLab CI/CD job.

Prerequisites:

- You have npm version 6.9.1 or later. In earlier versions, deleting distribution tags fails due to a bug in npm 6.9.0.

For example:

```yaml
npm-deploy-job:
  script:
    - echo "//${CI_SERVER_HOST}/api/v4/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=${CI_JOB_TOKEN}">.npmrc
    - npm dist-tag add @scope/package@version my-tag
```

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
- `npm pack`: Create a tarball from a package.
- `npm deprecate`: Deprecate a version of a package.

## Troubleshooting

### npm logs don't display correctly

You might encounter an error that says:

```shell
npm ERR! A complete log of this run can be found in: .npm/_logs/<date>-debug-0
```

If the log doesn't appear in the `.npm/_logs/` directory, you can copy the
log to your root directory and view it there:

```yaml
script:
    - npm install --loglevel verbose
    - cp -r /root/.npm/_logs/ .
  artifacts:
      paths:
        - './_logs
```

The npm log is copied to `/root/.npm/_logs/` as an artifact.

### `404 Not Found` errors are happening on `npm install` or `yarn`

Using `CI_JOB_TOKEN` to install npm packages with dependencies in another project gives you 404 Not Found errors. You need to authenticate with a token that has access to the package and all its dependencies.

If the package and its dependencies are in separate projects but in the same group, you can use a
[group deploy token](../../project/deploy_tokens/_index.md#create-a-deploy-token):

```ini
//gitlab.example.com/api/v4/packages/npm/:_authToken=<group-token>
@group-scope:registry=https://gitlab.example.com/api/v4/packages/npm/
```

If the package and its dependencies are spread across multiple groups, you can use a [personal access token](../../profile/personal_access_tokens.md)
from a user that has access to all the groups or individual projects:

```ini
//gitlab.example.com/api/v4/packages/npm/:_authToken=<personal-access-token>
@group-1:registry=https://gitlab.example.com/api/v4/packages/npm/
@group-2:registry=https://gitlab.example.com/api/v4/packages/npm/
```

WARNING:
Personal access tokens must be treated carefully. Read our [token security considerations](../../../security/tokens/_index.md#security-considerations)
for guidance on managing personal access tokens (for example, setting a short expiry and using minimal scopes).

### `npm publish` targets default npm registry (`registry.npmjs.org`)

Ensure that your package scope is set consistently in your `package.json` and `.npmrc` files.

For example, if your project name in GitLab is `@scope/my-package`, then your `package.json` file
should look like:

```json
{
  "name": "@scope/my-package"
}
```

And the `.npmrc` file should look like:

```shell
@scope:registry=https://your_domain_name/api/v4/projects/your_project_id/packages/npm/
//your_domain_name/api/v4/projects/your_project_id/packages/npm/:_authToken="${NPM_TOKEN}"
```

### `npm install` returns `npm ERR! 403 Forbidden`

If you get this error, ensure that:

- The package registry is enabled in your project settings. Although the package registry is enabled by default, it's possible to [disable it](../package_registry/_index.md#disable-the-package-registry).
- Your token is not expired and has appropriate permissions.
- A package with the same name or version doesn't already exist within the given scope.
- The scoped packages URL includes a trailing slash:
  - Correct: `//gitlab.example.com/api/v4/packages/npm/`
  - Incorrect: `//gitlab.example.com/api/v4/packages/npm`

### `npm publish` returns `npm ERR! 400 Bad Request`

If you get this error, one of the following problems could be causing it.

### Package name does not meet the naming convention

Your package name may not meet the [`@scope/package-name` package naming convention](#naming-convention).

Ensure the name meets the convention exactly, including the case. Then try to publish again.

### Package already exists

Your package has already been published to another project in the same root namespace and therefore cannot be published again using the same name.

This is also true even if the prior published package shares the same name, but not the version.

### Package JSON file is too large

Make sure that your `package.json` file does not exceed `20,000` characters.
