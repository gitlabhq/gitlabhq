---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Development style guides
---

## Editor/IDE styling standardization

We use [EditorConfig](https://editorconfig.org/) to automatically apply certain styling standards before files are saved
locally. Some editors and IDEs honor the `.editorconfig` settings [automatically by default](https://editorconfig.org/#pre-installed).

If your editor or IDE does not automatically support `.editorconfig`, we suggest investigating to
[see if a plugin exists](https://editorconfig.org/#download). For example, a
[plugin for vim](https://github.com/editorconfig/editorconfig-vim).

## Pre-commit and pre-push static analysis with Lefthook

[Lefthook](https://github.com/evilmartians/lefthook) is a Git hooks manager that allows
custom logic to be executed prior to Git committing or pushing. GitLab comes with
Lefthook configuration (`lefthook.yml`), but it must be installed.

We have a `lefthook.yml` checked in but it is ignored until Lefthook is installed.

### Uninstall Overcommit

We were using Overcommit prior to Lefthook, so you may want to uninstall it first with `overcommit --uninstall`.

### Install Lefthook

1. You can install lefthook in [different ways](https://github.com/evilmartians/lefthook/blob/master/docs/install.md#install-lefthook).
   If you do not choose to install it globally (for example, via Homebrew or package managers), and only want to use it for the GitLab project,
   you can install the Ruby gem via:

   ```shell
   bundle install
   ```

1. Install Lefthook managed Git hooks:

   ```shell
   # If installed globally
   lefthook install
   # Or if installed via ruby gem
   bundle exec lefthook install
   ```

1. Test Lefthook is working by running the Lefthook `pre-push` Git hook:

   ```shell
   # If installed globally
   lefthook run pre-push
   # Or if installed via ruby gem
   bundle exec lefthook run pre-push
   ```

This should return the Lefthook version and the list of executable commands with output.

### Lefthook configuration

Lefthook is configured with a combination of:

- Project configuration in [`lefthook.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lefthook.yml).
- Any [local configuration](https://github.com/evilmartians/lefthook/blob/master/README.md#local-config).

### Lefthook auto-fixing files

We have a custom lefthook target to run all the linters with auto-fix capabilities,
but just on the files which changed in your branch.

```shell
# If installed globally
lefthook run auto-fix
# Or if installed via ruby gem
bundle exec lefthook run auto-fix
```

### Disable Lefthook temporarily

To disable Lefthook temporarily, you can set the `LEFTHOOK` environment variable to `0`. For instance:

```shell
LEFTHOOK=0 git push ...
```

### Run Lefthook hooks manually

You can run the `pre-commit`, `pre-push`, and `auto-fix` hooks manually. For example:

```shell
bundle exec lefthook run pre-push
```

For more information, check out [Lefthook documentation](https://github.com/evilmartians/lefthook/blob/master/README.md#direct-control).

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

For more information, check out [Lefthook documentation](https://github.com/evilmartians/lefthook/blob/master/docs/configuration.md#exclude_tags).

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

For more information, check out [Lefthook documentation Skipping commands section](https://github.com/evilmartians/lefthook/blob/master/docs/configuration.md#skip).

## Database migrations

See the dedicated [Database Migrations Style Guide](../migration_style_guide.md).

## JavaScript

See the dedicated [JS Style Guide](../fe_guide/style/javascript.md).

## SCSS

See the dedicated [SCSS Style Guide](../fe_guide/style/scss.md).

## Ruby

See the dedicated [Ruby Style Guide](../backend/ruby_style_guide.md).

## Go

See the dedicated [Go standards and style guidelines](../go_guide/_index.md).

## Shell commands (Ruby)

See the dedicated [Guidelines for shell commands in the GitLab codebase](../shell_commands.md).

## Shell scripting

See the dedicated [Shell scripting standards and style guidelines](../shell_scripting_guide/_index.md).

## Markdown

<!-- vale gitlab_base.Spelling = NO -->

We're following [Ciro Santilli's Markdown Style Guide](https://cirosantilli.com/markdown-style-guide/).

<!-- vale gitlab_base.Spelling = YES -->

## Documentation

See the dedicated [Documentation Style Guide](../documentation/styleguide/_index.md).

### Guidelines for good practices

*Good practice* examples demonstrate encouraged ways of writing code while
comparing with examples of practices to avoid. These examples are labeled as
*Bad* or *Good*. In GitLab development guidelines, when presenting the cases,
it's recommended to follow a *first-bad-then-good* strategy. First demonstrate
the *Bad* practice (how things *could* be done, which is often still working
code), and then how things *should* be done better, using a *Good* example. This
is typically an improved example of the same code.

Consider the following guidelines when offering examples:

- First, offer the *Bad* example, and then the *Good* one.
- When only one bad case and one good case is given, use the same code block.
- When more than one bad case or one good case is offered, use separated code
  blocks for each. With many examples being presented, a clear separation helps
  the reader to go directly to the good part. Consider offering an explanation
  (for example, a comment, or a link to a resource) on why something is bad
  practice.
- Better and best cases can be considered part of the good cases' code block.
  In the same code block, precede each with comments: `# Better` and `# Best`.

Although the bad-then-good approach is acceptable for the GitLab development
guidelines, do not use it for user documentation. For user documentation, use
*Do* and *Don't*. For examples, see the [Pajamas Design System](https://design.gitlab.com/content/punctuation/).

## Python

See the dedicated [Python Development Guidelines](../python_guide/_index.md).

## Misc

Code should be written in [US English](https://en.wikipedia.org/wiki/American_English).
