# GraphQL

## Getting Started

### Helpful Resources

**General resources**:

- [📚 Official Introduction to GraphQL](https://graphql.org/learn/)
- [📚 Official Introduction to Apollo](https://www.apollographql.com/docs/tutorial/introduction/)

**GraphQL at GitLab**:

- [🎬 GitLab Unfiltered GraphQL playlist](https://www.youtube.com/watch?v=wHPKZBDMfxE&list=PL05JrBw4t0KpcjeHjaRMB7IGB2oDWyJzv)
- [🎬 GraphQL at GitLab: Deep Dive](../api_graphql_styleguide.md#deep-dive) (video) by Nick Thomas
  - An overview of the history of GraphQL at GitLab (not frontend-specific)
- [🎬 GitLab Feature Walkthrough with GraphQL and Vue Apollo](https://www.youtube.com/watch?v=6yYp2zB7FrM) (video) by Natalia Tepluhina
  - A real-life example of implementing a frontend feature in GitLab using GraphQL
- [🎬 History of client-side GraphQL at GitLab](https://www.youtube.com/watch?v=mCKRJxvMnf0) (video) Illya Klymov and Natalia Tepluhina
- [🎬 From Vuex to Apollo](https://www.youtube.com/watch?v=9knwu87IfU8) (video) by Natalia Tepluhina
  - A useful overview of when Apollo might be a better choice than Vuex, and how one could go about the transition
- [🛠 Vuex -> Apollo Migration: a proof-of-concept project](https://gitlab.com/ntepluhina/vuex-to-apollo/blob/master/README.md)
  - A collection of examples that show the possible approaches for state management with Vue+GraphQL+(Vuex or Apollo) apps

### Libraries

We use [Apollo](https://www.apollographql.com/) (specifically [Apollo Client](https://www.apollographql.com/docs/react/)) and [Vue Apollo](https://github.com/vuejs/vue-apollo)
when using GraphQL for frontend development.

If you are using GraphQL within a Vue application, the [Usage in Vue](#usage-in-vue) section
can help you learn how to integrate Vue Apollo.

For other use cases, check out the [Usage outside of Vue](#usage-outside-of-vue) section.

### Tooling

- [Apollo Client Devtools](https://github.com/apollographql/apollo-client-devtools)

#### [Apollo GraphQL VS Code extension](https://marketplace.visualstudio.com/items?itemName=apollographql.vscode-apollo)

If you use VS Code, the Apollo GraphQL extension supports autocompletion in `.graphql` files. To set up
the GraphQL extension, follow these steps:

1. Add an `apollo.config.js` file to the root of your `gitlab` local directory.
1. Populate the file with the following content:

    ```javascript
    module.exports = {
      client: {
        includes: ['./app/assets/javascripts/**/*.graphql', './ee/app/assets/javascripts/**/*.graphql'],
        service: {
          name: 'GitLab',
          localSchemaFile: './doc/api/graphql/reference/gitlab_schema.graphql',
        },
      },
    };
    ```

1. Restart VS Code.

### Exploring the GraphQL API

Our GraphQL API can be explored via GraphiQL at your instance's
`/-/graphql-explorer` or at [GitLab.com](https://gitlab.com/-/graphql-explorer). Consult the
[GitLab GraphQL API Reference documentation](../../api/graphql/reference)
where needed.

You can check all existing queries and mutations on the right side
of GraphiQL in its **Documentation explorer**. It's also possible to
write queries and mutations directly on the left tab and check
their execution by clicking **Execute query** button on the top left:

![GraphiQL interface](img/graphiql_explorer_v12_4.png)

## Apollo Client

To save duplicated clients getting created in different apps, we have a
[default client](https://gitlab.com/gitlab-org/gitlab/blob/master/app/assets/javascripts/lib/graphql.js) that should be used. This setups the
Apollo client with the correct URL and also sets the CSRF headers.

Default client accepts two parameters: `resolvers` and `config`.

- `resolvers` parameter is created to accept an object of resolvers for [local state management](#local-state-with-apollo) queries and mutations
- `config` parameter takes an object of configuration settings:
  - `cacheConfig` field accepts an optional object of settings to [customize Apollo cache](https://www.apollographql.com/docs/react/caching/cache-configuration/#configuring-the-cache)
  - `baseUrl` allows us to pass a URL for GraphQL endpoint different from our main endpoint (i.e.`${gon.relative_url_root}/api/graphql`)
  - `assumeImmutableResults` (set to `false` by default) - this setting, when set to `true`, will assume that every single operation on updating Apollo Cache is immutable. It also sets `freezeResults` to `true`, so any attempt on mutating Apollo Cache will throw a console warning in development environment. Please ensure you're following the immutability pattern on cache update operations before setting this option to `true`.

## GraphQL Queries

To save query compilation at runtime, webpack can directly import `.graphql`
files. This allows webpack to preprocess the query at compile time instead
of the client doing compilation of queries.

To distinguish queries from mutations and fragments, the following naming convention is recommended:

- `all_users.query.graphql` for queries;
- `add_user.mutation.graphql` for mutations;
- `basic_user.fragment.graphql` for fragments.

### Fragments

[Fragments](https://graphql.org/learn/queries/#fragments) are a way to make your complex GraphQL queries more readable and re-usable. Here is an example of GraphQL fragment:

```javascript
fragment DesignListItem on Design {
  id
  image
  event
  filename
  notesCount
}
```

Fragments can be stored in separate files, imported and used in queries, mutations, or other fragments.

```javascript
#import "./design_list.fragment.graphql"
#import "./diff_refs.fragment.graphql"

fragment DesignItem on Design {
  ...DesignListItem
  fullPath
  diffRefs {
    ...DesignDiffRefs
  }
}
```

More about fragments:
[GraphQL Docs](https://graphql.org/learn/queries/#fragments)

## Usage in Vue

To use Vue Apollo, import the [Vue Apollo](https://github.com/vuejs/vue-apollo) plugin as well
as the default client. This should be created at the same point
the Vue application is mounted.

```javascript
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

new Vue({
  ...,
  apolloProvider,
  ...
});
```

Read more about [Vue Apollo](https://github.com/vuejs/vue-apollo) in the [Vue Apollo documentation](https://vue-apollo.netlify.app/guide/).

### Local state with Apollo

It is possible to manage an application state with Apollo by passing
in a resolvers object when creating the default client. The default state can be set by writing
to the cache after setting up the default client.

```javascript
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
Vue.use(VueApollo);

const defaultClient = createDefaultClient({
  resolvers: {}
});

defaultClient.cache.writeData({
  data: {
    user: {
      name: 'John',
      surname: 'Doe',
      age: 30
    },
  },
});

const apolloProvider = new VueApollo({
  defaultClient,
});
```

We can query local data with `@client` Apollo directive:

```javascript
// user.query.graphql

query User {
  user @client {
    name
    surname
    age
  }
}
```

Along with creating local data, we can also extend existing GraphQL types with `@client` fields. This is extremely useful when we need to mock an API responses for fields not yet added to our GraphQL API.

#### Mocking API response with local Apollo cache

Using local Apollo Cache is handy when we have a need to mock some GraphQL API responses, queries or mutations locally (e.g. when they're still not added to our actual API).

For example, we have a [fragment](#fragments) on `DesignVersion` used in our queries:

```javascript
fragment VersionListItem on DesignVersion {
  id
  sha
}
```

We need to fetch also version author and the 'created at' property to display them in the versions dropdown but these changes are still not implemented in our API. We can change the existing fragment to get a mocked response for these new fields:

```javascript
fragment VersionListItem on DesignVersion {
  id
  sha
  author @client {
    avatarUrl
    name
  }
  createdAt @client
}
```

Now Apollo will try to find a _resolver_ for every field marked with `@client` directive. Let's create a resolver for `DesignVersion` type (why `DesignVersion`? because our fragment was created on this type).

```javascript
// resolvers.js

const resolvers = {
  DesignVersion: {
    author: () => ({
      avatarUrl:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
      name: 'Administrator',
      __typename: 'User',
    }),
    createdAt: () => '2019-11-13T16:08:11Z',
  },
};

export default resolvers;
```

We need to pass resolvers object to our existing Apollo Client:

```javascript
// graphql.js

import createDefaultClient from '~/lib/graphql';
import resolvers from './graphql/resolvers';

const defaultClient = createDefaultClient(
  {},
  resolvers,
);
```

Now every single time on attempt to fetch a version, our client will fetch `id` and `sha` from the remote API endpoint and will assign our hardcoded values to `author` and `createdAt` version properties. With this data, frontend developers are able to work on UI part without being blocked by backend. When actual response is added to the API, a custom local resolver can be removed fast and the only change to query/fragment is `@client` directive removal.

Read more about local state management with Apollo in the [Vue Apollo documentation](https://vue-apollo.netlify.app/guide/local-state.html#local-state).

### Using with Vuex

When Apollo Client is used within Vuex and fetched data is stored in the Vuex store, there is no need in keeping Apollo Client cache enabled. Otherwise we would have data from the API stored in two places - Vuex store and Apollo Client cache. More to say, with Apollo's default settings, a subsequent fetch from the GraphQL API could result in fetching data from Apollo cache (in the case where we have the same query and variables). To prevent this behavior, we need to disable Apollo Client cache passing a valid `fetchPolicy` option to its constructor:

```javascript
import fetchPolicies from '~/graphql_shared/fetch_policy_constants';

export const gqClient = createGqClient(
  {},
  {
    fetchPolicy: fetchPolicies.NO_CACHE,
  },
);
```

### Feature flags in queries

Sometimes it may be useful to have an entity in the GraphQL query behind a feature flag.
For example, when working on a feature where the backend has already been merged but the frontend
hasn't you might want to put the GraphQL entity behind a feature flag to allow for smaller
merge requests to be created and merged.

To do this we can use the `@include` directive to exclude an entity if the `if` statement passes.

```graphql
query getAuthorData($authorNameEnabled: Boolean = false) {
  username
  name @include(if: $authorNameEnabled)
}
```

Then in the Vue (or JavaScript) call to the query we can pass in our feature flag. This feature
flag will need to be already setup correctly. See the [feature flag documentation](../feature_flags/development.md)
for the correct way to do this.

```javascript
export default {
  apollo: {
    user: {
      query: QUERY_IMPORT,
      variables() {
        return {
          authorNameEnabled: gon?.features?.authorNameEnabled,
        };
      },
    }
  },
};
```

### Manually triggering queries

Queries on a component's `apollo` property are made automatically when the component is created.
Some components instead want the network request made on-demand, for example a dropdown with lazy-loaded items.

There are two ways to do this:

1. Use the `skip` property

```javascript
export default {
  apollo: {
    user: {
      query: QUERY_IMPORT,
      skip() {
        // only make the query when dropdown is open
        return !this.isOpen;
      },
    }
  },
};
```

1. Using `addSmartQuery`

You can manually create the Smart Query in your method.

```javascript
handleClick() {
  this.$apollo.addSmartQuery('user', {
    // this takes the same values as you'd have in the `apollo` section
    query: QUERY_IMPORT,
  }),
};
```

### Working with pagination

GitLab's GraphQL API uses [Relay-style cursor pagination](https://www.apollographql.com/docs/react/data/pagination/#cursor-based)
for connection types. This means a "cursor" is used to keep track of where in the data
set the next items should be fetched from. [GraphQL Ruby Connection Concepts](https://graphql-ruby.org/pagination/connection_concepts.html)
is a good overview and introduction to connections.

Every connection type (for example, `DesignConnection` and `DiscussionConnection`) has a field `pageInfo` that contains an information required for pagination:

```javascript
pageInfo {
  endCursor
  hasNextPage
  hasPreviousPage
  startCursor
}
```

Here:

- `startCursor` and `endCursor` display the cursor of the first and last items
  respectively.
- `hasPreviousPage` and `hasNextPage` allow us to check if there are more pages
  available before or after the current page.

When we fetch data with a connection type, we can pass cursor as `after` or `before`
parameter, indicating a starting or ending point of our pagination. They should be
followed with `first` or `last` parameter respectively to indicate _how many_ items
we want to fetch after or before a given endpoint.

For example, here we're fetching 10 designs after a cursor:

```javascript
query {
  project(fullPath: "root/my-project") {
    id
    issue(iid: "42") {
      designCollection {
        designs(atVersion: null, after: "Ihwffmde0i", first: 10) {
          edges {
            node {
              id
            }
          }
        }
      }
    }
  }
}
```

#### Using `fetchMore` method in components

When making an initial fetch, we usually want to start a pagination from the beginning.
In this case, we can either:

- Skip passing a cursor.
- Pass `null` explicitly to `after`.

After data is fetched, we should save a `pageInfo` object. Let's assume we're storing
it to Vue component `data`:

```javascript
data() {
  return {
    pageInfo: null,
  }
},
apollo: {
  designs: {
    query: projectQuery,
    variables() {
      return {
        // rest of design variables
        ...
        first: 10,
      };
    },
    result(res) {
      this.pageInfo = res.data?.project?.issue?.designCollection?.designs?.pageInfo;
    },
  },
},
```

When we want to move to the next page, we use an Apollo `fetchMore` method, passing a
new cursor (and, optionally, new variables) there. In the `updateQuery` hook, we have
to return a result we want to see in the Apollo cache after fetching the next page.

```javascript
fetchNextPage() {
  // as a first step, we're checking if we have more pages to move forward
  if (this.pageInfo?.hasNextPage) {
    this.$apollo.queries.designs.fetchMore({
      variables: {
        // rest of design variables
        ...
        first: 10,
        after: this.pageInfo?.endCursor,
      },
      updateQuery(previousResult, { fetchMoreResult }) {
        // here we can implement the logic of adding new designs to fetched one (for example, if we use infinite scroll)
        // or replacing old result with the new one if we use numbered pages

        const newDesigns = fetchMoreResult.project.issue.designCollection.designs;
        previousResult.project.issue.designCollection.designs.push(...newDesigns)

        return previousResult;
      },
    });
  }
}
```

Please note we don't have to save `pageInfo` one more time; `fetchMore` triggers a query
`result` hook as well.

### Testing

#### Mocking response as component data

With [Vue test utils](https://vue-test-utils.vuejs.org/) it is easy to quickly test components that
fetch GraphQL queries. The simplest way is to use `shallowMount` and then set
the data on the component

```javascript
it('tests apollo component', () => {
  const vm = shallowMount(App);

  vm.setData({
    ...mock data
  });
});
```

#### Testing loading state

If we need to test how our component renders when results from the GraphQL API are still loading, we can mock a loading state into respective Apollo queries/mutations:

```javascript
  function createComponent({
    loading = false,
  } = {}) {
    const $apollo = {
      queries: {
        designs: {
          loading,
        },
    };

    wrapper = shallowMount(Index, {
      sync: false,
      mocks: { $apollo }
    });
  }

  it('renders loading icon', () => {
  createComponent({ loading: true });

  expect(wrapper.element).toMatchSnapshot();
})
```

#### Testing Apollo components

If we use `ApolloQuery` or `ApolloMutation` in our components, in order to test their functionality we need to add a stub first:

```javascript
import { ApolloMutation } from 'vue-apollo';

function createComponent(props = {}) {
  wrapper = shallowMount(MyComponent, {
    sync: false,
    propsData: {
      ...props,
    },
    stubs: {
      ApolloMutation,
    },
  });
}
```

`ApolloMutation` component exposes `mutate` method via scoped slot. If we want to test this method, we need to add it to mocks:

```javascript
const mutate = jest.fn().mockResolvedValue();
const $apollo = {
  mutate,
};

function createComponent(props = {}) {
  wrapper = shallowMount(MyComponent, {
    sync: false,
    propsData: {
      ...props,
    },
    stubs: {
      ApolloMutation,
    },
    mocks: {
      $apollo:
    }
  });
}
```

Then we can check if `mutate` is called with correct variables:

```javascript
const mutationVariables = {
  mutation: createNoteMutation,
  update: expect.anything(),
  variables: {
    input: {
      noteableId: 'noteable-id',
      body: 'test',
      discussionId: '0',
    },
  },
};

it('calls mutation on submitting form ', () => {
  createComponent()
  findReplyForm().vm.$emit('submitForm');

  expect(mutate).toHaveBeenCalledWith(mutationVariables);
});
```

## Handling errors

GitLab's GraphQL mutations currently have two distinct error modes: [Top-level](#top-level-errors) and [errors-as-data](#errors-as-data).

When utilising a GraphQL mutation, we must consider handling **both of these error modes** to ensure that the user receives the appropriate feedback when an error occurs.

### Top-level errors

These errors are located at the "top level" of a GraphQL response. These are non-recoverable errors including argument errors and syntax errors, and should not be presented directly to the user.

#### Handling top-level errors

Apollo is aware of top-level errors, so we are able to leverage Apollo's various error-handling mechanisms to handle these errors (e.g. handling Promise rejections after invoking the [`mutate`](https://www.apollographql.com/docs/react/api/apollo-client/#ApolloClient.mutate) method, or handling the `error` event emitted from the [`ApolloMutation`](https://apollo.vuejs.org/api/apollo-mutation.html#events) component).

Because these errors are not intended for users, error messages for top-level errors should be defined client-side.

### Errors-as-data

These errors are nested within the `data` object of a GraphQL response. These are recoverable errors that, ideally, can be presented directly to the user.

#### Handling errors-as-data

First, we must add `errors` to our mutation object:

```diff
mutation createNoteMutation($input: String!) {
  createNoteMutation(input: $input) {
    note {
      id
+     errors
    }
  }
```

Now, when we commit this mutation and errors occur, the response will include `errors` for us to handle:

```javascript
{
  data: {
    mutationName: {
      errors: ["Sorry, we were not able to update the note."]
    }
  }
}
```

When handling errors-as-data, use your best judgement to determine whether to present the error message in the response, or another message defined client-side, to the user.

## Usage outside of Vue

It is also possible to use GraphQL outside of Vue by directly importing
and using the default client with queries.

```javascript
import createDefaultClient from '~/lib/graphql';
import query from './query.graphql';

const defaultClient = createDefaultClient();

defaultClient.query({ query })
  .then(result => console.log(result));
```

When [using Vuex](#Using-with-Vuex), disable the cache when:

- The data is being cached elsewhere
- The use case does not need caching
if the data is being cached elsewhere, or if there is simply no need for it for the given use case.

```javascript
import createDefaultClient from '~/lib/graphql';
import fetchPolicies from '~/graphql_shared/fetch_policy_constants';

const defaultClient = createDefaultClient(
  {},
  {
    fetchPolicy: fetchPolicies.NO_CACHE,
  },
);
```
