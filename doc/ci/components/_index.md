---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CD components
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Introduced as an [experimental feature](../../policy/development_stages_support.md#experiment) in GitLab 16.0, [with a flag](../../administration/feature_flags.md) named `ci_namespace_catalog_experimental`. Disabled by default.
> - [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/9897) in GitLab 16.2.
> - [Feature flag `ci_namespace_catalog_experimental` removed](https://gitlab.com/gitlab-org/gitlab/-/issues/394772) in GitLab 16.3.
> - [Moved](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/130824) to [beta](../../policy/development_stages_support.md#beta) in GitLab 16.6.
> - [Made generally available](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/134062) in GitLab 17.0.

A CI/CD component is a reusable single pipeline configuration unit. Use components
to create a small part of a larger pipeline, or even to compose a complete pipeline configuration.

A component can be configured with [input parameters](../yaml/inputs.md) for more
dynamic behavior.

CI/CD components are similar to the other kinds of [configuration added with the `include` keyword](../yaml/includes.md),
but have several advantages:

- Components can be listed in the [CI/CD Catalog](#cicd-catalog).
- Components can be released and used with a specific version.
- Multiple components can be defined in the same project and versioned together.

Instead of creating your own components, you can also search for published components
that have the functionality you need in the [CI/CD Catalog](#cicd-catalog).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an introduction and hands-on examples, see [Efficient DevSecOps workflows with reusable CI/CD components](https://www.youtube.com/watch?v=-yvfSFKAgbA).
<!-- Video published on 2024-01-22. DRI: Developer Relations, https://gitlab.com/groups/gitlab-com/marketing/developer-relations/-/epics/399 -->

For common questions and additional support, see the [FAQ: GitLab CI/CD Catalog](https://about.gitlab.com/blog/2024/08/01/faq-gitlab-ci-cd-catalog/)
blog post.

## Component project

> - The maximum number of components per project [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/436565) from 10 to 30 in GitLab 16.9.

A component project is a GitLab project with a repository that hosts one or more components.
All components in the project are versioned together, with a maximum of 30 components per project.

If a component requires different versioning from other components, the component should be moved
to a dedicated component project.

### Create a component project

To create a component project, you must:

1. [Create a new project](../../user/project/_index.md#create-a-blank-project) with a `README.md` file:
   - Ensure the description gives a clear introduction to the component.
   - Optional. After the project is created, you can [add a project avatar](../../user/project/working_with_projects.md#add-a-project-avatar).

   Components published to the [CI/CD catalog](#cicd-catalog) use both the description and avatar when displaying the component project's summary.

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

You can [use the component](#use-a-component) immediately, but you might want to consider
publishing the component to the [CI/CD catalog](#cicd-catalog).

### Directory structure

The repository must contain:

- A `README.md` Markdown file documenting the details of all the components in the repository.
- A top level `templates/` directory that contains all the component configurations.
  You can define components in this directory:
  - In single files ending in `.yml` for each component, like `templates/secret-detection.yml`.
  - In sub-directories containing `template.yml` files as entry points, for components
    that bundle together multiple related files. For example, `templates/secret-detection/template.yml`.

NOTE:
Optionally, each component can also have its own `README.md` file that provides more detailed information, and can be linked from the top-level `README.md` file. This helps to provide a better overview of your component project and how to use it.

You should also:

- Configure the project's `.gitlab-ci.yml` to [test the components](#test-the-component)
  and [release new versions](#publish-a-new-release).
- Add a `LICENSE.md` file with a license of your choice that covers the usage of your component.
  For example the [MIT](https://opensource.org/license/mit) or [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0#apply)
  open source licenses.

For example:

- If the project contains a single component, the directory structure should be similar to:

  ```plaintext
  ├── templates/
  │   └── my-component.yml
  ├── LICENSE.md
  ├── README.md
  └── .gitlab-ci.yml
  ```

- If the project contains multiple components, then the directory structure should be similar to:

  ```plaintext
  ├── templates/
  │   ├── my-simple-component.yml
  │   └── my-complex-component/
  │       ├── template.yml
  │       ├── Dockerfile
  │       └── test.sh
  ├── LICENSE.md
  ├── README.md
  └── .gitlab-ci.yml
  ```

  In this example:

  - The `my-simple-component` component's configuration is defined in a single file.
  - The `my-complex-component` component's configuration contains multiple files in a directory.

## Use a component

To add a component to a project's CI/CD configuration, use the [`include: component`](../yaml/_index.md#includecomponent)
keyword. The component reference is formatted as `<fully-qualified-domain-name>/<project-path>/<component-name>@<specific-version>`,
for example:

```yaml
include:
  - component: $CI_SERVER_FQDN/my-org/security-components/secret-detection@1.0.0
    inputs:
      stage: build
```

In this example:

- `$CI_SERVER_FQDN` is a [predefined variable](../variables/predefined_variables.md)
  for the fully qualified domain name (FQDN) matching the GitLab host.
  You can only reference components in the same GitLab instance as your project.
- `my-org/security-components` is the full path of the project containing the component.
- `secret-detection` is the component name that is defined as either a single file `templates/secret-detection.yml`
  or as a directory `templates/secret-detection/` containing a `template.yml`.
- `1.0.0` is the [version](#component-versions) of the component.

Pipeline configuration and component configuration are not processed independently.
When a pipeline starts, any included component configuration [merges](../yaml/includes.md#merge-method-for-include)
into the pipeline's configuration. If your pipeline and the component both contain configuration with the same name,
they can interact in unexpected ways.

For example, two jobs with the same name would merge together into a single job.
Similarly, a component using `extends` for configuration with the same name as a job in your pipeline
could extend the wrong configuration. Make sure your pipeline and the component do not share
any configuration with the same name, unless you intend to [override](../yaml/includes.md#override-included-configuration-values)
the component's configuration.

To use GitLab.com components on a GitLab Self-Managed instance, you must
[mirror the component project](#use-a-gitlabcom-component-on-gitlab-self-managed).

WARNING:
If a component requires the use of tokens, passwords, or other sensitive data to function,
be sure to audit the component's source code to verify that the data is only used to
perform actions that you expect and authorize. You should also use tokens and secrets
with the minimum permissions, access, or scope required to complete the action.

### Component versions

In order of highest priority first, the component version can be:

- A commit SHA, for example `e3262fdd0914fa823210cdb79a8c421e2cef79d8`.
- A tag, for example: `1.0.0`. If a tag and commit SHA exist with the same name,
  the commit SHA takes precedence over the tag. Components released to the CI/CD Catalog
  should be tagged with a [semantic version](#semantic-versioning).
- A branch name, for example `main`. If a branch and tag exist with the same name,
  the tag takes precedence over the branch.
- `~latest`, which always points to the latest semantic version
  published in the CI/CD Catalog. Use `~latest` only if you want to use the absolute
  latest version at all times, which could include breaking changes. `~latest`
  does not include pre-releases, for example `1.0.1-rc`, which are not considered
  production-ready.

You can use any version supported by the component, but using a version published
to the CI/CD catalog is recommended. The version referenced with a commit SHA or branch name
might not be published in the CI/CD catalog, but could be used for testing.

#### Semantic version ranges

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/450835) in GitLab 16.11

When [referencing a CI/CD catalog component](#component-versions), you can use a
special format to specify the latest [semantic version](#semantic-versioning) in a range.

This approach offers significant benefits for both consumers and authors of components:

- For users, using version ranges is an excellent way to automatically receive
  minor or patch updates without risking breaking changes from major releases. This ensures
  your pipelines stay up-to-date with the latest bug fixes and security patches
  while maintaining stability.
- For component authors, the use of version ranges allows major version releases
  without risk of immediately breaking existing pipelines. Users who have
  specified version ranges continue to use the latest compatible minor or patch version,
  giving them time to update their pipelines at their own pace.

To specify the latest release of:

- A minor version, use both the major and minor version numbers in the reference,
  but not the patch version number. For example, use `1.1` to use the latest version
  that starts with `1.1`, including `1.1.0` or `1.1.9`, but not `1.2.0`.
- A major version, use only the major version number in the reference. For example,
  use `1` to use the latest version that starts with `1.`, like `1.0.0` or `1.9.9`,
  but not `2.0.0`.
- All versions, use `~latest` to use the latest released version.

For example, a component is released in this exact order:

1. `1.0.0`
1. `1.1.0`
1. `2.0.0`
1. `1.1.1`
1. `1.2.0`
1. `2.1.0`
1. `2.0.1`

In this example, referencing the component with:

- `1` would use the `1.2.0` version.
- `1.1` would use the `1.1.1` version.
- `~latest` would use the `2.1.0` version.

Pre-release versions are never fetched when referencing a version range. To fetch
a pre-release version, specify the full version, for example `1.0.1-rc`.

## Write a component

This section describes some best practices for creating high quality component projects.

### Manage dependencies

While it's possible for a component to use other components in turn, make sure to carefully select the dependencies. To manage dependencies, you should:

- Keep dependencies to a minimum. A small amount of duplication is usually better than having dependencies.
- Rely on local dependencies whenever possible. For example, using [`include:local`](../yaml/_index.md#includelocal) is a good way
  to ensure the same Git SHA is used across multiple files.
- When depending on components from other projects, pin their version to a release from the catalog rather than using moving target
  versions such as `~latest` or a Git reference. Using a release or Git SHA guarantees that you are fetching the same revision
  all the time and that consumers of your component get consistent behavior.
- Update your dependencies regularly by pinning them to newer releases. Then publish a new release of your components with updated
  dependencies.

### Write a clear `README.md`

Each component project should have clear and comprehensive documentation. To
write a good `README.md` file:

- The documentation should start with a summary of the capabilities that the components in the project provide.
- If the project contains multiple components, use a [table of contents](../../user/markdown.md#table-of-contents)
  to help users quickly jump to a specific component's details.
- Add a `## Components` section with sub-sections like `### Component A` for each component in the project.
- In each component section:
  - Add a description of what the component does.
  - Add at least one YAML example showing how to use it.
  - If the component uses inputs, add a table showing all inputs with name, description, type, and default value.
  - If the component uses any variables or secrets, those should be documented too.
- A `## Contribute` section is recommended if contributions are welcome.

If a component needs more instructions, add additional documentation in a Markdown file
in the component directory and link to it from the main `README.md` file. For example:

```plaintext
README.md    # with links to the specific docs.md
templates/
├── component-1/
│   ├── template.yml
│   └── docs.md
└── component-2/
    ├── template.yml
    └── docs.md
```

For an example of a component `README.md`, see the [Deploy to AWS with GitLab CI/CD component's `README.md`](https://gitlab.com/components/aws/-/blob/main/README.md).

### Test the component

Testing CI/CD components as part of the development workflow is strongly recommended
and helps ensure consistent behavior.

Test changes in a CI/CD pipeline (like any other project) by creating a `.gitlab-ci.yml`
in the root directory. Make sure to test both the behavior and potential side-effects
of the component. You can use the [GitLab API](../../api/rest/_index.md) if needed.

For example:

```yaml
include:
  # include the component located in the current project from the current SHA
  - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/my-component@$CI_COMMIT_SHA
    inputs:
      stage: build

stages: [build, test, release]

# Check if `component job of my-component` is added.
# This example job could also test that the included component works as expected.
# You can inspect data generated by the component, use GitLab API endpoints, or third-party tools.
ensure-job-added:
  stage: test
  image: badouralix/curl-jq
  # Replace "component job of my-component" with the job name in your component.
  script:
    - |
      route="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/pipelines/${CI_PIPELINE_ID}/jobs"
      count=`curl --silent "$route" | jq 'map(select(.name | contains("component job of my-component"))) | length'`
      if [ "$count" != "1" ]; then
        exit 1; else
        echo "Component Job present"
      fi

# If the pipeline is for a new tag with a semantic version, and all previous jobs succeed,
# create the release.
create-release:
  stage: release
  image: registry.gitlab.com/gitlab-org/release-cli:latest
  script: echo "Creating release $CI_COMMIT_TAG"
  rules:
    - if: $CI_COMMIT_TAG
  release:
    tag_name: $CI_COMMIT_TAG
    description: "Release $CI_COMMIT_TAG of components repository $CI_PROJECT_PATH"
```

After committing and pushing changes, the pipeline tests the component, then creates
a release if the earlier jobs pass.

NOTE:
Authentication is necessary if the project is private.

#### Test a component against sample files

In some cases, components require source files to interact with. For example, a component
that builds Go source code likely needs some samples of Go to test against. Alternatively,
a component that builds Docker images likely needs some sample Dockerfiles to test against.

You can include sample files like these directly in the component project, to be used
during component testing.

You can learn more in [examples for testing a component](examples.md#test-a-component).

### Avoid hard-coding instance or project-specific values

When [using another component](#use-a-component) in your component, use `$CI_SERVER_FQDN`
instead of your instance's Fully Qualified Domain Name (like `gitlab.com`).

When accessing the GitLab API in your component, use the `$CI_API_V4_URL` instead of the
full URL and path for your instance (like `https://gitlab.com/api/v4`).

These [predefined variables](../variables/predefined_variables.md)
ensure that your component also works when used on another instance, for example when using
[a GitLab.com component on a GitLab Self-Managed instance](#use-a-gitlabcom-component-on-gitlab-self-managed).

### Do not assume API resources are always public

Ensure that the component and its testing pipeline work also [on GitLab Self-Managed](#use-a-gitlabcom-component-on-gitlab-self-managed).
While some API resources of public projects on GitLab.com could be accessed via unauthenticated requests
on a GitLab Self-Managed instance a component project could be mirrored as private or internal project.

It's important that an access token can optionally be provided via inputs or variables to
authenticate requests on GitLab Self-Managed instances.

### Avoid using global keywords

Avoid using [global keywords](../yaml/_index.md#global-keywords) in a component.
Using these keywords in a component affects all jobs in a pipeline, including jobs
directly defined in the main `.gitlab-ci.yml` or in other included components.

As an alternative to global keywords:

- Add the configuration directly to each job, even if it creates some duplication
  in the component configuration.
- Use the [`extends`](../yaml/_index.md#extends) keyword in the component, but use
  unique names that reduce the risk of naming conflicts when the component is merged
  into the configuration.

For example, avoid using the `default` global keyword:

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

- Add the configuration to each job explicitly:

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

### Replace hardcoded values with inputs

Avoid using hardcoded values in CI/CD components. Hardcoded values might force
component users to need to review the component's internal details and adapt their pipeline
to work with the component.

A common keyword with problematic hard-coded values is `stage`. If a component job's
stage is hardcoded, all pipelines using the component **must** either define
the exact same stage, or [override](../yaml/includes.md#override-included-configuration-values)
the configuration.

The preferred method is to use the [`input` keyword](../yaml/inputs.md) for dynamic
component configuration. The component user can specify the exact value they need.

For example, to create a component with `stage` configuration that can be defined by users:

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

- In a project using the component:

  ```yaml
  stages: [verify, release]

  include:
    - component: $CI_SERVER_FQDN/myorg/ruby/test@1.0.0
      inputs:
        stage: verify
  ```

#### Define job names with inputs

Similar to the values for the `stage` keyword, you should avoid hard-coding job names
in CI/CD components. When your component's users can customize job names, they can prevent conflicts
with the existing names in their pipelines. Users could also include a component
multiple times with different input options by using different names.

Use `inputs` to allow your component's users to define a specific job name, or a prefix for the
job name. For example:

```yaml
spec:
  inputs:
    job-prefix:
      description: "Define a prefix for the job name"
    job-name:
      description: "Alternatively, define the job's name"
    job-stage:
      default: test
---

"$[[ inputs.job-prefix ]]-scan-website":
  stage: $[[ inputs.job-stage ]]
  script:
    - scan-website-1

"$[[ inputs.job-name ]]":
  stage: $[[ inputs.job-stage ]]
  script:
    - scan-website-2
```

### Replace custom CI/CD variables with inputs

When using CI/CD variables in a component, evaluate if the `inputs` keyword
should be used instead. Avoid asking users to define custom variables to configure
components when `inputs` is a better solution.

Inputs are explicitly defined in the component's `spec` section, and have better validation than variables.
For example, if a required input is not passed to the component, GitLab returns a pipeline error.
By contrast, if a variable is not defined, its value is empty, and there is no error.

For example, use `inputs` instead of variables to configure a scanner's output format:

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
    - component: $CI_SERVER_FQDN/path/to/project/my-scanner@1.0.0
      inputs:
        scanner-output: yaml
  ```

In other cases, CI/CD variables might still be preferred. For example:

- Use [predefined variables](../variables/predefined_variables.md) to automatically configure
  a component to match a user's project.
- Ask users to store sensitive values as [masked or protected CI/CD variables in project settings](../variables/_index.md#define-a-cicd-variable-in-the-ui).

## CI/CD Catalog

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/407249) as an [experiment](../../policy/development_stages_support.md#experiment) in GitLab 16.1.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/432045) to [beta](../../policy/development_stages_support.md#beta) in GitLab 16.7.
> - [Made Generally Available](https://gitlab.com/gitlab-org/gitlab/-/issues/454306) in GitLab 17.0.

The [CI/CD Catalog](https://gitlab.com/explore/catalog) is a list of projects with published CI/CD components you can use
to extend your CI/CD workflow.

Anyone can [create a component project](#create-a-component-project) and add it to
the CI/CD Catalog, or contribute to an existing project to improve the available components.

For a click-through demo, see [the CI/CD Catalog beta Product Tour](https://gitlab.navattic.com/cicd-catalog).
<!-- Demo published on 2024-01-24 -->

### View the CI/CD Catalog

To access the CI/CD Catalog and view the published components that are available to you:

1. On the left sidebar, select **Search or go to**.
1. Select **Explore**.
1. Select **CI/CD Catalog**.

Alternatively, if you are already in the [pipeline editor](../pipeline_editor/_index.md)
in your project, you can select **CI/CD Catalog**.

Visibility of components in the CI/CD catalog follows the component source project's
[visibility setting](../../user/public_access.md). Components with source projects set to:

- Private are visible only to users assigned at least the Guest role for the source component project.
- Internal are visible only to users logged into the GitLab instance.
- Public are visible to anyone with access to the GitLab instance.

### Publish a component project

To publish a component project in the CI/CD catalog, you must:

1. Set the project as a catalog project.
1. Publish a new release.

#### Set a component project as a catalog project

To make published versions of a component project visible in the CI/CD catalog,
you must set the project as a catalog project.

Prerequisites:

- You must have the Owner role for the project.

To set the project as a catalog project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Turn on the **CI/CD Catalog project** toggle.

The project only becomes findable in the catalog after you publish a new release.

To use automation to enable this setting, you can use the [`mutationcatalogresourcescreate`](../../api/graphql/reference/_index.md#mutationcatalogresourcescreate)
GraphQL endpoint. [Issue 463043](https://gitlab.com/gitlab-org/gitlab/-/issues/463043)
proposes to expose this in the REST API as well.

#### Publish a new release

CI/CD components can be [used](#use-a-component) without being listed in the CI/CD catalog.
However, publishing a component's releases in the catalog makes it discoverable to other users.

Prerequisites:

- You must have at least the Maintainer role for the project.
- The project must:
  - Be set as a [catalog project](#set-a-component-project-as-a-catalog-project).
  - Have a [project description](../../user/project/working_with_projects.md#edit-project-name-and-description) defined.
  - Have a `README.md` file in the root directory for the commit SHA of the tag being released.
  - Have at least one [CI/CD component in the `templates/` directory](#directory-structure)
    for the commit SHA of the tag being released.
- You must use the [`release` keyword](../yaml/_index.md#release) in a CI/CD job to create the release,
  not the [Releases API](../../api/releases/_index.md#create-a-release).

To publish a new version of the component to the catalog:

1. Add a job to the project's `.gitlab-ci.yml` file that uses the `release`
   keyword to create the new release when a tag is created.
   You should configure the tag pipeline to [test the components](#test-the-component) before
   running the release job. For example:

   ```yaml
   create-release:
     stage: release
     image: registry.gitlab.com/gitlab-org/release-cli:latest
     script: echo "Creating release $CI_COMMIT_TAG"
     rules:
       - if: $CI_COMMIT_TAG
     release:
       tag_name: $CI_COMMIT_TAG
       description: "Release $CI_COMMIT_TAG of components in $CI_PROJECT_PATH"
   ```

1. Create a [new tag](../../user/project/repository/tags/_index.md#create-a-tag) for the release,
   which should trigger a tag pipeline that contains the job responsible for creating the release.
   The tag must use [semantic versioning](#semantic-versioning).

After the release job completes successfully, the release is created and the new version
is published to the CI/CD catalog.

#### Semantic versioning

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/427286) in GitLab 16.10.

When tagging and [releasing new versions](#publish-a-new-release) of components to the Catalog,
you must use [semantic versioning](https://semver.org). Semantic versioning is the standard
for communicating that a change is a major, minor, patch, or other kind of change.

For example, `1.0.0`, `2.3.4`, and `1.0.0-alpha` are all valid semantic versions.

### Unpublish a component project

To remove a component project from the catalog, turn off the [**CI/CD Catalog resource**](#set-a-component-project-as-a-catalog-project)
toggle in the project settings.

WARNING:
This action destroys the metadata about the component project and its versions published
in the catalog. The project and its repository still exist, but are not visible in the catalog.

To publish the component project in the catalog again, you need to [publish a new release](#publish-a-new-release).

### Verified component creators

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/433443) in GitLab 16.11

Some CI/CD components are badged with an icon to show that the component was created
and is maintained by users verified by GitLab:

- GitLab-maintained (**{tanuki-verified}**): Components that are created and maintained by GitLab.
- GitLab Partner (**{partner-verified}**): Components that are independently created
  and maintained by a GitLab-verified partner.

  GitLab partners can contact a member of the GitLab Partner Alliance to have their
  namespace flagged as GitLab-verified. Then any CI/CD components located in the
  namespace are badged as GitLab Partner components. The Partner Alliance member
  creates an internal request issue on behalf of the verified partner (GitLab team members only):
  `https://gitlab.com/gitlab-com/support/internal-requests/-/issues/new?issuable_template=CI%20Catalog%20Badge%20Request`.

  WARNING:
  GitLab Partner-created components are provided **as-is**, without warranty of any kind.
  An end user's use of a GitLab Partner-created component is at their own risk and
  GitLab shall have no indemnification obligations nor any liability of any type
  with respect to the end user's use of the component. The end user's use of such content
  and any liability related thereto shall be between the publisher of the content and the end user.

## Convert a CI/CD template to a component

Any existing CI/CD template that you use in projects by using the `include:` syntax
can be converted to a CI/CD component:

1. Decide if you want the component to be grouped with other components as part of
   an existing [component project](#component-project), or [create a new component project](#create-a-component-project).
1. Create a YAML file in the component project according to the [directory structure](#directory-structure).
1. Copy the content of the original template YAML file into the new component YAML file.
1. Refactor the new component's configuration to:
   - Follow the guidance on [writing a component](#write-a-component).
   - Improve the configuration, for example by enabling [merge request pipelines](../pipelines/merge_request_pipelines.md)
     or making it [more efficient](../pipelines/pipeline_efficiency.md).
1. Leverage the `.gitlab-ci.yml` in the components repository to [test changes to the component](#test-the-component).
1. Tag and [release the component](#publish-a-new-release).

You can learn more by following a practical example for [migrating the Go CI/CD template to CI/CD component](examples.md#cicd-component-migration-example-go).

## Use a GitLab.com component on GitLab Self-Managed

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

The CI/CD catalog of a fresh install of a GitLab instance starts with no published CI/CD components.
To populate your instance's catalog, you can:

- [Publish your own components](#publish-a-component-project).
- Mirror components from GitLab.com in your GitLab Self-Managed instance.

To mirror a GitLab.com component in your GitLab Self-Managed instance:

1. Make sure that [network outbound requests](../../security/webhooks.md) are allowed for `gitlab.com`.
1. [Create a group](../../user/group/_index.md#create-a-group) to host the component projects (recommended group: `components`).
1. [Create a mirror of the component project](../../user/project/repository/mirror/pull.md) in the new group.
1. Write a [project description](../../user/project/working_with_projects.md#edit-project-name-and-description)
   for the component project mirror because mirroring repositories does not copy the description.
1. [Set the self-hosted component project as a catalog resource](#set-a-component-project-as-a-catalog-project).
1. Publish [a new release](../../user/project/releases/_index.md) in the self-hosted component project by
   [running a pipeline](../pipelines/_index.md#run-a-pipeline-manually) for a tag (usually the latest tag).

## CI/CD component security best practices

### For component users

As anyone can publish components to the catalog, you should carefully review components before using them in your project.
Use of GitLab CI/CD components is at your own risk and GitLab cannot guarantee the security of third-party components.

When using third-party CI/CD components, consider the following security best practices:

- **Audit and review component source code**: Carefully examine the code to ensure it's free of malicious content.
- **Minimize access to credentials and tokens**:
  - Audit the component's source code to verify that any credentials or tokens are only used
    to perform actions that you expect and authorize.
  - Use minimally scoped access tokens.
  - Avoid using long-lived access tokens or credentials.
  - Audit use of credentials and tokens used by CI/CD components.
- **Use pinned versions**: Pin CI/CD components to a specific commit SHA (preferred)
  or release version tag to ensure the integrity of the component used in a pipeline.
  Only use release tags if you trust the component maintainer. Avoid using `latest`.
- **Store secrets securely**: Do not store secrets in CI/CD configuration files.
  Avoid storing secrets and credentials in project settings if you can use an external secret management
  solution instead.
- **Use ephemeral, isolated runner environments**: Run component jobs in temporary,
  isolated environments when possible. Be aware of [security risks](https://docs.gitlab.com/runner/security)
  with self-managed runners.
- **Securely handle cache and artifacts**: Do not pass cache or artifacts from other jobs
  in your pipeline to CI/CD component jobs unless absolutely necessary.
- **Limit CI_JOB_TOKEN access**: Restrict [CI/CD job token (`CI_JOB_TOKEN`) project access and permissions](../jobs/ci_job_token.md#control-job-token-access-to-your-project)
  for projects using CI/CD components.
- **Review CI/CD component changes**: Carefully review all changes to the CI/CD component configuration
  before changing to use an updated commit SHA or release tag for the component.
- **Audit custom container images**: Carefully review any custom container images used by the CI/CD component
  to ensure they are free of malicious content.

### For component maintainers

To maintain secure and trustworthy CI/CD components and ensure the integrity of the pipeline configuration
you deliver to users, follow these best practices:

- **Use two-factor authentication (2FA)**: Ensure all CI/CD component project maintainers
  and owners have [2FA enabled](../../user/profile/account/two_factor_authentication.md#enable-two-factor-authentication),
  or enforce [2FA for all users in the group](../../security/two_factor_authentication.md#enforce-2fa-for-all-users-in-a-group).
- **Use protected branches**:
  - Use [protected branches](../../user/project/repository/branches/protected.md)
    for component project releases.
  - Protect the default branch, and protect all release branches [using wildcard rules](../../user/project/repository/branches/protected.md#protect-multiple-branches-with-wildcard-rules).
  - Require everyone submit merge requests for changes to protected branches. Set the
    **Allowed to push and merge** option to `No one` for protected branches.
  - Block force pushes to protected branches.
- **Sign all commits**: [Sign all commits](../../user/project/repository/signed_commits/_index.md) to the component project.
- **Discourage using `latest`**: Avoid including examples in your `README.md` that use `@latest`.
- **Limit dependency on caches and artifacts from other jobs**: Only use cache and artifacts
  from other jobs in CI/CD components if absolutely necessary
- **Update CI/CD component dependencies**: Check for and apply updates to dependencies regularly.
- **Review changes carefully**:
  - Carefully review all changes to the CI/CD component pipeline configuration before
    merging into default or release branches.
  - Use [merge request approvals](../../user/project/merge_requests/approvals/_index.md)
    for all user-facing changes to CI/CD component catalog projects.

## Troubleshooting

### `content not found` message

You might receive an error message similar to the following when using the `~latest`
version qualifier to reference a component hosted by a [catalog project](#set-a-component-project-as-a-catalog-project):

```plaintext
This GitLab CI configuration is invalid: Component 'gitlab.com/my-namespace/my-project/my-component@~latest' - content not found
```

The `~latest` behavior [was updated](https://gitlab.com/gitlab-org/gitlab/-/issues/442238)
in GitLab 16.10. It now refers to the latest semantic version of the catalog resource. To resolve this issue, [create a new release](#publish-a-new-release).

### Error: `Build component error: Spec must be a valid json schema`

If a component has invalid formatting, you might not be able to create a release
and could receive an error like `Build component error: Spec must be a valid json schema`.

This error can be caused by an empty `spec:inputs` section. If your configuration
does not use any inputs, you can make the `spec` section empty instead. For example:

```yaml
spec:
---

my-component:
  script: echo
```
