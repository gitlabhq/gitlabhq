---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# CI/CD components **(FREE ALL BETA)**

> - Introduced as an [experimental feature](../../policy/experiment-beta-support.md) in GitLab 16.0, [with a flag](../../administration/feature_flags.md) named `ci_namespace_catalog_experimental`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/groups/gitlab-org/-/epics/9897) in GitLab 16.2.
> - [Feature flag `ci_namespace_catalog_experimental` removed](https://gitlab.com/gitlab-org/gitlab/-/issues/394772) in GitLab 16.3.
> - [Moved](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/130824) to [Beta status](../../policy/experiment-beta-support.md) in GitLab 16.6.

A CI/CD component is a reusable single pipeline configuration unit. Use them to compose an entire pipeline configuration or a small part of a larger pipeline.

A component can take [input parameters](../yaml/inputs.md).

CI/CD components are similar to the other kinds of [configuration added with the `include` keyword](../yaml/includes.md), but have several advantages:

- Components can be released and used with a specific version.
- Multiple components can be defined in the same project and versioned together.
- Components are discoverable in the [CI/CD Catalog](#cicd-catalog).

## Component project

A component project is a GitLab project with a repository that hosts one or more components.
All components in the project are versioned together.

If a component requires different versioning from other components, the component should be moved
to a dedicated component project.

One component repository can have a maximum of 10 components.

### Create a component project

To create a component project, you must:

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

The repository must contain:

- A `README.md` Markdown file documenting the details of all the components in the repository.
- A top level `templates/` directory that contains all the component configurations.
  You can define components in this directory:
  - In single files ending in `.yml` for each component, like `templates/secret-detection.yml`.
  - In sub-directories containing `template.yml` files as entry points, for components
    that bundle together multiple related files. For example, `templates/secret-detection/template.yml`.

Configure the project's `.gitlab-ci.yml` to [test the components](#test-the-component)
and [release new versions](#publish-a-new-release).

For example, if the project contains a single component, the directory structure should be similar to:

```plaintext
├── templates/
│   └── secret-detection.yml
├── README.md
└── .gitlab-ci.yml
```

If the project contains multiple components, then the directory structure should be similar to:

```plaintext
├── templates/
│   ├── all-scans.yml
│   └── secret-detection/
│       ├── template.yml
│       ├── Dockerfile
│       └── test.sh
├── README.md
└── .gitlab-ci.yml
```

In this example:

- The `all-scans` component configuration is defined in a single file.
- The `secret-detection` component configuration contains multiple files in a directory.

#### Component configurations saved in any directory (deprecated)

WARNING:
Saving components through the following directory structure is [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/415855) and should be avoided.

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

## Use a component

You can use a component in a CI/CD configuration with the `include: component` keyword.
The component is identified by a unique address formatted as `<fully-qualified-domain-name>/<project-path>/<component-name>@<specific-version>`.

For example:

```yaml
include:
  - component: gitlab.example.com/my-org/security-components/secret-detection@1.0
    inputs:
      stage: build
```

In this example:

- `gitlab.example.com` is the Fully Qualified Domain Name (FQDN) matching the GitLab host.
  You can only reference components in the same GitLab instance as your project.
- `my-org/security-components` is the full path of the project containing the component.
- `secret-detection` is the component name that is defined as either a single file `templates/secret-detection.yml`
  or as a directory `templates/secret-detection/` containing a `template.yml`.
- `1.0` is the version of the component. In order of highest priority first,
  the version can be:
  - A branch name, for example `main`.
  - A commit SHA, for example `e3262fdd0914fa823210cdb79a8c421e2cef79d8`.
  - A tag, for example: `1.0`. If a tag and branch exist with the same name, the tag
    takes precedence over the branch. If a tag and commit SHA exist with the same name,
    the commit SHA takes precedence over the tag.
  - `~latest`, which is a special version that always points to the most recent
    [release published in the CI/CD Catalog](#publish-a-new-release).

NOTE:
The `~latest` version keyword always returns the most recent published release, not the release with
the latest semantic version. For example, if you first release `2.0.0`, and later release
a patch fix like `1.5.1`, then `~latest` returns the `1.5.1` release.
[Issue #427286](https://gitlab.com/gitlab-org/gitlab/-/issues/427286) proposes to
change this behavior.

## CI/CD Catalog **(FREE ALL BETA)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/407249) in GitLab 16.1 as an [experiment](../../policy/experiment-beta-support.md#experiment).
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/432045) to [beta](../../policy/experiment-beta-support.md#beta) in GitLab 16.7.

The CI/CD Catalog is a list of projects with published CI/CD components you can use to extend your CI/CD workflow.

Anyone can add a [component project](index.md#component-project) to the CI/CD Catalog, or contribute
to an existing project to improve the available components.

### View the CI/CD Catalog

To access the CI/CD Catalog and view the published components that are available to you:

1. On the left sidebar, select **Search or go to**.
1. Select **Explore**.
1. Select **CI/CD Catalog**.

Alternatively, if you are already in the [pipeline editor](../pipeline_editor/index.md)
in your project, you can select **Browse CI/CD Catalog**.

NOTE:
Only public and internal projects are discoverable in the CI/CD Catalog.

### Publish a component project

To publish a component project in the CI/CD catalog, you must:

1. Set the project as a catalog resource.
1. Publish a new release.

#### Set a component project as a catalog resource

To make published versions of a component project visible in the CI/CD catalog,
you must set the project as a catalog resource:

1. On the left sidebar, select **Search or go to** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Scroll down to **CI/CD Catalog resource** and select the toggle to mark the project as a catalog resource.

#### Publish a new release

Components defined in a [component project](#component-project) can be [used](#use-a-component)
immediately and don't require to be published in the CI/CD catalog. However, having the component
project published in the catalog makes it discoverable to other users.

After the project is set as a [catalog resource](#set-a-component-project-as-a-catalog-resource),
add a job to the project's `.gitlab-ci.yml` file that creates a release using the
[`release`](../yaml/index.md#release) keyword.

For example:

```yaml
create-release:
  stage: deploy
  image: registry.gitlab.com/gitlab-org/release-cli:latest
  script: echo "Creating release $CI_COMMIT_TAG"
  release:
    tag_name: $CI_COMMIT_TAG
    description: "Release $CI_COMMIT_TAG of components in $CI_PROJECT_PATH"
```

The release fails if the project is missing:

- The [project description](../../user/project/working_with_projects.md#edit-project-name-and-description),
  to display in the catalog list.
- A `README.md` file in the root directory for the commit SHA of the tag being released.
- Any component in the `templates/` directory for the commit SHA of the tag being released.

Create a [new tag](../../user/project/repository/tags/index.md#create-a-tag) for the release,
which should trigger a tag pipeline that contains the job responsible that creates the release.
You should configure the tag pipeline to [test the components](#test-the-component) before
running the release job.

The release is created and the new version is published to the CI/CD catalog only if:

- All jobs before the release job succeed.
- All component project [requirements](#directory-structure) are satisfied.
- The component project is [set as a catalog resource](#set-a-component-project-as-a-catalog-resource).

NOTE:
If you disable [catalog resource setting](#set-a-component-project-as-a-catalog-resource),
the component project and all versions are removed from the catalog. To publish it again,
you must re-enable the setting and release a new version.

## Best practices

This section describes some best practices for creating high quality component projects.

### Test the component

Testing CI/CD components as part of the development workflow is strongly recommended
and helps ensure consistent behavior.

Test changes in a CI/CD pipeline (like any other project) by creating a `.gitlab-ci.yml`
in the root directory. Make sure to test both the behavior and potential side-effects
of the component. You can use the [GitLab API](../../api/rest/index.md) if needed.

For example:

```yaml
include:
  # include the component located in the current project from the current SHA
  - component: gitlab.com/$CI_PROJECT_PATH/my-component@$CI_COMMIT_SHA
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

# If we are tagging a release with a semantic version and all previous checks succeeded,
# we proceed with creating a release automatically.
create-release:
  stage: release
  image: registry.gitlab.com/gitlab-org/release-cli:latest
  rules:
    - if: $CI_COMMIT_TAG =~ /\d+/
  script: echo "Creating release $CI_COMMIT_TAG"
  release:
    tag_name: $CI_COMMIT_TAG
    description: "Release $CI_COMMIT_TAG of components repository $CI_PROJECT_PATH"
```

After committing and pushing changes, the pipeline tests the component, then releases the tag it if the test passes.

### Avoid using global keywords

Avoid using [global keywords](../yaml/index.md#global-keywords) in a component.
Using these keywords in a component affects all jobs in a pipeline, including jobs
directly defined in the main `.gitlab-ci.yml` or in other included components.

As an alternative to global keywords, instead:

- Add the configuration directly to each job, even if it creates some duplication
  in the component configuration.
- Use the [`extends`](../yaml/index.md#extends) keyword in the component, but use
  unique names that reduce the risk of naming conflicts when the component is merged
  into the configuration.

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

When tagging and [releasing new versions](#publish-a-new-release) of components, you should use
[semantic versioning](https://semver.org).
Semantic versioning is the standard for communicating that a change is a major, minor, patch,
or other kind of change.

You should use at least the `major.minor` format, as this is widely understood. For example,
`2.0` or `2.1`.

Other examples of semantic versioning:

- `1.0.0`
- `2.1.3`
- `1.0.0-alpha`
- `3.0.0-rc1`

## Convert a CI/CD template to a component

Any existing CI/CD template that you use in projects by using the `include:` syntax
can be converted to a CI/CD component:

1. Decide if you want the component to be part of an existing [component project](index.md#component-project)
   to be grouped with other components, or [create a new component project](#create-a-component-project).
1. Create a YAML file in the component project according to the expected [directory structure](index.md#directory-structure).
1. Copy the content of the original template YAML file into the new component YAML file.
1. Refactor the new component's configuration to:
   - Follow the [best practices](index.md#best-practices) for components.
   - Improve the configuration, for example by enabling [merge request pipelines](../pipelines/merge_request_pipelines.md)
     or making it [more efficient](../pipelines/pipeline_efficiency.md).
1. Leverage the `.gitlab-ci.yml` in the components repository to [test changes to the component](index.md#test-the-component).
1. Tag and [release the component](#publish-a-new-release).

## Troubleshooting

### `content not found` message

You might receive an error message similar to the following when using the `~latest`
version qualifier to reference a component hosted by a [catalog resource](#set-a-component-project-as-a-catalog-resource):

```plaintext
This GitLab CI configuration is invalid: component 'gitlab.com/my-namespace/my-project/my-component@~latest' - content not found`
```

The `~latest` behavior [was updated](https://gitlab.com/gitlab-org/gitlab/-/issues/429707)
in GitLab 16.7. It now refers to the latest published version of the catalog resource. To resolve this issue, [create a new release](#publish-a-new-release).
