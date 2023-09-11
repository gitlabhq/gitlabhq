---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# CI/CD Components **(FREE ALL EXPERIMENT)**

> - Introduced as an [experimental feature](../../policy/experiment-beta-support.md) in GitLab 16.0, [with a flag](../../administration/feature_flags.md) named `ci_namespace_catalog_experimental`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/groups/gitlab-org/-/epics/9897) in GitLab 16.2.
> - [Feature flag `ci_namespace_catalog_experimental` removed](https://gitlab.com/gitlab-org/gitlab/-/issues/394772) in GitLab 16.3.

This feature is an experimental feature and [an epic exists](https://gitlab.com/groups/gitlab-org/-/epics/9897)
to track future work. Tell us about your use case by leaving comments in the epic.

## Components Repository

A components repository is a GitLab project with a repository that hosts one or more pipeline components. A pipeline component is a reusable single pipeline configuration unit. You can use them to compose an entire pipeline configuration or a small part of a larger pipeline. It can optionally take [input parameters](../yaml/includes.md#define-input-parameters-with-specinputs).

### Create a components repository

To create a components repository, you must:

1. [Create a new project](../../user/project/index.md#create-a-blank-project) with a `README.md` file.

1. Create a `template.yml` file inside the project's root directory that contains the configuration you want to provide as a component. For example:

   ```yaml
   spec:
     inputs:
       stage:
         default: test
   ---
   component-job:
     script: echo job 1
     stage: $[[ inputs.stage ]]
   ```

### Directory structure

A components repository can host one or more components, and must follow a mandatory file structure.

Component configurations can be saved through the following directory structure, containing:

- A `templates` directory at the top level of your components repository. All component configuration files
  should be saved under this directory.
- Files ending in `.yml` containing the component configurations, one file per component.
- A Markdown `README.md` file explaining the details of all the components in the repository.

For example, if the project contains a single component and a pipeline to test the component,
the file structure should be similar to:

```plaintext
├── templates/
│   └── only_template.yml
├── README.md
└── .gitlab-ci.yml
```

This example component could be referenced with a path similar to `gitlab.com/my-username/my-component/only_template@<version>`,
if the project is:

- On GitLab.com
- Named `my-component`
- In a personal namespace named `my-username`

The templates directory and the suffix of the configuration file should be excluded from the referenced path.

If the project contains multiple components, then the file structure should be similar to:

```plaintext
├── README.md
├── .gitlab-ci.yml
└── templates/
    └── all-scans.yml
    └── secret-detection.yml
```

These components would be referenced with these paths:

- `gitlab.com/my-username/my-component/all-scans`
- `gitlab.com/my-username/my-component/secret-detection`

You can omit the filename in the path if the configuration file is named `template.yml`.
For example, the following component could be referenced with `gitlab.com/my-username/my-component/dast`:

```plaintext
├── README.md
├── .gitlab-ci.yml
├── templates/
│   └── dast
│       └── template.yml
```

#### Component configurations saved in any directory (deprecated)

NOTE:
Saving component configurations through this directory structure is [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/415855).

Components configurations can be saved through the following directory structure, containing:

- `template.yml`: The component configuration, one file per component. If there is
  only one component, this file can be in the root of the project. If there are multiple
  components, each file must be in a separate subdirectory.
- `README.md`: A documentation file explaining the details of all the components in the repository.

For example, if the project is on GitLab.com, named `my-component`, and in a personal
namespace named `my-username`:

- Containing a single component and a simple pipeline to test the component, then
  the file structure might be:

  ```plaintext
  ├── template.yml
  ├── README.md
  └── .gitlab-ci.yml
  ```

  The `.gitlab-ci.yml` file is not required for a CI/CD component to work, but [testing the component](#test-a-component)
  in a pipeline in the project is recommended.

  This component is referenced with the path `gitlab.com/my-username/my-component@<version>`.

- Containing one default component and multiple sub-components, then the file structure
  might be:

  ```plaintext
  ├── template.yml
  ├── README.md
  ├── .gitlab-ci.yml
  ├── unit/
  │   └── template.yml
  └── integration/
      └── template.yml
  ```

  These components are identified by these paths:

  - `gitlab.com/my-username/my-component`
  - `gitlab.com/my-username/my-component/unit`
  - `gitlab.com/my-username/my-component/integration`

It is possible to have a components repository with no default component, by having
no `template.yml` in the root directory.

**Additional notes:**

Nesting of components is not possible. For example:

```plaintext
├── unit/
│   └── template.yml
│   └── another_folder/
│       └── nested_template.yml
```

### Test a component

Testing CI/CD components as part of the development workflow is strongly recommended and helps ensure consistent behavior.

Test changes in a CI/CD pipeline like any other project, by creating a `.gitlab-ci.yml` file in the root directory of the component repository.

For example:

```yaml
include:
  # include the component located in the current project from the current SHA
  - component: gitlab.com/$CI_PROJECT_PATH@$CI_COMMIT_SHA
    inputs:
      stage: build

stages: [build, test, release]

# Expect `component-job` is added.
# This is an example of testing that the included component works as expected.
# You can leverage GitLab API endpoints or 3rd party tools to inspect data generated by the component.
ensure-job-added:
  stage: test
  image: badouralix/curl-jq
  script:
    - |
      route="https://gitlab.com/api/v4/projects/$CI_PROJECT_ID/pipelines/$CI_PIPELINE_ID/jobs"
      count=`curl --silent --header "PRIVATE-TOKEN: $API_TOKEN" $route | jq 'map(select(.name | contains("component-job"))) | length'`
      if [ "$count" != "1" ]; then
        exit 1
      fi

# If we are tagging a release with a specific convention ("v" + number) and all
# previous checks succeeded, we proceed with creating a release automatically.
create-release:
  stage: release
  image: registry.gitlab.com/gitlab-org/release-cli:latest
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+/
  script: echo "Creating release $CI_COMMIT_TAG"
  release:
    tag_name: $CI_COMMIT_TAG
    description: "Release $CI_COMMIT_TAG of components repository $CI_PROJECT_PATH"
```

After committing and pushing changes, the pipeline tests the component then releases it if the test passes.

### Release a component

To create a release for a CI/CD component, you can use:

- The [`release`](../yaml/index.md#release) keyword in a CI/CD pipeline.
- The [UI for creating a release](../../user/project/releases/index.md#create-a-release).

Like in the [example above](#test-a-component), after all tests pass in a pipeline running for a tag ref, we can release a new version of the components repository.

All released versions of the components repository are displayed in the Components Catalog page for the given resource, providing users with information about official releases.

Components [can be used](#use-a-component-in-a-cicd-configuration) without being released, but only with a commit SHA or a branch name. To enable the use of tags or the `~latest` version keyword, you must create a release.

### Use a component in a CI/CD configuration

A pipeline component is identified by a unique address in the form `<fully-qualified-doman-name>/<component-path>@<version>`
containing:

- **A fully qualified domain name (FQDN)**: The FQDN must match the GitLab host.
- **A specific version**: The version of the component can be (in order of highest priority first):
  - A commit SHA, for example `gitlab.com/gitlab-org/dast@e3262fdd0914fa823210cdb79a8c421e2cef79d8`.
  - A tag. for example: `gitlab.com/gitlab-org/dast@1.0`.
  - `~latest`, which is a special version that always points to the most recent released tag,
     for example `gitlab.com/gitlab-org/dast@~latest`.
  - A branch name, for example `gitlab.com/gitlab-org/dast@main`.
- **A component path**: Contains the project's full path and the directory where the component YAML file `template.yml` is located.

For example, for a component repository located at `gitlab-org/dast` on `gitlab.com`:

- The path `gitlab.com/gitlab-org/dast` tries to load the `template.yml` from the root directory.
- The path `gitlab.com/gitlab-org/dast/api-scan` tries to load the `template.yml` from the `/api-scan` directory.

**Additional notes:**

- You can only reference components in the same GitLab instance as your project.
- If a tag and branch exist with the same name, the tag takes precedence over the branch.
- If a tag is named the same as a commit SHA that exists, like `e3262fdd0914fa823210cdb79a8c421e2cef79d8`,
  the commit SHA takes precedence over the tag.

### Best practices

#### Avoid using global keywords

When using [global keywords](../yaml/index.md#global-keywords) all jobs in the
pipeline are affected. Using these keywords in a component affects all jobs in a
pipeline, whether they are directly defined in the main `.gitlab-ci.yml` or
in any included components.

To make the composition of pipelines more deterministic, either:

- Duplicate the default configuration for each job.
- Use [`extends`](../yaml/index.md#extends) feature within the component.

```yaml
##
# BAD
default:
  image: ruby:3.0

rspec:
  script: bundle exec rspec
```

```yaml
##
# GOOD
rspec:
  image: ruby:3.0
  script: bundle exec rspec
```

#### Replace hard-coded values with inputs

A typical hard-coded value found in CI templates is `stage:` value. Such hard coded values may force the user
of the component to know and adapt the pipeline to such implementation details.

For example, if `stage: test` is hard-coded for a job in a component, the pipeline using the component must
define the `test` stage. Additionally, if the user of the component want to customize the stage value it has
to override the configuration:

```yaml
##
# BAD: In order to use different stage name you need to override all the jobs
# included by the component.
include:
  - component: gitlab.com/gitlab-org/ruby-test@1.0

stages: [verify, deploy]

unit-test:
  stage: verify

integration-test:
  stage: verify
```

```yaml
##
# BAD: In order to use the component correctly you need to define the stage
# that is hard-coded in it.
include:
  - component: gitlab.com/gitlab-org/ruby-test@1.0

stages: [test, deploy]
```

To improve this we can use [input parameters](../yaml/includes.md#define-input-parameters-with-specinputs)
allowing the user of a component to inject values that can be customized:

```yaml
##
# GOOD: We don't need to know the implementation details of a component and instead we can
# rely on the inputs.
include:
  - component: gitlab.com/gitlab-org/ruby-test@1.0
    inputs:
      stage: verify

stages: [verify, deploy]

##
# inside the component's template.yml file:
spec:
  inputs:
    stage:
      default: test
---
unit-test:
  stage: $[[ inputs.stage ]]
  script: echo unit tests

integration-test:
  stage: $[[ inputs.stage ]]
  script: echo integration tests
```

#### Prefer inputs over variables

If variables are only used for YAML evaluation (for example `rules`) and not by the Runner
execution, it's advised to use inputs instead.
Inputs are explicitly defined in the component's contract and they are better validated
than variables.

For example, if a required input is not passed an error is returned as soon as the component
is being used. By contrast, if a variable is not defined, it's value is empty.

```yaml
##
# BAD: you need to configure an environment variable for a custom value that doesn't need
# to be used on the Runner 
unit-test:
  image: $MY_COMPONENT_X_IMAGE
  script: echo unit tests

integration-test:
  image: $MY_COMPONENT_X_IMAGE
  script: echo integration tests

##
# Usage:
include:
  - component: gitlab.com/gitlab-org/ruby-test@1.0

variables:
  MY_COMPONENT_X_IMAGE: ruby:3.2
```

```yaml
##
# GOOD: we define a customizable value and accept it as input
spec:
  inputs:
    image:
      default: ruby:3.0
---
unit-test:
  image: $[[ inputs.image ]]
  script: echo unit tests

integration-test:
  image: $[[ inputs.image ]]
  script: echo integration tests

##
# Usage:
include:
  - component: gitlab.com/gitlab-org/ruby-test@1.0
    inputs:
      image: ruby:3.2
```

#### Use semantic versioning

When tagging and releasing new versions of components we recommend using [semantic versioning](https://semver.org)
which is the standard for communicating bugfixes, minor and major or breaking changes.

We recommend adopting at least the `MAJOR.MINOR` format.

For example: `2.1`, `1.0.0`, `1.0.0-alpha`, `2.1.3`, `3.0.0-rc.1`.
