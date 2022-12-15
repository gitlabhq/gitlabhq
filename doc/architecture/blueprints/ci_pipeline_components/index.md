---
status: proposed
creation-date: "2022-09-14"
authors: [ "@fabio", "@grzesiek" ]
coach: "@kamil"
approvers: [ "@dhershkovitch", "@marknuzzo" ]
owning-stage: "~devops::verify"
participating-stages: []
---

# CI/CD pipeline components catalog

## Summary

## Goals

The goal of the CI/CD pipeline components catalog is to make the reusing pipeline configurations
easier and more efficient.
Providing a way to discover, understand and learn how to reuse pipeline constructs allows for a more streamlined experience.
Having a CI/CD pipeline components catalog also sets a framework for users to collaborate on pipeline constructs so that they can be evolved
and improved over time.

This blueprint defines the architectural guidelines on how to build a CI/CD catalog of pipeline components.
This blueprint also defines the long-term direction for iterations and improvements to the solution.

## Challenges

- GitLab CI/CD can have a steep learning curve for new users. Users must read the documentation and
  [YAML reference](../../../ci/yaml/index.md) to understand how to configure their pipelines.
- Developers are struggling to reuse existing CI/CD templates with the result of having to reinvent the wheel and write
  YAML configurations repeatedly.
- GitLab [CI templates](../../../development/cicd/templates.md#template-directories) provide users with
  scaffolding pipeline or jobs for specific purposes.
  However versioning them is challenging today due to being shipped with the GitLab instance.
  See [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/17716) for more information.
- Users of GitLab CI/CD (pipeline authors) today have their own ad-hoc way to organize shared pipeline
  configurations inside their organization. Those configurations tend to be mostly undocumented.
- The only discoverable configurations are GitLab CI templates. However they don't have any inline documentation
  so it becomes harder to know what they do and how to use them without copy-pasting the content in the
  editor and read the actual YAML.
- It's harder to adopt additional GitLab features (CD, security, test, etc.).
- There is no framework for testing reusable CI configurations.
  Many configurations are not unit tested against single changes.
- Communities, partners, 3rd parties, individual contributors, must go through the
  [GitLab Contribution process](https://about.gitlab.com/community/contribute/) to contribute to GitLab managed
  templates. See [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/323727) for more information.
- GitLab has more than 100 of templates with some of them barely maintained after their addition.

### Problems with GitLab CI templates

- GitLab CI Templates have not been designed with deterministic behavior in mind.
- GitLab CI Templates have not been design with reusability in mind.
- `Jobs/` templates hard-code the `stage:` attribute but the user of the template must somehow override
  or know in advance what stage is needed.
  - The user should be able to import the job inside a given stage or pass the stage names as input parameter
    when using the component.
  - Failures in mapping the correct stage can result in confusing errors.
- Some templates are designed to work with AutoDevops but are not generic enough
  ([example](https://gitlab.com/gitlab-org/gitlab/-/blob/2c0e8e4470001442e999391df81e19732b3439e6/lib/gitlab/ci/templates/AWS/Deploy-ECS.gitlab-ci.yml)).
- Many CI templates, especially those [language specific](https://gitlab.com/gitlab-org/gitlab/-/tree/2c0e8e4470001442e999391df81e19732b3439e6/lib/gitlab/ci/templates)
  are tutorial/scaffolding-style templates.
  - They are meant to show the user how a typical pipeline would look like but it requires high customization from the user perspective.
  - They require a different UX: copy-paste in the position of the Pipeline Editor cursor.
- Some templates like `SAST.latest.gitlab-ci.yml` add multiple jobs conditionally to the same pipeline.
  - Ideally these jobs could run as a child pipeline and make the reports available to the parent pipeline.
  - [This epic](https://gitlab.com/groups/gitlab-org/-/epics/8205) is necessary for Parent-child pipelines to be used.
- Some templates incorrectly use `variables`, `image` and other top-level keywords but that defines them in all pipeline jobs,
  not just those defined in the template.
  - This technique introduces inheritance issues when a template modifies jobs unnecessarily.

## Opportunities

- Having a catalog of pipeline constructs where users can search and find what they need can greatly lower
  the bar for new users.
- Customers are already trying to rollout their ad-hoc catalog of shared configurations. We could provide a
  standardized way to write, package and share pipeline constructs directly in the product.
- As we implement new pipeline constructs (for example, reusable job steps) they could be items of the
  catalog. The catalog can boost the adoption of new constructs.
- The catalog can be a place where we strengthen our relationship with partners, having components offered
  and maintained by our partners.
- With discoverability and better versioning mechanism we can have more improvements and better collaboration.
- Competitive landscape is showing the need for such feature
  - [R2DevOps](https://r2devops.io) implements a catalog of CI templates for GitLab pipelines.
  - [GitHub Actions](https://github.com/features/actions) provides an extensive catalog of reusable job steps.

## Implementation guidelines

- Start with the smallest user base. Dogfood the feature for `gitlab-org` and `gitlab-com` groups.
  Involve the Engineering Productivity and other groups authoring pipeline configurations to test
  and validate our solutions.
- Ensure we can integrate all the feedback gathered, even if that means changing the technical design or
  UX. Until we make the feature GA we should have clear expectations with early adopters.
- Reuse existing functionality as much as possible. Don't reinvent the wheel on the initial iterations.
  For example: reuse project features like title, description, avatar to build a catalog.
- Leverage GitLab features for the development lifecycle of the components (testing via `.gitlab-ci.yml`,
  release management, Pipeline Editor, etc.).
- Design the catalog with self-managed support in mind.
- Allow the catalog an the workflow to support future types of pipeline constructs and new ways of using them.
- Design components and catalog following industry best practice related to building deterministic package managers.

## Glossary

This section defines some terms that are used throughout this document. With these terms we are only
identifying abstract concepts and are subject to changes as we refine the design by discovering new insights.

- **Component** Is the reusable unit of pipeline configuration.
- **Project** Is the GitLab project attached to a repository. A project can contain multiple components.
- **Catalog** is the collection of projects that are set to contain components.
- **Version** is the release name of a tag in the project, which allows components to be pinned to a specific revision.

## Definition of pipeline component

A pipeline component is a reusable single-purpose building block that abstracts away a single pipeline configuration unit.
Components are used to compose a part or entire pipeline configuration.
It can optionally take input parameters and set output data to be adaptable and reusable in different pipeline contexts,
while encapsulating and isolating implementation details.

Components allow a pipeline to be assembled by using abstractions instead of having all the details defined in one place.
When using a component in a pipeline, a user shouldn't need to know the implementation details of the component and should
only rely on the provided interface.

A pipeline component defines its type which indicates in which context of the pipeline configuration the component can be used.
For example, a component of type X can only be used according to the type X use-case.

For best experience with any systems made of components it's fundamental that components:

- **Single purpose**: a component must focus on a single goal and the scope be as small as possible.
- **Isolated**: when a component is used in a pipeline, its implementation details should not leak outside the
  component itself and into the main pipeline.
- **Reusable**: a component is designed to be used in different pipelines.
  Depending on the assumptions it's built on a component can be more or less generic.
  Generic components are more reusable but may require more customization.
- **Versioned**: when using a component we must specify the version we are interested in.
  The version identifies the exact interface and behavior of the component.
- **Resolvable**: when a component depends on another component, this dependency must be explicit and trackable.

## Structure of a component

A pipeline component is identified by the path to a repository or directory that defines it
and a specific version: `<component-path>@<version>`.

For example: `gitlab-org/dast@1.0`.

### The component path

A component path must contain at least the metadata YAML and optionally a related `README.md` documentation file.

The component path can be:

- A path to a project: `gitlab-org/dast`. In this case the 2 files are defined in the root directory of the repository.
- A path to a project subdirectory: `gitlab-org/dast/api-scan`. In this case the 2 files are defined in the `api-scan` directory.
- A path to a local directory: `/path/to/component`. This path must contain the metadata YAML that defines the component.
  The path must start with `/` to indicate a full path in the repository.

The metadata YAML file follows the filename convention `gitlab-<component-type>.yml` where component type is one of:

| Component type | Context |
| -------------- | ------- |
| `template`     | For components used under `include:` keyword |
| `step`         | For components used under `steps:` keyword  |
| `workflow`     | For components used under `trigger:` keyword |

Based on the context where the component is used we fetch the correct YAML file.
For example, if we are including a component `gitlab-org/dast@1.0` we expect a YAML file named `gitlab-template.yml` in the
top level directory of `gitlab-org/dast` repository.

A `gitlab-<component-type>.yml` file:

- Must have a **name** to be referenced to and **description** for extra details.
- Must specify its **type** in the filename, which defines how it can be used (raw configuration to be `include`d, child pipeline workflow, job step).
- Must define its **content** based on the type.
- Must specify **input parameters** that it accepts. Components should depend on input parameters for dynamic values and not environment variables.
- Can optionally define **output data** that it returns.
- Should be **validated statically** (for example: using JSON schema validators).

```yaml
spec:
  inputs:
    website:
    environment:
      default: test
    test_run:
      options:
        - unit
        - integration
        - system
content: { ... }
```

Components that are released in the catalog must have a `README.md` file in the same directory as the
metadata YAML file. The `README.md` represents the documentation for the specific component, hence it's recommended
even when not releasing versions in the catalog.

### The component version

The version of the component can be (in order of highest priority first):

1. A commit SHA - For example: `gitlab-org/dast@e3262fdd0914fa823210cdb79a8c421e2cef79d8`
1. A released tag - For example: `gitlab-org/dast@1.0`
1. A special moving target version that points to the most recent released tag - For example: `gitlab-org/dast@~latest`
1. An unreleased tag - For example: `gitlab-org/dast@rc-1.0`
1. A branch name - For example: `gitlab-org/dast@master`

If a tag and branch exist with the same name, the tag takes precedence over the branch.
Similarly, if a tag is named `e3262fdd0914fa823210cdb79a8c421e2cef79d8`, a commit SHA (if exists)
takes precedence over the tag.

As we want to be able to reference any revisions (even those not released), a component must be defined in a Git repository.

NOTE:
When referencing a component by local path (for example `./path/to/component`), its version is implicit and matches
the commit SHA of the current pipeline context.

## Components project

A components project is a GitLab project/repository that exclusively hosts one or more pipeline components.

For components projects it's highly recommended to set an appropriate avatar and project description
to improve discoverability in the catalog.

### Structure of a components project

A project can host one or more components depending on whether the author wants to define a single component
per project or include multiple cohesive components under the same project.

Let's imagine we are developing a component that runs RSpec tests for a Rails app. We create a component project
called `myorg/rails-rspec`.

The following directory structure would support 1 component per project:

```plaintext
.
├── gitlab-<type>.yml
├── README.md
└── .gitlab-ci.yml
```

The `.gitlab-ci.yml` is recommended for the project to ensure changes are verified accordingly.

The component is now identified by the path `myorg/rails-rspec`. In other words, this means that
the `gitlab-<type>.yml` and `README.md` are located in the root directory of the repository.

The following directory structure would support multiple components per project:

```plaintext
.
├── .gitlab-ci.yml
├── unit/
│   ├── gitlab-workflow.yml
│   └── README.md
├── integration/
│   ├── gitlab-workflow.yml
│   └── README.md
└── feature/
    ├── gitlab-workflow.yml
    └── README.md
```

In this example we are defining multiple test profiles that are executed with RSpec.
The user could choose to use one or more of these.

Each of these components are identified by their path `myorg/rails-rspec/unit`, `myorg/rails-rspec/integration`
and `myorg/rails-rspec/feature`.

This directory structure could also support both strategies:

```plaintext
.
├── gitlab-template.yml # myorg/rails-rspec
├── README.md
├── .gitlab-ci.yml
├── unit/
│   ├── gitlab-workflow.yml # myorg/rails-rspec/unit
│   └── README.md
├── integration/
│   ├── gitlab-workflow.yml # myorg/rails-rspec/integration
│   └── README.md
└── feature/
    ├── gitlab-workflow.yml # myorg/rails-rspec/feature
    └── README.md
```

With the above structure we could have a top-level component that can be used as the
default component. For example, `myorg/rails-rspec` could run all the test profiles together.
However, more specific test profiles could be used separately (for example `myorg/rails-rspec/integration`).

NOTE:
Any nesting more than 1 level is initially not permitted.
This limitation encourages cohesion at project level and keeps complexity low.

## Input parameters `spec:inputs:` parameters

If the component takes any input parameters they must be specified according to the following schema:

```yaml
spec:
  inputs:
    website: # by default all declared inputs are mandatory.
    environment:
      default: test # apply default if not provided. This makes the input optional.
    test_run:
      options: # a choice must be made from the list since there is no default value.
        - unit
        - integration
        - system
```

When using the component we pass the input parameters as follows:

```yaml
include:
  - component: org/my-component@1.0
    with:
      website: ${MY_WEBSITE} # variables expansion
      test_run: system
      environment: $[[ inputs.environment ]] # interpolation of upstream inputs
```

Variables expansion must be supported for `with:` syntax as well as interpolation of
possible [inputs provided upstream](#input-parameters-for-pipelines).

Input parameters are validated as soon as possible:

1. Read the file `gitlab-template.yml` inside `org/my-component`.
1. Parse `spec:inputs` and validate the parameters against this schema.
1. If successfully validated, proceed with parsing `content:`. Return an error otherwise.
1. Interpolate input parameters inside the component's `content:`.

```yaml
spec:
  inputs:
    environment:
      options: [test, staging, production]
content:
  "run-tests-$[[ inputs.environment ]]":
    script: ./run-test

  scan-website:
    script: ./scan-website $[[ inputs.environment ]]
    rules:
      - if: $[[ inputs.environment ]] == 'staging'
      - if: $[[ inputs.environment ]] == 'production'
```

With `$[[ inputs.XXX ]]` inputs are interpolated immediately after parsing the `content:`.

### Why input parameters and not environment variables?

Until today we have been leveraging environment variables to pass information around.
For example, we use environment variables to pass information from an upstream pipeline to a
downstream pipeline.

Using environment variables for passing information to a component is like declaring global
variables in programming languages. The more variables we declare the more we risk variable
conflicts and increase variables scope.

Input parameters are like variables passed to the component which exist inside a specific
scope and they don't leak to the outside.
Inputs are not inherited from upstream `include`s. They must be passed explicitly.

This paradigm allows to build more robust and isolated components as well as declare and
enforce contracts.

### Input parameters for existing `include:` syntax

Because we are adding input parameters to components used via `include:component` we have an opportunity to
extend it to other `include:` types support inputs via `with:` syntax:

```yaml
include:
  - component: org/my-component@1.0
    with:
      foo: bar
  - local: path/to/file.yml
    with:
      foo: bar
  - project: org/another
    file: .gitlab-ci.yml
    with:
      foo: bar
  - remote: http://example.com/ci/config
    with:
      foo: bar
  - template: Auto-DevOps.gitlab-ci.yml
    with:
      foo: bar
```

Then the configuration being included must specify the inputs:

```yaml
spec:
  inputs:
    foo:

# rest of the configuration
```

If a YAML includes content using `with:` but the including YAML doesn't specify `inputs:`, an error should be raised.

|`with:`| `inputs:` | result |
| --- | --- | --- |
| specified | |  raise error  |
| specified | specified | validate inputs |
| | specified | use defaults |
| | | legacy `include:` without input passing |

### Input parameters for pipelines

Inputs can also be used to pass parameters to a pipeline when triggered and benefit from immediate validation.

Today we have different use cases where using explicit input parameters would be beneficial:

1. `Run Pipeline` UI form.
    - **Problem today**: We are using top-level variables with `variables:*:description` to surface environment variables to the UI.
    The problem with this is the mix of responsibilities as well as the jump in [precedence](../../../ci/variables/index.md#cicd-variable-precedence)
    that a variable gets (from a YAML variable to a pipeline variable).
    Building validation and features on top of this solution is challenging and complex.
1. Trigger a pipeline via API. For example `POST /projects/:id/pipelines/trigger` with `{ inputs: { provider: 'aws' } }`
1. Trigger a pipeline via `trigger:` syntax.

```yaml
deploy-app:
  trigger:
    project: org/deployer
    with:
      provider: aws
      deploy_environment: staging
```

To solve the problem of `Run Pipeline` UI form we could fully leverage the `spec:inputs` schema:

```yaml
spec:
  inputs:
    concurrency:
      default: 10    # displayed as default value in the input box
    provider: # can enforce `required` in the form validation
      description: Deployment provider # optional: render as input label.
    deploy_environment:
      options: # render a selectbox with options in order of how they are defined below
        - staging    # 1st option
        - canary     # 2nd option
        - production # 3rd option
      default: staging # selected by default in the UI.
                     # if `default:` is not specified, the user must explicitly select
                     # an option.
      description: Deployment environment # optional: render as input label.
```

## Limits

Any MVC that exposes a feature should be added with limitations from the beginning.
It's safer to add new features with restrictions than trying to limit a feature after it's being used.
We can always soften the restrictions later depending on user demand.

Some limits we could consider adding:

- number of components that a single project can contain/export
- number of imports that a `.gitlab-ci.yml` file can use
- number of imports that a component can declare/use
- max level of nested imports
- max length of the exported component name

## Iterations

1. Experimentation phase
    - Build an MVC behind a feature flag with `namespace` actor.
    - Enable the feature flag only for `gitlab-com` and `gitlab-org` namespaces to initiate the dogfooding.
    - Refine the solution and UX based on feedback.
    - Find customers to be early adopters of this feature and iterate on their feedback.
1. Design new pipeline constructs (in parallel with other phases)
    - Start the technical and design process to work on proposals for new pipeline constructs (steps, workflows, templates).
    - Implement new constructs. The catalog must be compatible with them.
    - Dogfood new constructs and iterate on feedback.
    - Release new constructs on private catalogs.
1. Release the private catalog for groups on Ultimate plan.
    - Iterate on feedback.
1. Release the public catalog for all GitLab users (prospect feature)
    - Publish new versions of GitLab CI templates as components using the new constructs whenever possible.
    - Allow self-managed administrators to populate their self-managed catalog by importing/updating
      components from GitLab.com or from repository exports.
    - Iterate on feedback.

## Who

Proposal:

<!-- vale gitlab.Spelling = NO -->

| Role                           | Who
|--------------------------------|-------------------------|
| Author                         | Fabio Pitino            |
| Engineering Leaders            | Cheryl Li, Mark Nuzzo   |
| Product Manager                | Dov Hershkovitch        |
| Architecture Evolution Coaches | Kamil Trzciński, Grzegorz Bizon |

DRIs:

| Role                         | Who
|------------------------------|------------------------|
| Leadership                   | Mark Nuzzo             |
| Product                      | Dov Hershkovitch       |
| Engineering                  | Fabio Pitino           |
| UX                           | Kevin Comoli (interim), Sunjung Park          |

Domain experts:

| Area                         | Who
|------------------------------|------------------------|
| Verify / Pipeline authoring  | Avielle Wolfe          |
| Verify / Pipeline authoring  | Laura Montemayor-Rodriguez  |

<!-- vale gitlab.Spelling = YES -->
