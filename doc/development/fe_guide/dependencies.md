---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
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

We use the [Renovate GitLab Bot](https://gitlab.com/gitlab-org/frontend/renovate-gitlab-bot) to
automatically create merge requests for updating dependencies of several projects.
You can find the up-to-date list of projects managed by the renovate bot in the project's README.

Some key dependencies updated using renovate are:

- [`@gitlab/ui`](https://gitlab.com/gitlab-org/gitlab-ui)
- [`@gitlab/svgs`](https://gitlab.com/gitlab-org/gitlab-svgs)
- [`@gitlab/eslint-plugin`](https://gitlab.com/gitlab-org/frontend/eslint-plugin)
- And any other package in the `@gitlab/` scope

We have the goal of updating [_all_ dependencies with renovate](https://gitlab.com/gitlab-org/frontend/rfcs/-/issues/21).

Updating dependencies automatically has several benefits, have a look at this [example MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/53613).

- MRs will be created automatically when new versions are released
- MRs can easily be rebased and updated with just checking a checkbox in the MR description
- MRs contain changelog summaries and links to compare the different package versions
- MRs can be assigned to people directly responsible for the dependencies

### Community contributions updating dependencies

It is okay to reject Community Contributions that solely bump dependencies.
Simple dependency updates are better done automatically for the reasons provided above.
If a community contribution needs to be rebased, runs into conflicts, or goes stale, the effort required
to instruct the contributor to correct it often outweighs the benefits.

If a dependency update is accompanied with significant migration efforts, due to major version updates,
a community contribution is acceptable.

Here is a message you can use to explain to community contributors as to why we reject simple updates:

```markdown
Hello CONTRIBUTOR!

Thank you very much for this contribution. It seems like you are doing a "simple" dependency update.

If a dependency update is as simple as increasing the version number, we'd like a Bot to do this to save you and ourselves some time.

This has certain benefits as outlined in our <a href="https://docs.gitlab.com/ee/development/fe_guide/dependencies.html#updating-dependencies">Frontend development guidelines</a>.

You might find that we do not currently update DEPENDENCY automatically, but we are planning to do so in [the near future](https://gitlab.com/gitlab-org/frontend/rfcs/-/issues/21).

Thank you for understanding, I will close this Merge Request.
/close
```

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
