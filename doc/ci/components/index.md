---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# CI/CD components **(FREE ALL BETA)**

> - Introduced as an [experimental feature](../../policy/experiment-beta-support.md) in GitLab 16.0, [with a flag](../../administration/feature_flags.md) named `ci_namespace_catalog_experimental`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/groups/gitlab-org/-/epics/9897) in GitLab 16.2.
> - [Feature flag `ci_namespace_catalog_experimental` removed](https://gitlab.com/gitlab-org/gitlab/-/issues/394772) in GitLab 16.3.
> - [Moved](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/130824) to [Beta status](../../policy/experiment-beta-support.md) in GitLab 16.6.

A CI/CD component is a reusable single pipeline configuration unit. Use them to compose an entire pipeline configuration or a small part of a larger pipeline.

A component can optionally take [input parameters](../yaml/inputs.md).

CI/CD components are similar to the other kinds of [configuration added with the `include` keyword](../yaml/includes.md), but have several advantages:

- Components can be released and used with a specific version.
- Multiple components can be combined in the same project and released with a single tag.
- Components are discoverable in the [CI/CD Catalog](catalog.md).

## Components repository

A components repository is a GitLab project with a repository that hosts one or more pipeline components. All components in the project are versioned and released together.

If a component requires different versioning from other components, the component should be migrated to its own components repository.

One component repository can have a maximum of 10 components.

## Create a components repository

To create a components repository, you must:

1. [Create a new project](../../user/project/index.md#create-a-blank-project) with a `README.md` file.
1. Add a YAML configuration file for each component, following the [required directory structure](#directory-structure).

   For example:

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
│   └── secret-detection.yml
├── README.md
└── .gitlab-ci.yml
```

This example component could be referenced with a path similar to `gitlab.com/my-namespace/my-project/secret-detection@<version>`,
if the project is:

- On GitLab.com
- Named `my-project`
- In a personal namespace or group named `my-namespace`

The templates directory and the suffix of the configuration file should be excluded from the referenced path.

If the project contains multiple components, then the file structure should be similar to:

```plaintext
├── README.md
├── .gitlab-ci.yml
└── templates/
    ├── all-scans.yml
    └── secret-detection.yml
```

These components would be referenced with these paths:

- `gitlab.com/my-namespace/my-project/all-scans@<version>`
- `gitlab.com/my-namespace/my-project/secret-detection@<version>`

You can also have components defined as a directory if you want to bundle together multiple related files.
In this case GitLab expects a `template.yml` file to be present:

For example:

```plaintext
├── README.md
├── .gitlab-ci.yml
└── templates/
    └── dast
        ├── docs.md
        ├── Dockerfile
        └── template.yml
```

In this example, the component could be referenced with `gitlab.com/my-namespace/my-project/dast@<version>`.

#### Component configurations saved in any directory (deprecated)

WARNING:
Saving component configurations through this directory structure is [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/415855) and should be avoided.

Components configurations can be saved through the following directory structure, containing:

- `template.yml`: The component configuration, one file per component. If there is
  only one component, this file can be in the root of the project. If there are multiple
  components, each file must be in a separate subdirectory.
- `README.md`: A documentation file explaining the details of all the components in the repository.

For example, if the project is on GitLab.com, named `my-project`, and in a personal
namespace named `my-namespace`:

- Containing a single component and a simple pipeline to test the component, then
  the file structure might be:

  ```plaintext
  ├── template.yml
  ├── README.md
  └── .gitlab-ci.yml
  ```

  The `.gitlab-ci.yml` file is not required for a CI/CD component to work, but
  [testing the component](#test-the-component) in a pipeline in the project is recommended.

  This component is referenced with the path `gitlab.com/my-namespace/my-project@<version>`.

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

  - `gitlab.com/my-namespace/my-project`
  - `gitlab.com/my-namespace/my-project/unit`
  - `gitlab.com/my-namespace/my-project/integration`

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

## Release a component

To create a release for a CI/CD component, use the [`release`](../yaml/index.md#release)
keyword in a CI/CD pipeline.

For example:

```yaml
create-release:
  stage: deploy
  image: registry.gitlab.com/gitlab-org/release-cli:latest
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+/
  script: echo "Creating release $CI_COMMIT_TAG"
  release:
    tag_name: $CI_COMMIT_TAG
    description: "Release $CI_COMMIT_TAG of components repository $CI_PROJECT_PATH"
```

In this example, the job runs only for tags formatted as `v` + version number.
If all previous jobs succeed, the release is created.

Like in the [component testing example](#test-the-component), you can set a component to automatically
be released after all tests pass in pipelines for new tags.

All released versions of the components repositories are displayed in the [CI/CD Catalog](catalog.md),
providing users with information about official releases.

Components [can be used](#use-a-component-in-a-cicd-configuration) without being released,
by using the commit SHA or ref. However, the `~latest` version keyword can only be used with released tags.

## Use a component in a CI/CD configuration

You can add a component to a CI/CD configuration with the `include: component` keyword.
For example:

```yaml
include:
  - component: gitlab.example.com/my-namespace/my-project@1.0
    inputs:
      stage: build
```

The component is identified by a unique address in the form `<fully-qualified-domain-name>/<component-path>@<specific-version>`,
where:

- `<fully-qualified-domain-name>` matches the GitLab host. You can only reference components
  in the same GitLab instance as your project.
- `<component-path>` is the component project's full path and directory where the
  component YAML file is located.
- `<specific-version>` is the version of the component. In order of highest priority first,
  the version can be:
  - A branch name, for example `main`.
  - A commit SHA, for example `e3262fdd0914fa823210cdb79a8c421e2cef79d8`.
  - A tag, for example: `1.0`. If a tag and branch exist with the same name, the tag
    takes precedence over the branch. If a tag and commit SHA exist with the same name,
    the commit SHA takes precedence over the tag.
  - `~latest`, which is a special version that always points to the most recent released tag.
    Available only if the component has been [released](#release-a-component).

For example, for a component repository located at `gitlab-org/dast` on `gitlab.com`,
the path:

- `gitlab.com/gitlab-org/dast@main` targets the `template.yml` in the root directory
  on the `main` branch.
- `gitlab.com/gitlab-org/dast@e3262fdd0914fa823210cdb79a8c421e2cef79d8` targets the same file
  for the specified commit SHA.
- `gitlab.com/gitlab-org/dast@1.0` targets the same file for the `1.0` tag.
- `gitlab.com/gitlab-org/dast@~latest` targets the same file for the latest release.
- `gitlab.com/gitlab-org/dast/api-scan@main` targets a different file, the `template.yml`
  in the `/api-scan` directory in the component repository, for the `main` branch.

## Best practices

### Avoid using global keywords

Avoid using [global keywords](../yaml/index.md#global-keywords) in a component.
Using these keywords in a component affects all jobs in a pipeline, including jobs
directly defined in the main `.gitlab-ci.yml` or in other included components.

As an alternative to global keywords, instead:

- Add the configuration directly to each job, even if it creates some duplication
  in the component configuration.
- Use the [`extends`](../yaml/index.md#extends) keyword in the component.

For example, using the `default` keyword is not recommended:

```yaml
# Not recommended
default:
  image: ruby:3.0

rspec-1:
  script: bundle exec rspec dir1/

rspec-2:
  script: bundle exec rspec dir2/
```

Instead, you can:

- Add the configuration to each job:

  ```yaml
  rspec-1:
    image: ruby:3.0
    script: bundle exec rspec dir1/

  rspec-2:
    image: ruby:3.0
    script: bundle exec rspec dir2/
  ```

- Use `extends` to reuse configuration:

  ```yaml
  .rspec-image:
    image: ruby:3.0

  rspec-1:
    extends:
      - .rspec-image
    script: bundle exec rspec dir1/

  rspec-2:
    extends:
      - .rspec-image
    script: bundle exec rspec dir2/
  ```

### Replace hard-coded values with inputs

Avoid hard-coding values in CI/CD components. Hard-coded values might force
component users to need to review the component's internal details and adapt their pipeline
to work with the component.

A common keyword with problematic hard-coded values is `stage`. If a component job's
stage is set to a specific value, the pipeline using the component **must** define
the exact same stage. Additionally, if the component user wants to use a different stage,
they must [override](../yaml/includes.md#override-included-configuration-values) the configuration.

The preferred method is to use the [`input` keyword](../yaml/inputs.md).
The component user can specify the exact value they need.

For example:

- In the component configuration:

  ```yaml
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

- In the project using the component:

  ```yaml
  include:
    - component: gitlab.com/gitlab-org/ruby-test@1.0
      inputs:
        stage: verify

  stages: [verify, deploy]
  ```

### Replace custom CI/CD variables with inputs

When using CI/CD variables in a component, evaluate if the `inputs` keyword
should be used instead. Avoid requiring a user to define custom variables to change a component's
behavior. You should try to use `inputs` for any component customization.

Inputs are explicitly defined in the component's specs, and are better validated than variables.
For example, if a required input is not passed to the component, GitLab returns a pipeline error.
By contrast, if a variable is not defined, its value is empty, and there is no error.

For example, use `inputs` instead of variables to let users change a scanner's output format:

- In the component configuration:

  ```yaml
  spec:
    inputs:
      scanner-output:
        default: json
  ---
  my-scanner:
    script: my-scan --output $[[ inputs.scanner-output ]]
  ```

- In the project using the component:

  ```yaml
  include:
    - component: gitlab.example.com/my-scanner@1.0
      inputs:
        scanner-output: yaml
  ```

In other cases, CI/CD variables are still preferred, including:

- Using [predefined variables](../variables/predefined_variables.md) to automatically configure
  a component to match a user's project.
- Requiring tokens or other sensitive values to be stored as [masked or protected variables in project settings](../variables/index.md#define-a-cicd-variable-in-the-ui).

### Use semantic versioning

When tagging and releasing new versions of components, you should use [semantic versioning](https://semver.org).
Semantic versioning is the standard for communicating that a change is a major, minor, patch,
or other kind of change.

You should use at least the `major.minor` format, as this is widely understood. For example,
`2.0` or `2.1`.

Other examples of semantic versioning:

- `1.0.0`
- `2.1.3`
- `1.0.0-alpha`
- `3.0.0-rc1`

### Test the component

Testing CI/CD components as part of the development workflow is strongly recommended
and helps ensure consistent behavior.

Test changes in a CI/CD pipeline (like any other project) by creating a `.gitlab-ci.yml`
in the root directory.

For example:

```yaml
include:
  # include the component located in the current project from the current SHA
  - component: gitlab.com/$CI_PROJECT_PATH/my-project@$CI_COMMIT_SHA
    inputs:
      stage: build

stages: [build, test, release]

# Expect `component-job` is added.
# This example tests that the included component works as expected.
# You can inspect data generated by the component, use GitLab API endpoints or third-party tools.
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

After committing and pushing changes, the pipeline tests the component, then releases it if the test passes.

## Convert a CI/CD template to a component

Any existing CI/CD template that you use in projects by using the `include:` syntax
can be converted to a CI/CD component:

1. Decide if you want the component to be part of an existing [components repository](index.md#components-repository)
   to be grouped with other components, or create and set up a new components repository.
1. Create a YAML file in the components repository according to the expected [directory structure](index.md#directory-structure).
1. Copy the content of the original template YAML file into the new component YAML file.
1. Refactor the new component's configuration to:
   - Follow the [best practices](index.md#best-practices) for components.
   - Improve the configuration, for example by enabling [merge request pipelines](../pipelines/merge_request_pipelines.md)
     or making it [more efficient](../pipelines/pipeline_efficiency.md).
1. Leverage the `.gitlab-ci.yml` in the components repository to [test changes to the component](index.md#test-the-component).
1. Tag and [release the component](index.md#release-a-component).
