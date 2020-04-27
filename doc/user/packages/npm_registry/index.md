# GitLab NPM Registry **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/5934) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.7.

With the GitLab NPM Registry, every
project can have its own space to store NPM packages.

![GitLab NPM Registry](img/npm_package_view_v12_5.png)

NOTE: **Note:**
Only [scoped](https://docs.npmjs.com/misc/scope) packages are supported.

## Enabling the NPM Registry

NOTE: **Note:**
This option is available only if your GitLab administrator has
[enabled support for the NPM registry](../../../administration/packages/index.md).**(PREMIUM ONLY)**

After the NPM registry is enabled, it will be available for all new projects
by default. To enable it for existing projects, or if you want to disable it:

1. Navigate to your project's **Settings > General > Permissions**.
1. Find the Packages feature and enable or disable it.
1. Click on **Save changes** for the changes to take effect.

You should then be able to see the **Packages** section on the left sidebar.

Before proceeding to authenticating with the GitLab NPM Registry, you should
get familiar with the package naming convention.

## Getting started

This section will cover installing NPM (or Yarn) and building a package for your
JavaScript project. This is a quickstart if you are new to NPM packages. If you
are already using NPM and understand how to build your own packages, move on to
the [next section](#authenticating-to-the-gitlab-npm-registry).

### Installing NPM

Follow the instructions at [npmjs.com](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm) to download and install Node.js and
NPM to your local development environment.

Once installation is complete, verify you can use NPM in your terminal by
running:

```shell
npm --version
```

You should see the NPM version printed in the output:

```plaintext
6.10.3
```

### Installing Yarn

You may want to install and use Yarn as an alternative to NPM. Follow the
instructions at [yarnpkg.com](https://classic.yarnpkg.com/en/docs/install) to install on
your development environment.

Once installed, you can verify that Yarn is available with the following command:

```shell
yarn --version
```

You should see the version printed like so:

```plaintext
1.19.1
```

### Creating a project

Understanding how to create a full JavaScript project is outside the scope of
this guide but you can initialize a new empty package by creating and navigating
to an empty directory and using the following command:

```shell
npm init
```

Or if you're using Yarn:

```shell
yarn init
```

This will take you through a series of questions to produce a `package.json`
file, which is required for all NPM packages. The most important question is the
package name. NPM packages must [follow the naming convention](#package-naming-convention)
and be scoped to the project or group where the registry exists.

Once you have completed the setup, you are now ready to upload your package to
the GitLab registry. To get started, you will need to set up authentication then
configure GitLab as a remote registry.

## Authenticating to the GitLab NPM Registry

If a project is private or you want to upload an NPM package to GitLab,
credentials will need to be provided for authentication. [Personal access tokens](../../profile/personal_access_tokens.md)
are preferred, but support is available for [OAuth tokens](../../../api/oauth2.md#resource-owner-password-credentials-flow).

CAUTION: **2FA is only supported with personal access tokens:**
If you have 2FA enabled, you need to use a [personal access token](../../profile/personal_access_tokens.md) with OAuth headers with the scope set to `api`. Standard OAuth tokens won't be able to authenticate to the GitLab NPM Registry.

### Authenticating with a personal access token

To authenticate with a [personal access token](../../profile/personal_access_tokens.md),
set your NPM configuration:

```shell
# Set URL for your scoped packages.
# For example package with name `@foo/bar` will use this URL for download
npm config set @foo:registry https://gitlab.com/api/v4/packages/npm/

# Add the token for the scoped packages URL. This will allow you to download
# `@foo/` packages from private projects.
npm config set '//gitlab.com/api/v4/packages/npm/:_authToken' "<your_token>"

# Add token for uploading to the registry. Replace <your_project_id>
# with the project you want your package to be uploaded to.
npm config set '//gitlab.com/api/v4/projects/<your_project_id>/packages/npm/:_authToken' "<your_token>"
```

Replace `<your_project_id>` with your project ID which can be found on the home page
of your project and `<your_token>` with your personal access token.

If you have a self-managed GitLab installation, replace `gitlab.com` with your
domain name.

You should now be able to download and upload NPM packages to your project.

NOTE: **Note:**
If you encounter an error message with [Yarn](https://classic.yarnpkg.com/en/), see the
[troubleshooting section](#troubleshooting).

### Using variables to avoid hard-coding auth token values

To avoid hard-coding the `authToken` value, you may use a variables in its place:

```shell
npm config set '//gitlab.com/api/v4/projects/<your_project_id>/packages/npm/:_authToken' "${NPM_TOKEN}"
npm config set '//gitlab.com/api/v4/packages/npm/:_authToken' "${NPM_TOKEN}"
```

Then, you could run `npm publish` either locally or via GitLab CI/CD:

- **Locally:** Export `NPM_TOKEN` before publishing:

  ```shell
  NPM_TOKEN=<your_token> npm publish
  ```

- **GitLab CI/CD:** Set an `NPM_TOKEN` [variable](../../../ci/variables/README.md)
  under your project's **Settings > CI/CD > Variables**.

### Authenticating with a CI job token

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/9104) in GitLab Premium 12.5.

If you’re using NPM with GitLab CI/CD, a CI job token can be used instead of a personal access token.
The token will inherit the permissions of the user that generates the pipeline.

Add a corresponding section to your `.npmrc` file:

```ini
@foo:registry=https://gitlab.com/api/v4/packages/npm/
//gitlab.com/api/v4/packages/npm/:_authToken=${CI_JOB_TOKEN}
//gitlab.com/api/v4/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=${CI_JOB_TOKEN}
```

## Uploading packages

Before you will be able to upload a package, you need to specify the registry
for NPM. To do this, add the following section to the bottom of `package.json`:

```json
"publishConfig": {
  "@foo:registry":"https://gitlab.com/api/v4/projects/<your_project_id>/packages/npm/"
}
```

Replace `<your_project_id>` with your project ID, which can be found on the home
page of your project, and replace `@foo` with your own scope.

If you have a self-managed GitLab installation, replace `gitlab.com` with your
domain name.

Once you have enabled it and set up [authentication](#authenticating-to-the-gitlab-npm-registry),
you can upload an NPM package to your project:

```shell
npm publish
```

You can then navigate to your project's **Packages** page and see the uploaded
packages or even delete them.

If you attempt to publish a package with a name that already exists within
a given scope, you will receive a `403 Forbidden!` error.

## Uploading a package with the same version twice

You cannot upload a package with the same name and version twice, unless you
delete the existing package first. This aligns with npmjs.org's behavior, with
the exception that npmjs.org does not allow users to ever publish the same version
more than once, even if it has been deleted.

## Package naming convention

**Packages must be scoped in the root namespace of the project**. The package
name may be anything but it is preferred that the project name be used unless
it is not possible due to a naming collision. For example:

| Project                | Package                 | Supported |
| ---------------------- | ----------------------- | --------- |
| `foo/bar`              | `@foo/bar`              | Yes       |
| `foo/bar/baz`          | `@foo/baz`              | Yes       |
| `foo/bar/buz`          | `@foo/anything`         | Yes       |
| `gitlab-org/gitlab`    | `@gitlab-org/gitlab`    | Yes       |
| `gitlab-org/gitlab`    | `@foo/bar`              | No        |

The regex that is used for naming is validating all package names from all package managers:

```plaintext
/\A\@?(([\w\-\.\+]*)\/)*([\w\-\.]+)@?(([\w\-\.\+]*)\/)*([\w\-\.]*)\z/
```

It allows for capital letters, while NPM does not, and allows for almost all of the
characters NPM allows with a few exceptions (`~` is not allowed).

NOTE: **Note:** Capital letters are needed because the scope is required to be
identical to the top level namespace of the project. So, for example, if your
project path is `My-Group/project-foo`, your package must be named `@My-Group/any-package-name`.
`@my-group/any-package-name` will not work.

CAUTION: **When updating the path of a user/group or transferring a (sub)group/project:**
If you update the root namespace of a project with NPM packages, your changes will be rejected. To be allowed to do that, make sure to remove any NPM package first. Don't forget to update your `.npmrc` files to follow the above naming convention and run `npm publish` if necessary.

Now, you can configure your project to authenticate with the GitLab NPM
Registry.

## Installing a package

NPM packages are commonly installed using the `npm` or `yarn` commands
inside a JavaScript project. If you haven't already, you will need to set the
URL for scoped packages. You can do this with the following command:

```shell
npm config set @foo:registry https://gitlab.com/api/v4/packages/npm/
```

You will need to replace `@foo` with your scope.

Next, you will need to ensure [authentication](#authenticating-to-the-gitlab-npm-registry)
is setup so you can successfully install the package. Once this has been
completed, you can run the following command inside your project to install a
package:

```shell
npm install @my-project-scope/my-package
```

Or if you're using Yarn:

```shell
yarn add @my-project-scope/my-package
```

### Forwarding requests to npmjs.org

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/55344) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.9.

By default, when an NPM package is not found in the GitLab NPM Registry, the request will be forwarded to [npmjs.com](https://www.npmjs.com/).

Administrators can disable this behavior in the [Continuous Integration settings](../../admin_area/settings/continuous_integration.md).

## Removing a package

In the packages view of your project page, you can delete packages by clicking
the red trash icons or by clicking the **Delete** button on the package details
page.

## Publishing a package with CI/CD

To work with NPM commands within [GitLab CI/CD](./../../../ci/README.md), you can use
`CI_JOB_TOKEN` in place of the personal access token in your commands.

A simple example `.gitlab-ci.yml` file for publishing NPM packages:

```yml
image: node:latest

stages:
  - deploy

deploy:
  stage: deploy
  script:
    - echo '//gitlab.com/api/v4/projects/<your_project_id>/packages/npm/:_authToken=${CI_JOB_TOKEN}'>.npmrc
    - npm publish
```

## Troubleshooting

### Error running yarn with NPM registry

If you are using [yarn](https://classic.yarnpkg.com/en/) with the NPM registry, you may get
an error message like:

```shell
yarn install v1.15.2
warning package.json: No license field
info No lockfile found.
warning XXX: No license field
[1/4] 🔍  Resolving packages...
[2/4] 🚚  Fetching packages...
error An unexpected error occurred: "https://gitlab.com/api/v4/projects/XXX/packages/npm/XXX/XXX/-/XXX/XXX-X.X.X.tgz: Request failed \"404 Not Found\"".
info If you think this is a bug, please open a bug report with the information provided in "/Users/XXX/gitlab-migration/module-util/yarn-error.log".
info Visit https://classic.yarnpkg.com/en/docs/cli/install for documentation about this command
```

In this case, try adding this to your `.npmrc` file (and replace `<your_token>`
with your personal access token):

```text
//gitlab.com/api/v4/projects/:_authToken=<your_token>
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
  "publishConfig": {
    "@foo:registry":"https://gitlab.com/api/v4/projects/<your_project_id>/packages/npm/"
  }
}
```

And the `.npmrc` file should look like:

```ini
//gitlab.com/api/v4/projects/<your_project_id>/packages/npm/:_authToken=<your_token>
//gitlab.com/api/v4/packages/npm/:_authToken=<your_token>
@foo:registry=https://gitlab.com/api/v4/packages/npm/
```

### `npm install` returns `Error: Failed to replace env in config: ${NPM_TOKEN}`

You do not need a token to run `npm install` unless your project is private (the token is only required to publish). If the `.npmrc` file was checked in with a reference to `$NPM_TOKEN`, you can remove it. If you prefer to leave the reference in, you'll need to set a value prior to running `npm install` or set the value using [GitLab environment variables](./../../../ci/variables/README.md):

```shell
NPM_TOKEN=<your_token> npm install
```

### `npm install` returns `npm ERR! 403 Forbidden`

- Check that your token is not expired and has appropriate permissions.
- Check if you have attempted to publish a package with a name that already exists within a given scope.
- Ensure the scoped packages URL includes a trailing slash:
  - Correct: `//gitlab.com/api/v4/packages/npm/`
  - Incorrect: `//gitlab.com/api/v4/packages/npm`

## NPM dependencies metadata

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/11867) in GitLab Premium 12.6.

Starting from GitLab 12.6, new packages published to the GitLab NPM Registry expose the following attributes to the NPM client:

- name
- version
- dist-tags
- dependencies
  - dependencies
  - devDependencies
  - bundleDependencies
  - peerDependencies
  - deprecated

## NPM distribution tags

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/9425) in GitLab Premium 12.8.

You can add [distribution tags](https://docs.npmjs.com/cli/dist-tag) for newly published packages.
They follow NPM's convention where they are optional, and each tag can only be assigned to one
package at a time. The `latest` tag is added by default when a package is published without a tag.
The same applies to installing a package without specifying the tag or version.

Examples of the supported `dist-tag` commands and using tags in general:

```shell
npm publish @scope/package --tag               # Publish new package with new tag
npm dist-tag add @scope/package@version my-tag # Add a tag to an existing package
npm dist-tag ls @scope/package                 # List all tags under the package
npm dist-tag rm @scope/package@version my-tag  # Delete a tag from the package
npm install @scope/package@my-tag              # Install a specific tag
```

CAUTION: **Warning:**
Due to a bug in NPM 6.9.0, deleting dist tags fails. Make sure your NPM version is greater than 6.9.1.
