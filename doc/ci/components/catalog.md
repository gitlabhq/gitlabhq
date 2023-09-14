---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# CI/CD catalog **(PREMIUM ALL EXPERIMENT)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/407249) in GitLab 16.1.

The CI/CD catalog is a list of [components repositories](index.md#components-repository),
each containing resources that you can add to your CI/CD pipelines.

## Mark a components repository as a catalog resource

After components are added to a components repository, they can immediately be [used](index.md#use-a-component-in-a-cicd-configuration)
to build pipelines in other projects.

However, this repository is not discoverable. You must mark this project as a catalog resource
to allow it to be visible in the CI/CD Catalog so other users can discover it.

To mark a project as a catalog resource:

1. On the left sidebar, select **Search or go to** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Scroll down to **CI/CD Catalog resource** and select the toggle to mark the project as a catalog resource.

Ensure the project has a clear [description](../../user/project/settings/index.md#edit-project-name-and-description),
as the project description is displayed in the component list in the catalog.

NOTE:
This action is not reversible.
