---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
description: Learn how to contribute to GitLab Documentation.
title: Documentation and UI link tests
---

For testing:

- Relative links between documentation files, we use [Lychee](https://lychee.cli.rs/overview/).
- Links to documentation from the GitLab UI, we use [`haml-lint`, `eslint`, and `rubocop`](#run-ui-link-tests-locally).

## Run the relative link test locally

To run the relative link test locally, you can either:

- Run the link check for a single project that contains documentation.
- Run the link check across entire local copy of the [GitLab documentation site](https://docs.gitlab.com).

### Check a single project

To check the links on a single project:

1. Install [Lychee](https://lychee.cli.rs/guides/getting-started/).
1. Change into the root directory of the project.
1. Run `lychee --offline --include-fragments <doc_directory>`, where `<doc_directory>` is the directory that contains
   documentation to check. For example: `lychee --offline --include-fragments doc`.

### Check all GitLab Docs site projects

To check links on the entire [GitLab documentation site](https://docs.gitlab.com):

1. Make sure you have all the documentation projects cloned in the same directory as your `docs-gitlab-com` clone. You can
   run `make clone-docs-projects` to clone any projects you don't have in that location.
1. Go to the [`docs-gitlab-com`](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com) directory.
1. Run `hugo`, which builds the GitLab Docs site.
1. Run `lychee --offline public` to check links.

## Run UI link tests locally

To test documentation links from GitLab code files locally, you can run:

- `eslint`: For frontend (`.js` and `.vue`) files.
- `rubocop`: For `.rb` and `.haml` files.

### Run `eslint` tests

1. Open the `gitlab` directory in a terminal window.
1. Run:

   ```shell
   scripts/frontend/lint_docs_links.mjs
   ```

If you receive an error the first time you run this test, run `yarn install`, which
installs the dependencies for GitLab, and try again.

### Run `rubocop` tests

1. [Install RuboCop](https://github.com/rubocop/rubocop#installation)
1. Open the `gitlab` directory in a terminal window.
1. To run the check on all Ruby files:

   ```shell
   rubocop --only Gitlab/DocumentationLinks/Link
   ```

   To run the check on a single Ruby file:

   ```shell
   rubocop --only Gitlab/DocumentationLinks/Link path/to/ruby/file.rb
   ```
