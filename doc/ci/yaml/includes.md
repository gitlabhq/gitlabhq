---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference
---

# Use CI/CD configuration from other files **(FREE)**

You can use [`include`](index.md#include) to include external YAML files in your CI/CD jobs.

## Include a single configuration file

To include a single configuration file, use either of these syntax options:

- `include` by itself with a single file. If this is a local file, it is the same as [`include:local`](index.md#includelocal).
  If this is a remote file, it is the same as [`include:remote`](index.md#includeremote).

  ```yaml
  include: '/templates/.after-script-template.yml'
  ```

## Include an array of configuration files

You can include an array of configuration files:

- If you do not specify an `include` type, each array item defaults to [`include:local`](index.md#includelocal)
  or [`include:remote`](index.md#includeremote), as needed:

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

- You can define an array that combines both default and specific `include` types:

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

You can define a [`default`](index.md#default) section in a
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

### Merge method for `include`

The `include` configuration merges with the main configuration file with this process:

- Included files are read in the order defined in the configuration file, and
  the included configuration is merged together in the same order.
- If an included file also uses `include`, that nested `include` configuration is merged first (recursively).
- If parameters overlap, the last included file takes precedence when merging the configuration
  from the included files.
- After all configuration added with `include` is merged together, the main configuration
  is merged with the included configuration.

This merge method is a _deep merge_, where hash maps are merged at any depth in the
configuration. To merge hash map "A" (that contains the configuration merged so far) and "B" (the next piece
of configuration), the keys and values are processed as follows:

- When the key only exists in A, use the key and value from A.
- When the key exists in both A and B, and their values are both hash maps, merge those hash maps.
- When the key exists in both A and B, and one of the values is not a hash map, use the value from B.
- Otherwise, use the key and value from B.

For example, with a configuration that consists of two files:

- The `.gitlab-ci.yml` file:

  ```yaml
  include: 'common.yml'

  variables:
    POSTGRES_USER: username

  test:
    rules:
      - if: $CI_PIPELINE_SOURCE == "merge_request_event"
        when: manual
    artifacts:
      reports:
        junit: rspec.xml
  ```

- The `common.yml` file:

  ```yaml
  variables:
    POSTGRES_USER: common_username
    POSTGRES_PASSWORD: testing_password

  test:
    rules:
      - when: never
    script:
      - echo LOGIN=${POSTGRES_USER} > deploy.env
      - rake spec
    artifacts:
      reports:
        dotenv: deploy.env
  ```

The merged result is:

```yaml
variables:
  POSTGRES_USER: username
  POSTGRES_PASSWORD: testing_password

test:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: manual
  script:
    - echo LOGIN=${POSTGRES_USER} > deploy.env
    - rake spec
  artifacts:
    reports:
      junit: rspec.xml
      dotenv: deploy.env
```

In this example:

- Variables are only evaluated after all the files are merged together. A job in an included file
  might end up using a variable value defined in a different file.
- `rules` is an array so it cannot be merged. The top-level file takes precedence.
- `artifacts` is a hash map so it can be deep merged.

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

### Use nested includes with duplicate `includes` entries

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/28987) in GitLab 14.8

Nested includes can include the same configuration file. The duplicate configuration
file is included multiple times, but the effect is the same as if it was only
included once.

For example, with the following nested includes, where `defaults.gitlab-ci.yml`
is included multiple times:

- Contents of the `.gitlab-ci.yml` file:

  ```yaml
  include:
    - template: defaults.gitlab-ci.yml
    - local: unit-tests.gitlab-ci.yml
    - local: smoke-tests.gitlab-ci.yml
  ```

- Contents of the `defaults.gitlab-ci.yml` file:

  ```yaml
  default:
    before_script: default-before-script.sh
    retry: 2
  ```

- Contents of the `unit-tests.gitlab-ci.yml` file:

  ```yaml
  include:
    - template: defaults.gitlab-ci.yml

  unit-test-job:
    script: unit-test.sh
    retry: 0
  ```

- Contents of the `smoke-tests.gitlab-ci.yml` file:

  ```yaml
  include:
    - template: defaults.gitlab-ci.yml

  smoke-test-job:
    script: smoke-test.sh
  ```

The final configuration would be:

```yaml
unit-test-job:
  before_script: default-before-script.sh
  script: unit-test.sh
  retry: 0

smoke-test-job:
  before_script: default-before-script.sh
  script: smoke-test.sh
  retry: 2
```

## Use variables with `include`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/284883) in GitLab 13.8.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/294294) in GitLab 13.9.
> - [Support for project, group, and instance variables added](https://gitlab.com/gitlab-org/gitlab/-/issues/219065) in GitLab 14.2.
> - [Support for pipeline variables added](https://gitlab.com/gitlab-org/gitlab/-/issues/337633) in GitLab 14.5.

In `include` sections in your `.gitlab-ci.yml` file, you can use:

- [Project variables](../variables/index.md#for-a-project).
- [Group variables](../variables/index.md#for-a-group).
- [Instance variables](../variables/index.md#for-an-instance).
- Project [predefined variables](../variables/predefined_variables.md) (`CI_PROJECT_*`).
- In GitLab 14.2 and later, the `$CI_COMMIT_REF_NAME` [predefined variable](../variables/predefined_variables.md).

  When used in `include`, the `CI_COMMIT_REF_NAME` variable returns the full
  ref path, like `refs/heads/branch-name`. In `include:rules`, you might need to use
  `if: $CI_COMMIT_REF_NAME =~ /main/` (not `== main`). This behavior is resolved in GitLab 14.5.

In GitLab 14.5 and later, you can also use:

- [Trigger variables](../triggers/index.md#pass-cicd-variables-in-the-api-call).
- [Scheduled pipeline variables](../pipelines/schedules.md#add-a-pipeline-schedule).
- [Manual pipeline run variables](../pipelines/index.md#run-a-pipeline-manually).
- The `CI_PIPELINE_SOURCE` and `CI_PIPELINE_TRIGGERED` [predefined variables](../variables/predefined_variables.md).

For example:

```yaml
include:
  project: '$CI_PROJECT_PATH'
  file: '.compliance-gitlab-ci.yml'
```

You cannot use variables defined in jobs, or in a global [`variables`](../yaml/index.md#variables)
section which defines the default variables for all jobs. Includes are evaluated before jobs,
so these variables cannot be used with `include`.

For an example of how you can include predefined variables, and the variables' impact on CI/CD jobs,
see this [CI/CD variable demo](https://youtu.be/4XR8gw3Pkos).

## Use `rules` with `include`

> - Introduced in GitLab 14.2 [with a flag](../../administration/feature_flags.md) named `ci_include_rules`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/337507) in GitLab 14.3.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/337507) in GitLab 14.4. Feature flag `ci_include_rules` removed.
> - Support for `exists` keyword [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/341511) in GitLab 14.5.
> - Support for `needs` job dependency [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/345377) in GitLab 15.11.

You can use [`rules`](index.md#rules) with `include` to conditionally include other configuration files.

You can only use `rules` with [certain variables](#use-variables-with-include), and
these keywords:

- [`rules:if`](index.md#rulesif).
- [`rules:exists`](index.md#rulesexists).

### `include` with `rules:if`

Use [`rules:if`](index.md#rulesif) to conditionally include other configuration files
based on the status of CI/CD variables. For example:

```yaml
include:
  - local: builds.yml
    rules:
      - if: $INCLUDE_BUILDS == "true"
  - local: deploys.yml
    rules:
      - if: $CI_COMMIT_BRANCH == "main"

test:
  stage: test
  script: exit 0
```

### `include` with `rules:exists`

Use [`rules:exists`](index.md#rulesexists) to conditionally include other configuration files
based on the existence of files. For example:

```yaml
include:
  - local: builds.yml
    rules:
      - exists:
          - file.md

test:
  stage: test
  script: exit 0
```

In this example, GitLab checks for the existence of `file.md` in the current project.

There is a known issue if you configure `include` with `rules:exists` to add a configuration file
from a different project. GitLab checks for the existence of the file in the _other_ project.
For example:

```yaml
include:
- project: my-group/my-project-2
  ref: main
  file: test-file.yml
  rules:
    - exists:
        - file.md

test:
  stage: test
  script: exit 0
```

In this example, GitLab checks for the existence of `test-file.yml` in `my-group/my-project-2`,
not the current project. Follow [issue 386040](https://gitlab.com/gitlab-org/gitlab/-/issues/386040)
for information about work to improve this behavior.

## Use `include:local` with wildcard file paths

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/25921) in GitLab 13.11.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/327315) in GitLab 14.2.

You can use wildcard paths (`*` and `**`) with `include:local`.

Example:

```yaml
include: 'configs/*.yml'
```

When the pipeline runs, GitLab:

- Adds all `.yml` files in the `configs` directory into the pipeline configuration.
- Does not add `.yml` files in subfolders of the `configs` directory. To allow this,
  add the following configuration:

  ```yaml
  # This matches all `.yml` files in `configs` and any subfolder in it.
  include: 'configs/**.yml'

  # This matches all `.yml` files only in subfolders of `configs`.
  include: 'configs/**/*.yml'
  ```

## Define inputs for configuration added with `include` (Beta)

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/391331) in GitLab 15.11 as a Beta feature.

FLAG:
`spec` and `with` are experimental [Open Beta features](../../policy/alpha-beta-support.md#beta)
and subject to change without notice.

### Define input parameters with `spec:inputs`

Use `spec:inputs` to define input parameters for CI/CD configuration intended to be added
to a pipeline with `include`. Use [`include:inputs`](#set-input-parameter-values-with-includeinputs)
to define the values to use when the pipeline runs.

The specs must be declared at the top of the configuration file, in a header section.
Separate the header from the rest of the configuration with `---`.

Use the interpolation format `$[[ input.input-id ]]` to reference the values outside of the header section.
The inputs are evaluated and interpolated once, when the configuration is fetched
during pipeline creation, but before the configuration is merged with the contents of the `.gitlab-ci.yml`.

```yaml
spec:
  inputs:
    environment:
    job-stage:
---

scan-website:
  stage: $[[ inputs.job-stage ]]
  script: ./scan-website $[[ inputs.environment ]]
```

When using `spec:inputs`:

- Defined inputs are mandatory by default.
- Inputs can be made optional by specifying a `default`. Use `default: null` to have no default value.
- A string containing an interpolation block must not exceed 1 MB.
- The string inside an interpolation block must not exceed 1 KB.

For example, a `custom_configuration.yml`:

```yaml
spec:
  inputs:
    website:
    user:
      default: 'test-user'
    flags:
      default: null
---

# The pipeline configuration would follow...
```

In this example:

- `website` is mandatory and must be defined.
- `user` is optional. If not defined, the value is `test-user`.
- `flags` is optional. If not defined, it has no value.

### Set input parameter values with `include:inputs`

> `include:with` [renamed to `include:inputs`](https://gitlab.com/gitlab-org/gitlab/-/issues/406780) in GitLab 16.0.

Use `include:inputs` to set the values for the parameters when the included configuration
is added to the pipeline.

For example, to include a `custom_configuration.yml` that has the same specs
as the [example above](#define-input-parameters-with-specinputs):

```yaml
include:
  - local: 'custom_configuration.yml'
    inputs:
      website: "My website"
```

In this example:

- `website` has a value of `My website` for the included configuration.
- `user` has a value of `test-user`, because that is the default when not specified.
- `flags` has no value, because it is optional and has no default when not specified.

## Troubleshooting

### `Maximum of 150 nested includes are allowed!` error

The maximum number of [nested included files](#use-nested-includes) for a pipeline is 150.
If you receive the `Maximum 150 includes are allowed` error message in your pipeline,
it's likely that either:

- Some of the nested configuration includes an overly large number of additional nested `include` configuration.
- There is an accidental loop in the nested includes. For example, `include1.yml` includes
  `include2.yml` which includes `include1.yml`, creating a recursive loop.

To help reduce the risk of this happening, edit the pipeline configuration file
with the [pipeline editor](../pipeline_editor/index.md), which validates if the
limit is reached. You can remove one included file at a time to try to narrow down
which configuration file is the source of the loop or excessive included files.

In [GitLab 16.0 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/207270) self-managed users can
change the [maximum includes](../../user/admin_area/settings/continuous_integration.md#maximum-includes) value.
