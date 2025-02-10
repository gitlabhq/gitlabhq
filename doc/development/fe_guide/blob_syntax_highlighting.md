---
stage: Create
group: Source Code
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Syntax highlighting development guidelines (repository blob viewer)
---

This guide outlines best practices and implementation details for syntax highlighting in the repository source code viewer. GitLab uses two syntax highlighting libraries:

- [Highlight.js](https://highlightjs.org/) for client-side highlighting in the source viewer
  - See the [full list of supported languages](https://github.com/highlightjs/highlight.js/blob/main/SUPPORTED_LANGUAGES.md)
- [Rouge](https://rubygems.org/gems/rouge) as a server-side fallback
  - See the [full list of supported languages](https://github.com/rouge-ruby/rouge/wiki/list-of-supported-languages-and-lexers)

The source code viewer uses this dual approach to ensure broad language support and optimal performance when viewing files in the repository.

## Components Overview

The syntax highlighting implementation consists of several key components:

- `blob_content_viewer.vue`: Main component for displaying file content
- `source_viewer.vue`: Handles the rendering of source code
- `highlight_mixin.js`: Manages the highlighting process and WebWorker communication
- `highlight_utils.js`: Provides utilities for content chunking and processing

## Performance Principles

### Display content as quickly as possible

We optimize the display of content through a staged rendering approach:

1. Immediately render the first 70 lines in plaintext (without highlighting)
1. Request the WebWorker to highlight the first 70 lines
1. Request the WebWorker to highlight the entire file

### Maintain optimal browser performance

To maintain optimal browser performance:

- Use a WebWorker for the highlighting task so that it doesn't block the main thread
- Break highlighted content into chunks and render them as the user scrolls using the [IntersectionObserver API](https://developer.mozilla.org/en-US/docs/Web/API/Intersection_Observer_API)

## Adding Syntax Highlighting Support

You can add syntax highlighting support for new languages by:

1. Using existing third-party language definitions.
1. Creating custom language definitions in our codebase.

The method you choose depends on whether the language already has a Highlight.js compatible definition available.

### For Languages with Third-Party Definitions

We can add third-party dependencies to our [`package.json`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/package.json) and import the dependency in [`highlight_js_language_loader`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/content_editor/services/highlight_js_language_loader.js#L260).

**Example:**

- Add the dependency to `package.json`:

```javascript
// package.json

//...
  "dependencies": {
    "@gleam-lang/highlight.js-gleam": "^1.5.0",
//...
```

- Import the language in `highlight_js_language_loader.js`:

```javascript
// highlight_js_language_loader.js

//...
  gleam: () => import(/* webpackChunkName: 'hl-gleam' */ '@gleam-lang/highlight.js-gleam'),
//...
```

If the language is still displayed as plaintext, you might need to add language detection based on the file extension in [`highlight_mixin.js`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/repository/mixins/highlight_mixin.js):

```javascript
if (name.endsWith('.gleam')) {
  language = 'gleam';
}
```

### For Languages Without Existing Definitions

New language definitions can be added to our codebase under [`~/vue_shared/components/source_viewer/languages/`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/app/assets/javascripts/vue_shared/components/source_viewer/languages/).

To add support for a new language:

1. Create a new language definition file following the [Highlight.js syntax](https://highlightjs.readthedocs.io/en/latest/language-contribution.html).
1. Register the language in `highlight_js_language_loader.js`.
1. Add file extension mapping in `highlight_mixin.js` if needed.

Here are two examples of custom language implementations:

1. [Svelte](https://gitlab.com/gitlab-org/gitlab/-/commit/0680b3a27b3973287ae6a973703faf9472535c47)
1. [CODEOWNERS](https://gitlab.com/gitlab-org/gitlab/-/commit/825fd1e97df582b9f2654fc248c15e073d78d82b)
