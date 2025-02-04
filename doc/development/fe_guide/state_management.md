---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: State management guidance
---

At GitLab we support two solutions for client state management: [Apollo](https://www.apollographql.com/) and [Pinia](https://pinia.vuejs.org/).
It is non-trivial to pick either of these as your primary state manager.
This page should provide you with general guidance on how to make this choice.

You may also see Vuex in the GitLab codebase. [Vuex is deprecated in GitLab](vuex.md#deprecated) and **no new Vuex stores should be created**.
If your app has a Vuex store, [consider migrating](migrating_from_vuex.md).

## Difference between state and data

**Data** is information that user interacts with.
It usually comes from external requests (GraphQL or REST) or from the page itself.

**State** stores information about user or system interactions.
For example any flag is considered state: `isLoading`, `isFormVisible`, etc.

State management could be used to work with both state and data.

## Do I need to have state management?

You should prefer using the standard Vue data flow in your application first:
components define local state and pass it down through props and change it through events.

However this might not be sufficient for complex cases where state is shared between multiple components
that are not direct descendants of the component which defined this state.
You might consider hoisting that state to the root of your application, but that eventually
bloats the root component because it starts to do too many things at once.

To deal with that complexity you can use a state management solution.
The sections below will help you with this choice.
If you're still uncertain, prefer using Apollo before Pinia.

## Apollo

[Apollo](https://www.apollographql.com/), our primary interface to GraphQL API, can also be used as a client-side state manager.
[Learn more about GraphQL and Apollo](graphql.md).

### Strengths

- Great for working with data from GraphQL requests,
  provides [data normalization](https://www.apollographql.com/docs/react/caching/overview#data-normalization) out of the box.
- Can cache data from REST API when GraphQL is not available.
- Queries are statically verified against the GraphQL schema.

### Weaknesses

- [More complex and involved than Pinia for client state management](https://www.apollographql.com/docs/react/local-state/managing-state-with-field-policies).
- Apollo DevTools: don't properly work on a significant part of our pages, Apollo Client errors are hard to track down.

### Pick Apollo when

- You rely on the GraphQL API
- You need specific Apollo features, for example:
  - [Parametrized cache, cache invalidation](graphql.md#immutability-and-cache-updates)
  - [Polling](graphql.md#polling-and-performance)
  - [Stale While Revalidate](https://www.apollographql.com/docs/react/caching/advanced-topics#persisting-the-cache)
  - [Real-time updates](graphql.md#subscriptions)
  - [Other](https://www.apollographql.com/docs/react/)

## Pinia

WARNING:
**[Pilot Phase](https://gitlab.com/gitlab-org/gitlab/-/issues/479279)**: Adopt Pinia with caution.
This is a new technology at GitLab and we might not have all the necessary precautions and best practices in place yet.
If you're considering using Pinia please drop a message in the `#frontend` internal Slack channel for evaluation.

[Pinia](https://pinia.vuejs.org/) is the client-side state management tool Vue recommends.
[Learn more about Pinia at GitLab](pinia.md).

### Strengths

- Simple but robust
- Lightweight at ≈1.5kb (as quoted by the Pinia site)
- Vue reactivity under the hood, API similar to Vuex
- Easy to debug

### Weaknesses

- Can't do any advanced request handling out of the box (data normalization, polling, caching, etc.)
- Can lead to same pitfalls as Vuex without guidance (overblown stores)

### Pick Pinia when you have any of these

- Significant percentage of Vue application state is client-side state
- Migrating from Vuex is a high priority
- Your application does not rely primarily on GraphQL API, and you don't plan the migration to GraphQL API in the near future

## Combining Pinia and Apollo

We recommend you pick either Apollo or Pinia as the only state manager in your app.
Combining them is not recommended because:

- Pinia and Apollo are both global stores, which means sharing responsibilities and having two sources of truth.
- Difference in mental models: Apollo is configuration based, Pinia is not. Switching between these mental models is tedious and error-prone.
- Experiencing the drawbacks of both approaches.

However there may be cases when it's OK to combine these two to seek specific benefits from both solutions:

- If there's a significant percentage of client-side state that would be best managed in Pinia.
- If domain-specific concerns warrant Apollo for cohesive GraphQL requests within a component.

If you have to use both Apollo and Pinia, please follow these rules:

- **Never use Apollo Client in Pinia stores**. Apollo Client should only be consumed within a Vue component or a [composable](vue.md#composables).
- Do not sync data between Apollo and Pinia.
- You should have only one source of truth for your requests.

### Add Apollo to an existing app with Pinia

You can have Apollo data management in your components alongside existing Pinia state when you both:

- Need to work with data coming from GraphQL
- Can't migrate from Pinia to Apollo because of high migration effort

Don't try to manage client state (not to be confused with GraphQL or REST data) with Apollo and Pinia at the same time,
consider migrating from Pinia to Apollo if you need this.
Don't use Apollo inside Pinia stores.

### Add Pinia to an existing app with Apollo

Strongly consider [using Apollo for client-side state management](graphql.md#local-state-with-apollo) first. However, if all of the
following are true, Apollo might not be the best tool for managing this client-side state:

- If the footprint of client-side state is significant enough that there's a high implementation cost due to Apollo's complexities.
- If the client-side state can be nicely decoupled from the Apollo managed GraphQL API data.

### Vuex used alongside Apollo

[Vuex is deprecated in GitLab](vuex.md#deprecated), use the guidance above to pick either Apollo or Pinia as your primary state manager.
Follow the corresponding migration guide: [Apollo](migrating_from_vuex.md) or [Pinia](pinia.md#migrating-from-vuex).
Do not add new Pinia stores on top of the existing Vuex store, migrate first.
