# GitLab Gems

This directory contains all GitLab built monorepo Gems.

## Development guidelines

The Gems created in this repository should adhere to the following rules:

- MUST: Contain `.gitlab-ci.yml`.
- MUST: Contain `.rubocop.yml` and be based on `gitlab-styles`.
- MUST: Be added to `.gitlab/ci/gitlab-gems.gitlab-ci.yml`.
- MUST NOT: Reference source code outside of `gems/<gem-name>/` with `require_relative "../../lib"`.
- MUST NOT: Require other gems that would result in circular dependencies.
- MAY: Reference other Gems in `gems/` folder or `vendor/gems/` with `gem <name>, path: "../gitlab-rspec"`.
- MAY: Define in `.gemspec` the owning group, like `group::tenant scale`.
- RECOMMENDED: Namespaced with `Gitlab::<GemName>`.
- RECOMMENDED: Be added to `CODEOWNERS`.
- MUST NOT: Have an active associated project created in [gitlab-org/ruby/gems/](https://gitlab.com/gitlab-org/ruby/gems).
