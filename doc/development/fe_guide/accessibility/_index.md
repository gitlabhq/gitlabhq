---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Accessibility
---

Accessibility is important for users who use screen readers or rely on keyboard-only functionality
to ensure they have an equivalent experience to sighted mouse users.

[We aim to conform to level AA of the World Wide Web Consortium (W3C) Web Content Accessibility Guidelines 2.1](https://design.gitlab.com/accessibility/a11y).

## How our accessibility tools work together

GitLab uses a comprehensive, multi-level approach to ensure accessibility compliance. Each tool serves a specific purpose in our development workflow, working together to provide complete coverage from development to production:

| Tool                                            | When to use             | Coverage                                 | Feedback timing                                    |
|-------------------------------------------------|-------------------------|------------------------------------------|----------------------------------------------------|
| [Linting](#linting-for-accessibility-defects)   | While writing code      | JS, Vue, Markdown files                  | Real-time in editor                                |
| [Storybook tests](#storybook-component-testing) | Component development   | Vue components in isolation              | CI pipeline on component changes and local testing |
| [Feature tests](#feature-testing)               | Feature development     | Complete user journeys (HAML + Vue + JS) | CI pipeline and local testing                      |
| [Browser extension](#browser-extensions)        | Code review & debugging | Any page, on-demand                      | Manual, immediate                                  |
| [Monitoring](#accessibility-monitoring)         | Production oversight    | Key application pages                    | Continuous monitoring                              |

### When to use which tool

During development:

1. **Start with linting:** get immediate feedback while writing code.
1. **Add Storybook tests:** ensure components work in isolation.
1. **Include feature tests:** validate complete user experiences.
1. **Use browser extension:** debug specific issues or review changes.

For different file types:

- **Vue/JS files**: Linting + Storybook tests + Feature tests
- **HAML files**: Feature tests + Browser extension (linting not supported)
- **Complete pages**: Feature tests + Browser extension + Monitoring

#### New components

1. Create comprehensive Storybook stories covering all component states.
1. Ensure Storybook tests pass before integration.
1. Test manually with keyboard navigation and with a screen reader.

#### New features

1. Identify mission-critical user journeys.
1. Write feature tests that cover these journeys completely.
1. Focus on testing critical UI states and interactions.

#### Existing code

1. Prioritize high-traffic areas and critical user flows.
1. Add tests incrementally as you work on related features.
1. Use monitoring data to identify areas needing attention.

## Linting for accessibility defects

You can enable linting for accessibility defects with a free VS Code plugin - [axe Accessibility Linter](https://marketplace.visualstudio.com/items?itemName=deque-systems.vscode-axe-linter).
We strongly recommend that to everyone contributing to GitLab that use VS Code.

To enable linting:

1. Open VS Code editor
1. Go to Extensions
1. Search for "axe Accessibility Linter" and install the plugin

The GitLab repository includes `axe-linter.yml` configuration that maps Pajamas Design System components to native HTML elements, significantly increasing linter coverage.

## Storybook component testing

[Storybook tests](storybook_tests.md) use axe-playwright to automatically test Vue components for accessibility violations.

Component's tests run in CI on any Vue or JavaScript file change and block merges when it finds violations. However, it only tests components that have Storybook entries and they need to be up-to-date.

## Feature testing

[Feature tests](feature_tests.md) with `axe-core-gem` provide the most comprehensive accessibility testing by validating complete user experiences.

They cover all our frontend architecture (HAML, Vue, JS) and allow checks at any step of a user journey. Though they may be resource heavy.

## Browser extensions

Use axe DevTools browser extensions for immediate accessibility feedback:

- [axe for Firefox](https://www.deque.com/axe/devtools/firefox-browser-extension/)
- [axe for Chrome](https://www.deque.com/axe/devtools/chrome-browser-extension/)

There is no setup required. You get a full page scan with resources on how to fix violations. Highlighting feature will help you identify the elements in question. A paid pro version offers guided testing and component-specific scans.

## Accessibility monitoring

Our Sitespeed setup with axe extension provides ongoing accessibility monitoring with minimal setup.

You can see SiteSpeed Report for the latest run against staging in [GitLab Browser Performance Tool](https://gitlab.com/gitlab-org/quality/performance-sitespeed/-/wikis/Benchmarks/SiteSpeed/staging).

## Automated accessibility testing

For detailed implementation guidance, see our [automated testing guide](automated_testing.md):

- [Accessibility Storybook tests](storybook_tests.md)
- [Accessibility feature tests](feature_tests.md)

## Accessibility best practices

Follow these [best practices](best_practices.md) to implement accessible web applications:

- [Quick checklist](best_practices.md#quick-checklist)
- [Accessible names for screen readers](best_practices.md#provide-accessible-names-for-screen-readers)
- [Icons](best_practices.md#icons)
- [When to use ARIA](best_practices.md#when-to-use-aria)

## Training and education

Enhance your accessibility knowledge with these resources:

- [Introduction to digital accessibility](https://levelup.edcast.com/insights/ECL-1a014b4a-f92b-4da3-98fc-833be512257b) course
- Accessible Web Development course (coming in Q3 FY26)

## Other resources

### Viewing the browser accessibility tree

- [Firefox DevTools guide](https://firefox-source-docs.mozilla.org/devtools-user/accessibility_inspector/index.html#accessing-the-accessibility-inspector)
- [Chrome DevTools guide](https://developer.chrome.com/docs/devtools/accessibility/reference/#pane)

### Additional learning resources

- [The A11Y Project](https://www.a11yproject.com/) - Comprehensive accessibility resource
- [Awesome Accessibility](https://github.com/brunopulis/awesome-a11y) - Curated accessibility materials
- [Pajamas Design System Accessibility](https://design.gitlab.com/accessibility/a11y) - GitLab-specific guidance
