---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Automated accessibility testing
---

GitLab is committed to ensuring our platform is accessible to all users. We use automated accessibility testing as part of our comprehensive approach to identify and prevent accessibility barriers.

[We aim to conform to level AA of the World Wide Web Consortium (W3C) Web Content Accessibility Guidelines 2.1](https://design.gitlab.com/accessibility/a11y).

## Our testing approach

GitLab uses multiple approaches for automated accessibility testing to provide comprehensive coverage:

1. **[Feature tests](feature_tests.md)** - End-to-end accessibility testing using axe-core in feature tests to validate complete user flows and page interactions
1. **[Storybook component tests](storybook_tests.md)** - Isolated component testing using Storybook test-runner with axe-playwright to ensure individual Vue components meet accessibility standards

These complementary approaches ensure that both individual components and complete user experiences are accessible.
