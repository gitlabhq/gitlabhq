---
type: reference, dev
stage: none
group: Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Style guides

## Editor/IDE styling standardization

We use [EditorConfig](https://editorconfig.org/) to automatically apply certain styling
standards before files are saved locally. Most editors/IDEs will honor the `.editorconfig`
settings automatically by default. If your editor/IDE does not automatically support `.editorconfig`,
we suggest investigating to see if a plugin exists. For instance here is the
[plugin for vim](https://github.com/editorconfig/editorconfig-vim).

## Pre-push static analysis

We strongly recommend installing [Lefthook](https://github.com/Arkweid/lefthook) to automatically check
for static analysis offenses before pushing your changes.

To install `lefthook`, run the following in your GitLab source directory:

```shell
# 1. Make sure to uninstall Overcommit first
overcommit --uninstall

# If using rbenv, at this point you may need to do: rbenv rehash

# 2. Install lefthook...

## With Homebrew (macOS)
brew install Arkweid/lefthook/lefthook

## Or with Go
go get github.com/Arkweid/lefthook

## Or with Rubygems
gem install lefthook

# 3. Install the Git hooks
lefthook install -f
```

Before you push your changes, Lefthook then automatically run Danger checks, and other checks
for changed files. This saves you time as you don't have to wait for the same errors to be detected
by CI/CD.

Lefthook relies on a pre-push hook to prevent commits that violate its ruleset.
To override this behavior, pass the environment variable `LEFTHOOK=0`. That is,
`LEFTHOOK=0 git push`.

You can also:

- Define [local configuration](https://github.com/Arkweid/lefthook/blob/master/docs/full_guide.md#local-config).
- Skip [checks per tag on the fly](https://github.com/Arkweid/lefthook/blob/master/docs/full_guide.md#skip-some-tags-on-the-fly).
  For example, `LEFTHOOK_EXCLUDE=frontend git push origin`.
- Run [hooks manually](https://github.com/Arkweid/lefthook/blob/master/docs/full_guide.md#run-githook-group-directly).
  For example, `lefthook run pre-push`.

## Ruby, Rails, RSpec

Our codebase style is defined and enforced by [RuboCop](https://github.com/rubocop-hq/rubocop).

You can check for any offenses locally with `bundle exec rubocop --parallel`.
On the CI, this is automatically checked by the `static-analysis` jobs.

For RuboCop rules that we have not taken a decision on yet, we follow the
[Ruby Style Guide](https://github.com/rubocop-hq/ruby-style-guide),
[Rails Style Guide](https://github.com/rubocop-hq/rails-style-guide), and
[RSpec Style Guide](https://github.com/rubocop-hq/rspec-style-guide) as general
guidelines to write idiomatic Ruby/Rails/RSpec, but reviewers/maintainers should
be tolerant and not too pedantic about style.

Similarly, some RuboCop rules are currently disabled, and for those,
reviewers/maintainers must not ask authors to use one style or the other, as both
are accepted. This isn't an ideal situation since this leaves space for
[bike-shedding](https://en.wiktionary.org/wiki/bikeshedding), and ideally we
should enable all RuboCop rules to avoid style-related
discussions/nitpicking/back-and-forth in reviews.

Additionally, we have a dedicated
[newlines style guide](../newlines_styleguide.md), as well as dedicated
[test-specific style guides and best practices](../testing_guide/index.md).

### Creating new RuboCop cops

Typically it is better for the linting rules to be enforced programmatically as it
reduces the aforementioned [bike-shedding](https://en.wiktionary.org/wiki/bikeshedding).

To that end, we encourage creation of new RuboCop rules in the codebase.

When creating a new cop that could be applied to multiple applications, we encourage you
to add it to our [GitLab Styles](https://gitlab.com/gitlab-org/gitlab-styles) gem.

## Database migrations

See the dedicated [Database Migrations Style Guide](../migration_style_guide.md).

## JavaScript

See the dedicated [JS Style Guide](../fe_guide/style/javascript.md).

## SCSS

See the dedicated [SCSS Style Guide](../fe_guide/style/scss.md).

## Go

See the dedicated [Go standards and style guidelines](../go_guide/index.md).

## Shell commands (Ruby)

See the dedicated [Guidelines for shell commands in the GitLab codebase](../shell_commands.md).

## Shell scripting

See the dedicated [Shell scripting standards and style guidelines](../shell_scripting_guide/index.md).

## Markdown

We're following [Ciro Santilli's Markdown Style Guide](https://cirosantilli.com/markdown-style-guide/).

## Documentation

See the dedicated [Documentation Style Guide](../documentation/styleguide/index.md).

## Python

See the dedicated [Python Development Guidelines](../python_guide/index.md).

## Misc

Code should be written in [US English](https://en.wikipedia.org/wiki/American_English).

---

[Return to Contributing documentation](index.md)
