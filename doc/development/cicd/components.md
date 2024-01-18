---
stage: Verify
group: Pipeline Authoring
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Development guide for GitLab CI/CD components

This document explains how to develop [CI/CD components](../../ci/components/index.md) that are maintained by GitLab.

The official location for all GitLab-maintained component projects is the [`gitlab.com/components`](https://gitlab.com/components) group.
This group contains all components that are designed to be generic, served to all GitLab users, and maintained by GitLab.

A component project can initially be created under a different group (for example `gitlab-org`)
but they need to be moved into the `components` group before the first version gets published to the catalog.

Components that are for GitLab internal use only, for example specific to `gitlab-org/gitlab` project, should be
implemented under `gitlab-org` group.

Component projects that are expected to be published in the [CI/CD catalog](../../ci/components/index.md#cicd-catalog)
should first be dogfooded to ensure we stay on top of the project quality and have first-hand
experience with it.

## Define ownership

GitLab-maintained components are trusted by the community and require a high degree of quality and timely maintenance.
Components must be kept up to date, monitored for security vulnerabilities, and bugs fixed.

Each component project must have a set of owners and maintainers that are also domain experts.
Experts can be from any department in GitLab, from Engineering to Support, Customer Success, and Developer Relations.

If a component is related to a GitLab feature (for example Secret Detection), the team that owns the
feature category or is most closely related to it should maintain the project.

The component project can be created by a separate team or individual initially but it must be transitioned
to a set of owners before the first version gets published to the catalog.

The `README.md` file in the project repository must indicate the main owners of the project so that
they can be contacted by the wider community if needed.

NOTE:
If a set of project owners cannot be guaranteed or the components cannot be dogfooded, we strongly recommend
not creating a GitLab-maintained component project and instead let the wider community fulfill the demand
in the catalog.

## Development process

1. Create a project under [`gitlab.com/components`](https://gitlab.com/components)
   or ask one of the group owners to create an empty project for you.
1. Follow the [standard guide for creating components](../../ci/components/index.md).
1. Add a concise project description that clearly describes the capabilities offered by the component project.
1. Ensure that the [best practices](../../ci/components/index.md#best-practices) are followed.
1. Use [semantic versioning](https://semver.org) in the form `MAJOR.MINOR` or `MAJOR.MINOR.PATCH`.
1. Add a `LICENSE.md` file with the MIT license.
1. The project must have a `.gitlab-ci.yml` file that:
   - Validates all the components in the project correctly.
   - Contains a `release` job to publish newly released tags to the catalog.
1. Ensure that the `README.md` contains at least the sections below (for example, see the [Code quality component](https://gitlab.com/components/code-quality)):
   - **Overview**: The capabilities offered by the component project.
   - **Components**: Sub-sections for each component, each with:
     - **Usage**: Examples with and without inputs (when optional).
     - **Inputs**: A table showing the input names, types, default values (if any) and descriptions.
     - **Variables** (when applicable): The variable names, possible values, and descriptions.
   - **Contribute**: Notes and how to get in touch with the maintainers.
     Usually the contribution process should follow the [official guide](../../ci/components/index.md).
1. Upload the [official avatar image](img/avatar_component_project.png) to the component project.

## Review and contribution process

It's possible that components in the project have a related [CI/CD template](templates.md) in the GitLab codebase.
In that case we need to cross link the component project and CI/CD template:

- Add a comment in the CI/CD template with the location of the related component project.
- Add a section in the `README.md` of the component project with the location of the existing CI/CD template.

When changes are applied to these components, check whether we can integrate the changes in the CI/CD template too.
This might not be possible due to the rigidity of versioning in CI/CD templates.

Ping [`@gitlab-org/maintainers/ci-components`](https://gitlab.com/groups/gitlab-org/maintainers/ci-components/-/group_members?with_inherited_permissions=exclude)
for reviews to ensure that the components are written in consistent style and follow the best practices.
