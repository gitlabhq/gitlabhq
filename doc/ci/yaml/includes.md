---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# GitLab CI/CD include examples **(FREE)**

You can use [`include`](index.md#include) to include external YAML files in your CI/CD jobs.

## Include a single configuration file

To include a single configuration file, use either of these syntax options:

- `include` by itself with a single file, which is the same as
  [`include:local`](index.md#includelocal):

  ```yaml
  include: '/templates/.after-script-template.yml'
  ```

- `include` with a single file, and you specify the `include` type:

  ```yaml
  include:
    remote: 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
  ```

## Include an array of configuration files

You can include an array of configuration files:

- If you do not specify an `include` type, the type defaults to [`include:local`](index.md#includelocal):

  ```yaml
  include:
    - 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
    - '/templates/.after-script-template.yml'
  ```

- You can define a single item array:

  ```yaml
  include:
    - remote: 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
  ```

- You can define an array and explicitly specify multiple `include` types:

  ```yaml
  include:
    - remote: 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
    - local: '/templates/.after-script-template.yml'
    - template: Auto-DevOps.gitlab-ci.yml
  ```

- You can define an array that combines both default and specific `include` type:

  ```yaml
  include:
    - 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
    - '/templates/.after-script-template.yml'
    - template: Auto-DevOps.gitlab-ci.yml
    - project: 'my-group/my-project'
      ref: main
      file: '/templates/.gitlab-ci-template.yml'
  ```

## Use `default` configuration from an included configuration file

You can define a [`default`](index.md#custom-default-keyword-values) section in a
configuration file. When you use a `default` section with the `include` keyword, the defaults apply to
all jobs in the pipeline.

For example, you can use a `default` section with [`before_script`](index.md#before_script).

Content of a custom configuration file named `/templates/.before-script-template.yml`:

```yaml
default:
  before_script:
    - apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs
    - gem install bundler --no-document
    - bundle install --jobs $(nproc)  "${FLAGS[@]}"
```

Content of `.gitlab-ci.yml`:

```yaml
include: '/templates/.before-script-template.yml'

rspec1:
  script:
    - bundle exec rspec

rspec2:
  script:
    - bundle exec rspec
```

The default `before_script` commands execute in both `rspec` jobs, before the `script` commands.

## Override included configuration values

When you use the `include` keyword, you can override the included configuration values to adapt them
to your pipeline requirements.

The following example shows an `include` file that is customized in the
`.gitlab-ci.yml` file. Specific YAML-defined variables and details of the
`production` job are overridden.

Content of a custom configuration file named `autodevops-template.yml`:

```yaml
variables:
  POSTGRES_USER: user
  POSTGRES_PASSWORD: testing_password
  POSTGRES_DB: $CI_ENVIRONMENT_SLUG

production:
  stage: production
  script:
    - install_dependencies
    - deploy
  environment:
    name: production
    url: https://$CI_PROJECT_PATH_SLUG.$KUBE_INGRESS_BASE_DOMAIN
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

Content of `.gitlab-ci.yml`:

```yaml
include: 'https://company.com/autodevops-template.yml'

image: alpine:latest

variables:
  POSTGRES_USER: root
  POSTGRES_PASSWORD: secure_password

stages:
  - build
  - test
  - production

production:
  environment:
    url: https://domain.com
```

The `POSTGRES_USER` and `POSTGRES_PASSWORD` variables
and the `environment:url` of the `production` job defined in the `.gitlab-ci.yml` file
override the values defined in the `autodevops-template.yml` file. The other keywords
do not change. This method is called *merging*.

## Override included configuration arrays

You can use merging to extend and override configuration in an included template, but
you cannot add or modify individual items in an array. For example, to add
an additional `notify_owner` command to the extended `production` job's `script` array:

Content of `autodevops-template.yml`:

```yaml
production:
  stage: production
  script:
    - install_dependencies
    - deploy
```

Content of `.gitlab-ci.yml`:

```yaml
include: 'autodevops-template.yml'

stages:
  - production

production:
  script:
    - install_dependencies
    - deploy
    - notify_owner
```

If `install_dependencies` and `deploy` are not repeated in
the `.gitlab-ci.yml` file, the `production` job would have only `notify_owner` in the script.

## Use nested includes

You can nest `include` sections in configuration files that are then included
in another configuration. For example, for `include` keywords nested three deep:

Content of `.gitlab-ci.yml`:

```yaml
include:
  - local: /.gitlab-ci/another-config.yml
```

Content of `/.gitlab-ci/another-config.yml`:

```yaml
include:
  - local: /.gitlab-ci/config-defaults.yml
```

Content of `/.gitlab-ci/config-defaults.yml`:

```yaml
default:
  after_script:
    - echo "Job complete."
```
