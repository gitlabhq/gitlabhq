---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Ruby gems in the Package Registry **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/803) in [GitLab Free](https://about.gitlab.com/pricing/) 13.10.

WARNING:
The Ruby gems registry for GitLab is under development and isn't ready for production use due to
limited functionality.

You can publish Ruby gems in your project's Package Registry, then install the packages when you
need to use them as a dependency. Although you can push gems to the registry, you cannot install
them from the registry. However, you can download `gem` files directly from the Package Registry's
UI, or by using the [API](../../../api/packages/rubygems.md#download-a-gem-file).

For documentation of the specific API endpoints that the Ruby gems and Bundler package manager
clients use, see the [Ruby gems API documentation](../../../api/packages/rubygems.md).

## Enable the Ruby gems registry

The Ruby gems registry for GitLab is behind a feature flag that is disabled by default. GitLab
administrators with access to the GitLab Rails console can enable this registry for your instance.

To enable it:

```ruby
Feature.enable(:rubygem_packages)
```

To disable it:

```ruby
Feature.disable(:rubygem_packages)
```

To enable or disable it for specific projects:

```ruby
Feature.enable(:rubygem_packages, Project.find(1))
Feature.disable(:rubygem_packages, Project.find(2))
```

## Create a Ruby gem

If you need help creating a Ruby gem, see the [RubyGems documentation](https://guides.rubygems.org/make-your-own-gem/).

## Authenticate to the Package Registry

Before you can push to the Package Registry, you must authenticate.

To do this, you can use:

- A [personal access token](../../../user/profile/personal_access_tokens.md)
  with the scope set to `api`.
- A [deploy token](../../project/deploy_tokens/index.md) with the scope set to
  `read_package_registry`, `write_package_registry`, or both.
- A [CI job token](#authenticate-with-a-ci-job-token).

### Authenticate with a personal access token or deploy token

To authenticate with a personal access token, create or edit the `~/.gem/credentials` file and add:

```ini
---
https://gitlab.example.com/api/v4/projects/<project_id>/packages/rubygems: '<your token>'
```

- `<your token>` must be the token value of either your personal access token or deploy token.
- Your project ID is on your project's home page.

### Authenticate with a CI job token

To work with RubyGems commands within [GitLab CI/CD](../../../ci/index.md),
you can use `CI_JOB_TOKEN` instead of a personal access token or deploy token.

For example:

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

You can also use `CI_JOB_TOKEN` in a `~/.gem/credentials` file that you check in to
GitLab:

```ini
---
https://gitlab.example.com/api/v4/projects/${env.CI_PROJECT_ID}/packages/rubygems: '${env.CI_JOB_TOKEN}'
```

## Push a Ruby gem

Prerequisites:

- You must [authenticate to the Package Registry](#authenticate-to-the-package-registry).
- The maximum allowed gem size is 3 GB.

To push your gem, run a command like this one:

```shell
gem push my_gem-0.0.1.gem --host <host>
```

Note that `<host>` is the URL you used when setting up authentication. For example:

```shell
gem push my_gem-0.0.1.gem --host https://gitlab.example.com/api/v4/projects/1/packages/rubygems
```

This message indicates that the gem uploaded successfully:

```plaintext
Pushing gem to https://gitlab.example.com/api/v4/projects/1/packages/rubygems...
{"message":"201 Created"}
```

To view the published gem, go to your project's **Packages & Registries** page. Gems pushed to
GitLab aren't displayed in your project's Packages UI immediately. It can take up to 10 minutes to
process a gem.

### Pushing gems with the same name or version

You can push a gem if a package of the same name and version already exists.
Both are visible and accessible in the UI. However, only the most recently
pushed gem is used for installs.

## Install a Ruby gem

The Ruby gems registry for GitLab is under development, and isn't ready for production use. You
cannot install Gems from the registry. However, you can download `.gem` files directly from the UI
or by using the [API](../../../api/packages/rubygems.md#download-a-gem-file).
