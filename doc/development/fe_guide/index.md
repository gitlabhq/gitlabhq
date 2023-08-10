---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Frontend Development Guidelines

This document describes various guidelines to ensure consistency and quality
across the GitLab frontend team.

## Overview

GitLab is built on top of [Ruby on Rails](https://rubyonrails.org). It uses [Haml](https://haml.info/) and a JavaScript-based frontend with [Vue.js](https://vuejs.org). If you are not sure when to use Vue on top of Haml-page, please read  [this explanation](vue.md#when-to-add-vue-application).

<!-- vale gitlab.Spelling = NO -->

Be wary of [the limitations that come with using Hamlit](https://github.com/k0kubun/hamlit/blob/master/REFERENCE.md#limitations).

<!-- vale gitlab.Spelling = YES -->

When it comes to CSS, we use a utils-based CSS approach. GitLab has its own CSS utils which are packaged inside the `gitlab-ui` project and can be seen [in the repository](https://gitlab.com/gitlab-org/gitlab-ui/-/tree/main/src/scss/utility-mixins) or on [UNPKG](https://unpkg.com/browse/@gitlab/ui@latest/src/scss/utility-mixins/). Please favor using these before adding or using any SCSS classes.

We also use [SCSS](https://sass-lang.com) and plain JavaScript with
modern ECMAScript standards supported through [Babel](https://babeljs.io/) and ES module support through [webpack](https://webpack.js.org/).

When making API calls, we use [GraphQL](graphql.md) as [the first choice](../../api/graphql/index.md#vision). There are still instances where GitLab REST API is used such as when creating new simple HAML pages or in legacy part of the codebase, but we should always default to GraphQL when possible.

We use [Apollo](https://www.apollographql.com/) as our global state manager and [GraphQL client](graphql.md).
[VueX](vuex.md) is still in use across the codebase, but it is no longer the recommended global state manager.
You should **not** [use VueX and Apollo together](graphql.md#using-with-vuex),
and should [avoid adding new VueX stores](migrating_from_vuex.md) whenever possible.

For copy strings and translations, we have frontend utilities available. Please see the JavaScript section of [Preparing a page for translation](../i18n/externalization.md#javascript-files) for more information.

Working with our frontend assets requires Node (v12.22.1 or greater) and Yarn
(v1.10.0 or greater). You can find information on how to install these on our
[installation guide](../../install/installation.md#5-node).

## Vision

As Frontend engineers, we strive to give users **delightful experiences**. We should always think of how this applies at GitLab specifically: a great GitLab experience means helping our userbase ship **their own projects faster and with more confidence** when shipping their own software. This means that whenever confronted with a choice for the future of our department, we should remember to try to put this first.

### Values

We define three core values, Stability, Speed and Maintainability (SSM)

#### Stability

Although velocity is extremely important, we believe that GitLab is now an enterprise-grade platform that requires even the smallest MVC to be **stable, tested and with a good architecture**. We should not merge code, even as an MVC, that could introduce degradation, poor performance, confusion or generally lower our users expectations.

This is an extension of the core value that want our users to have confidence in their own software and to do so, they need to have **confidence in GitLab first**. This means that our own confidence in our software should be at the absolute maximum.

#### Speed

Users should be able to navigate through the GitLab application with ease. This implies fast load times, easy to find pages, clear UX and an overall sense that they can accomplish their goal without friction.

Additionally, we want our speed to be felt and appreciated by our developers. This means that we should put a lot of effort and thoughts into processes, tools and documentation that help us achieve success faster across our department. This benefits us as engineers, but also our users that end up receiving quality features at a faster rate.

#### Maintainability

GitLab is now a large, enterprise-grade software and it often requires complex code to give the best possible experience. Although complexity is a necessity, we must remain vigilent to not let it grow more than it should. To minimize this, we want to focus on making our codebase maintainable by **encapsulating complexity**. This is done by:

- Building tools that solve commonly-faced problems and making them easily discoverable.
- Writing better documentation on how we solve our problems.
- Writing loosely coupled components that can be easily added or removed from our codebase.
- Remove older technologies or pattern that we deem are no longer acceptable.

By focusing on these aspects, we aim to allow engineers to contain complexity in well defined boundaries and quickly share them with their peers.

### Goals

Now that our values have been defined, we can base our goals on these values and determine what we would like to achieve at GitLab with this in mind.

- Lowest possible FID, LCP and cross-page navigation times
- Minimal page reloads when interacting with the UI
- [Have as little Vue applications per page as possible](vue.md#avoid-multiple-vue-applications-on-the-page)
- Leverage [Ruby ViewComponents](view_component.md) for simple pages and avoid Vue overhead when possible
- [Migrate away from VueX](migrating_from_vuex.md), but more urgently **stop using Apollo and VueX together**
- Remove jQuery from our codebase
- Add a visual testing framework
- Reduce CSS bundle size to a minimum
- Reduce cognitive overhead and improve maintainability of our CSS
- Improve our pipelines speed
- Build a better set of shared components with documentation

We have detailed description on how we see GitLab frontend in the future in [Frontend Goals](frontend_goals.md) section

### Frontend onboarding course

The [Frontend onboarding course](onboarding_course/index.md) provides a 6-week structured curriculum to learn how to contribute to the GitLab frontend.

### Browser Support

For supported browsers, see our [requirements](../../install/requirements.md#supported-web-browsers).

Use [BrowserStack](https://www.browserstack.com/) to test with our supported browsers.
Sign in to BrowserStack with the credentials saved in the **Engineering** vault of the GitLab
[shared 1Password account](https://about.gitlab.com/handbook/security/#1password-guide).

## Initiatives

You can find current frontend initiatives with a cross-functional impact on epics
with the label [frontend-initiative](https://gitlab.com/groups/gitlab-org/-/epics?state=opened&page=1&sort=UPDATED_AT_DESC&label_name[]=frontend-initiative).

## Principles

[High-level guidelines](principles.md) for contributing to GitLab.

## Development Process

How we [plan and execute](development_process.md) the work on the frontend.

## Architecture

How we go about [making fundamental design decisions](architecture.md) in the GitLab frontend team
or make changes to our frontend development guidelines.

## Testing

How we write [frontend tests](../testing_guide/frontend_testing.md), run the GitLab test suite, and debug test related
issues.

## Pajamas Design System

Reusable components with technical and usage guidelines can be found in our
[Pajamas Design System](https://design.gitlab.com/).

## Design Patterns

JavaScript [design patterns](design_patterns.md) in the GitLab codebase.

## Design Anti-patterns

JavaScript [design anti-patterns](design_anti_patterns.md) we try to avoid.

## Vue.js Best Practices

Vue specific [design patterns and practices](vue.md).

## Vuex

[Vuex](vuex.md) specific design patterns and practices.

## Axios

[Axios](axios.md) specific practices and gotchas.

## GraphQL

How to use [GraphQL](graphql.md).

## HAML

How to use [HAML](haml.md).

## ViewComponent

How we use [ViewComponent](view_component.md).

## Icons and Illustrations

How we use SVG for our [Icons and Illustrations](icons.md).

## Dependencies

General information about frontend [dependencies](dependencies.md) and how we manage them.

## Keyboard Shortcuts

How we implement [keyboard shortcuts](keyboard_shortcuts.md) that can be customized and disabled.

## Editors

GitLab text editing experiences are provided by the [source editor](source_editor.md) and
the [rich text editor](content_editor.md).

## Frontend FAQ

Read the [frontend's FAQ](frontend_faq.md) for common small pieces of helpful information.

## Style Guides

See the relevant style guides for our guidelines and for information on linting:

- [JavaScript](style/javascript.md). Our guide is based on
the excellent [Airbnb](https://github.com/airbnb/javascript) style guide with a few small
changes.
- [SCSS](style/scss.md): [our SCSS conventions](https://gitlab.com/gitlab-org/frontend/gitlab-stylelint-config) which are enforced through [`stylelint`](https://stylelint.io).
- [HTML](style/html.md). Guidelines for writing HTML code consistent with the rest of the codebase.
- [Vue](style/vue.md). Guidelines and conventions for Vue code may be found here.

## [Tooling](tooling.md)

Our code is automatically formatted with [Prettier](https://prettier.io) to follow our guidelines. Read our [Tooling guide](tooling.md) for more detail.

## [Performance](performance.md)

Best practices for monitoring and maximizing frontend performance.

## [Security](security.md)

Frontend security practices.

## Accessibility

Our [accessibility standards and resources](accessibility.md).

## Logging

Best practices for [client-side logging](logging.md) for GitLab frontend development.

## [Internationalization (i18n) and Translations](../i18n/externalization.md)

Frontend internationalization support is described in [this document](../i18n/index.md).
The [externalization part of the guide](../i18n/externalization.md) explains the helpers/methods available.

## [Troubleshooting](troubleshooting.md)

Running into a Frontend development problem? Check out [this guide](troubleshooting.md) to help resolve your issue.
