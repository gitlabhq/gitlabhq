---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Accessibility
---

Accessibility is important for users who use screen readers or rely on keyboard-only functionality
to ensure they have an equivalent experience to sighted mouse users.

## Linting for accessibility defects

You can enable linting for accessibility defects with a free VS Code plugin - [axe Accessibility Linter](https://marketplace.visualstudio.com/items?itemName=deque-systems.vscode-axe-linter).
We strongly recommend that to everyone contributing to GitLab that use VS Code.

1. Open VS Code editor
1. Go to Extensions
1. Search for axe Accessibility Linter and install the plugin

Axe Accessibility Linter works in HTML, Markdown and Vue files. As for this moment, there is no support for HAML files. You will get immediate feedback, while writing your code.

GitLab repository contains `axe-linter.yml` file that adds additional configuration to the plugin.
It enables the linter to analyze some of the Pajamas components by mapping them and their attributes to native HTML elements.

## Automated accessibility testing

Uncover accessibility problems and ensure that your features stay accessible over time by
[implementing automated A11Y tests](automated_testing.md).

- [When to add accessibility tests](automated_testing.md#when-to-add-accessibility-tests)
- [How to add accessibility tests](automated_testing.md#how-to-add-accessibility-tests)

## Accessibility best practices

Follow these [best practices](best_practices.md) to implement accessible web applications. These are
some of the topics covered in that guide:

- [Quick checklist](best_practices.md#quick-checklist)
- [Accessible names for screen readers](best_practices.md#provide-accessible-names-for-screen-readers)
- [Icons](best_practices.md#icons)
- [When to use ARIA](best_practices.md#when-to-use-aria)

## Other resources

Use these tools and learning resources to improve your web accessibility workflow and skills.

### Viewing the browser accessibility tree

- [Firefox DevTools guide](https://firefox-source-docs.mozilla.org/devtools-user/accessibility_inspector/index.html#accessing-the-accessibility-inspector)
- [Chrome DevTools guide](https://developer.chrome.com/docs/devtools/accessibility/reference/#pane)

### Browser extensions

We have two options for Web accessibility testing:

- axe for [Firefox](https://www.deque.com/axe/devtools/firefox-browser-extension/)
- axe for [Chrome](https://www.deque.com/axe/devtools/chrome-browser-extension/)

### Other links

- [The A11Y Project](https://www.a11yproject.com/) is a good resource for accessibility
- [Awesome Accessibility](https://github.com/brunopulis/awesome-a11y)
  is a compilation of accessibility-related material
