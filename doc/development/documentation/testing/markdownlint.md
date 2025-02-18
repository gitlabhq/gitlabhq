---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
description: Learn how to contribute to GitLab Documentation.
title: markdownlint documentation tests
---

[markdownlint](https://github.com/DavidAnson/markdownlint) checks that Markdown syntax follows
[certain rules](https://github.com/DavidAnson/markdownlint/blob/master/doc/Rules.md#rules), and is
used by the `docs-lint` test.

Our [Documentation Style Guide](../styleguide/_index.md#markdown) and
[Markdown Guide](https://handbook.gitlab.com/docs/markdown-guide/) elaborate on which choices must
be made when selecting Markdown syntax for GitLab documentation. This tool helps catch deviations
from those guidelines.

markdownlint configuration is found in the following projects:

- [`gitlab`](https://gitlab.com/gitlab-org/gitlab)
- [`gitlab-runner`](https://gitlab.com/gitlab-org/gitlab-runner)
- [`omnibus-gitlab`](https://gitlab.com/gitlab-org/omnibus-gitlab)
- [`charts`](https://gitlab.com/gitlab-org/charts/gitlab)
- [`gitlab-development-kit`](https://gitlab.com/gitlab-org/gitlab-development-kit)
- [`gitlab-operator`](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator)

This configuration is also used in build pipelines.

You can use markdownlint:

- On the command line, with either:
  - [`markdownlint-cli`](https://github.com/igorshubovych/markdownlint-cli#markdownlint-cli).
  - [`markdownlint-cli2`](https://github.com/DavidAnson/markdownlint-cli2#markdownlint-cli2).
- [In a code editor](#configure-markdownlint-in-your-editor).
- [In a `pre-push` hook](_index.md#configure-pre-push-hooks).

## Install markdownlint

You can install either `markdownlint-cli` or `markdownlint-cli2` to run `markdownlint`.

To install `markdownlint-cli`, run:

```shell
yarn global add markdownlint-cli
```

To install `markdownlint-cli2`, run:

```shell
yarn global add markdownlint-cli2
```

You should install the version of `markdownlint-cli` or `markdownlint-cli2`
[used (see `variables:` section)](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/.gitlab-ci.yml) when building
the `image:docs-lint-markdown`.

## Configure markdownlint in your editor

Using markdownlint in your editor is more convenient than having to run the commands from the
command line.

To configure markdownlint in your editor, install one of the following as appropriate:

- Visual Studio Code [`DavidAnson.vscode-markdownlint` extension](https://marketplace.visualstudio.com/items?itemName=DavidAnson.vscode-markdownlint).
- Sublime Text [`SublimeLinter-contrib-markdownlint` package](https://packagecontrol.io/packages/SublimeLinter-contrib-markdownlint).
  This package uses `markdownlint-cli` by default, but can be configured to use `markdownlint-cli2` with this
  SublimeLinter configuration:

  ```json
  "markdownlint": {
    "executable": [ "markdownlint-cli2" ]
  }
  ```

- Vim [ALE plugin](https://github.com/dense-analysis/ale).
- Emacs [Flycheck extension](https://github.com/flycheck/flycheck). `Flycheck` supports
  `markdownlint-cli` out of the box, but you must add a `.dir-locals.el` file to
  point it to the `.markdownlint.yml` at the base of the project directory:

  ```lisp
  ;; Place this code in a file called `.dir-locals.el` at the root of the gitlab project.
  ((markdown-mode . ((flycheck-markdown-markdownlint-cli-config . ".markdownlint.yml"))))
  ```

## Run `markdownlint-cli2` locally

You can run `markdownlint-cli2` from anywhere in your repository. From the root of your repository,
you don't need to specify the location of the configuration file. If you run it from elsewhere
in your repository, you must specify the configuration file's location. In these commands,
replace `doc/**/*.md` with the path to the Markdown files in your repository:

```shell
# From the root directory, you don't need to specify the configuration file
$ markdownlint-cli2 'doc/**/*.md'

# From elsewhere in the repository, specify the configuration file
$ markdownlint-cli2 --config .markdownlint-cli2.yaml 'doc/**/*.md'
```

For a full list of command-line options, see [Command Line](https://github.com/DavidAnson/markdownlint-cli2?tab=readme-ov-file#command-line)
in the `markdownlint-cli2` documentation.

## Disable markdownlint tests

To disable all markdownlint rules, add a `<!-- markdownlint-disable -->` tag before the text, and a
`<!-- markdownlint-enable -->` tag after the text.

To disable only a [specific rule](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md#rules),
add the rule number to the tag, for example `<!-- markdownlint-disable MD044 -->`
and `<!-- markdownlint-enable MD044 -->`.

Whenever possible, exclude only the problematic lines.

## Troubleshooting

### Markdown rule `MD044/proper-names` (capitalization)

A rule that can cause confusion is `MD044/proper-names`. The failure, or
how to correct it, might not be immediately clear.
This rule checks a list of known words, listed in the `.markdownlint.yml`
file in each project, to verify proper use of capitalization and backticks.
Words in backticks are ignored by markdownlint.

In general, product names should follow the exact capitalization of the official
names of the products, protocols, and so on.

Some examples fail if incorrect capitalization is used:

- MinIO (needs capital `IO`)
- NGINX (needs all capitals)
- runit (needs lowercase `r`)

Additionally, commands, parameters, values, filenames, and so on must be
included in backticks. For example:

- "Change the `needs` keyword in your `.gitlab-ci.yml`..."
  - `needs` is a parameter, and `.gitlab-ci.yml` is a file, so both need backticks.
    Additionally, `.gitlab-ci.yml` without backticks fails markdownlint because it
    does not have capital G or L.
- "Run `git clone` to clone a Git repository..."
  - `git clone` is a command, so it must be lowercase, while Git is the product,
    so it must have a capital G.
