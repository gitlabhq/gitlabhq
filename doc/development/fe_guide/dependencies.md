---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Frontend dependencies

## Package manager

We use [Yarn](https://yarnpkg.com/) to manage frontend dependencies. There are a few exceptions:

- [FontAwesome](https://fontawesome.com/), installed via the `font-awesome-rails` gem: we are working to replace it with
  [GitLab SVGs](https://gitlab-org.gitlab.io/gitlab-svgs/) icons library.
- [ACE](https://ace.c9.io/) editor, installed via the `ace-rails-ap` gem.
- Other dependencies found under `vendor/assets/`.

## Updating dependencies

### Renovate GitLab Bot

We use the [Renovate GitLab Bot](https://gitlab.com/gitlab-org/frontend/renovate-gitlab-bot) to
automatically create merge requests for updating dependencies of several projects. You can find the
up-to-date list of projects managed by the renovate bot in the project’s README. Some key dependencies
updated using renovate are:

- [`@gitlab/ui`](https://gitlab.com/gitlab-org/gitlab-ui)
- [`@gitlab/svgs`](https://gitlab.com/gitlab-org/gitlab-svgs)
- [`@gitlab/eslint-plugin`](https://gitlab.com/gitlab-org/frontend/eslint-plugin)

### Blocked dependencies

We discourage installing some dependencies in [GitLab repository](https://gitlab.com/gitlab-org/gitlab)
because they can create conflicts in the dependency tree. Blocked dependencies are declared in the
`blockDependencies` property of GitLab’s [`package.json` file](https://gitlab.com/gitlab-org/gitlab/-/blob/master/package.json).

## Dependency notes

### BootstrapVue

[BootstrapVue](https://bootstrap-vue.org/) is a component library built with Vue.js and Bootstrap.
We wrap BootstrapVue components in [GitLab UI](https://gitlab.com/gitlab-org/gitlab-ui/) with the
purpose of applying visual styles and usage guidelines specified in the
[Pajamas Design System](https://design.gitlab.com/). For this reason, we recommend not installing
BootstrapVue directly in the GitLab repository. Instead create a wrapper of the BootstrapVue
component you want to use in GitLab UI first.
