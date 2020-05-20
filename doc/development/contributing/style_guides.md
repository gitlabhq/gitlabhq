# Style guides

## Editor/IDE styling standardization

We use [EditorConfig](https://editorconfig.org/) to automatically apply certain styling
standards before files are saved locally. Most editors/IDEs will honor the `.editorconfig`
settings automatically by default. If your editor/IDE does not automatically support `.editorconfig`,
we suggest investigating to see if a plugin exists. For instance here is the
[plugin for vim](https://github.com/editorconfig/editorconfig-vim).

## Pre-commit static analysis

You're strongly advised to install
[Overcommit](https://github.com/sds/overcommit) to automatically check for
static analysis offenses before committing locally.

In your GitLab source directory run:

```shell
make -C tooling/overcommit
```

Then before a commit is created, Overcommit will automatically check for
RuboCop (and other checks) offenses on every modified file.

This saves you time as you don't have to wait for the same errors to be detected
by the CI.

Overcommit relies on a pre-commit hook to prevent commits that violate its ruleset.
If you wish to override this behavior, it can be done by passing the ENV variable
`OVERCOMMIT_DISABLE`; i.e. `OVERCOMMIT_DISABLE=1 git rebase master` to rebase while
disabling the Git hook.

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

We're following [Ciro Santilli's Markdown Style Guide](https://cirosantilli.com/markdown-style-guide).

## Documentation

See the dedicated [Documentation Style Guide](../documentation/styleguide.md).

## Python

See the dedicated [Python Development Guidelines](../python_guide/index.md).

## Misc

Code should be written in [US English](https://en.wikipedia.org/wiki/American_English).

---

[Return to Contributing documentation](index.md)
