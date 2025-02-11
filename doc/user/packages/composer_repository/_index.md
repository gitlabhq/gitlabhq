---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Composer packages in the package registry
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated
**Status:** Beta

WARNING:
The Composer package registry for GitLab is under development and isn't ready for production use due to
limited functionality. This [epic](https://gitlab.com/groups/gitlab-org/-/epics/6817) details the remaining
work and timelines to make it production ready.

Publish [Composer](https://getcomposer.org/) packages in your project's package registry.
Then, install the packages whenever you need to use them as a dependency.

For documentation of the specific API endpoints that the Composer
client uses, see the [Composer API documentation](../../../api/packages/composer.md).

Composer v2.0 is recommended. Composer v1.0 is supported, but it has lower performance when working
in groups with very large numbers of packages.

Learn how to [build a Composer package](../workflows/build_packages.md#composer).

## Publish a Composer package by using the API

Publish a Composer package to the package registry,
so that anyone who can access the project can use the package as a dependency.

Prerequisites:

- A package in a GitLab repository. Composer packages should be versioned based on
  the [Composer specification](https://getcomposer.org/doc/04-schema.md#version).
  If the version is not valid, for example, it has three dots (`1.0.0.0`), an
  error (`Validation failed: Version is invalid`) occurs when you publish.
- A valid `composer.json` file at the project root directory.
- The Packages feature is enabled in a GitLab repository.
- The project ID, which is displayed on the [project overview page](../../project/working_with_projects.md#access-a-project-by-using-the-project-id).
- One of the following token types:
  - A [personal access token](../../profile/personal_access_tokens.md) with the scope set to `api`.
  - A [deploy token](../../project/deploy_tokens/_index.md)
    with the scope set to `write_package_registry`.

To publish the package with a personal access token:

- Send a `POST` request to the [Packages API](../../../api/packages.md).

  For example, you can use `curl`:

  ```shell
  curl --fail-with-body --data tag=<tag> "https://__token__:<personal-access-token>@gitlab.example.com/api/v4/projects/<project_id>/packages/composer"
  ```

  - `<personal-access-token>` is your personal access token.
  - `<project_id>` is your project ID.
  - `<tag>` is the Git tag name of the version you want to publish.
    To publish a branch, use `branch=<branch>` instead of `tag=<tag>`.

To publish the package with a deploy token:

- Send a `POST` request to the [Packages API](../../../api/packages.md).

  For example, you can use `curl`:

  ```shell
  curl --fail-with-body --data tag=<tag> --header "Deploy-Token: <deploy-token>" "https://gitlab.example.com/api/v4/projects/<project_id>/packages/composer"
  ```

  - `<deploy-token>` is your deploy token
  - `<project_id>` is your project ID.
  - `<tag>` is the Git tag name of the version you want to publish.
    To publish a branch, use `branch=<branch>` instead of `tag=<tag>`.

You can view the published package by going to **Deploy > Package Registry** and
selecting the **Composer** tab.

## Publish a Composer package by using CI/CD

You can publish a Composer package to the package registry as part of your CI/CD process.

1. Specify a `CI_JOB_TOKEN` in your `.gitlab-ci.yml` file:

   ```yaml
   stages:
     - deploy

   deploy:
     stage: deploy
     script:
       - apk add curl
       - 'curl --fail-with-body --header "Job-Token: $CI_JOB_TOKEN" --data tag=<tag> "${CI_API_V4_URL}/projects/$CI_PROJECT_ID/packages/composer"'
     environment: production
   ```

1. Run the pipeline.

To view the published package, go to **Deploy > Package Registry** and select the **Composer** tab.

### Use a CI/CD template

A more detailed Composer CI/CD file is also available as a `.gitlab-ci.yml` template:

1. On the left sidebar, select **Project overview**.
1. Above the file list, select **Set up CI/CD**. If this button is not available, select **CI/CD Configuration** and then **Edit**.
1. From the **Apply a template** list, select **Composer**.

WARNING:
Do not save unless you want to overwrite the existing CI/CD file.

## Publishing packages with the same name or version

When you publish:

- The same package with different data, it overwrites the existing package.
- The same package with the same data, a `400 Bad request` error occurs.

## Install a Composer package

Install a package from the package registry so you can use it as a dependency.

Prerequisites:

- A package in the package registry.
- The package registry is enabled in the project responsible for publishing the package.
- The group ID, which is on the group's home page.
- One of the following token types:
  - A [personal access token](../../profile/personal_access_tokens.md)
    with the scope set to, at minimum, `api`.
  - A [deploy token](../../project/deploy_tokens/_index.md)
    with the scope set to `read_package_registry`, `write_package_registry`, or both.
  - A [CI/CD Job token](../../../ci/jobs/ci_job_token.md)

To install a package:

1. Add the package registry URL to your project's `composer.json` file, along with the package name and version you want to install:

   - Connect to the package registry for your group:

     ```shell
     composer config repositories.<group_id> composer https://gitlab.example.com/api/v4/group/<group_id>/-/packages/composer/packages.json
     ```

   - Set the required package version:

     ```shell
     composer require <package_name>:<version>
     ```

   Result in the `composer.json` file:

   ```json
   {
     ...
     "repositories": {
       "<group_id>": {
         "type": "composer",
         "url": "https://gitlab.example.com/api/v4/group/<group_id>/-/packages/composer/packages.json"
       },
       ...
     },
     "require": {
       ...
       "<package_name>": "<version>"
     },
     ...
   }
   ```

   You can unset this with the command:

   ```shell
   composer config --unset repositories.<group_id>
   ```

   - `<group_id>` is the group ID.
   - `<package_name>` is the package name defined in your package's `composer.json` file.
   - `<version>` is the package version.

1. Create an `auth.json` file with your GitLab credentials:

   Using a personal access token:

   ```shell
   composer config gitlab-token.<DOMAIN-NAME> <personal_access_token>
   ```

   Result in the `auth.json` file:

   ```json
   {
     ...
     "gitlab-token": {
       "<DOMAIN-NAME>": "<personal_access_token>",
       ...
     }
   }
   ```

   Using a deploy token:

   ```shell
   composer config gitlab-token.<DOMAIN-NAME> <deploy_token_username> <deploy_token>
   ```

   Result in the `auth.json` file:

   ```json
   {
     ...
     "gitlab-token": {
       "<DOMAIN-NAME>": {
         "username": "<deploy_token_username>",
         "token": "<deploy_token>",
       ...
     }
   }
   ```

   Using a CI/CD job token:

   ```shell
   composer config -- gitlab-token.<DOMAIN-NAME> gitlab-ci-token "${CI_JOB_TOKEN}"
   ```

   Result in the `auth.json` file:

   ```json
   {
     ...
     "gitlab-token": {
       "<DOMAIN-NAME>": {
         "username": "gitlab-ci-token",
         "token": "<ci-job-token>",
       ...
     }
   }
   ```

   You can unset this with the command:

   ```shell
   composer config --unset --auth gitlab-token.<DOMAIN-NAME>
   ```

   - `<DOMAIN-NAME>` is the GitLab instance URL `gitlab.com` or `gitlab.example.com`.
   - `<personal_access_token>` with the scope set to `api`, or `<deploy_token>` with the scope set
     to `read_package_registry` and/or `write_package_registry`.

1. If you are on GitLab Self-Managed, add `gitlab-domains` to `composer.json`.

   ```shell
   composer config gitlab-domains gitlab01.example.com gitlab02.example.com
   ```

   Result in the `composer.json` file:

   ```json
   {
     ...
     "repositories": [
       { "type": "composer", "url": "https://gitlab.example.com/api/v4/group/<group_id>/-/packages/composer/packages.json" }
     ],
     "config": {
       ...
       "gitlab-domains": ["gitlab01.example.com", "gitlab02.example.com"]
     },
     "require": {
       ...
       "<package_name>": "<version>"
     },
     ...
   }
   ```

   You can unset this with the command:

   ```shell
   composer config --unset gitlab-domains
   ```

   NOTE:
   On GitLab.com, Composer uses the GitLab token from `auth.json` as a private token by default.
   Without the `gitlab-domains` definition in `composer.json`, Composer uses the GitLab token
   as basic-auth, with the token as a username and a blank password. This results in a 401 error.

1. With the `composer.json` and `auth.json` files configured, you can install the package by running:

   ```shell
   composer update
   ```

   Or to install the single package:

   ```shell
   composer req <package-name>:<package-version>
   ```

WARNING:
Never commit the `auth.json` file to your repository. To install packages from a CI/CD job,
consider using the [`composer config`](https://getcomposer.org/doc/articles/handling-private-packages.md#satis) tool with your access token
stored in a [GitLab CI/CD variable](../../../ci/variables/_index.md) or in
[HashiCorp Vault](../../../ci/secrets/_index.md).

### Install from source

You can install from source by pulling the Git repository directly. To do so, either:

- Use the `--prefer-source` option:

  ```shell
  composer update --prefer-source
  ```

- In the `composer.json`, use the [`preferred-install` field under the `config` key](https://getcomposer.org/doc/06-config.md#preferred-install):

  ```json
  {
    ...
    "config": {
      "preferred-install": {
        "<package name>": "source"
      }
    }
    ...
   }
  ```

#### SSH access

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119739) in GitLab 16.4 [with a flag](../../../administration/feature_flags.md) named `composer_use_ssh_source_urls`. Disabled by default.
> - [Enabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/329246) GitLab 16.5.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135467) in GitLab 16.6. Feature flag `composer_use_ssh_source_urls` removed.

When you install from source, the `composer` configures an
access to the project's Git repository.
Depending on the project visibility, the access type is different:

- On public projects, the `https` Git URL is used. Make sure you can [clone the repository with HTTPS](../../../topics/git/clone.md#clone-with-https).
- On internal or private projects, the `ssh` Git URL is used. Make sure you can [clone the repository with SSH](../../../topics/git/clone.md#clone-with-ssh).

You can access the `ssh` Git URL from a CI/CD job using [SSH keys with GitLab CI/CD](../../../ci/jobs/ssh_keys.md).

### Working with Deploy Tokens

Although Composer packages are accessed at the group level, a group or project deploy token can be
used to access them:

- A group deploy token has access to all packages published to projects in that group or its
  subgroups.
- A project deploy token only has access to packages published to that particular project.

## Troubleshooting

### Caching

To improve performance, Composer caches files related to a package. Composer doesn't remove data by
itself. The cache grows as new packages are installed. If you encounter issues, clear the cache with
this command:

```shell
composer clearcache
```

### Authorization requirement when using `composer install`

Authorization is required for the [downloading a package archive](../../../api/packages/composer.md#download-a-package-archive) endpoint.
If you encounter a credentials prompt when you are using `composer install`, follow the instructions in the [install a composer package](#install-a-composer-package) section to create an `auth.json` file.

### Publish fails with `The file composer.json was not found`

You might see an error that says `The file composer.json was not found`.

This issue occurs when [configuration requirements for publishing a package](#publish-a-composer-package-by-using-the-api) are not met.

To resolve the error, commit a `composer.json` file to the project root directory.

## Supported CLI commands

The GitLab Composer repository supports the following Composer CLI commands:

- `composer install`: Install Composer dependencies.
- `composer update`: Install the latest version of Composer dependencies.
