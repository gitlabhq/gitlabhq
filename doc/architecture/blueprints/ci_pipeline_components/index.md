---
status: ongoing
creation-date: "2022-09-14"
authors: [ "@ayufan", "@fabiopitino", "@grzesiek" ]
coach: [ "@ayufan", "@grzesiek" ]
approvers: [ "@dhershkovitch", "@marknuzzo" ]
owning-stage: "~devops::verify"
participating-stages: []
---

<!-- vale gitlab.FutureTense = NO -->

# CI/CD Catalog

## Summary

## Goals

The goal of the CI/CD pipeline components catalog is to make the reusing
pipeline configurations easier and more efficient. Providing a way to
discover, understand and learn how to reuse pipeline constructs allows for a
more streamlined experience. Having a CI/CD pipeline components catalog also
sets a framework for users to collaborate on pipeline constructs so that they
can be evolved and improved over time.

This blueprint defines the architectural guidelines on how to build a CI/CD
catalog of pipeline components. This blueprint also defines the long-term
direction for iterations and improvements to the solution.

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
- Some templates are designed to work with AutoDevOps but are not generic enough
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
  - [CircleCI Orbs](https://circleci.com/orbs/) provide reusable YAML configuration packages.

## Glossary

This section defines some terms that are used throughout this document. With these terms we are only
identifying abstract concepts and are subject to changes as we refine the design by discovering new insights.

- **Component** Is the reusable unit of pipeline configuration.
- **Components repository** represents a collection of CI components stored in the same project.
- **Project** is the GitLab project attached to a single components repository.
- **Catalog** is a collection of resources like components repositories.
- **Catalog resource** is the single item displayed in the catalog. A components repository is a catalog resource.
- **Version** is a specific revision of catalog resource. It maps to the released tag in the project,
  which allows components to be pinned to a specific revision.
- **Steps** is a collection of instructions for how jobs can be executed.

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

### Predictable components

Eventually, we want to make CI Catalog Components predictable. Including a
component by its path, using a fixed `@` version, should always return the same
configuration, regardless of a context from which it is getting included from.
The resulting configuration should be the same for a given component version
and the set of inputs passed using `include:inputs` keyword, therefore it should be
[deterministic](https://en.wikipedia.org/wiki/Deterministic_algorithm).

A component should not produce side effects by being included and should be
[referentially transparent](https://en.wikipedia.org/wiki/Referential_transparency).

Making components predictable is a process, and we may not be able to achieve
this without significantly redesigning CI templates, what could be disruptive
for users and customers right now. We initially considered restricting some
top-level keywords, like `include: remote:` to make components more
deterministic, but eventually agreed that we first need to iterate on the MVP
to better understand the design that is required to make components more
predictable. The predictability, determinism, referential transparency and
making CI components predictable is still important for us, but we may be
unable to achieve it early iterations.

## Structure of a component

A pipeline component is identified by a unique address in the form `<fqdn>/<component-path>@<version>` containing:

- FQDN (Fully Qualified Domain Name).
- The path to a repository or directory that defines it.
- A specific version

For example: `gitlab.com/gitlab-org/dast@1.0`.

### The FQDN

Initially we support only component addresses that point to the same GitLab instance, meaning that the FQDN matches
the GitLab host.

### The component path

The directory identified by the component path must contain at least the component YAML and optionally a
related `README.md` documentation file.

The component path can be:

- A path to a project: `gitlab.com/gitlab-org/dast`. The default component is processed.
- A path to an explicit component: `gitlab.com/gitlab-org/dast/api-scan`. In this case the explicit `api-scan` component is processed.
- A relative path to a local directory: `./path/to/component`. This path must contain the component YAML that defines the component.
  The path must start with `./` or `../` to indicate a path relative to the current file's path.

Relative local paths are a abbreviated form of the full component address, meaning that `./path/to/component` called from
a file `mydir/file.yml` in `gitlab-org/dast` project would be expanded to:

```plaintext
gitlab.com/gitlab-org/dast/mydir/path/to/component@<CURRENT_SHA>
```

The component YAML file follows the filename convention `<type>.yml` where component type is one of:

| Component type | Context |
| -------------- | ------- |
| `template`     | For components used under `include:` keyword |

Based on the context where the component is used we fetch the correct YAML file.
For example:

- if we are including a component `gitlab.com/gitlab-org/dast@1.0` we expect a YAML file named `template.yml` in the
  root directory of `gitlab-org/dast` repository.
- if we are including a component `gitlab.com/gitlab-org/dast/api-scan@1.0` we expect a YAML file named `template.yml` inside a
  directory `api-scan` of `gitlab-org/dast` repository.

A component YAML file:

- Must have a **name** to be referenced to.
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
---
# content of the component
```

### The component version

The version of the component can be (in order of highest priority first):

1. A commit SHA - For example: `gitlab.com/gitlab-org/dast@e3262fdd0914fa823210cdb79a8c421e2cef79d8`
1. A tag - For example: `gitlab.com/gitlab-org/dast@1.0`
1. A special moving target version that points to the most recent released tag. The target project must be
explicitly marked as a [catalog resource](#catalog-resource) - For example: `gitlab.com/gitlab-org/dast@~latest`
1. A branch name - For example: `gitlab.com/gitlab-org/dast@master`

If a tag and branch exist with the same name, the tag takes precedence over the branch.
Similarly, if a tag is named `e3262fdd0914fa823210cdb79a8c421e2cef79d8`, a commit SHA (if exists)
takes precedence over the tag.

As we want to be able to reference any revisions (even those not released), a component must be defined in a Git repository.

When referencing a component by local path (for example `./path/to/component`), its version is implicit and matches
the commit SHA of the current pipeline context.

## Components repository

A components repository is a GitLab project/repository that exclusively hosts one or more pipeline components.

A components repository can be a catalog resource. For a components repository it's highly recommended to set
an appropriate avatar and project description to improve discoverability in the catalog.

Components repositories that are released in the catalog must have a `README.md` file at the root directory of the repository.
The `README.md` represents the documentation of the components repository, hence it's recommended
even when not listing the repository in the catalog.

### Structure of a components repository

A components repository can host one or more components. The author can decide whether to define a single component
per repository or include multiple cohesive components in the same repository.

A components repository is identified by the project full path.

Let's imagine we are developing a component that runs RSpec tests for a Rails app. We create a project
called `myorg/rails-rspec`.

The following directory structure would support 1 component per repository:

```plaintext
.
├── template.yml
├── README.md
└── .gitlab-ci.yml
```

The `.gitlab-ci.yml` is recommended for the project to ensure changes are verified accordingly.

The component is now identified by the path `gitlab.com/myorg/rails-rspec` which also maps to the
project path. We expect a `template.yml` file and `README.md` to be located in the root directory of the repository.

The following directory structure would support multiple components per repository:

```plaintext
.
├── .gitlab-ci.yml
├── README.md
├── unit/
│   └── template.yml
├── integration/
│   └── template.yml
└── feature/
    └── template.yml
```

In this example we are defining multiple test profiles that are executed with RSpec.
The user could choose to use one or more of these.

Each of these components are identified by their path `gitlab.com/myorg/rails-rspec/unit`, `gitlab.com/myorg/rails-rspec/integration`
and `gitlab.com/myorg/rails-rspec/feature`.

This directory structure could also support both strategies:

```plaintext
.
├── template.yml       # myorg/rails-rspec
├── README.md
├── LICENSE
├── .gitlab-ci.yml
├── unit/
│   └── template.yml   # myorg/rails-rspec/unit
├── integration/
│   └── template.yml   # myorg/rails-rspec/integration
└── feature/
    └── template.yml   # myorg/rails-rspec/feature
```

With the above structure we could have a top-level component that can be used as the
default component. For example, `myorg/rails-rspec` could run all the test profiles together.
However, more specific test profiles could be used separately (for example `myorg/rails-rspec/integration`).

NOTE:
Nesting of components is not permitted.
This limitation encourages cohesion at project level and keeps complexity low.

## `spec:inputs:` parameters

If the component takes any input parameters they must be specified according to the following schema:

```yaml
spec:
  inputs:
    website: # by default all declared inputs are mandatory.
    environment:
      default: test # apply default if not provided. This makes the input optional.
    flags:
      default: null # make an input entirely optional with no value by default.
    test_run:
      options: # a choice must be made from the list since there is no default value.
        - unit
        - integration
        - system
---
# content of the component
my-job:
  script: echo
```

The YAML in this case contains 2 documents. The first document represents the specifications while the
second document represents the content.

When using the component we pass the input parameters as follows:

```yaml
include:
  - component: gitlab.com/org/my-component@1.0
    inputs:
      website: ${MY_WEBSITE} # variables expansion
      test_run: system
      environment: $[[ inputs.environment ]] # interpolation of upstream inputs
```

Variables expansion must be supported for `include:inputs` syntax as well as interpolation of
possible [inputs provided upstream](#input-parameters-for-pipelines).

Input parameters are validated as soon as possible:

1. Read the file `gitlab-template.yml` inside `org/my-component` project.
1. Parse `spec:inputs` from the specifications and validate the parameters against this schema.
1. If successfully validated, proceed with parsing the content. Return an error otherwise.
1. Interpolate input parameters inside the component's content.

```yaml
spec:
  inputs:
    environment:
      options: [test, staging, production]
---
"run-tests-$[[ inputs.environment ]]":
  script: ./run-test

scan-website:
  script: ./scan-website $[[ inputs.environment ]]
  rules:
    - if: $[[ inputs.environment ]] == 'staging'
    - if: $[[ inputs.environment ]] == 'production'
```

With `$[[ inputs.XXX ]]` inputs are interpolated immediately after parsing the content.

### CI configuration interpolation perspectives and limitations

With `spec:inputs` users will be able to define input arguments for CI configuration.
With `include:inputs`, they will pass these arguments to CI components.

`inputs` in `$[[ inputs.something ]]` is going to be an initial "object" or
"container" that we will provide, to allow users to access their arguments in
the interpolation block. This, however, can evolve into myriads of directions, for example:

1. We could provide `variables` or `env` object, for users to access their environment variables easier.
1. We can extend the block evaluation to easier navigate JSON or YAML objects passed from elsewhere.
1. We can provide access to the repository files, snippets or issues from there too.

The CI configuration interpolation is a relative compute-intensive technology,
especially because we foresee this mechanism being used frequently on
GitLab.com. In order to ensure that users are using this responsibly, we have
introduced various limits, required to keep our production system safe. The
limits should not impact users, because there are application limits available
on a different level (maximum YAML size supported, timeout on parsing YAML
files etc); the interpolation limits we've introduced are typically much higher
then these. Some of them are:

1. An interpolation block should not be larger than 1 kilobyte.
1. A YAML value with interpolation in it can't be larger than 1 megabyte.
1. YAML configuration can't consist of more than half million entries.

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
extend it to other `include:` types support inputs through `inputs:` syntax:

```yaml
include:
  - component: gitlab.com/org/my-component@1.0
    inputs:
      foo: bar
  - local: path/to/file.yml
    inputs:
      foo: bar
  - project: org/another
    file: .gitlab-ci.yml
    inputs:
      foo: bar
  - remote: http://example.com/ci/config
    inputs:
      foo: bar
  - template: Auto-DevOps.gitlab-ci.yml
    inputs:
      foo: bar
```

Then the configuration being included must specify the inputs by defining a specification section in the YAML:

```yaml
spec:
  inputs:
    foo:
---
# rest of the configuration
```

If a YAML includes content using `include:inputs` but the including YAML doesn't define `spec:inputs` in the specifications,
an error should be raised.

| `include:inputs` | `spec:inputs` | result                                  |
|------------------|---------------|-----------------------------------------|
| specified        |               | raise error                             |
| specified        | specified     | validate inputs                         |
|                  | specified     | use defaults                            |
|                  |               | legacy `include:` without input passing |

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
    inputs:
      provider: aws
      deploy_environment: staging
```

To solve the problem of `Run Pipeline` UI form we could fully leverage the `inputs` specifications:

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
---
# rest of the pipeline config
```

## CI Catalog

The CI Catalog is an index of resources that users can leverage in CI/CD. It initially
contains a list of components repositories that users can discover and use in their pipelines.

In the future, the Catalog could contain also other types of resources (for example:
integrations, project templates, etc.).

To list a components repository in the Catalog we need to mark the project as being a
catalog resource. We do that initially with an API endpoint, similar to changing a project setting.

Once a project is marked as a "catalog resource" it can be displayed in the Catalog.

We could create a database record when the API endpoint is used and remove the record when
the same is disabled/removed.

## Catalog resource

Upon publishing, a catalog resource should have at least following attributes:

- `path`: to be uniquely identified.
- `name`: for components repository this could be the project name.
- `documentation`: we would use the `README.md` file which would be mandatory.
- `versions`: one or more releases of the resource.

Other properties of a catalog resource:

- `description`: for components repository this could be the project description.
- `avatar image`: we could use the project avatar.
- indicators of popularity (stars, forks).
- categorization: user should select a category and or define search tags

As soon as a components repository is marked as being a "catalog resource"
we should be seeing the resource listed in the Catalog.

Initially for the resource, the project may not have any released tags.
Users would be able to use the components repository by specifying a branch name or
commit SHA for the version. However, these types of version qualifiers should not
be listed in the catalog resource's page for various reasons:

- The list of branches and tags can get very large.
- Branches and tags may not be meaningful for the end-user.
- Branches and tags don't communicate versioning thoroughly.

## Releasing new resource versions to the Catalog

The versions that should be displayed for the resource should be the project [releases](../../../user/project/releases/index.md).
Creating project releases is an official act of versioning a resource.

A resource page would have:

- The latest release in evidence (for example: the default version).
- The ability to inspect and use past releases of the resource.
- The documentation represented by the `README.md`.

Users should be able to release new versions of the resource in a CI pipeline job,
similar to how software is being deployed following Continuous Delivery principles.

To ensure that the components repository and the including components
meet quality standards, users can test them before releasing new versions in the
CI Catalog.

Some examples of checks we can run during the release of a new resource version:

- Ensure the project contains a `README.md` in the root directory.
- Ensure the project description exists.
- If an index of available components is present for a components repository, ensure each
  component has valid YAML.

Once a new release for the project gets created we index the resource's
metadata. We want to initially index as much metadata as possible, to gain more
flexibility in how we design CI Catalog's main page. We don't want to be
constrained by the lack of data available to properly visualize resources in
the CI Catalog. To do that, we may need to find all resources that are
being released and index their data and metadata.
For example: index the content of `spec:` section for CI components.

See an [example of development workflow](dev_workflow.md) for a components repository.

## Note about future resource types

In the future, to support multiple types of resources in the Catalog we could
require a file `catalog-resource.yml` to be defined in the root directory of the project:

```yaml
name: DAST
description: Scan a web endpoint to find vulnerabilities
category: security
tags: [dynamic analysis, security scanner]
type: components_repository
```

This file could also be used for indexing metadata about the content of the resource.
For example, users could list the components in the repository and we can index
further data for search purpose:

```yaml
name: DAST
description: Scan a web endpoint to find vulnerabilities
category: security
tags: [dynamic analysis, security scanner]
type: components_repository
metadata:
  components:
    - all-scans
    - scan-x
    - scan-y
```

## Implementation guidelines

- Start with the smallest user base. Dogfood the feature for `gitlab-org` and
  `gitlab-com` groups. Involve the Engineering Productivity and other groups
  authoring pipeline configurations to test and validate our solutions.
- Ensure we can integrate all the feedback gathered, even if that means
  changing the technical design or UX. Until we make the feature GA we should
  have clear expectations with early adopters.
- Reuse existing functionality as much as possible. Don't reinvent the wheel on
  the initial iterations. For example: reuse project features like title,
  description, avatar to build a catalog.
- Leverage GitLab features for the development lifecycle of the components
  (testing via `.gitlab-ci.yml`, release management, Pipeline Editor, etc.).
- Design the catalog with self-managed support in mind.
- Allow the catalog and the workflow to support future types of pipeline
  constructs and new ways of using them.
- Design components and catalog following industry best practice related to
  building deterministic package managers.

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
| Verify / Pipeline authoring  | Laura Montemayor       |

<!-- vale gitlab.Spelling = YES -->
