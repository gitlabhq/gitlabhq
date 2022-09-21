---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Frontend dependencies

We use [yarn@1](https://classic.yarnpkg.com/lang/en/) to manage frontend dependencies.

There are a few exceptions in the GitLab repository, stored in `vendor/assets/`.

## What are production and development dependencies?

These dependencies are defined in two groups within `package.json`, `dependencies` and `devDependencies`.
For our purposes, we consider anything that is required to compile our production assets a "production" dependency.
That is, anything required to run the `webpack` script with `NODE_ENV=production`.
Tools like `eslint`, `jest`, and various plugins and tools used in development are considered `devDependencies`.
This distinction is used by omnibus to determine which dependencies it requires when building GitLab.

Exceptions are made for some tools that we require in the
`compile-production-assets` CI job such as `webpack-bundle-analyzer` to analyze our
production assets post-compile.

## Updating dependencies

See the main [Dependencies](../dependencies.md) page for general information about dependency updates.

### Blocked dependencies

We discourage installing some dependencies in [GitLab repository](https://gitlab.com/gitlab-org/gitlab) because they can create conflicts in the dependency tree.
Blocked dependencies are declared in the `blockDependencies` property of the GitLab [`package.json`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/package.json).

## Dependency notes

### BootstrapVue

[BootstrapVue](https://bootstrap-vue.org/) is a component library built with Vue.js and Bootstrap.
We wrap BootstrapVue components in [GitLab UI](https://gitlab.com/gitlab-org/gitlab-ui/) with the
purpose of applying visual styles and usage guidelines specified in the
[Pajamas Design System](https://design.gitlab.com/). For this reason, we recommend not installing
BootstrapVue directly in the GitLab repository. Instead create a wrapper of the BootstrapVue
component you want to use in GitLab UI first.
