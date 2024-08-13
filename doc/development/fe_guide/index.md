---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Frontend Development Guidelines

This document describes various guidelines to ensure consistency and quality
across the GitLab frontend team.

## Overview

GitLab is built on top of [Ruby on Rails](https://rubyonrails.org). It uses [Haml](https://haml.info/) and a JavaScript-based frontend with [Vue.js](https://vuejs.org). If you are not sure when to use Vue on top of Haml-page, read [this explanation](vue.md#when-to-add-vue-application).

<!-- vale gitlab_base.Spelling = NO -->

Be wary of [the limitations that come with using Hamlit](https://github.com/k0kubun/hamlit/blob/master/REFERENCE.md#limitations).

<!-- vale gitlab_base.Spelling = YES -->

When it comes to CSS, we use a utils-based CSS approach. GitLab has its own CSS utils which are packaged inside the `gitlab-ui` project and can be seen [in the repository](https://gitlab.com/gitlab-org/gitlab-ui/-/tree/main/src/scss/utility-mixins) or on [UNPKG](https://unpkg.com/browse/@gitlab/ui@latest/src/scss/utility-mixins/). Favor using these before adding or using any SCSS classes.

We also use [SCSS](https://sass-lang.com) and plain JavaScript with
modern ECMAScript standards supported through [Babel](https://babeljs.io/) and ES module support through [webpack](https://webpack.js.org/).

When making API calls, we use [GraphQL](graphql.md) as [the first choice](../api_graphql_styleguide.md#vision). There are still instances where GitLab REST API is used such as when creating new simple HAML pages or in legacy part of the codebase, but we should always default to GraphQL when possible.

We use [Apollo](https://www.apollographql.com/) as our global state manager and [GraphQL client](graphql.md).
[VueX](vuex.md) is still in use across the codebase, but it is no longer the recommended global state manager.
You should **not** [use VueX and Apollo together](graphql.md#using-with-vuex),
and should [avoid adding new VueX stores](migrating_from_vuex.md) whenever possible.

For copy strings and translations, we have frontend utilities available. See the JavaScript section of [Preparing a page for translation](../i18n/externalization.md#javascript-files) for more information.

Working with our frontend assets requires Node (v12.22.1 or greater) and Yarn
(v1.10.0 or greater). You can find information on how to install these on our
[installation guide](../../install/installation.md#5-node).

## Vision

As Frontend engineers, we strive to give users **delightful experiences**. We should always think of how this applies at GitLab specifically: a great GitLab experience means helping our user base ship **their own projects faster and with more confidence** when shipping their own software. This means that whenever confronted with a choice for the future of our department, we should remember to try to put this first.

### Values

We define three core values, Stability, Speed and Maintainability (SSM)

#### Stability

Although velocity is extremely important, we believe that GitLab is now an enterprise-grade platform that requires even the smallest MVC to be **stable, tested and with a good architecture**. We should not merge code, even as an MVC, that could introduce degradation, poor performance, confusion or generally lower our users expectations.

This is an extension of the core value that want our users to have confidence in their own software and to do so, they need to have **confidence in GitLab first**. This means that our own confidence in our software should be at the absolute maximum.

#### Speed

Users should be able to navigate through the GitLab application with ease. This implies fast load times, easy to find pages, clear UX and an overall sense that they can accomplish their goal without friction.

Additionally, we want our speed to be felt and appreciated by our developers. This means that we should put a lot of effort and thoughts into processes, tools and documentation that help us achieve success faster across our department. This benefits us as engineers, but also our users that end up receiving quality features at a faster rate.

#### Maintainability

GitLab is now a large, enterprise-grade software and it often requires complex code to give the best possible experience. Although complexity is a necessity, we must remain vigilant to not let it grow more than it should. To minimize this, we want to focus on making our codebase maintainable by **encapsulating complexity**. This is done by:

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

### First time contributors

If you're a first-time contributor, see [Contribute to GitLab development](../contributing/index.md).

When you're ready to create your first merge request, or need to review the GitLab frontend workflow, see [Getting started](getting_started.md).

For a guided introduction to frontend development at GitLab, you can watch the [Frontend onboarding course](onboarding_course/index.md) which provides a six-week structured curriculum.

### Helpful links

#### Initiatives

You can find current frontend initiatives with a cross-functional impact on epics
with the label [frontend-initiative](https://gitlab.com/groups/gitlab-org/-/epics?state=opened&page=1&sort=UPDATED_AT_DESC&label_name[]=frontend-initiative).

#### Testing

How we write [frontend tests](../testing_guide/frontend_testing.md), run the GitLab test suite, and debug test related
issues.

#### Pajamas Design System

Reusable components with technical and usage guidelines can be found in our
[Pajamas Design System](https://design.gitlab.com/).

#### Frontend FAQ

Read the [frontend FAQ](frontend_faq.md) for common small pieces of helpful information.

#### Internationalization (i18n) and Translations

Frontend internationalization support is described in [**Translate GitLab to your language**](../i18n/index.md).
The [externalization part of the guide](../i18n/externalization.md) explains the helpers/methods available.

#### Troubleshooting

Running into a Frontend development problem? Check out [this troubleshooting guide](troubleshooting.md) to help resolve your issue.

#### Browser support

For supported browsers, see our [requirements](../../install/requirements.md#supported-web-browsers).

Use [BrowserStack](https://www.browserstack.com/) to test with our supported browsers.
Sign in to BrowserStack with the credentials saved in the **Engineering** vault of the GitLab
[shared 1Password account](https://handbook.gitlab.com/handbook/security/password-guidelines/#1password-for-teams).
