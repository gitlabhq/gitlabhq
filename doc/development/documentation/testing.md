---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
description: Learn how to contribute to GitLab Documentation.
---

# Documentation testing

GitLab documentation is stored in projects with code and treated like code. Therefore, we use
processes similar to those used for code to maintain standards and quality of documentation.

We have tests:

- To lint the words and structure of the documentation.
- To check the validity of internal links in the documentation suite.
- To check the validity of links from UI elements, such as files in `app/views` files.

For the specifics of each test run in our CI/CD pipelines, see the configuration for those tests
in the relevant projects:

- <https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/docs.gitlab-ci.yml>
- <https://gitlab.com/gitlab-org/gitlab-runner/-/blob/main/.gitlab/ci/docs.gitlab-ci.yml>
- <https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/gitlab-ci-config/gitlab-com.yml>
- <https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/.gitlab-ci.yml>
- <https://gitlab.com/gitlab-org/cloud-native/gitlab-operator/-/blob/master/.gitlab-ci.yml>

We also run some documentation tests in the:

- GitLab Development Kit project:
  <https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/.gitlab/ci/test.gitlab-ci.yml>.
- Gitaly project: <https://gitlab.com/gitlab-org/gitaly/-/blob/master/.gitlab-ci.yml>.

## Run tests locally

Similar to [previewing your changes locally](review_apps.md), you can also
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

Merge requests containing changes to Markdown (`.md`) files run a `docs-lint markdown`
job. This job runs `markdownlint`, and a set of tests from
[`/scripts/lint-doc.sh`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/lint-doc.sh)
that look for page content problems that Vale and markdownlint cannot test for.
The job fails if any of these tests fail:

- Curl (`curl`) commands must use long-form options (`--header`) instead of short options, like `-h`.
- Documentation pages must contain front matter indicating ownership of the page.
- Non-standard Unicode space characters (NBSP, NNBSP, ZWSP) must not be used in documentation,
  because they can cause irregularities in search indexing and grepping.
- `CHANGELOG.md` must not contain duplicate versions.
- No files in the `doc/` directory may be executable.
- Use `index.md` instead of `README.md`.
- Directories and file names must use underscores instead of dashes.
- Directories and file names must be in lower case.

#### Run lint checks locally

Lint checks are performed by the [`lint-doc.sh`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/lint-doc.sh)
script and can be executed with the help of a Rake task as follows:

1. Go to your `gitlab` directory.
1. Run:

   ```shell
   rake lint:markdown
   ```

To specify a single file or directory you would like to run lint checks for, run:

```shell
MD_DOC_PATH=path/to/my_doc.md rake lint:markdown
```

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
- A working Docker or `containerd` installation, to use an image with these tools pre-installed.

### Documentation link tests

Merge requests containing changes to Markdown (`.md`) files run a `docs-lint links`
job, which runs two types of link checks. In both cases, links with destinations
that begin with `http` or `https` are considered external links, and skipped:

- `bundle exec nanoc check internal_links`: Tests links to internal pages.
- `bundle exec nanoc check internal_anchors`: Tests links to topic title anchors on internal pages.

Failures from these tests are displayed at the end of the test results in the **Issues found!** area.
For example, failures in the `internal_anchors` test follow this format:

```plaintext
[ ERROR ] internal_anchors - Broken anchor detected!
  - source file `/tmp/gitlab-docs/public/ee/user/application_security/api_fuzzing/index.html`
  - destination `/tmp/gitlab-docs/public/ee/development/code_review.html`
  - link `../../../development/code_review.html#review-response-slo`
  - anchor `#review-response-slo`
```

- **Source file**: The full path to the file containing the error. To find the
  file in the `gitlab` repository, replace `/tmp/gitlab-docs/public/ee` with `doc`, and `.html` with `.md`.
- **Destination**: The full path to the file not found by the test. To find the
  file in the `gitlab` repository, replace `/tmp/gitlab-docs/public/ee` with `doc`, and `.html` with `.md`.
- **Link**: The actual link the script attempted to find.
- **Anchor**: If present, the topic title anchor the script attempted to find.

Check for multiple instances of the same broken link on each page reporting an error.
Even if a specific broken link appears multiple times on a page, the test reports it only once.

#### Run document link tests locally

To execute documentation link tests locally:

1. Go to the [`gitlab-docs`](https://gitlab.com/gitlab-org/gitlab-docs) directory.
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

## Update linter configuration

[Vale configuration](#vale) and [markdownlint configuration](#markdownlint) is under source control in each
project, so updates must be committed to each project individually.

We consider the configuration in the `gitlab` project as the source of truth and that's where all updates should
first be made.

On a regular basis, the changes made in `gitlab` project to the Vale and markdownlint configuration should be
synchronized to the other projects. In `omnibus-gitlab`, `gitlab-runner`, and `charts/gitlab`:

1. Create a new branch.
1. Copy the configuration files from the `gitlab` project into this branch, overwriting
   the project's old configuration. Make sure no project-specific changes from the `gitlab`
   project are included. For example, [`RelativeLinks.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab/RelativeLinks.yml)
   is hard coded for specific projects.
1. Create a merge request and submit it to a technical writer for review and merge.

## Update linting images

Lint tests run in CI/CD pipelines using images from the `gitlab-docs` [container registry](https://gitlab.com/gitlab-org/gitlab-docs/container_registry).

If a new version of a dependency is released (like a new version of Ruby), we
should update the images to use the newer version. Then, we can update the configuration
files in each of our documentation projects to point to the new image.

To update the linting images:

1. In `gitlab-docs`, open a merge request to update `.gitlab-ci.yml` to use the new tooling
   version. ([Example MR](https://gitlab.com/gitlab-org/gitlab-docs/-/merge_requests/2571))
1. When merged, start a `Build docs.gitlab.com every hour` [scheduled pipeline](https://gitlab.com/gitlab-org/gitlab-docs/-/pipeline_schedules).
1. Go the pipeline you started, and manually run the relevant build-images job,
   for example, `image:docs-lint-markdown`.
1. In the job output, get the name of the new image.
   ([Example job output](https://gitlab.com/gitlab-org/gitlab-docs/-/jobs/2335033884#L334))
1. Verify that the new image was added to the container registry.
1. Open merge requests to update each of these configuration files to point to the new image.
   In each merge request, include a small doc update to trigger the job that uses the image.
   - <https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/docs.gitlab-ci.yml> ([Example MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85177))
   - <https://gitlab.com/gitlab-org/gitlab-runner/-/blob/main/.gitlab/ci/test.gitlab-ci.yml> ([Example MR](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3408))
   - <https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/gitlab-ci-config/gitlab-com.yml> ([Example MR](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/6037))
   - <https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/.gitlab-ci.yml> ([Example MR](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/2511))
   - <https://gitlab.com/gitlab-org/cloud-native/gitlab-operator/-/blob/master/.gitlab-ci.yml> ([Example MR](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator/-/merge_requests/462))
   - <https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/.gitlab/ci/test.gitlab-ci.yml> ([Example MR](https://gitlab.com/gitlab-org/gitlab-development-kit/-/merge_requests/2417))
1. In each merge request, check the relevant job output to confirm the updated image was
   used for the test. ([Example job output](https://gitlab.com/gitlab-org/charts/gitlab/-/jobs/2335470260#L24))
1. Assign the merge requests to any technical writer to review and merge.

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
- [`gitlab-operator`](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator)

This configuration is also used in build pipelines.

You can use markdownlint:

- On the command line, with either:
  - [`markdownlint-cli`](https://github.com/igorshubovych/markdownlint-cli#markdownlint-cli).
  - [`markdownlint-cli2`](https://github.com/DavidAnson/markdownlint-cli2#markdownlint-cli2).
- [In a code editor](#configure-editors).
- [In a `pre-push` hook](#configure-pre-push-hooks).

#### Markdown rule `MD044/proper-names` (capitalization)

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

### Vale

[Vale](https://vale.sh/) is a grammar, style, and word usage linter for the
English language. Vale's configuration is stored in the
[`.vale.ini`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.vale.ini) file located in the root
directory of projects.

Vale supports creating [custom tests](https://vale.sh/docs/topics/styles/) that extend any of
several types of checks, which we store in the `.linting/vale/styles/gitlab` directory in the
documentation directory of projects.

You can find Vale configuration in the following projects:

- [`gitlab`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc/.vale/gitlab)
- [`gitlab-runner`](https://gitlab.com/gitlab-org/gitlab-runner/-/tree/main/docs/.vale/gitlab)
- [`omnibus-gitlab`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/tree/master/doc/.vale/gitlab)
- [`charts`](https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master/doc/.vale/gitlab)
- [`gitlab-development-kit`](https://gitlab.com/gitlab-org/gitlab-development-kit/-/tree/main/doc/.vale/gitlab)

This configuration is also used in build pipelines, where
[error-level rules](#vale-result-types) are enforced.

You can use Vale:

- [On the command line](https://vale.sh/docs/vale-cli/structure/).
- [In a code editor](#configure-editors).
- [In a Git hook](#configure-pre-push-hooks). Vale only reports errors in the Git hook (the same
  configuration as the CI/CD pipelines), and does not report suggestions or warnings.

#### Vale result types

Vale returns three types of results:

- **Error** - For branding guidelines, trademark guidelines, and anything that causes content on
  the documentation site to render incorrectly.
- **Warning** - For general style guide rules, tenets, and best practices.
- **Suggestion** - For technical writing style preferences that may require refactoring of documentation or updates to an exceptions list.

The result types have these attributes:

| Result type  | Displays in CI/CD job output | Displays in MR diff | Causes CI/CD jobs to fail | Vale rule link |
|--------------|------------------------------|---------------------|---------------------------|----------------|
| `error`      | **{check-circle}** Yes       | **{check-circle}** Yes | **{check-circle}** Yes | [Error-level Vale rules](https://gitlab.com/search?utf8=✓&snippets=false&scope=&repository_ref=master&search=path%3Adoc%2F.vale%2Fgitlab+Error%3A&group_id=9970&project_id=278964) |
| `warning`    | **{dotted-circle}** No       | **{check-circle}** Yes | **{dotted-circle}** No | [Warning-level Vale rules](https://gitlab.com/search?utf8=✓&snippets=false&scope=&repository_ref=master&search=path%3Adoc%2F.vale%2Fgitlab+Warning%3A&group_id=9970&project_id=278964) |
| `suggestion` | **{dotted-circle}** No       | **{dotted-circle}** No | **{dotted-circle}** No | [Suggestion-level Vale rules](https://gitlab.com/search?utf8=✓&snippets=false&scope=&repository_ref=master&search=path%3Adoc%2F.vale%2Fgitlab+Suggestion%3A&group_id=9970&project_id=278964) |

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

#### Vale uppercase (acronym) test

The [`Uppercase.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab/Uppercase.yml)
test checks for incorrect usage of words in all capitals. For example, avoid usage
like `This is NOT important`.

If the word must be in all capitals, follow these guidelines:

| Flagged word                                                   | Guideline |
|----------------------------------------------------------------|-----------|
| Acronym (likely known by the average visitor to that page)     | Add the acronym to the list of words and acronyms in `Uppercase.yml`. |
| Acronym (likely not known by the average visitor to that page) | The first time the acronym is used, write it out fully followed by the acronym in parentheses. In later uses, use just the acronym by itself. For example: `This feature uses the File Transfer Protocol (FTP). FTP is...`. |
| Correctly capitalized name of a product or service           | Add the name to the list of words and acronyms in `Uppercase.yml`. |
| Command, variable, code, or similar                            | Put it in backticks or a code block. For example: ``Use `FALSE` as the variable value.`` |
| UI text from a third-party product                             | Rewrite the sentence to avoid it, or [add the vale exception code in-line](#disable-vale-tests). |

#### Vale readability score

In [`ReadingLevel.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab/ReadingLevel.yml),
we have implemented
[the Flesch-Kincaid grade level test](https://readable.com/readability/flesch-reading-ease-flesch-kincaid-grade-level/)
to determine the readability of our documentation.

As a general guideline, the lower the score, the more readable the documentation.
For example, a page that scores `12` before a set of changes, and `9` after, indicates an iterative improvement to readability. The score is not an exact science, but is meant to help indicate the
general complexity level of the page.

The readability score is calculated based on the number of words per sentence, and the number
of syllables per word. For more information, see [the Vale documentation](https://vale.sh/docs/topics/styles/#metric).

#### When to add a new Vale rule

It's tempting to add a Vale rule for every style guide rule. However, we should be
mindful of the effort to create and enforce a Vale rule, and the noise it creates.

In general, follow these guidelines:

- If you add an [error-level Vale rule](#vale-result-types), you must fix
  the existing occurrences of the issue in the documentation before you can add the rule.

  If there are too many issues to fix in a single merge request, add the rule at a
  `warning` level. Then, fix the existing issues in follow-up merge requests.
  When the issues are fixed, promote the rule to an `error`.

- If you add a warning-level or suggestion-level rule, consider:

  - How many more warnings or suggestions it creates in the Vale output. If the
    number of additional warnings is significant, the rule might be too broad.

  - How often an author might ignore it because it's acceptable in the context.
    If the rule is too subjective, it cannot be adequately enforced and creates
    unnecessary additional warnings.

  - Whether it's appropriate to display in the merge request diff in the GitLab UI.
    If the rule is difficult to implement directly in the merge request (for example,
    it requires page refactoring), set it to suggestion-level so it displays in local editors only.

### Install linters

At a minimum, install [markdownlint](#markdownlint) and [Vale](#vale) to match the checks run in build pipelines.

These tools can be [integrated with your code editor](#configure-editors).

#### Install markdownlint

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

#### Install Vale

Install [`vale`](https://github.com/errata-ai/vale/releases) using either:

- The [`asdf-vale` plugin](https://github.com/pdemagny/asdf-vale) if using [`asdf`](https://asdf-vm.com). In a checkout
  of a GitLab project with a `.tool-versions` file ([example](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.tool-versions)),
  run:

  ```shell
  asdf plugin add vale && asdf install vale
  ```

- A package manager:
  - macOS using `brew`, run: `brew install vale`.
  - Linux, use your distribution's package manager or a [released binary](https://github.com/errata-ai/vale/releases).

### Update linters

It's preferable to use linter versions that are the same as those used in our CI/CD pipelines for maximum compatibility
with the linting rules we use.

To match the versions of `markdownlint-cli` (or `markdownlint-cli2`) and `vale` used in the GitLab projects, refer to:

- For projects managed with `asdf`, the `.tool-versions` file in the project. For example, the
  [`.tool-versions` file in the `gitlab` project](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.tool-versions).
- The [versions used (see `variables:` section)](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/.gitlab-ci.yml)
  when building the `image:docs-lint-markdown` Docker image containing these tools for CI/CD.

Versions set in these two locations should be the same.

| Tool                | Version  | Command                                   | Additional information                                                                       |
|:--------------------|:---------|:------------------------------------------|:---------------------------------------------------------------------------------------------|
| `markdownlint-cli`  | Latest   | `yarn global add markdownlint-cli`        | None.                                                                                        |
| `markdownlint-cli2` | Latest   | `yarn global add markdownlint-cli2`       | None.                                                                                        |
| `markdownlint-cli`  | Specific | `yarn global add markdownlint-cli@0.35.0` | The `@` indicates a specific version, and this example updates the tool to version `0.35.0`. |
| `markdownlint-cli2` | Specific | `yarn global add markdownlint-cli2@0.8.1` | The `@` indicates a specific version, and this example updates the tool to version `0.8.1`.  |
| Vale (using `asdf`) | Specific | `asdf install`                            | Installs the version of Vale set in `.tool-versions` file in a project.                      |
| Vale (other)        | Specific | Not applicable.                           | Binaries can be [directly downloaded](https://github.com/errata-ai/vale/releases).           |
| Vale (using `brew`) | Latest   | `brew update && brew upgrade vale`        | This command is for macOS only.                                                              |

### Configure editors

Using linters in your editor is more convenient than having to run the commands from the
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

To configure Vale in your editor, install one of the following as appropriate:

- Visual Studio Code [`ChrisChinchilla.vale-vscode` extension](https://marketplace.visualstudio.com/items?itemName=ChrisChinchilla.vale-vscode).
  You can configure the plugin to [display only a subset of alerts](#show-subset-of-vale-alerts).
- Sublime Text [`SublimeLinter-vale` package](https://packagecontrol.io/packages/SublimeLinter-vale). To have Vale
  suggestions appears as blue instead of red (which is how errors appear), add `vale` configuration to your
  [SublimeLinter](http://sublimelinter.readthedocs.org) configuration:

  ```json
  "vale": {
    "styles": [{
      "mark_style": "outline",
      "scope": "region.bluish",
      "types": ["suggestion"]
    }]
  }
  ```

- [LSP for Sublime Text](https://lsp.sublimetext.io) package [`LSP-vale-ls`](https://packagecontrol.io/packages/LSP-vale-ls).
- Vim [ALE plugin](https://github.com/dense-analysis/ale).
- JetBrains IDEs - No plugin exists, but
  [this issue comment](https://github.com/errata-ai/vale-server/issues/39#issuecomment-751714451)
  contains tips for configuring an external tool.
- Emacs [Flycheck extension](https://github.com/flycheck/flycheck). A minimal configuration
  for Flycheck to work with Vale could look like:

  ```lisp
  (flycheck-define-checker vale
    "A checker for prose"
    :command ("vale" "--output" "line" "--no-wrap"
              source)
    :standard-input nil
    :error-patterns
      ((error line-start (file-name) ":" line ":" column ":" (id (one-or-more (not (any ":")))) ":" (message)   line-end))
    :modes (markdown-mode org-mode text-mode)
    :next-checkers ((t . markdown-markdownlint-cli))
  )

  (add-to-list 'flycheck-checkers 'vale)
  ```

  In this setup the `markdownlint` checker is set as a "next" checker from the defined `vale` checker.
  Enabling this custom Vale checker provides error linting from both Vale and markdownlint.

### Configure pre-push hooks

Git [pre-push hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) allow Git users to:

- Run tests or other processes before pushing a branch.
- Avoid pushing a branch if failures occur with these tests.

[`lefthook`](https://github.com/Arkweid/lefthook) is a Git hooks manager, making configuring,
installing, and removing Git hooks simpler.

Configuration for `lefthook` is available in the [`lefthook.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lefthook.yml)
file for the [`gitlab`](https://gitlab.com/gitlab-org/gitlab) project.

To set up `lefthook` for documentation linting, see
[Pre-push static analysis](../contributing/style_guides.md#pre-push-static-analysis-with-lefthook).

#### Show Vale warnings on push

By default, `lefthook` shows only Vale errors when pushing changes to a branch. The default branches
have no Vale errors, so any errors listed here are introduced by commits to the branch.

To also see the Vale warnings when pushing to a branch, set a local environment variable: `VALE_WARNINGS=true`.

Enable Vale warnings on push to improve the documentation suite by:

- Detecting warnings you might be introducing with your commits.
- Identifying warnings that already exist in the page, which you can resolve to reduce technical debt.

These warnings:

- Don't stop the push from working.
- Don't result in a broken pipeline.
- Include all warnings for a file, not just warnings that are introduced by the commits.

To enable Vale warnings on push:

- Automatically, add `VALE_WARNINGS=true` to your shell configuration.
- Manually, prepend `VALE_WARNINGS=true` to invocations of `lefthook`. For example:

  ```shell
  VALE_WARNINGS=true bundle exec lefthook run pre-push
  ```

You can also [configure your editor](#configure-editors) to show Vale warnings.

### Show subset of Vale alerts

You can set Visual Studio Code to display only a subset of Vale alerts when viewing files:

1. Go to **Preferences > Settings > Extensions > Vale**.
1. In **Vale CLI: Min Alert Level**, select the minimum alert level you want displayed in files.

To display only a subset of Vale alerts when running Vale from the command line, use
the `--minAlertLevel` flag, which accepts `error`, `warning`, or `suggestion`. Combine it with `--config`
to point to the configuration file in the project, if needed:

```shell
vale --config .vale.ini --minAlertLevel error doc/**/*.md
```

Omit the flag to display all alerts, including `suggestion` level alerts.

### Disable Vale tests

You can disable a specific Vale linting rule or all Vale linting rules for any portion of a
document:

- To disable a specific rule, add a `<!-- vale gitlab.rulename = NO -->` tag before the text, and a
  `<!-- vale gitlab.rulename = YES -->` tag after the text, replacing `rulename` with the file name of a test in the
  [GitLab styles](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc/.linting/vale/styles/gitlab)
  directory.
- To disable all Vale linting rules, add a `<!-- vale off -->` tag before the text, and a
  `<!-- vale on -->` tag after the text.

Whenever possible, exclude only the problematic rule and lines.

For more information, see
[Vale's documentation](https://vale.sh/docs/topics/scoping/).

### Disable markdownlint tests

To disable all markdownlint rules, add a `<!-- markdownlint-disable -->` tag before the text, and a
`<!-- markdownlint-enable -->` tag after the text.

To disable only a [specific rule](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md#rules),
add the rule number to the tag, for example `<!-- markdownlint-disable MD044 -->`
and `<!-- markdownlint-enable MD044 -->`.

Whenever possible, exclude only the problematic lines.
