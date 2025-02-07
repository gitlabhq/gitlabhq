---
stage: Verify
group: Pipeline Authoring
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Development guide for GitLab official CI/CD components
---

This document explains how to develop [CI/CD components](../../ci/components/_index.md) that are maintained by GitLab, either the official public ones or those for internal use.

The location for all official GitLab component projects is the [`gitlab.com/components`](https://gitlab.com/components) group.
This group contains all components that are designed to be generic, served to all GitLab users, and maintained by GitLab.
For example: SAST, Secret Detection and Code Quality components.
A component project can initially be created under a different group (for example `gitlab-org`)
but it needs to be moved into the `components` group before the first version gets published to the catalog. All projects under [`gitlab.com/components`](https://gitlab.com/components) group must be public

Components that are for GitLab internal use only, for example specific to `gitlab-org/gitlab` project, should be
implemented under `gitlab-org` group.

Component projects that are expected to be published in the [CI/CD catalog](../../ci/components/_index.md#cicd-catalog)
should first be dogfooded to ensure we stay on top of the project quality and have first-hand
experience with it.

## Define ownership

Official GitLab components are trusted by the community and require a high degree of quality and timely maintenance.
Components must be kept up to date, monitored for security vulnerabilities, and bugs fixed.

Each component project must have a set of owners and maintainers that are also domain experts.
Experts can be from any department in GitLab, from Engineering to Support, Customer Success, and Developer Relations.

If a component is related to a GitLab feature (for example Secret Detection), the team that owns the
feature category or is most closely related to it should maintain the project.
In this case, the Engineering Manager for the feature category is assigned as the project owner.

Members with the `owner` role for the project are the DRIs responsible for triaging open issues and merge requests to ensure they get addressed promptly.

The component project can be created by a separate team or individual initially but it must be transitioned
to a set of owners before the first version gets published to the catalog.

The `README.md` file in the project repository must indicate the main owners of the project so that
they can be contacted by the wider community if needed.

NOTE:
If a set of project owners cannot be guaranteed or the components cannot be dogfooded, we strongly recommend
not creating an official GitLab component project and instead let the wider community fulfill the demand
in the catalog.

## Development process

1. Create a project under [`gitlab.com/components`](https://gitlab.com/components)
   or ask one of the group owners to create an empty project for you.
1. Follow the [standard guide for creating components](../../ci/components/_index.md).
1. Add a concise project description that clearly describes the capabilities offered by the component project.
1. Make sure to follow the general guidance given to [write a component](../../ci/components/_index.md#write-a-component) as well as
   the guidance [for official components](#best-practices-for-official-components).
1. Add a `LICENSE.md` file with the MIT license ([example](https://gitlab.com/components/ruby/-/blob/d8db5288b01947e8a931d8d1a410befed69325a7/LICENSE.md)).
1. The project must have a `.gitlab-ci.yml` file that:
   - Validates all the components in the project correctly
     ([example](https://gitlab.com/components/secret-detection/-/blob/646d0fcbbf3c2a3e4b576f1884543c874041c633/.gitlab-ci.yml#L11-23)).
   - Contains a `release` job to publish newly released tags to the catalog
     ([example](https://gitlab.com/components/secret-detection/-/blob/646d0fcbbf3c2a3e4b576f1884543c874041c633/.gitlab-ci.yml#L50-58)).
1. For official component projects, upload the [official avatar image](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/cicd/img/avatar_component_project_v16_8.png) to the component project.

### Best practices for official components

1. Ensure that the `README.md` contains at least the sections below (for example, see the [Code quality component](https://gitlab.com/components/code-quality)):
   - **Overview**: The capabilities offered by the component project.
   - **Components**: Sub-sections for each component, each with:
     - **Usage**: Examples with and without inputs (when optional).
     - **Inputs**: A table showing the input names, types, default values (if any) and descriptions.
     - **Variables** (when applicable): The variable names, supported values, and descriptions.
   - **Contribute**: Notes and how to get in touch with the maintainers.
     Usually the contribution process should follow the [official guide](../../ci/components/_index.md).
1. Use underscores `_` for composite input names and hyphens `-` as separators, if necessary. For example: `service_x-project_name`.

## Review and contribution process for official components

It's possible that components in the project have a related [CI/CD template](templates.md) in the GitLab codebase.
In that case we need to cross link the component project and CI/CD template:

- Add a comment in the CI/CD template with the location of the related component project.
- Add a section in the `README.md` of the component project with the location of the existing CI/CD template.

When changes are applied to these components, check whether we can integrate the changes in the CI/CD template too.
This might not be possible due to the rigidity of versioning in CI/CD templates.

Ping any of the [maintainers](#default-maintainers-of-gitlab-official-components)
for reviews to ensure that the components are written in consistent style and follow the best practices.

## Default maintainers of GitLab official components

Each component project under [`gitlab.com/components`](https://gitlab.com/components) group should
have specific DRIs and maintainers, however the [`@gitlab-org/maintainers/ci-components`](https://gitlab.com/groups/gitlab-org/maintainers/ci-components/-/group_members?with_inherited_permissions=exclude)
group of maintainers is responsible for managing the `components` group in general.

The responsibilities for this group of maintainers:

- Manage any development and helper resources, such as toolkit components and project templates, to provide the best development experience.
- Manage any component projects that is missing a clear DRI, or is in the process of being developed, and work to find the right owners long term.
- Guide and mentor the maintainers of individual component projects, including during code reviews and when troubleshooting issues.
- Ensure best practices are applied and improved over time.

Requirements for becoming a maintainer:

- Have a an in-depth understanding of the [CI/CD YAML syntax](../../ci/yaml/_index.md) and features.
- Understand how CI components work and demonstrate experience developing them.
- Have a solid understanding of how to [write a component](../../ci/components/_index.md#write-a-component).

How to join the `gitlab-components` group of general maintainers:

- Review the [process for becoming a `gitlab-components` maintainer](https://handbook.gitlab.com/handbook/engineering/workflow/code-review/#project-maintainer-process-for-gitlab-components).
