---
stage: none
group: Documentation Guidelines
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
description: Learn how to contribute to GitLab Documentation.
---

# Documentation testing

We treat documentation as code, and so use tests in our CI pipeline to maintain the
standards and quality of the docs. The current tests, which run in CI jobs when a
merge request with new or changed docs is submitted, are:

- [`docs lint`](https://gitlab.com/gitlab-org/gitlab/-/blob/0b562014f7b71f98540e682c8d662275f0011f2f/.gitlab/ci/docs.gitlab-ci.yml#L41):
  Runs several tests on the content of the docs themselves:
  - [`lint-doc.sh` script](https://gitlab.com/gitlab-org/gitlab/blob/master/scripts/lint-doc.sh)
    runs the following checks and linters:
    - All cURL examples use the long flags (ex: `--header`, not `-H`).
    - The `CHANGELOG.md` does not contain duplicate versions.
    - No files in `doc/` are executable.
    - No new `README.md` was added.
    - [markdownlint](#markdownlint).
    - [Vale](#vale).
  - Nanoc tests:
    - [`internal_links`](https://gitlab.com/gitlab-org/gitlab/-/blob/0b562014f7b71f98540e682c8d662275f0011f2f/.gitlab/ci/docs.gitlab-ci.yml#L58)
      checks that all internal links (ex: `[link](../index.md)`) are valid.
    - [`internal_anchors`](https://gitlab.com/gitlab-org/gitlab/-/blob/0b562014f7b71f98540e682c8d662275f0011f2f/.gitlab/ci/docs.gitlab-ci.yml#L60)
      checks that all internal anchors (ex: `[link](../index.md#internal_anchor)`)
      are valid.
  - [`ui-docs-links lint`](https://gitlab.com/gitlab-org/gitlab/-/blob/0b562014f7b71f98540e682c8d662275f0011f2f/.gitlab/ci/docs.gitlab-ci.yml#L62)
    checks that all links to docs from UI elements (`app/views` files, for example)
    are linking to valid docs and anchors.

## Run tests locally

Apart from [previewing your changes locally](index.md#previewing-the-changes-live), you can also run all lint checks
and Nanoc tests locally.

### Lint checks

Lint checks are performed by the [`lint-doc.sh`](https://gitlab.com/gitlab-org/gitlab/blob/master/scripts/lint-doc.sh)
script and can be executed as follows:

1. Navigate to the `gitlab` directory.
1. Run:

   ```shell
   MD_DOC_PATH=path/to/my_doc.md scripts/lint-doc.sh
   ```

Where `MD_DOC_PATH` points to the file or directory you would like to run lint checks for.
If you omit it completely, it defaults to the `doc/` directory.
The output should be similar to:

```plaintext
=> Linting documents at path /path/to/gitlab as <user>...
=> Checking for cURL short options...
=> Checking for CHANGELOG.md duplicate entries...
=> Checking /path/to/gitlab/doc for executable permissions...
=> Checking for new README.md files...
=> Linting markdown style...
=> Linting prose...
✔ 0 errors, 0 warnings and 0 suggestions in 1 file.
✔ Linting passed
```

This requires you to either:

- Have the required lint tools installed on your machine.
- A working Docker installation, in which case an image with these tools pre-installed is used.

### Nanoc tests

To execute Nanoc tests locally:

1. Navigate to the [`gitlab-docs`](https://gitlab.com/gitlab-org/gitlab-docs) directory.
1. Run:

   ```shell
   # Check for broken internal links
   bundle exec nanoc check internal_links

   # Check for broken external links (might take a lot of time to complete).
   # This test is set to be allowed to fail and is run only in the gitlab-docs project CI
   bundle exec nanoc check internal_anchors
   ```

### `ui-docs-links` test

The `ui-docs-links lint` job uses `haml-lint` to test that all links to docs from
UI elements (`app/views` files, for example) are linking to valid docs and anchors.

To run the `ui-docs-links` test locally:

1. Open the `gitlab` directory in a terminal window.
1. Run:

   ```shell
   bundle exec haml-lint -i DocumentationLinks
   ```

If you receive an error the first time you run this test, run `bundle install`, which
installs GitLab's dependencies, and try again.

If you don't want to install all of GitLab's dependencies to test the links, you can:

1. Open the `gitlab` directory in a terminal window.
1. Install `haml-lint`:

   ```shell
   gem install haml_lint
   ```

1. Run:

   ```shell
   haml-lint -i DocumentationLinks
   ```

If you manually install `haml-lint` with this process, it does not update automatically
and you should make sure your version matches the version used by GitLab.

## Local linters

To help adhere to the [documentation style guidelines](styleguide/index.md), and improve the content
added to documentation, [install documentation linters](#install-linters) and
[integrate them with your code editor](#configure-editors).

At GitLab, we mostly use:

- [markdownlint](#markdownlint)
- [Vale](#vale)

### markdownlint

[markdownlint](https://github.com/DavidAnson/markdownlint) checks that Markdown syntax follows
[certain rules](https://github.com/DavidAnson/markdownlint/blob/master/doc/Rules.md#rules), and is
used by the `docs-lint` test.

Our [Documentation Style Guide](styleguide/index.md#markdown) and
[Markdown Guide](https://about.gitlab.com/handbook/markdown-guide/) elaborate on which choices must
be made when selecting Markdown syntax for GitLab documentation. This tool helps catch deviations
from those guidelines.

markdownlint configuration is found in the following projects:

- [`gitlab`](https://gitlab.com/gitlab-org/gitlab/blob/master/.markdownlint.json)
- [`gitlab-runner`](https://gitlab.com/gitlab-org/gitlab-runner/blob/master/.markdownlint.json)
- [`omnibus-gitlab`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/.markdownlint.json)
- [`charts`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/.markdownlint.json)
- [`gitlab-development-kit`](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/master/.markdownlint.json)

This configuration is also used within build pipelines.

You can use markdownlint:

- [On the command line](https://github.com/igorshubovych/markdownlint-cli#markdownlint-cli--).
- [Within a code editor](#configure-editors).
- [In a `pre-push` hook](#configure-pre-push-hooks).

### Vale

[Vale](https://errata-ai.gitbook.io/vale/) is a grammar, style, and word usage linter for the
English language. Vale's configuration is stored in the
[`.vale.ini`](https://gitlab.com/gitlab-org/gitlab/blob/master/.vale.ini) file located in the root
directory of projects.

Vale supports creating [custom tests](https://errata-ai.github.io/vale/styles/) that extend any of
several types of checks, which we store in the `.linting/vale/styles/gitlab` directory within the
documentation directory of projects.

Vale configuration is found in the following projects:

- [`gitlab`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc/.vale/gitlab)
- [`gitlab-runner`](https://gitlab.com/gitlab-org/gitlab-runner/-/tree/master/docs/.vale/gitlab)
- [`omnibus-gitlab`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/tree/master/doc/.vale/gitlab)
- [`charts`](https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master/doc/.vale/gitlab)
- [`gitlab-development-kit`](https://gitlab.com/gitlab-org/gitlab-development-kit/-/tree/master/doc/.vale/gitlab)

This configuration is also used within build pipelines.

You can use Vale:

- [On the command line](https://errata-ai.gitbook.io/vale/getting-started/usage).
- [Within a code editor](#configure-editors).
- [In a Git hook](#configure-pre-push-hooks). Vale only reports errors in the Git hook (the same
  configuration as the CI/CD pipelines), and does not report suggestions or warnings.

### Install linters

At a minimum, install [markdownlint](#markdownlint) and [Vale](#vale) to match the checks run in
build pipelines:

1. Install `markdownlint-cli`, using either:

   - `npm`:

     ```shell
     npm install -g markdownlint-cli
     ```

   - `yarn`:

     ```shell
     yarn global add markdownlint-cli
     ```

     We recommend installing the version of `markdownlint-cli` currently used in the documentation
     linting [Docker image](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/master/.gitlab-ci.yml#L420).

1. Install [`vale`](https://github.com/errata-ai/vale/releases). For example, to install using
   `brew` for macOS, run:

   ```shell
   brew install vale
   ```

   We recommend installing the version of Vale currently used in the documentation linting
   [Docker image](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/master/.gitlab-ci.yml#L419).

In addition to using markdownlint and Vale at the command line, these tools can be
[integrated with your code editor](#configure-editors).

### Configure editors

To configure markdownlint within your editor, install one of the following as appropriate:

- [Sublime Text](https://packagecontrol.io/packages/SublimeLinter-contrib-markdownlint)
- [Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=DavidAnson.vscode-markdownlint)
- [Atom](https://atom.io/packages/linter-node-markdownlint)
- [Vim](https://github.com/dense-analysis/ale)

To configure Vale within your editor, install one of the following as appropriate:

- The Sublime Text [`SublimeLinter-contrib-vale` plugin](https://packagecontrol.io/packages/SublimeLinter-contrib-vale).
- The Visual Studio Code [`errata-ai.vale-server` extension](https://marketplace.visualstudio.com/items?itemName=errata-ai.vale-server).
  You don't need Vale Server to use the plugin. You can configure the plugin to
  [display only a subset of alerts](#show-subset-of-vale-alerts).
- [Vim](https://github.com/dense-analysis/ale).

We don't use [Vale Server](https://errata-ai.github.io/vale/#using-vale-with-a-text-editor-or-another-third-party-application).

### Configure pre-push hooks

Git [pre-push hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) allow Git users to:

- Run tests or other processes before pushing a branch.
- Avoid pushing a branch if failures occur with these tests.

[`lefthook`](https://github.com/Arkweid/lefthook) is a Git hooks manager, making configuring,
installing, and removing Git hooks easy.

Configuration for `lefthook` is available in the [`lefthook.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lefthook.yml)
file for the [`gitlab`](https://gitlab.com/gitlab-org/gitlab) project.

To set up `lefthook` for documentation linting, see
[Pre-push static analysis](../contributing/style_guides.md#pre-push-static-analysis).

### Show subset of Vale alerts

You can set Visual Studio Code to display only a subset of Vale alerts when viewing files:

1. Go to **Preferences > Settings > Extensions > Vale**.
1. In **Vale CLI: Min Alert Level**, select the minimum alert level you want displayed in files.

To display only a subset of Vale alerts when running Vale from the command line, use
the `--minAlertLevel` flag, which accepts `error`, `warning`, or `suggestion`. Combine it with `--config`
to point to the configuration file within the project, if needed:

```shell
vale --config .vale.ini --minAlertLevel error doc/**/*.md
```

Omit the flag to display all alerts, including `suggestion` level alerts.

### Disable Vale tests

You can disable a specific Vale linting rule or all Vale linting rules for any portion of a
document:

- To disable a specific rule, add a `<!-- vale gitlab.rulename = NO -->` tag before the text, and a
  `<!-- vale gitlab.rulename = YES -->` tag after the text, replacing `rulename` with the filename
  of a test in the
  [GitLab styles](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc/.linting/vale/styles/gitlab)
  directory.
- To disable all Vale linting rules, add a `<!-- vale off -->` tag before the text, and a
  `<!-- vale on -->` tag after the text.

Whenever possible, exclude only the problematic rule and line(s).

For more information, see
[Vale's documentation](https://errata-ai.gitbook.io/vale/getting-started/markup#markup-based-configuration).
