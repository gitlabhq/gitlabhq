---
stage: none
group: Documentation Guidelines
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
description: Learn how to contribute to GitLab Documentation.
---

# Documentation testing

GitLab documentation is stored in projects with code and treated like code. Therefore, we use
processes similar to those used for code to maintain standards and quality of documentation.

We have tests:

- To lint the words and structure of the documentation.
- To check the validity of internal links within the documentation suite.
- To check the validity of links from UI elements, such as files in `app/views` files.

For the specifics of each test run in our CI/CD pipelines, see the configuration for those tests
in the relevant projects:

- <https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/docs.gitlab-ci.yml>
- <https://gitlab.com/gitlab-org/gitlab-runner/-/blob/main/.gitlab/ci/docs.gitlab-ci.yml>
- <https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/gitlab-ci-config/gitlab-com.yml>
- <https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/.gitlab-ci.yml>

## Run tests locally

Similar to [previewing your changes locally](index.md#previewing-the-changes-live), you can also
run these tests on your local computer. This has the advantage of:

- Speeding up the feedback loop. You can know of any problems with the changes in your branch
  without waiting for a CI/CD pipeline to run.
- Lowering costs. Running tests locally is cheaper than running tests on the cloud
  infrastructure GitLab uses.

To run tests locally, it's important to:

- [Install the tools](#install-linters), and [keep them up to date](#update-linters).
- Run [linters](#lint-checks), [documentation link tests](#documentation-link-tests), and
  [UI link tests](#ui-link-tests) the same way they are run in CI/CD pipelines. It's important to use
  same configuration we use in CI/CD pipelines, which can be different than the default configuration
  of the tool.

### Lint checks

Lint checks are performed by the [`lint-doc.sh`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/lint-doc.sh)
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

- Have the [required lint tools installed](#local-linters) on your computer.
- A working Docker installation, in which case an image with these tools pre-installed is used.

### Documentation link tests

To execute documentation link tests locally:

1. Navigate to the [`gitlab-docs`](https://gitlab.com/gitlab-org/gitlab-docs) directory.
1. Run the following commands:

   ```shell
   # Check for broken internal links
   bundle exec nanoc check internal_links

   # Check for broken external links (might take a lot of time to complete).
   # This test is set to be allowed to fail and is run only in the gitlab-docs project CI
   bundle exec nanoc check internal_anchors
   ```

### UI link tests

The `ui-docs-links lint` job uses `haml-lint` to test that all documentation links from
UI elements (`app/views` files, for example) are linking to valid pages and anchors.

To run the `ui-docs-links` test locally:

1. Open the `gitlab` directory in a terminal window.
1. Run:

   ```shell
   bundle exec haml-lint -i DocumentationLinks
   ```

If you receive an error the first time you run this test, run `bundle install`, which
installs the dependencies for GitLab, and try again.

If you don't want to install all of the dependencies to test the links, you can:

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

- [`gitlab`](https://gitlab.com/gitlab-org/gitlab)
- [`gitlab-runner`](https://gitlab.com/gitlab-org/gitlab-runner)
- [`omnibus-gitlab`](https://gitlab.com/gitlab-org/omnibus-gitlab)
- [`charts`](https://gitlab.com/gitlab-org/charts/gitlab)
- [`gitlab-development-kit`](https://gitlab.com/gitlab-org/gitlab-development-kit)

This configuration is also used in build pipelines.

You can use markdownlint:

- [On the command line](https://github.com/igorshubovych/markdownlint-cli#markdownlint-cli--).
- [In a code editor](#configure-editors).
- [In a `pre-push` hook](#configure-pre-push-hooks).

### Vale

[Vale](https://docs.errata.ai/vale/about/) is a grammar, style, and word usage linter for the
English language. Vale's configuration is stored in the
[`.vale.ini`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.vale.ini) file located in the root
directory of projects.

Vale supports creating [custom tests](https://errata-ai.github.io/vale/styles/) that extend any of
several types of checks, which we store in the `.linting/vale/styles/gitlab` directory in the
documentation directory of projects.

You can find Vale configuration in the following projects:

- [`gitlab`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc/.vale/gitlab)
- [`gitlab-runner`](https://gitlab.com/gitlab-org/gitlab-runner/-/tree/main/docs/.vale/gitlab)
- [`omnibus-gitlab`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/tree/master/doc/.vale/gitlab)
- [`charts`](https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master/doc/.vale/gitlab)
- [`gitlab-development-kit`](https://gitlab.com/gitlab-org/gitlab-development-kit/-/tree/master/doc/.vale/gitlab)

This configuration is also used in build pipelines, where
[error-level rules](#vale-result-types) are enforced.

You can use Vale:

- [On the command line](https://docs.errata.ai/vale/cli).
- [In a code editor](#configure-editors).
- [In a Git hook](#configure-pre-push-hooks). Vale only reports errors in the Git hook (the same
  configuration as the CI/CD pipelines), and does not report suggestions or warnings.

#### Vale result types

Vale returns three types of results: `suggestion`, `warning`, and `error`:

- **Suggestion**-level results are writing tips and aren't displayed in CI
  job output. Suggestions don't break CI. See a list of
  [suggestion-level rules](https://gitlab.com/search?utf8=✓&snippets=false&scope=&repository_ref=master&search=path%3Adoc%2F.vale%2Fgitlab+Suggestion%3A&group_id=9970&project_id=278964).
- **Warning**-level results are [Style Guide](styleguide/index.md) violations, aren't displayed in CI
  job output, and should contain clear explanations of how to resolve the warning.
  Warnings may be technical debt, or can be future error-level test items
  (after the Technical Writing team completes its cleanup). Warnings don't break CI. See a list of
  [warning-level rules](https://gitlab.com/search?utf8=✓&snippets=false&scope=&repository_ref=master&search=path%3Adoc%2F.vale%2Fgitlab+Warning%3A&group_id=9970&project_id=278964).
- **Error**-level results are Style Guide violations, and should contain clear explanations
  about how to resolve the error. Errors break CI and are displayed in CI job output.
  of how to resolve the error. Errors break CI and are displayed in CI job output. See a list of
  [error-level rules](https://gitlab.com/search?utf8=✓&snippets=false&scope=&repository_ref=master&search=path%3Adoc%2F.vale%2Fgitlab+Error%3A&group_id=9970&project_id=278964).

#### Vale spelling test

When Vale flags a valid word as a spelling mistake, you can fix it following these
guidelines:

| Flagged word                                         | Guideline |
|------------------------------------------------------|-----------|
| jargon                                               | Rewrite the sentence to avoid it. |
| *correctly-capitalized* name of a product or service | Add the word to the [vale spelling exceptions list](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab/spelling-exceptions.txt). |
| name of a person                                     | Remove the name if it's not needed, or [add the vale exception code in-line](#disable-vale-tests). |
| a command, variable, code, or similar                | Put it in backticks or a code block. For example: ``The git clone command can be used with the CI_COMMIT_BRANCH variable.`` -> ``The `git clone` command can be used with the `CI_COMMIT_BRANCH` variable.`` |
| UI text from GitLab                                  | Verify it correctly matches the UI, then: If it does not match the UI, update it. If it matches the UI, but the UI seems incorrect, create an issue to see if the UI needs to be fixed. If it matches the UI and seems correct, add it to the [vale spelling exceptions list](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab/spelling-exceptions.txt). |
| UI text from a third-party product                   | Rewrite the sentence to avoid it, or [add the vale exception code in-line](#disable-vale-tests). |

### Install linters

At a minimum, install [markdownlint](#markdownlint) and [Vale](#vale) to match the checks run in
build pipelines:

1. Install `markdownlint-cli`:

   ```shell
   yarn global add markdownlint-cli
   ```

   We recommend installing the version of `markdownlint-cli`
   [used (see `variables:` section)](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/.gitlab-ci.yml) when building
   the `image:docs-lint-markdown`.

1. Install [`vale`](https://github.com/errata-ai/vale/releases). For example, to install using
   `brew` for macOS, run:

   ```shell
   brew install vale
   ```

These tools can be [integrated with your code editor](#configure-editors).

### Update linters

It's important to use linter versions that are the same or newer than those run in
CI/CD. This provides access to new features and possible bug fixes.

To match the versions of `markdownlint-cli` and `vale` used in the GitLab projects, refer to the
[versions used (see `variables:` section)](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/.gitlab-ci.yml)
when building the `image:docs-lint-markdown` Docker image containing these tools for CI/CD.

| Tool               | Version   | Command                                   | Additional information |
|--------------------|-----------|-------------------------------------------|------------------------|
| `markdownlint-cli` | Latest    | `yarn global add markdownlint-cli`        | n/a                    |
| `markdownlint-cli` | Specific  | `yarn global add markdownlint-cli@0.23.2` | The `@` indicates a specific version, and this example updates the tool to version `0.23.2`. |
| Vale               | Latest    | `brew update && brew upgrade vale`        | This command is for macOS only. |
| Vale               | Specific  | n/a                                       | Not possible using `brew`, but can be [directly downloaded](https://github.com/errata-ai/vale/releases). |

### Configure editors

Using linters in your editor is more convenient than having to run the commands from the
command line.

To configure markdownlint in your editor, install one of the following as appropriate:

- Sublime Text [`SublimeLinter-contrib-markdownlint` package](https://packagecontrol.io/packages/SublimeLinter-contrib-markdownlint).
- Visual Studio Code [`DavidAnson.vscode-markdownlint` extension](https://marketplace.visualstudio.com/items?itemName=DavidAnson.vscode-markdownlint).
- Atom [`linter-node-markdownlint` package](https://atom.io/packages/linter-node-markdownlint).
- Vim [ALE plugin](https://github.com/dense-analysis/ale).

To configure Vale in your editor, install one of the following as appropriate:

- Sublime Text [`SublimeLinter-contrib-vale` package](https://packagecontrol.io/packages/SublimeLinter-contrib-vale).
- Visual Studio Code [`errata-ai.vale-server` extension](https://marketplace.visualstudio.com/items?itemName=errata-ai.vale-server).
  You can configure the plugin to
  [display only a subset of alerts](#show-subset-of-vale-alerts).

  In the extension's settings:

  - Select the **Use CLI** checkbox.
  - In the <!-- vale gitlab.Spelling = NO --> **Config** setting, enter an absolute
    path to [`.vale.ini`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.vale.ini)
    in one of the cloned GitLab repositories on your computer.
    <!-- vale gitlab.Spelling = YES -->

  - In the **Path** setting, enter the absolute path to the Vale binary. In most
    cases, `vale` should work. To find the location, run `which vale` in a terminal.

- Vim [ALE plugin](https://github.com/dense-analysis/ale).

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
[Pre-push static analysis](../contributing/style_guides.md#pre-push-static-analysis-with-lefthook).

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

Whenever possible, exclude only the problematic rule and lines.

For more information, see
[Vale's documentation](https://docs.errata.ai/vale/scoping#markup-based-configuration).

### Disable markdownlint tests

To disable all markdownlint rules, add a `<!-- markdownlint-disable -->` tag before the text, and a
`<!-- markdownlint-enable -->` tag after the text.

To disable only a [specific rule](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md#rules),
add the rule number to the tag, for example `<!-- markdownlint-disable MD044 -->`
and `<!-- markdownlint-enable MD044 -->`.

Whenever possible, exclude only the problematic lines.
