---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# CI/CD Catalog **(PREMIUM ALL EXPERIMENT)**

The CI/CD Catalog is a list of [components repositories](index.md#components-repository),
each containing resources that you can add to your CI/CD pipelines.

## Mark the project as a catalog resource

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/407249) in GitLab 16.1.

After components are added to a components repository, they can immediately be [used](index.md#use-a-component-in-a-cicd-configuration) to build pipelines in other projects.

However, this repository is not discoverable. You must mark this project as a catalog resource to allow it to be visible in the CI Catalog
so other users can discover it.

To mark a project as a catalog resource:

1. On the left sidebar, select **Search or go to** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Scroll down to **CI/CD Catalog resource** and select the toggle to mark the project as a catalog resource.

On the left sidebar, select **Search or go to** and find your project.

NOTE:
This action is not reversible.

## Convert a CI template to component

Any existing CI template, that you share with other projects via `include:` syntax, can be converted to a CI component.

1. Decide whether you want the component to be part of an existing [components repository](index.md#components-repository),
   if you want to logically group components together. Create and setup a [components repository](index.md#components-repository) otherwise.
1. Create a YAML file in the components repository according to the expected [directory structure](index.md#directory-structure).
1. Copy the content of the template YAML file into the new component YAML file.
1. Refactor the component YAML to follow the [best practices](index.md#best-practices) for components.
1. Leverage the `.gitlab-ci.yml` in the components repository to [test changes to the component](index.md#test-a-component).
1. Tag and [release the component](index.md#release-a-component).
