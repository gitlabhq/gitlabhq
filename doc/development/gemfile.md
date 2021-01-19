---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# `Gemfile` guidelines

When adding a new entry to `Gemfile` or upgrading an existing dependency pay
attention to the following rules.

## No gems fetched from Git repositories

We do not allow gems that are fetched from Git repositories. All gems have
to be available in the RubyGems index. We want to minimize external build
dependencies and build times.

## License compliance

Refer to [licensing guidelines](licensing.md) for ensuring license compliance.

## Upgrade Rails

When upgrading the Rails gem and its dependencies, you also should update the following:

- The [Gemfile in the `qa` directory](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/Gemfile).
- The [Gemfile in Gitaly Ruby](https://gitlab.com/gitlab-org/gitaly/-/blob/master/ruby/Gemfile),
  to ensure that we ship only one version of these gems.

You should also update NPM packages that follow the current version of Rails:

- `@rails/ujs`
- `@rails/actioncable`
