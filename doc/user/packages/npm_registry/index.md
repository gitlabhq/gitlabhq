---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# npm packages in the package registry

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

For documentation of the specific API endpoints that the npm package manager client uses, see the [npm API documentation](../../../api/packages/npm.md).

Learn how to build an [npm](../workflows/build_packages.md#npm) or [yarn](../workflows/build_packages.md#yarn) package.

Watch a [video demo](https://youtu.be/yvLxtkvsFDA) of how to publish npm packages to the GitLab package registry.

## Publish to GitLab package registry

### Authentication to the package registry

You need a token to publish a package. There are different tokens available depending on what you're trying to achieve. For more information, review the [guidance on tokens](../../../user/packages/package_registry/index.md#authenticate-with-the-registry).

- If your organization uses two factor authentication (2FA), you must use a personal access token with the scope set to `api`.
- If you are publishing a package via CI/CD pipelines, you must use a CI job token.

Create a token and save it to use later in the process.

Do not use authentication methods other than the methods documented here. Undocumented authentication methods might be removed in the future.

### Naming convention

Depending on how the package is installed, you may need to adhere to the naming convention.

You can use one of three API endpoints to install packages:

- **Instance-level**: Use when you have many npm packages in different GitLab groups or in their own namespace.
- **Group-level**: Use when you have many npm packages in different projects under the same group or subgroup.
- **Project-level**: Use when you have few npm packages and they are not in the same GitLab group.

If you plan to install a package through the [project level](#install-from-the-project-level) or [group level](#install-from-the-group-level), then you do not have to adhere to the naming convention.

If you plan to install a package through the [instance level](#install-from-the-instance-level), then you must name your package with a [scope](https://docs.npmjs.com/misc/scope/). Scoped packages begin with a `@` have the format of `@owner/package-name`. You can set up the scope for your package in the `.npmrc` file and by using the `publishConfig` option in the `package.json`.

- The value used for the `@scope` is the root of the project that is hosting the packages and not the root
  of the project with the source code of the package itself. The scope should be lowercase.
- The package name can be anything you want

| Project URL                                             | Package registry in | Scope     | Full package name      |
| ------------------------------------------------------- | ------------------- | --------- | ---------------------- |
| `https://gitlab.com/my-org/engineering-group/analytics` | Analytics           | `@my-org` | `@my-org/package-name` |

Make sure that the name of your package in the `package.json` file matches this convention:

```shell
"name": "@my-org/package-name"
```

## Publishing a package via the command line

### Authenticating via the `.npmrc`

Create or edit the `.npmrc` file in the same directory as your `package.json`. Include the following lines in the `.npmrc` file:

```shell
@scope:registry=https://your_domain_name/api/v4/projects/your_project_id/packages/npm/
//your_domain_name/api/v4/projects/your_project_id/packages/npm/:_authToken="${NPM_TOKEN}"
```

- Replace `@scope` with the [root level group](#naming-convention) of the project you're publishing to the package to.
- Replace `your_domain_name` with your domain name, for example, `gitlab.com`.
- Replace `your_project_id` with your project ID, found on the [project overview page](../../project/working_with_projects.md#access-a-project-by-using-the-project-id).
- `"${NPM_TOKEN}"` is associated with the token you created later in the process.

WARNING:
Never hardcode GitLab tokens (or any tokens) directly in `.npmrc` files or any other files that can
be committed to a repository.

### Publishing a package via the command line

Associate your [token](#authentication-to-the-package-registry) with the `"${NPM_TOKEN}"` in the `.npmrc`. Replace `your_token` with a deploy token, group access token, project access token, or personal access token.

```shell
NPM_TOKEN=your_token npm publish
```

Your package should now publish to the package registry.

If the uploaded package has more than one `package.json` file, only the first one found is used, and the others are ignored.

## Publishing a package by using a CI/CD pipeline

When publishing by using a CI/CD pipeline, you can use the [predefined variables](../../../ci/variables/predefined_variables.md) `${CI_PROJECT_ID}` and `${CI_JOB_TOKEN}` to authenticate with your project's package registry. We use these variables to create a `.npmrc` file [for authentication](#authenticating-via-the-npmrc) during execution of your CI/CD job.

WARNING:
When generating the `.npmrc` file, do not specify the port after `${CI_SERVER_HOST}` if it is a default port,
such as `80` for a URL starting with `http` or `443` for a URL starting with `https`.

In the GitLab project containing your `package.json`, edit or create a `.gitlab-ci.yml` file. For example:

```yaml
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

- Replace `@scope` with the [scope](https://docs.npmjs.com/cli/v10/using-npm/scope/) of the package that is being published.

Your package is published to the package registry when the `publish-npm` job in your pipeline runs.

## Install a package

If multiple packages have the same name and version, when you install a package, the most recently-published package is retrieved.

You can install a package from a GitLab project, group, or instance:

- **Instance-level**: Use when you have many npm packages in different GitLab groups or in their own namespace.
- **Group-level**: Use when you have many npm packages in different projects in the same GitLab group.
- **Project-level**: Use when you have few npm packages and they are not in the same GitLab group.

### Authenticate to the package registry

You must authenticate to the package registry to install a package from a private project or a private group.
No authentication is needed if the project or the group is public.
If the project is internal, you must be a registered user on the GitLab instance.
An anonymous user cannot pull packages from an internal project.

To authenticate with `npm`:

```shell
npm config set -- //your_domain_name/:_authToken=your_token
```

With npm version 7 or earlier, use the full URL to the endpoint.

If you're installing:

- From the instance level:

  ```shell
  npm config set -- //your_domain_name/api/v4/packages/npm/:_authToken=your_token
  ```

- From the group level:

  ```shell
  npm config set -- //your_domain_name/api/v4/groups/your_group_id/-/packages/npm/:_authToken=your_token
  ```

- From the project level:

  ```shell
  npm config set -- //your_domain_name/api/v4/projects/your_project_id/packages/npm/:_authToken=your_token
  ```

In these examples:

- Replace `your_domain_name` with your domain name, for example, `gitlab.com`.
- Replace `your_group_id` with your group ID, found on the group's home page.
- Replace `your_project_id` with your project ID, found on the [project overview page](../../project/working_with_projects.md#access-a-project-by-using-the-project-id).
- Replace `your_token` with a deploy token, group access token, project access token, or personal access token.

NOTE:
Starting with npm version 8, you can [use a URI fragment instead of a full URL](https://docs.npmjs.com/cli/v8/configuring-npm/npmrc/?v=true#auth-related-configuration)
in the `_authToken` parameter. However, [group-level endpoints](https://gitlab.com/gitlab-org/gitlab/-/issues/299834)
are not supported.

### Install from the instance level

WARNING:
To install a package from the instance level, the package must have been published following the scoped [naming convention](#naming-convention).

1. [Authenticate to the package registry](#authenticate-to-the-package-registry).

1. Set the registry

   ```shell
   npm config set @scope:registry https://your_domain_name.com/api/v4/packages/npm/
   ```

   - Replace `@scope` with the [root level group](#naming-convention) of the project you're installing to the package from.
   - Replace `your_domain_name` with your domain name, for example `gitlab.com`.
   - Replace `your_token` with a deploy token, group access token, project access token, or personal access token.

1. Install the package

   ```shell
   npm install @scope/my-package
   ```

### Install from the group level

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/299834) in GitLab 16.0 [with a flag](../../../administration/feature_flags.md) named `npm_group_level_endpoints`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121837) in GitLab 16.1. Feature flag `npm_group_level_endpoints` removed.

1. [Authenticate to the package registry](#authenticate-to-the-package-registry).

1. Set the registry

   ```shell
   npm config set @scope:registry=https://your_domain_name/api/v4/groups/your_group_id/-/packages/npm/
   ```

   - Replace `@scope` with the [root level group](#naming-convention) of the group you're installing to the package from.
   - Replace `your_domain_name` with your domain name, for example, `gitlab.com`.
   - Replace `your_group_id` is your group ID, found on the group's home page.

1. Install the package

   ```shell
   npm install @scope/my-package
   ```

### Install from the project level

1. [Authenticate to the package registry](#authenticate-to-the-package-registry).

1. Set the registry

   ```shell
   npm config set @scope:registry=https://your_domain_name/api/v4/projects/your_project_id/packages/npm/
   ```

   - Replace `@scope` with the [root level group](#naming-convention) of the project you're installing to the package from.
   - Replace `your_domain_name` with your domain name, for example, `gitlab.com`.
   - Replace `your_project_id` with your project ID, found on the [project overview page](../../project/working_with_projects.md#access-a-project-by-using-the-project-id).

1. Install the package

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

Pre-requisites:

- The same [permissions](../../permissions.md) as deleting a package.
- [Authenticated to the package registry](#authentication-to-the-package-registry).

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

### Remove deprecation warning

To remove a package's deprecation warning, specify `""` (an empty string) for the message. For example:

```shell
npm deprecate @scope/package ""
```

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
These are similar to the [abbreviated metadata format](https://github.com/npm/registry/blob/9e368cf6aaca608da5b2c378c0d53f475298b916/docs/responses/package-metadata.md#abbreviated-metadata-format):

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

You can use a [`CI_JOB_TOKEN`](../../../ci/jobs/ci_job_token.md) or [deploy token](../../project/deploy_tokens/index.md)
to run `npm dist-tag` commands in a GitLab CI/CD job. For example:

```yaml
npm-deploy-job:
  script:
    - echo "//${CI_SERVER_HOST}/api/v4/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=${CI_JOB_TOKEN}">.npmrc
    - npm dist-tag add @scope/package@version my-tag
```

Due to a bug in npm 6.9.0, deleting distribution tags fails. Make sure your npm version is 6.9.1 or later.

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

### `404 Not Found` errors are happening on `npm install` or `yarn`

Using `CI_JOB_TOKEN` to install npm packages with dependencies in another project gives you 404 Not Found errors. You need to authenticate with a token that has access to the package and all its dependencies.

If the package and its dependencies are in separate projects but in the same group, you can use a
[group deploy token](../../project/deploy_tokens/index.md#create-a-deploy-token):

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
Personal access tokens must be treated carefully. Read our [token security considerations](../../../security/token_overview.md#security-considerations)
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

- The package registry is enabled in your project settings. Although the package registry is enabled by default, it's possible to [disable it](../package_registry/index.md#disable-the-package-registry).
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
