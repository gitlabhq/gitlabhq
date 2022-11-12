---
status: proposed
creation-date: "2022-09-14"
authors: [ "@fabio", "@grzesiek" ]
coach: "@kamil"
approvers: [ "@dov" ]
owning-stage: "~devops::verify"
participating-stages: []
---

# CI/CD pipeline components catalog

DISCLAIMER:
This page contains information related to upcoming products, features, and functionality.
It is important to note that the information presented is for informational purposes only.
Please do not rely on this information for purchasing or planning purposes.
As with all projects, the items mentioned on this page are subject to change or delay.
The development, release, and timing of any products, features, or functionality remain at the
sole discretion of GitLab Inc.

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

A pipeline component is a reusable single-purpose building block that abstracts away a single pipeline configuration unit. Components are used to compose a part or entire pipeline configuration.
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

## Proposal

Prerequisites to create a component:

- Create a project. Description and avatar are highly recommended to improve discoverability.
- Add a `README.md` in the top level directory that documents the component.
  What it does, how to use it, how to contribute, etc.
  This file is mandatory.
- Add a `.gitlab-ci.yml` in the top level directory to test that the components works as expected.
  This file is highly recommended.

Characteristics of a component:

- It must have a **name** to be referenced to and **description** for extra details.
- It must specify its **type** which defines how it can be used (raw configuration to be `include`d, child pipeline workflow, job step).
- It must define its **content** based on the type.
- It must specify **input parameters** that it accepts. Components should depend on input parameters for dynamic values and not environment variables.
- It can optionally define **output data** that it returns.
- Its YAML specification should be **validated statically** (for example: using JSON schema validators).
- It should be possible to use specific **versions** of a component by referencing official releases and SHA.
- It should be possible to use components defined locally in the same repository.

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
