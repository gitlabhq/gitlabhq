---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Monorepo package management workflows
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use a monorepo project as a package registry to publish packages to multiple projects.

## Publish packages to a project and its child projects

To publish packages to a project and its child projects, you must add configuration files for each package. To learn how to configure packages for a specific package manager, see [Supported package managers](../package_registry/supported_package_managers.md).

The following example shows you how to publish packages for a project and its child project with [npm](../npm_registry/_index.md).

Prerequisites:

- A [personal access token](../../profile/personal_access_tokens.md)
  with the scope set to `api`.
- A test project.

In this example, `MyProject` is the parent project. It contains a child project called `ChildProject` in the
`components` directory:

```plaintext
MyProject/
  |- src/
  |   |- components/
  |       |- ChildProject/
  |- package.json
```

To publish a package for `MyProject`:

1. Go to the `MyProject` directory.
1. Initialize the project by running `npm init`. Make sure the package name follows the [naming convention](../npm_registry/_index.md#naming-convention).
1. Create a `.npmrc` file. Include the registry URL and the project endpoint. For example:

   ```yaml
   //gitlab.example.com/api/v4/projects/<project_id>/packages/npm/:_authToken="${NPM_TOKEN}"
   @scope:registry=https://gitlab.example.com/api/v4/projects/<project_id>/packages/npm/
   ```

1. Publish your package from the command line. Replace `<token>` with your personal access token:

   ```shell
   NPM_TOKEN=<token> npm publish
   ```

WARNING:
Never hardcode GitLab tokens (or any tokens) directly in `.npmrc` files or any other files that can
be committed to a repository.

You should see the package for `MyProject` published in your project's package registry.

To publish a package in `ChildProject`, follow the same steps. The contents of the `.npmrc` file can be identical to the one you added in `MyProject`.

After you publish the package for `ChildProject`, you should see the package in your project's package registry.

## Publishing packages to other projects

A package is associated with a project on GitLab. But, a package is not associated
with the code in that project.

For example, when configuring a package for npm or Maven, the `project_id` sets the registry URL that the package publishes to:

```yaml
# npm
https://gitlab.example.com/api/v4/projects/<project_id>/packages/npm/

# maven
https://gitlab.example.com/api/v4/projects/<project_id>/packages/maven/
```

If you change the `project_id` in the registry URL to another project, your package publishes to that project.

By changing the `project_id`, you can publish multiple packages to one project separately from the code. For more information, see [Store all of your packages in one GitLab project](project_registry.md).
