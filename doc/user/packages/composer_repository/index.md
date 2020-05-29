# GitLab Composer Repository **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15886) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.1.

With the GitLab Composer Repository, every project can have its own space to store [Composer](https://getcomposer.org/) packages.

## Enabling the Composer Repository

NOTE: **Note:**
This option is available only if your GitLab administrator has
[enabled support for the Package Registry](../../../administration/packages/index.md). **(PREMIUM ONLY)**

After the Composer Repository is enabled, it will be available for all new projects
by default. To enable it for existing projects, or if you want to disable it:

1. Navigate to your project's **Settings > General > Permissions**.
1. Find the Packages feature and enable or disable it.
1. Click on **Save changes** for the changes to take effect.

You should then be able to see the **Packages & Registries** section on the left sidebar.

## Getting started

This section will cover creating a new example Composer package to publish. This is a
quickstart to test out the **GitLab Composer Registry**.

You will need a recent version of [Composer](https://getcomposer.org/).

### Creating a package project

Understanding how to create a full Composer project is outside the scope of this
guide, but you can create a small package to test out the registry. Start by
creating a new directory called `my-composer-package`:

```shell
mkdir my-composer-package && cd my-composer-package
```

Create a new `composer.json` file inside this directory to set up the basic project:

```shell
touch composer.json
```

Inside `composer.json`, add the following code:

```json
{
  "name": "<namespace>/composer-test",
  "type": "library",
  "license": "GPL-3.0-only",
  "version": "1.0.0"
}
```

Replace `<namespace>` with a unique namespace like your GitLab username or group name.

After this basic package structure is created, we need to tag it in Git and push it to the repository.

```shell
git init
add composer.json
git commit -m 'Composer package test'
git tag v1.0.0
git add origin git@gitlab.com:<namespace>/<project-name>.git
git push origin v1.0.0
```

### Publishing the package

Now that the basics of our project is completed, we can publish the package.
For accomplishing this you will need the following:

- A personal access token. You can generate a [personal access token](../../../user/profile/personal_access_tokens.md) with the scope set to `api` for repository authentication.
- Your project ID which can be found on the home page of your project.

To publish the package hosted on GitLab we'll need to make a `POST` to the GitLab package API using a tool like `curl`:

```shell
curl --data tag=<tag> 'https://__token__:<personal-access-token>@gitlab.com/api/v4/projects/<project_id>/packages/composer'
```

Where:

- `<personal-access-token>` is your personal access token.
- `<project_id>` is your project ID.
- `<tag>` is the Git tag name of the version you want to publish. In this example it should be `v1.0.0`. Notice that instead of `tag=<tag>` you can also use `branch=<branch>` to publish branches.

If the above command succeeds, you now should be able to see the package under the **Packages & Registries** section of your project page.

### Installing a package

To install your package you will need:

- A personal access token. You can generate a [personal access token](../../../user/profile/personal_access_tokens.md) with the scope set to `api` for repository authentication.
- Your group ID which can be found on the home page of your project's group.

Add the GitLab Composer package repository to your existing project's `composer.json` file, along with the package name and version you want to install like so:

```json
{
  ...
  "repositories": [
    { "type": "composer", "url": "https://gitlab.com/api/v4/group/<group_id>/-/packages/composer/packages.json" }
  ],
  "require": {
    ...
    "<package_name>": "<version>"
  },
  ...
}
```

Where:

- `<group_id>` is the group ID found under your project's group page.
- `<package_name>` is your package name as defined in your package's `composer.json` file.
- `<version>` is your package version (`1.0.0` in this example).

You will also need to create a `auth.json` file with your GitLab credentials:

```json
{
    "http-basic": {
        "gitlab.com": {
            "username": "___token___",
            "password": "<personal_access_token>"
        }
    }
}
```

Where:

- `<personal_access_token>` is your personal access token.

With the `composer.json` and `auth.json` files configured, you can install the package by running `composer`:

```shell
composer update
```

If successful, you should be able to see the output indicating that the package has been successfully installed.
