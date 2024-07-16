---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# State management guidance

At GitLab we support two solutions for client state management: [Apollo](https://www.apollographql.com/) and [Pinia](https://pinia.vuejs.org/).
It is non-trivial to pick either of these as your primary state manager.
This page should provide you with general guidance on how to make this choice.

You may also see Vuex appear in GitLab codebase. [Vuex is deprecated in GitLab](vuex.md#deprecated) and **no new Vuex stores should be created**.
If your app has a Vuex store [consider migrating](migrating_from_vuex.md).

## Apollo

[Apollo state manager](https://www.apollographql.com/) is generally used when you rely on GraphQL in your app.
[Learn mode about GraphQL and Apollo](graphql.md).

### Strengths

- Great for handling GraphQL requests
- Can cache data from REST API when GraphQL is not available
- Strongly typed
- Can be used to describe client state

### Weaknesses

- Very heavy on bundle size (`ApolloClient` just by itself [produces at least 170KB additional payload](https://bundlephobia.com/package/@apollo/client@3.10.4))
- [More complex and involved than Pinia for client state management](https://www.apollographql.com/docs/react/local-state/managing-state-with-field-policies)
- Hard to debug even with Apollo DevTools

### Pick Apollo when

- You rely on the GraphQL server state
- You need specific Apollo features, for example:
  - [Parametrized cache, cache invalidation](graphql.md#immutability-and-cache-updates)
  - [Polling](graphql.md#polling-and-performance)
  - [Stale While Revalidate](https://www.apollographql.com/docs/react/caching/advanced-topics#persisting-the-cache)
  - [Real-time updates](graphql.md#subscriptions)
  - [Other](https://www.apollographql.com/docs/react/)

## Pinia

[Pinia](https://pinia.vuejs.org/) is generally used for any kind of client state management and\or for caching REST API data.
[Learn more about Pinia](pinia.md).

### Strengths

- Concise and simple
- Easy to understand data flow (explicit state changes)
- Lightweight ([20KB payload](https://bundlephobia.com/package/pinia@2.1.7))
- API agnostic: can cache both REST and GraphQL data
- Vue reactivity under the hood, API similar to Vuex
- Easy to debug

### Weaknesses

- Can't do any advanced GraphQL request handling out of the box (polling, caching, etc.)
- Most of the advanced features have to be implemented from scratch
- Can lead to same pitfalls as Vuex without guidance (overblown stores)

### Pick Pinia when you have any of these

- Performance-critical application
- Client-only state
- High reliance on data from REST API

## Combining Pinia and Apollo

We recommend you pick either Apollo or Pinia as the only state manager in your app.
Combining them is not recommended because of the following reasons:

- Pinia and Apollo are both global stores, which means sharing responsibilities and having two sources of truth
- Difference in mental models: Apollo is configuration based, Pinia is not. Switching between these mental models is tedious and error-prone
- Experiencing the drawbacks of both approaches

However there may be cases when it's OK to combine these two to seek specific benefits from both solutions.
If you have to use both remember to combine them only within a component or a [composable](vue.md#composables), **never use Apollo client in Pinia stores**.

### Add Apollo to an existing app with Pinia

You can add Apollo to an existing app with Pinia if you either:

- Have a clear plan to migrate from REST API to GraphQL
- Need specific features from Apollo but can't drop Pinia because of high migration effort

You don't have to use Apollo if Axios is good enough for your GraphQL requests. Examples:

- Don't add Apollo if you need to only fetch and store server data.
- Add Apollo on the component level if you need real-time updates.

Don't use Apollo inside Pinia stores.

### Add Pinia to an existing app with Apollo

Consider [using Apollo for local state management](graphql.md#local-state-with-apollo) first.
If you feel like local state management in Apollo becomes a burden try moving local state to Pinia stores.

Don't use Apollo inside Pinia stores.

### Vuex used alongside Apollo

[Vuex is deprecated in GitLab](vuex.md#deprecated), use the guidance above to pick either Apollo or Pinia as your primary state manager.
Follow the corresponding migration guide: [Apollo](migrating_from_vuex.md) or [Pinia](pinia.md#migrating-from-vuex).
Do not add new Pinia stores on top of the existing Vuex store, migrate first.
