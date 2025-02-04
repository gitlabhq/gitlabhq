---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
description: Learn how to contribute to GitLab Documentation.
title: Documentation testing
---

GitLab documentation is stored in projects with code, and treated like code.
To maintain standards and quality of documentation, we use processes similar to
those used for code.

Merge requests containing changes to Markdown (`.md`) files run these CI/CD jobs:

- `docs-lint markdown`: Runs several types of tests, including:
  - [Vale](vale.md): Checks documentation content.
  - [markdownlint](markdownlint.md): Checks Markdown structure.
  - [`lint-docs.sh`](#tests-in-lint-docsh) script: Miscellaneous tests, including
    [`mermaidlint`](#mermaid-chart-linting) to check for invalid Mermaid charts.
- `docs-lint links`: Checks the validity of [relative links](links.md#run-the-relative-link-test-locally) in the documentation suite.
- `ui-docs-links lint`: Checks links to documentation [from `.haml` files](links.md#run-haml-lint-tests).
- `rubocop-docs`: Checks links to documentation [from `.rb` files](links.md#run-rubocop-tests).
- `eslint-docs`: Checks links to documentation [from `.js` and `.vue` files](links.md#run-eslint-tests).
- `docs-lint redirects`: Checks for deleted or renamed documentation files without [redirects](../redirects.md).
- `docs code_quality` and `code_quality cache`: Runs [code quality](../../../ci/testing/code_quality.md)
  to add Vale [warnings and errors into the MR changes tab (diff view)](../../../ci/testing/code_quality.md#merge-request-changes-view).

A few files are generated from scripts. A CI/CD job fails when either the source code files
or the documentation files are updated without following the correct process:

- `graphql-verify`: Fails when `doc/api/graphql/reference/_index.md` is not updated
  with the [update process](../../rake_tasks.md#update-graphql-documentation-and-schema-definitions).
- `docs-lint deprecations-and-removals`: Fails when `doc/update/deprecations.md` is
  not updated with the [update process](../../deprecation_guidelines/_index.md#update-the-deprecations-and-removals-documentation).

For a full list of automated files, see [Automated pages](../site_architecture/automation.md).

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
- Mermaid charts must render without errors.

### Mermaid chart linting

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144328) in GitLab 16.10.

[Mermaid](https://mermaid.js.org/) builds charts and diagrams from code.

The script (`scripts/lint/check_mermaid.mjs`) runs during `lint-doc.sh` checks on
all merge requests that contain changes to Markdown files. The script returns an
error if any Markdown files return a Mermaid syntax error.

To help debug your Mermaid charts, use the
[Mermaid Live Editor](https://mermaid-js.github.io/mermaid-live-editor/edit).

## Tests in `docs-lint links` and other jobs

To check for broken links, merge requests containing changes to Markdown (`.md`) files run these jobs in their
pipelines:

- `docs-lint links` job in the `gitlab` project. For example: <https://gitlab.com/gitlab-org/gitlab/-/jobs/7065686331>.
- `docs-lint links` job in the `omnibus-gitlab` project. For example: <https://gitlab.com/gitlab-org/omnibus-gitlab/-/jobs/7065337075>.
- `docs-lint links` job in the `gitlab-operator` project.
- `docs:lint markdown` job in the `gitlab-runner` project, which includes link checking. For example:
  <https://gitlab.com/gitlab-org/gitlab-runner/-/jobs/7056674997>.
- `check_docs_links` job in the `charts/gitlab` project. For example:
  <https://gitlab.com/gitlab-org/charts/gitlab/-/jobs/7066011619>.

These jobs check links, including anchor links, and report any problems. Any link that requires a network
connection is skipped.

## Install documentation linters

To help adhere to the [documentation style guidelines](../styleguide/_index.md), and
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

### Run Vale, markdownlint, or link checks locally

Installation and configuration instructions are available for:

- [markdownlint](markdownlint.md).
- [Vale](vale.md).
- [Lychee](links.md) and UI link checkers.

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

## Update linter configuration

Vale and markdownlint configurations are under source control in each
project, so updates must be committed to each project individually.

The configuration in the `gitlab` project should be treated as the source of truth,
and all updates should first be made there.

On a regular basis, the changes made in `gitlab` project to the Vale and markdownlint configuration should be
synchronized to the other projects. In each of the [supported projects](#supported-projects):

1. Create a new branch. Add `docs-` to the beginning or `-docs` to the end of the branch name. Some projects use this
   convention to limit the jobs that run.
1. Copy the configuration files from the `gitlab` project. For example, in the root directory of the project, run:

   ```shell
   # Copy markdownlint configuration file
   cp ../gitlab/.markdownlint-cli2.yaml .
   # Remove existing Vale configuration in case some rules have been removed from the GitLab project
   rm -r docs/.vale/gitlab
   # Copy gitlab_base Vale configuration files for a project with documentation stored in 'docs' directory
   cp -r ../gitlab/doc/.vale/gitlab_base docs/.vale
   ```

1. If updating `gitlab-runner`, `gitlab-omnibus`, `charts/gitlab`, or `gitlab-operator`, also copy the `gitlab-docs`
   Vale configuration from the `gitlab` project. For example, in the root directory of the project, run:

   ```shell
   # Copy gitlab-docs Vale configuration files for a project with documentation stored in 'docs' directory
   cp -r ../gitlab/doc/.vale/gitlab_docs docs/.vale
   ```

1. Review the diff created for `.markdownlint-cli2.yaml`. For example, run:

   ```shell
   git diff .markdownlint-cli2.yaml
   ```

1. Remove any changes that aren't required. For example, `customRules` is only used in the `gitlab` project.
1. Review the diffs created for the Vale configuration. For example, run:

   ```shell
   git diff docs
   ```

1. Remove unneeded changes to `RelativeLinks.yml`. This rule is specific to each project.
1. Remove any `.tmpl` files. These files are only used in the `gitlab` project.
1. Run `markdownlint-cli2` to check for any violations of the new rules. For example:

   ```shell
   markdownlint-cli2 docs/**/*.md
   ```

1. Run Vale to check for any violations of the new rules. For example:

   ```shell
   vale --minAlertLevel error docs
   ```

1. Commit the changes to the new branch. Some projects require
   [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/) so check the contributing information for the
   project before committing.

1. Submit a merge request for review.

## Update linting images

Lint tests run in CI/CD pipelines using images from the
`gitlab-docs` [container registry](https://gitlab.com/gitlab-org/gitlab-docs/container_registry).

If a new version of a dependency is released (like a new version of Ruby), we
should update the images to use the newer version. Then, we can update the configuration
files in each of our documentation projects to point to the new image.

To update the linting images:

1. In `gitlab-docs`, open a merge request to update `.gitlab-ci.yml` to use the new tooling
   version. ([Example MR](https://gitlab.com/gitlab-org/gitlab-docs/-/merge_requests/2571))
1. When merged, start a `Build docker images manually` [scheduled pipeline](https://gitlab.com/gitlab-org/gitlab-docs/-/pipeline_schedules).
1. Go the pipeline you started, and wait for the relevant `test:image` job to complete,
   for example `test:image:docs-lint-markdown`. If the job:
   - Passes, start the relevant `image:` job, for example, `image:docs-lint-markdown`.
   - Fails, review the test job log and start troubleshooting the issue. The image configuration
     likely needs some manual tweaks to work with the updated dependency.
1. After the `image:` job passes, check the job's log for the name of the new image.
   ([Example job output](https://gitlab.com/gitlab-org/gitlab-docs/-/jobs/2335033884#L334))
1. Verify that the new image was added to the container registry.
1. Open merge requests to update each of these configuration files to point to the new image.
   In each merge request, include a small doc update to trigger the job that uses the image.
   - <https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/docs.gitlab-ci.yml> ([Example MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85177))
   - <https://gitlab.com/gitlab-org/gitlab-runner/-/blob/main/.gitlab/ci/docs.gitlab-ci.yml> ([Example MR](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3408))
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

[Lefthook](https://github.com/Arkweid/lefthook) is a Git hooks manager. It makes configuring,
installing, and removing Git hooks simpler. Configuration for it is available in the
[`lefthook.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lefthook.yml)
file for the [`gitlab`](https://gitlab.com/gitlab-org/gitlab) project.

To set up Lefthook for documentation linting, see
[Pre-commit and pre-push static analysis with Lefthook](../../contributing/style_guides.md#pre-commit-and-pre-push-static-analysis-with-lefthook).

To show Vale errors on commit or push, see [Show Vale warnings on commit or push](vale.md#show-vale-warnings-on-commit-or-push).

## Disable linting on documentation

Some, but not all, linting can be disabled on documentation files:

- [Vale tests can be disabled](vale.md#disable-vale-tests) for all or part of a file.
- [`markdownlint` tests can be disabled](markdownlint.md#disable-markdownlint-tests) for all or part of a file.

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

We also run some documentation tests in these projects:

- GitLab CLI: <https://gitlab.com/gitlab-org/cli/-/blob/main/.gitlab-ci.yml>
- GitLab Development Kit:
  <https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/.gitlab/ci/test.gitlab-ci.yml>
- Gitaly: <https://gitlab.com/gitlab-org/gitaly/-/blob/master/.gitlab-ci.yml>
- GitLab Duo Plugin for JetBrains: <https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/blob/main/.gitlab-ci.yml>
- GitLab Workflow extension for VS Code: <https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/.gitlab-ci.yml>
- GitLab Plugin for Neovim: <https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/blob/main/.gitlab-ci.yml>
- GitLab Language Server: <https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/.gitlab-ci.yml>
- GitLab Extension for Visual Studio: <https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/blob/main/.gitlab-ci.yml>
- AI gateway: <https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/.gitlab/ci/lint.gitlab-ci.yml>
- Prompt Library: <https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library/-/blob/main/.gitlab-ci.yml>
