---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Migrating from Vuex
---

[Vuex is deprecated in GitLab](vuex.md#deprecated), if you have an existing Vuex store you should strongly consider migrating.

## Why?

We have defined the [GraphQL API](../../api/graphql/_index.md) as the primary choice for all user-facing features.
We can safely assume that whenever GraphQL is present, so will the Apollo Client.
We [do not want to use Vuex with Apollo](graphql.md#using-with-vuex), so the VueX stores count
will naturally decline over time as we move from the REST API to GraphQL.

This section gives guidelines and methods to translate an existing VueX store to
pure Vue and Apollo, or how to rely less on VueX.

## How?

[Pick your preferred state manager solution](state_management.md) before proceeding with the migration.

- If you plan to use Pinia (in pilot phase), [follow this guide](pinia.md#migrating-from-vuex).
- If you plan to use Apollo Client for all state management, then [follow the guide below](#migrate-to-vue-managed-state-and-apollo-client).

### Migrate to Vue-managed state and Apollo Client

As a whole, we want to understand how complex our change will be. Sometimes, we only have a few properties that are truly worth being stored in a global state and sometimes they can safely all be extracted to pure `Vue`. `VueX` properties generally fall into one of these categories:

- Static properties
- Reactive mutable properties
- Getters
- API data

Therefore, the first step is to read the current VueX state and determine the category of each property.

At a high level, we could map each category with an equivalent non-VueX code pattern:

- Static properties: Provide/Inject from Vue API.
- Reactive mutable properties: Vue events and props, Apollo Client.
- Getters: Utils functions, Apollo `update` hook, computed properties.
- API data: Apollo Client.

Let's go through an example. In each section we refer to this state and slowly go through migrating it fully:

```javascript
// state.js AKA our store
export default ({ blobPath = '', summaryEndpoint = '', suiteEndpoint = '' }) => ({
  blobPath,
  summaryEndpoint,
  suiteEndpoint,
  testReports: {},
  selectedSuiteIndex: null,
  isLoading: false,
  errorMessage: null,
  limit : 10,
  pageInfo: {
    page: 1,
    perPage: 20,
  },
});
```

### How to migrate static values

The easiest type of values to migrate are static values, either:

- Client-side constants: If the static value is a client-side constant, it may have been implemented
  in the store for easy access by other state properties or methods. However, it is generally
  a better practice to add such values to a `constants.js` file and import it when needed.
- Rails-injected dataset: These are values that we may need to provide to our Vue apps.
  They are static, so adding them to the VueX store is not necessary and it could instead
  be done easily through the `provide/inject` Vue API, which would be equivalent but without the VueX overhead. This should **only** be injected inside the top-most JS file that mounts our component.

If we take a look at our example above, we can already see that two properties contain `Endpoint` in their name, which probably means that these come from our Rails dataset. To confirm this, we would search the codebase for these properties and see where they are defined, which is the case in our example. Additionally, `blobPath` is also a static property, and a little less obvious here is that `pageInfo` is actually a constant! It is never modified and is only used as a default value that we use inside our getter:

```javascript
// state.js AKA our store
export default ({ blobPath = '', summaryEndpoint = '', suiteEndpoint = '' }) => ({
  limit
  blobPath, // Static - Dataset
  summaryEndpoint, // Static - Dataset
  suiteEndpoint, // Static - Dataset
  testReports: {},
  selectedSuiteIndex: null,
  isLoading: false,
  errorMessage: null,
  pageInfo: { // Static - Constant
    page: 1, // Static - Constant
    perPage: 20, // Static - Constant
  },
});
```

### How to migrate reactive mutable values

These values are especially useful when used by a lot of different components, so we can first evaluate how many reads and writes each property gets, and how far apart these are from each other. The fewer reads there are and the closer together they live, the easier it will be to remove these properties in favor of native Vue props and events.

#### Simple read/write values

If we go back to our example, `selectedSuiteIndex` is only used by **one component** and also **once inside a getter**. Additionally, this getter is only used once itself! It would be quite easy to translate this logic to Vue because this could become a `data` property on the component instance. For the getter, we can use a computed property instead, or a method on the component that returns the right item because we will have access to the index there as well. This is a perfect example of how the VueX store here complicates the application by adding a lot of abstractions when really everything could live inside the same component.

Luckily, in our example all properties could live inside the same component. However, there are cases where it will not be possible. When this happens, we can use Vue events and props to communicate between sibling components. Store the data in question inside a parent component that should know about the state, and when a child component wants to write to the component, it can `$emit` an event with the new value and let the parent update. Then, by cascading props down to all of its children, all instances of the sibling components will share the same data.

Sometimes, it can feel that events and props are cumbersome, especially in very deep component trees. However, it is quite important to be aware that this is mostly an inconvenience issue and not an architectural flaw or problem to fix. Passing down props, even deeply nested, is a very acceptable pattern for cross-components communication.

#### Shared read/write values

Let's assume that we have a property in the store that is used by multiple components for read and writes that are either so numerous or far apart that Vue props and events seem like a bad solution. Instead, we use Apollo client-side resolvers. This section requires knowledge of [Apollo Client](graphql.md), so feel free to check the apollo details as needed.

First we need to set up our Vue app to use `VueApollo`. Then when creating our store, we pass the `resolvers` and `typedefs` (defined later) to the Apollo Client:

```javascript
import { resolvers } from "./graphql/settings.js"
import typeDefs from './graphql/typedefs.graphql';

...
const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient({
    resolvers, // To be written soon
    { typeDefs }, // We are going to create this in a sec
  }),
});
```

For our example, let's call our field `app.status`, and we need is to define queries and mutations that use the `@client` directives. Let's create them right now:

```javascript
// get_app_status.query.graphql
query getAppStatus {
  app @client {
    status
  }
}
```

```javascript
// update_app_status.mutation.graphql
mutation updateAppStatus($appStatus: String) {
  updateAppStatus(appStatus: $appStatus) @client
}
```

For fields that **do not exist in our schema**, we need to set up `typeDefs`. For example:

```javascript
// typedefs.graphql

type TestReportApp {
  status: String!
}

extend type Query {
  app: TestReportApp
}
```

Now we can write our resolvers so that we can update the field with our mutation:

```javascript
// settings.js
export const resolvers = {
  Mutation: {
    // appStatus is the argument to our mutation
    updateAppStatus: (_, { appStatus }, { cache }) => {
      cache.writeQuery({
        query: getAppStatus,
        data: {
          app: {
            __typename: 'TestReportApp',
            status: appStatus,
          },
        },
      });
    },
  }
}
```

For querying, this works without any additional instructions because it behaves like any `Object`, because querying for `app { status }` is equivalent to `app.status`. However, we need to write either a "default" `writeQuery` (to define the very first value our field will have) or we can set up the [`typePolicies` for our `cacheConfig`](graphql.md#local-state-with-apollo) to provide this default value.

So now when we want to read from this value, we can use our local query. When we need to update it, we can call the mutation and pass the new value as an argument.

#### Network-related values

There are values like `isLoading` and `errorMessage` which are tied to the network request state. These are read/write properties, but will easily be replaced later with Apollo Client's own capabilities without us doing any extra work:

```javascript
// state.js AKA our store
export default ({ blobPath = '', summaryEndpoint = '', suiteEndpoint = '' }) => ({
  blobPath, // Static - Dataset
  summaryEndpoint, // Static - Dataset
  suiteEndpoint, // Static - Dataset
  testReports: {},
  selectedSuiteIndex: null, // Mutable -> data property
  isLoading: false, // Mutable -> tied to network
  errorMessage: null, // Mutable -> tied to network
  pageInfo: { // Static - Constant
    page: 1, // Static - Constant
    perPage: 20, // Static - Constant
  },
});
```

### How to migrate getters

Getters have to be reviewed case-by-case, but a general guideline is that it is highly possible to write a pure JavaScript util function that takes as an argument the state values we used to use inside the getter, and then return whatever value we want. Consider the following getter:

```javascript
// getters.js
export const getSelectedSuite = (state) =>
  state.testReports?.test_suites?.[state.selectedSuiteIndex] || {};
```

All that we do here is reference two state values, which can both become arguments to a function:

```javascript
//new_utils.js
export const getSelectedSuite = (testReports, selectedSuiteIndex) =>
  testReports?.test_suites?.[selectedSuiteIndex] || {};
```

This new util can then be imported and used as it previously was, but directly inside the component. Also, most of the specs for the getters can be ported to the utils quite easily because the logic is preserved.

### How to migrate API data

Our last property is called `testReports` and it is fetched via an `axios` call to the API. We assume that we are in a pure REST application and that GraphQL data is not yet available:

```javascript
// actions.js
export const fetchSummary = ({ state, commit, dispatch }) => {
  dispatch('toggleLoading');

  return axios
    .get(state.summaryEndpoint)
    .then(({ data }) => {
      commit(types.SET_SUMMARY, data);
    })
    .catch(() => {
      createAlert({
        message: s__('TestReports|There was an error fetching the summary.'),
      });
    })
    .finally(() => {
      dispatch('toggleLoading');
    });
};
```

We have two options here. If this action is only used once, there is nothing preventing us from just moving all of this code from the `actions.js` file to the component that does the fetching. Then, it would be easy to remove all the state related code in favor of `data` properties. In that case, `isLoading` and `errorMessages` would both live along with it because it's only used once.

If we are reusing this function multiple time (or plan to), then that Apollo Client can be leveraged to do what it does best: network calls and caching. In this section, we assume Apollo Client knowledge and that you know how to set it up, but feel free to read through [the GraphQL documentation](graphql.md).

We can use a local GraphQL query (with an `@client` directive) to structure how we want to receive the data, and then use a client-side resolver to tell Apollo Client how to resolve that query. We can take a look at our REST call in the browser network tab and determine which structure suits the use case. In our example, we could write our query like:

```graphql
query getTestReportSummary($fullPath: ID!, $iid: ID!, endpoint: String!) {
  project(fullPath: $fullPath){
    id,
    pipeline(iid: $iid){
      id,
      testReportSummary(endpoint: $endpoint) @client {
        testSuites{
          nodes{
            name
            totalTime,
            # There are more fields here, but they aren't needed for our example
          }
        }
      }
    }
  }
}
```

The structure here is arbitrary in the sense that we could write this however we want. It might be tempting to skip the `project.pipeline.testReportSummary` because this is not how the REST call is structured. However, by making the query structure compliant with the `GraphQL` API, we will not need to modify our query if we do decide to transition to `GraphQL` later, and can simply remove the `@client` directive. This also gives us **caching for free** because if we try to fetch the summary again for the same pipeline, Apollo Client knows that we already have the result!

Additionally, we are passing an `endpoint` argument to our field `testReportSummary`. This would not be necessary in pure `GraphQL`, but our resolver is going to need that information to make the `REST` call later.

Now we need to write a client-side resolver. When we mark a field with an `@client` directive, it is **not sent to the server**, and Apollo Client instead expects us to [define our own code to resolve the value](graphql.md#using-client-side-resolvers). We can write a client-side resolver for `testReportSummary` inside the `cacheConfig` object that we pass to Apollo Client. We want this resolver to make the Axios call and return whatever data structure we want. That this is also the perfect place to transfer a getter if it was always used when accessing the API data or massaging the data structure:

```javascript
// graphql_config.js
export const resolvers = {
  Query: {
    testReportSummary(_, { summaryEndpoint }): {
    return axios.get(summaryEndpoint).then(({ data }) => {
      return data // we could format/massage our data here instead of using a getter
    }
  }
}
```

Any time we make a call to the `testReportSummary @client` field, this resolver is executed and returns the result of the operation, which is essentially doing the same job as the `VueX` action did.

If we assume that our GraphQL call is stored inside a data property called `testReportSummary`, we can replace `isLoading` with `this.$apollo.queries.testReportSummary.lodaing` in any component that fires this query. Errors can be handled inside the `error` hook of the Query.

### Migration strategy

Now that we have gone through each type of data, let's review how to plan for the transition between a VueX-based store and one without. We are trying to avoid VueX and Apollo coexisting, so the less time where both stores are available in the same context the better. To minimize this overlap, we should start our migration by removing from the store all that does not involve adding an Apollo store. Each of the following point could be its own MR:

1. Migrate away from Static values, both `Rails` dataset and client-side constants and use `provide/inject` and `constants.js` files instead.
1. Replace simple read/write operations with either:
   - `data` properties and `methods` if in a single component.
   - `props` and `emits` if shared across a localized group of components.
1. Replace shared read/write operations with Apollo Client `@client` directives.
1. Replace network data with Apollo Client, either with actual GraphQL calls when available or by using client-side resolvers to make REST calls.

If it is impossible to quickly replace shared read/write operations or network data (for example in one or two milestones), consider making a different Vue component behind a feature flag that is exclusively functional with Apollo Client, and rename the current component that uses VueX with a `legacy-` prefix. The newer component might not be able to implement all functionality right away, but we can progressively add them as we make MRs. This way, our legacy component is exclusively using VueX as a store and the new one is only Apollo. After the new component has re-implemented all the logic, we can turn the Feature Flag on and ensure that it behaves as expected.
