---
stage: Package
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Registry architecture
---

GitLab has several registry applications. Given that they all leverage similar UI, UX, and business
logic, they are all built with the same architecture. In addition, a set of shared components
already exists to unify the user and developer experiences.

Existing registries:

- Package registry
- Container registry
- Terraform Module Registry
- Dependency Proxy

## Frontend architecture

### Component classification

All the registries follow an architecture pattern that includes four component types:

- Pages: represent an entire app, or for the registries using [vue-router](https://v3.router.vuejs.org/) they represent one router
  route.
- Containers: represent a single piece of functionality. They contain complex logic and may
  connect to the API.
- Presentationals: represent a portion of the UI. They receive all their data with `props` or through
  `inject`, and do not connect to the API.
- Shared components: presentational components that accept a various array of configurations and are
  shared across all of the registries.

### Communicating with the API

The complexity and communication with the API should be concentrated in the pages components, and
in the container components when needed. This makes it easier to:

- Handle concurrent requests, loading states, and user messages.
- Maintain the code, especially to estimate work. If it touches a page or functional component,
  expect it to be more complex.
- Write fast and consistent unit tests.

### Best practices

- Use [`provide` or `inject`](https://v2.vuejs.org/v2/api/?redirect=true#provide-inject)
  to pass static, non-reactive values coming from the app initialization.
- When passing data, prefer `props` over nested queries or Vuex bindings. Only pages and
  container components should be aware of the state and API communication.
- Don't repeat yourself. If one registry receives functionality, the likelihood of the rest needing
  it in the future is high. If something seems reusable and isn't bound to the state, create a
  shared component.
- Try to express functionality and logic with dedicated components. It's much easier to deal with
  events and properties than callbacks and asynchronous code (see
  [`delete_package.vue`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/packages_and_registries/package_registry/components/functional/delete_package.vue)).
- Leverage [startup for GraphQL calls](graphql.md#making-initial-queries-early-with-graphql-startup-calls).

## Shared components library

Inside `vue_shared/components/registry` and `packages_and_registries/shared`, there's a set of
shared components that you can use to implement registry functionality. These components build the
main pieces of the desired UI and UX of a registry page. The most important components are:

- `code-instruction`: represents a copyable box containing code. Supports multiline and single line
  code boxes. Snowplow tracks the code copy event.
- `details-row`: represents a row of details. Used to add additional information in the details area of
  the `list-item` component.
- `history-item`: represents a history list item used to build a timeline.
- `list-item`: represents a list element in the registry. It supports: left action, left primary and
  secondary content, right primary and secondary content, right action, and details slots.
- `metadata-item`: represents one piece of metadata, with an icon or a link. Used primarily in the
  title area.
- `persisted-dropdown-selection`: represents a menu that stores the user selection in the
  `localStorage`.
- `registry-search`: implements `gl-filtered-search` with a sorting section on the right.
- `title-area`: implements the top title area of the registry. Includes: a main title, an avatar, a
  subtitle, a metadata row, and a right actions slot.

## Adding a new registry page

When adding a new registry:

- Leverage the shared components that already exist. It's good to look at how the components are
  structured and used in the more mature registries (for example, the package registry).
- If it's in line with the backend requirements, we suggest using GraphQL for the API. This helps in
  dealing with the innate performance issue of registries.
- If possible, we recommend using [Vue Router](https://v3.router.vuejs.org/)
  and frontend routing. Coupled with Apollo, the caching layer helps with the perceived page
  performance.
