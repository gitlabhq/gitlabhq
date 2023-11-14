---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# CI/CD catalog **(PREMIUM ALL EXPERIMENT)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/407249) in GitLab 16.1.

The CI/CD catalog is a list of [components repositories](index.md#components-repository),
each containing resources that you can add to your CI/CD pipelines.

Each top level namespace has its own catalog, which contains all the releases from
components repositories hosted under it. You can create components repositories anywhere
under the desired top level namespace and the released components are available to
all projects in that namespace.

## Add a components repository to the Catalog

After components are added to a components repository, they can immediately be [used](index.md#use-a-component-in-a-cicd-configuration)
to build pipelines in other projects.

However, the repository is not discoverable. You must set the project as a catalog resource
for it to be visible in the CI/CD Catalog, then other users can discover it. You should only set a repository as a catalog resource when the components are ready for usage.

To set a project as a catalog resource:

1. On the left sidebar, select **Search or go to** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Scroll down to **CI/CD Catalog resource** and select the toggle to mark the project as a catalog resource.

Ensure the project has a clear [description](../../user/project/working_with_projects.md#edit-project-name-and-description),
as the project description is displayed in the component list in the catalog.

NOTE:
This action is not reversible, and the
component is always visible in the Catalog unless the repository is deleted. If a component has a bug or other issue, you can [create a new release](index.md#release-a-component) with an updated version.

After the repository is set as a components repository, it appears in the CI/CD Catalog of the namespace.

## View available components in the CI/CD Catalog

To view the components available to your project from the CI/CD Catalog:

1. On the left sidebar, select **Search or go to** and find your project.
1. On the left sidebar, select **Build > Pipeline Editor**.
1. Select **Browse CI/CD Catalog**.
