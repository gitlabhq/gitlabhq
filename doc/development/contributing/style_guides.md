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

## Pre-push static analysis with Lefthook

[Lefthook](https://github.com/Arkweid/lefthook) is a Git hooks manager that allows
custom logic to be executed prior to Git committing or pushing. GitLab comes with
Lefthook configuration (`lefthook.yml`), but it must be installed.

We have a `lefthook.yml` checked in but it is ignored until Lefthook is installed.

### Uninstall Overcommit

We were using Overcommit prior to Lefthook, so you may want to uninstall it first with `overcommit --uninstall`.

### Install Lefthook

1. Install the `lefthook` Ruby gem:

   ```shell
   bundle install
   ```

1. Install Lefthook managed Git hooks:

   ```shell
   bundle exec lefthook install
   ```

1. Test Lefthook is working by running the Lefthook `prepare-commit-msg` Git hook:

   ```shell
   bundle exec lefthook run prepare-commit-msg
   ```

This should return a fully qualified path command with no other output.

### Lefthook configuration

The current Lefthook configuration can be found in [`lefthook.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lefthook.yml).

Before you push your changes, Lefthook automatically runs the following checks:

- Danger: Runs a subset of checks that `danger-review` runs on your merge requests.
- ES lint: Run `yarn run lint:eslint` checks (with the [`.eslintrc.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.eslintrc.yml) configuration) on the modified `*.{js,vue}` files. Tags: `frontend`, `style`.
- HAML lint: Run `bundle exec haml-lint` checks (with the [`.haml-lint.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.haml-lint.yml) configuration) on the modified `*.html.haml` files. Tags: `view`, `haml`, `style`.
- Markdown lint: Run `yarn markdownlint` checks on the modified `*.md` files. Tags: `documentation`, `style`.
- SCSS lint: Run `yarn lint:stylelint` checks (with the [`.stylelintrc`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.stylelintrc) configuration) on the modified `*.scss{,.css}` files. Tags: `stylesheet`, `css`, `style`.
- RuboCop: Run `bundle exec rubocop` checks (with the [`.rubocop.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.rubocop.yml) configuration) on the modified `*.rb` files. Tags: `backend`, `style`.
- Vale: Run `vale` checks (with the [`.vale.ini`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.vale.ini) configuration) on the modified `*.md` files. Tags: `documentation`, `style`.

In addition to the default configuration, you can define a [local configuration](https://github.com/Arkweid/lefthook/blob/master/docs/full_guide.md#local-config).

### Disable Lefthook temporarily

To disable Lefthook temporarily, you can set the `LEFTHOOK` environment variable to `0`. For instance:

```shell
LEFTHOOK=0 git push ...
```

### Run Lefthook hooks manually

To run the `pre-push` Git hook, run:

```shell
bundle exec lefthook run pre-push
```

For more information, check out [Lefthook documentation](https://github.com/Arkweid/lefthook/blob/master/docs/full_guide.md#run-githook-group-directly).

### Skip Lefthook checks per tag

To skip some checks based on tags when pushing, you can set the `LEFTHOOK_EXCLUDE` environment variable. For instance:

```shell
LEFTHOOK_EXCLUDE=frontend,documentation git push ...
```

As an alternative, you can create `lefthook-local.yml` with this structure:

```yaml
pre-push:
  exclude_tags:
    - frontend
    - documentation
```

For more information, check out [Lefthook documentation](https://github.com/Arkweid/lefthook/blob/master/docs/full_guide.md#skip-some-tags-on-the-fly).

### Skip or enable a specific Lefthook check

To skip or enable a check based on its name when pushing, you can add `skip: true`
or `skip: false` to the `lefthook-local.yml` section for that hook. For instance,
you might want to enable the gettext check to detect issues with `locale/gitlab.pot`:

```yaml
pre-push:
  commands:
    gettext:
      skip: false
```

For more information, check out [Lefthook documentation Skipping commands section](https://github.com/evilmartians/lefthook/blob/master/docs/full_guide.md#skipping-commands).

## Ruby, Rails, RSpec

Our codebase style is defined and enforced by [RuboCop](https://github.com/rubocop-hq/rubocop).

You can check for any offenses locally with `bundle exec rubocop --parallel`.
On the CI, this is automatically checked by the `static-analysis` jobs.

In addition, you can [integrate RuboCop](../developing_with_solargraph.md) into
supported IDEs using the [Solargraph](https://github.com/castwide/solargraph) gem.

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

We currently maintain Cops across several Ruby code bases, and not all of them are
specific to the GitLab application.
When creating a new cop that could be applied to multiple applications, we encourage you
to add it to our [GitLab Styles](https://gitlab.com/gitlab-org/gitlab-styles) gem.
If the Cop targets rules that only apply to the main GitLab application,
it should be added to [GitLab](https://gitlab.com/gitlab-org/gitlab) instead.

### Resolving RuboCop exceptions

When the number of RuboCop exceptions exceed the default [`exclude-limit` of 15](https://docs.rubocop.org/rubocop/1.2/usage/basic_usage.html#command-line-flags),
we may want to resolve exceptions over multiple commits. To minimize confusion,
we should track our progress through the exception list.

When auto-generating the `.rubocop_todo.yml` exception list for a particular Cop,
and more than 15 files are affected, we should add the exception list to
a different file, `.rubocop_manual_todo.yml`.

This ensures that our list isn't mistakenly removed by another auto generation of
the `.rubocop_todo.yml`. This also allows us greater visibility into the exceptions
which are currently being resolved.

One way to generate the initial list is to run the `todo` auto generation,
with `exclude limit` set to a high number.

```shell
bundle exec rubocop --auto-gen-config --auto-gen-only-exclude --exclude-limit=100000
```

You can then move the list from the freshly generated `.rubocop_todo.yml` for the Cop being actively
resolved and place it in the `.rubocop_manual_todo.yml`. In this scenario, do not commit auto generated
changes to the `.rubocop_todo.yml` as an `exclude limit` that is higher than 15 will make the
`.rubocop_todo.yml` hard to parse.

### Reveal existing RuboCop exceptions

To reveal existing RuboCop exceptions in the code that have been excluded via `.rubocop_todo.yml` and
`.rubocop_manual_todo.yml`, set the environment variable `REVEAL_RUBOCOP_TODO` to `1`.

This allows you to reveal existing RuboCop exceptions during your daily work cycle and fix them along the way.

NOTE:
Permanent `Exclude`s should be defined in `.rubocop.yml` instead of `.rubocop_manual_todo.yml`.

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

<!-- vale gitlab.Spelling = NO -->

We're following [Ciro Santilli's Markdown Style Guide](https://cirosantilli.com/markdown-style-guide/).

<!-- vale gitlab.Spelling = YES -->

## Documentation

See the dedicated [Documentation Style Guide](../documentation/styleguide/index.md).

## Python

See the dedicated [Python Development Guidelines](../python_guide/index.md).

## Misc

Code should be written in [US English](https://en.wikipedia.org/wiki/American_English).

---

[Return to Contributing documentation](index.md)
