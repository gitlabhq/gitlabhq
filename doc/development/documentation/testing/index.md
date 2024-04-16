---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
description: Learn how to contribute to GitLab Documentation.
---

# Documentation testing

GitLab documentation is stored in projects with code, and treated like code.
To maintain standards and quality of documentation, we use processes similar to
those used for code.

Merge requests containing changes to Markdown (`.md`) files run these CI/CD jobs:

- `docs-lint markdown`: Tests the documentation content with [Vale](vale.md),
  the Markdown structure with [markdownlint](markdownlint.md), and other tests
  [in `lint-docs.sh`](#tests-in-lint-docsh).
- `docs-lint links`: Checks the validity of internal links in the documentation suite.
- `mermaidlint`: Checks for invalid Mermaid charts in the documentation.
- `ui-docs-links lint`: Checks the validity of links from UI elements, such as files in `app/views` files.

## Tests in `lint-doc.sh`

The tests in
[`/scripts/lint-doc.sh`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/lint-doc.sh)
look for page content problems that Vale and markdownlint cannot test for.
The `docs-lint markdown` job fails if any of these `lint-doc.sh` tests fail:

- Curl (`curl`) commands must use long-form options (`--header`) instead of short options, like `-h`.
- Documentation pages must contain front matter indicating ownership of the page.
- Non-standard Unicode space characters (NBSP, NNBSP, ZWSP) must not be used in documentation,
  because they can cause irregularities in search indexing and grepping.
- `CHANGELOG.md` must not contain duplicate versions.
- No files in the `doc/` directory may be executable.
- Use `index.md` instead of `README.md`.
- Directories and filenames must use underscores instead of dashes.
- Directories and filenames must be in lower case.

## Tests in `docs-lint links`

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

## Tests in `mermaidlint`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144328) in GitLab 16.10.

[Mermaid](https://mermaid.js.org/) builds charts and diagrams from code.

The `mermaidlint` job runs on merge requests that contain changes to Markdown files.
The script (`scripts/lint/check_mermaid.mjs`) returns an error if any Markdown
files return a Mermaid syntax error.

To help debug your Mermaid charts, use the
[Mermaid Live Editor](https://mermaid-js.github.io/mermaid-live-editor/edit).

## Tests in `ui-docs-links lint`

The `ui-docs-links lint` job uses `haml-lint` to test that all documentation links from
UI elements (`app/views` files, for example) link to valid pages and anchors.

## Install documentation linters

To help adhere to the [documentation style guidelines](../styleguide/index.md), and
improve the content added to documentation, install documentation linters and
integrate them with your code editor. At a minimum, install [markdownlint](markdownlint.md)
and [Vale](vale.md) to match the checks run in build pipelines. Both tools can
integrate with your code editor.

## Run documentation tests locally

Similar to [previewing your changes locally](../review_apps.md), you can also run
documentation tests on your local computer. This has the advantage of:

- Speeding up the feedback loop. You can know of any problems with the changes in your branch
  without waiting for a CI/CD pipeline to run.
- Lowering costs. Running tests locally is cheaper than running tests on the cloud
  infrastructure GitLab uses.

It's important to:

- Keep the tools up-to-date, and [match the versions used](#tool-versions-used-in-cicd-pipelines) in our CI/CD pipelines.
- Run linters, documentation link tests, and UI link tests the same way they are
  run in CI/CD pipelines. It's important to use same configuration we use in
  CI/CD pipelines, which can be different than the default configuration of the tool.

### Run Vale or markdownlint locally

Installation and configuration instructions for [markdownlint](markdownlint.md)
and [Vale](vale.md) are available.

### Run `lint-doc.sh` locally

Use a Rake task to run the `lint-doc.sh` tests locally.

Prerequisites:

- You have either:
  - The [required lint tools installed](#install-documentation-linters) on your computer.
  - A working Docker or `containerd` installation, to use an image with these tools pre-installed.

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

### Run documentation link tests locally

To test links in the documentation locally:

1. Go to the [`gitlab-docs`](https://gitlab.com/gitlab-org/gitlab-docs) directory.
1. Run the following commands:

   ```shell
   # Check for broken internal links
   bundle exec nanoc check internal_links

   # Check for broken external links (might take a lot of time to complete).
   # This test is allowed to fail, and is run only in the gitlab-docs project CI
   bundle exec nanoc check internal_anchors
   ```

### Run UI link tests locally

To test documentation links in the GitLab UI locally:

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

Vale and markdownlint configurations are under source control in each
project, so updates must be committed to each project individually.

The configuration in the `gitlab` project should be treated as the source of truth,
and all updates should first be made there.

On a regular basis, the changes made in `gitlab` project to the Vale and markdownlint configuration should be
synchronized to the other projects. In each of the [supported projects](#supported-projects):

1. Create a new branch.
1. Copy the configuration files from the `gitlab` project into this branch, overwriting
   the project's old configuration. Make sure no project-specific changes from the `gitlab`
   project are included. For example, [`RelativeLinks.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab/RelativeLinks.yml)
   is hard coded for specific projects.
1. Create a merge request and submit it to a technical writer for review and merge.

## Update linting images

Lint tests run in CI/CD pipelines using images from the
`gitlab-docs` [container registry](https://gitlab.com/gitlab-org/gitlab-docs/container_registry).

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

## Configure pre-push hooks

Git [pre-push hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) allow Git users to:

- Run tests or other processes before pushing a branch.
- Avoid pushing a branch if failures occur with these tests.

[`lefthook`](https://github.com/Arkweid/lefthook) is a Git hooks manager. It makes configuring,
installing, and removing Git hooks simpler. Configuration for it is available in the
[`lefthook.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lefthook.yml)
file for the [`gitlab`](https://gitlab.com/gitlab-org/gitlab) project.

To set up `lefthook` for documentation linting, see
[Pre-push static analysis](../../contributing/style_guides.md#pre-push-static-analysis-with-lefthook).

To show Vale errors on push, see [Show Vale warnings on push](vale.md#show-vale-warnings-on-push).

## Disable linting on documentation

Some, but not all, linting can be disabled on documentation files:

- [Vale tests can be disabled](vale.md#disable-vale-tests) for all or part of a file.
- [`markdownlint` tests can be disabled](markdownlint.md#disable-markdownlint-tests) for all or part of a file.
- [Documentation link tests](#run-documentation-link-tests-locally) cannot be disabled.
- [UI link tests](#run-ui-link-tests-locally) cannot be disabled.

## Tool versions used in CI/CD pipelines

You should use linter versions that are the same as those used in our CI/CD pipelines for maximum compatibility
with the linting rules we use.

To match the versions of `markdownlint-cli2` and `vale` used in the GitLab projects, refer to:

- For projects managed with `asdf`, the `.tool-versions` file in the project. For example, the
  [`.tool-versions` file in the `gitlab` project](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.tool-versions).
- The [versions used (see `variables:` section)](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/.gitlab-ci.yml)
  when building the `image:docs-lint-markdown` Docker image containing these tools for CI/CD.

Versions set in these two locations should be the same.

| Tool                | Version  | Command                                   | Additional information |
|---------------------|----------|-------------------------------------------|------------------------|
| `markdownlint-cli2` | Latest   | `yarn global add markdownlint-cli2`       | None.                  |
| `markdownlint-cli2` | Specific | `yarn global add markdownlint-cli2@0.8.1` | The `@` indicates a specific version, and this example updates the tool to version `0.8.1`. |
| Vale (using `asdf`) | Specific | `asdf install`                            | Installs the version of Vale set in `.tool-versions` file in a project. |
| Vale (other)        | Specific | Not applicable.                           | Binaries can be [directly downloaded](https://github.com/errata-ai/vale/releases). |
| Vale (using `brew`) | Latest   | `brew update && brew upgrade vale`        | This command is for macOS only. |

## Supported projects

For the specifics of each test run in our CI/CD pipelines, see the configuration for those tests
in the relevant projects:

- <https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/docs.gitlab-ci.yml>
- <https://gitlab.com/gitlab-org/gitlab-runner/-/blob/main/.gitlab/ci/docs.gitlab-ci.yml>
- <https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/gitlab-ci-config/gitlab-com.yml>
- <https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/.gitlab-ci.yml>
- <https://gitlab.com/gitlab-org/cloud-native/gitlab-operator/-/blob/master/.gitlab-ci.yml>

We also run some documentation tests in the:

- GitLab CLI project: <https://gitlab.com/gitlab-org/cli/-/blob/main/.gitlab-ci.yml>
- GitLab Development Kit project:
  <https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/.gitlab/ci/test.gitlab-ci.yml>.
- Gitaly project: <https://gitlab.com/gitlab-org/gitaly/-/blob/master/.gitlab-ci.yml>.
- GitLab Duo Plugin for JetBrains: <https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/blob/main/.gitlab-ci.yml>
- GitLab VS Code Extension project: <https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/.gitlab-ci.yml>.
- GitLab Plugin for Neovim project: <https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/blob/main/.gitlab-ci.yml>.
- GitLab Language Server project: <https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/.gitlab-ci.yml>.
- GitLab Extension for Visual Studio project: <https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/blob/main/.gitlab-ci.yml>.
