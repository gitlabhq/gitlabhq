---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Ruby gems in the package registry
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/52147) in GitLab 13.9 [with a flag](../../../administration/feature_flags.md) named `rubygem_packages`. Disabled by default. This feature is an [experiment](../../../policy/development_stages_support.md).

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

You can publish Ruby gems to your project's package registry. Then, you can download them from the UI or with the API.

This feature is an [experiment](../../../policy/development_stages_support.md).
For more information about the development of this feature, see [epic 3200](https://gitlab.com/groups/gitlab-org/-/epics/3200).

## Authenticate to the package registry

Before you can interact with the package registry, you must authenticate to it.

To do this, you can use:

- A [personal access token](../../profile/personal_access_tokens.md)
  with the scope set to `api`.
- A [deploy token](../../project/deploy_tokens/_index.md) with the scope set to
  `read_package_registry`, `write_package_registry`, or both.
- A [CI/CD job token](../../../ci/jobs/ci_job_token.md).

For example:

::Tabs

:::TabTitle With an access token

To authenticate with an access token:

- Create or edit your `~/.gem/credentials` file, and add:

  ```ini
  ---
  https://gitlab.example.com/api/v4/projects/<project_id>/packages/rubygems: '<token>'
  ```

In this example:

- `<token>` must be the token value of either your personal access token or deploy token.
- `<project_id>` is displayed on the [project overview page](../../project/working_with_projects.md#access-a-project-by-using-the-project-id).

:::TabTitle With a CI/CD job token

To authenticate with a CI/CD job token:

- Create or edit your  `.gitlab-ci.yml` file, and add:

  ```yaml
  # assuming a my_gem.gemspec file is present in the repository with the version currently set to 0.0.1
  image: ruby

  run:
    before_script:
      - mkdir ~/.gem
      - echo "---" > ~/.gem/credentials
      - |
        echo "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/rubygems: '${CI_JOB_TOKEN}'" >> ~/.gem/credentials
      - chmod 0600 ~/.gem/credentials # rubygems requires 0600 permissions on the credentials file
    script:
      - gem build my_gem
      - gem push my_gem-0.0.1.gem --host ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/rubygems
  ```

  You can also use `CI_JOB_TOKEN` in a `~/.gem/credentials` file you check in to GitLab:

  ```ini
  ---
  https://gitlab.example.com/api/v4/projects/${env.CI_PROJECT_ID}/packages/rubygems: '${env.CI_JOB_TOKEN}'
  ```

::EndTabs

## Push a Ruby gem

Prerequisites:

- You must [authenticate to the package registry](#authenticate-to-the-package-registry).
- Your Ruby gem must be 3 GB or less.

To do this:

- Run a command like:

  ```shell
  gem push my_gem-0.0.1.gem --host <host>
  ```

  In this example, `<host>` is the URL you used when setting up authentication. For example:

  ```shell
  gem push my_gem-0.0.1.gem --host https://gitlab.example.com/api/v4/projects/1/packages/rubygems
  ```

When a gem is published successfully, a message like this is displayed:

```plaintext
Pushing gem to https://gitlab.example.com/api/v4/projects/1/packages/rubygems...
{"message":"201 Created"}
```

The gem is published to your package registry, and is shown on the **Packages and registries** page.
It can take up to 10 minutes before GitLab processes and displays your gem.

### Pushing gems with the same name or version

You can push a gem if a package of the same name and version already exists.
Both are visible and accessible in the UI.

## Download gems

You can't install Ruby gems from the GitLab package registry. However, you can download gem files for local use.

To do this:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Deploy > Package registry**.
1. Select the package name and version.
1. Under **Assets**, select the Ruby gem you want to download.

To download Ruby gems, you can also [use the API](../../../api/packages/rubygems.md#download-a-gem-file).

## Related topics

- [Make your own gem](https://guides.rubygems.org/make-your-own-gem/)
- [Ruby gems API documentation](../../../api/packages/rubygems.md)
