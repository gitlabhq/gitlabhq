---
stage: Plan
group: Knowledge
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
description: "Development guidelines for GitLab Flavored Markdown (GLFM)."
title: GitLab Flavored Markdown (GLFM) development guidelines
---

<!-- vale gitlab_base.GitLabFlavoredMarkdown = NO -->

This and neighboring pages contain developer guidelines for GitLab Flavored Markdown (GLFM).
For the user documentation about Markdown in GitLab, refer to
[GitLab Flavored Markdown](../../user/markdown.md).

GitLab supports Markdown in various places, such as issue or merge request descriptions, comments, and wikis.
The Markdown implementation we use is called
GitLab Flavored Markdown (GLFM).

[CommonMark](https://spec.commonmark.org/current/) is the core of GLFM.

> ...a standard, unambiguous syntax specification for Markdown, along with a suite of comprehensive tests to validate Markdown implementations against this specification.

Extensions from [GitHub Flavored Markdown (GFM)](https://github.github.com/gfm/), such as tables and task lists, are supported.
Various [extensions](../../user/markdown.md#differences-with-standard-markdown), such as math and multiline
blockquotes are then added, creating GLFM.

NOTE:
In many places in the code, we use `gfm` or `GFM`. In those cases, we're usually
referring to the Markdown in general, not specifically GLFM.

## Basic flow

To create the HTML displayed to the user, the Markdown is usually processed as follows:

- Markdown is read from the user or from the database and given to the backend.
- A processing pipeline (the "Banzai" pipeline) is run.
  - Some pre-processing happens, then is converted into basic HTML using the
    [`gitlab-glfm-markdown`](https://gitlab.com/gitlab-org/ruby/gems/gitlab-glfm-markdown) gem, which uses [`comrak`](https://github.com/kivikakk/comrak).
  - Various filters are run which further transform the HTML. For example handling
    references or custom emoji.
- The HTML is then handed to the frontend, which displays it in various ways, or cached in the database.
  - For example, the rich text editor converts the HTML into a format used by [`tiptap`](https://tiptap.dev/product/editor) to be displayed and edited.

## Goal

We aim for GLFM to always be 100% compliant with CommonMark.
Great pains are taken not to add new syntax unless truly necessary.
And in such cases research should be done to find the most
acceptable "Markdown" syntax, closely adhering to a common implementation if available.
The [CommonMark forum](https://talk.commonmark.org) is a good place to research discussions on different topics.

## Additional resources

- [GitLab Flavored Markdown](../../user/markdown.md)
- [Rich text editor development guidelines](../fe_guide/content_editor.md)
- [Emojis](../fe_guide/emojis.md)
- [How to render GitLab-flavored Markdown on the frontend?](../fe_guide/frontend_faq.md#10-how-to-render-gitlab-flavored-markdown)
- [Diagrams.net integration](../fe_guide/diagrams_net_integration.md)

Please contact the [Plan:Knowledge team](https://handbook.gitlab.com/handbook/engineering/development/dev/plan/knowledge/) if you have any questions.
