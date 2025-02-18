---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Frontend Development Guidelines
---

This document describes various guidelines to ensure consistency and quality
across the GitLab frontend team.

## Introduction

GitLab is built on top of [Ruby on Rails](https://rubyonrails.org). It uses [Haml](https://haml.info/) and a JavaScript-based frontend with [Vue.js](https://vuejs.org). If you are not sure when to use Vue on top of Haml-page, read [this explanation](vue.md#when-to-add-vue-application).

<!-- vale gitlab_base.Spelling = NO -->

For more information, see [Hamlit](https://github.com/k0kubun/hamlit/blob/master/REFERENCE.md).

<!-- vale gitlab_base.Spelling = YES -->

When it comes to CSS, we use a utils-based CSS approach. For more information and to find where CSS utilities are defined, refer to the [SCSS style section](style/scss.md#where-are-css-utility-classes-defined) of this guide.

We also use [SCSS](https://sass-lang.com) and plain JavaScript with
modern ECMAScript standards supported through [Babel](https://babeljs.io/) and ES module support through [webpack](https://webpack.js.org/).

When making API calls, we use [GraphQL](graphql.md) as the first choice.
There are still instances where the GitLab REST API is used, such as when creating new simple Haml pages, or in legacy parts of the codebase, but we should always default to GraphQL when possible.

For [client-side state management](state_management.md) in Vue, depending on the specific needs of the feature,
we use:

- [Apollo](https://www.apollographql.com/) (default choice for applications relying on [GraphQL](graphql.md))
- [Pinia](pinia.md) (in [pilot phase](https://gitlab.com/gitlab-org/gitlab/-/issues/479279))
- Stateful components.

[Vuex is deprecated](vuex.md) and you should [migrate away from it](migrating_from_vuex.md) whenever possible.

Learn: [How do I know which state manager to use?](state_management.md)

For copy strings and translations, we have frontend utilities available. See the JavaScript section of [Preparing a page for translation](../i18n/externalization.md#javascript-files) for more information.

Working with our frontend assets requires Node (v12.22.1 or greater) and Yarn
(v1.10.0 or greater). You can find information on how to install these on our
[installation guide](../../install/installation.md#5-node).

### High-level overview

GitLab core frontend code is located under [`app/assets/javascripts`](https://gitlab.com/gitlab-org/gitlab/-/tree/4ce851345054dbf09956dabcc9b958ae8aab77bb/app/assets/javascripts).

Since GitLab uses the [Ruby on Rails](https://rubyonrails.org) framework, we inject our Vue applications into the views using [Haml](https://haml.info/). For example, to build a Vue app in a Rails view, we set up a view like [`app/views/projects/pipeline_schedules/index.html.haml`](https://gitlab.com/gitlab-org/gitlab/-/blob/4ce851345054dbf09956dabcc9b958ae8aab77bb/app/views/projects/pipeline_schedules/index.html.haml). Inside this view, we add an element with an `id` like `#pipeline-schedules-app`. This element serves as the mounting point for our frontend code.

The application structure typically follows the pattern: `app/assets/javascripts/<feature-name>`. For example, the directory for a specific feature might look like [`app/assets/javascripts/ci/pipeline_schedules`](https://gitlab.com/gitlab-org/gitlab/-/tree/4ce851345054dbf09956dabcc9b958ae8aab77bb/app/assets/javascripts/ci/pipeline_schedules). Within these type of directories, we organize our code into subfolders like `components` or `graphql`, which house the code that makes up a feature. A typical structure might look like

- `feature_name/`
  - `components/` (vue components that make up a feature)
  - `graphql/` (queries/mutations)
  - `utils/` (helper functions)
  - `router/` (optional: only for Vue Router powered apps)
  - `constants.js` (shared variables)
  - `index.js` (file that injects the Vue app)

There is always a top-level Vue component that acts as the “main” component and imports lower-level components to build a feature. In all cases, there is an accompanying file (often named index.js or app.js but often varies) that looks for the injection point on a Haml view (e.g., `#pipeline-schedules-app`) and mounts the Vue app to the page.

We achieve this by importing a JavaScript file like [`app/assets/javascripts/ci/pipeline_schedules/mount_pipeline_schedules_app.js`](https://gitlab.com/gitlab-org/gitlab/-/blob/4ce851345054dbf09956dabcc9b958ae8aab77bb/app/assets/javascripts/ci/pipeline_schedules/mount_pipeline_schedules_app.js) (which sets up the Vue app) into the related Haml view’s corresponding page bundle, such as [`app/assets/javascripts/pages/projects/pipeline_schedules/index/index.js`](https://gitlab.com/gitlab-org/gitlab/-/blob/4ce851345054dbf09956dabcc9b958ae8aab77bb/app/assets/javascripts/pages/projects/pipeline_schedules/index/index.js).

Often, a feature will have multiple routes, such as `index`, `show`, `edit`, or `new`. For these cases, we typically inject different Vue applications based on the specific route. The folder structure within `app/assets/javascripts/pages` reflects this setup. For example, a subfolder like `app/assets/javascripts/pages/<feature-name>/show` corresponds to the Rails controller `app/controllers/<controller-name>` and its action `def show; end`. Alternatively, we can mount the Vue application on the `index` route and handle routing on the client with [Vue Router](https://router.vuejs.org/).

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

If you're a first-time contributor, see [Contribute to GitLab development](../contributing/_index.md).

When you're ready to create your first merge request, or need to review the GitLab frontend workflow, see [Getting started](getting_started.md).

For a guided introduction to frontend development at GitLab, you can watch the [Frontend onboarding course](onboarding_course/_index.md) which provides a six-week structured curriculum.

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

Frontend internationalization support is described in [**Translate GitLab to your language**](../i18n/_index.md).
The [externalization part of the guide](../i18n/externalization.md) explains the helpers/methods available.

#### Troubleshooting

Running into a Frontend development problem? Check out [this troubleshooting guide](troubleshooting.md) to help resolve your issue.

#### Browser support

For supported browsers, see our [requirements](../../install/requirements.md#supported-web-browsers).
