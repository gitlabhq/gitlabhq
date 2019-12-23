# GraphQL

Our GraphQL API can be explored via GraphiQL at your instance's
`/-/graphql-explorer` or at [GitLab.com](https://gitlab.com/-/graphql-explorer).

You can check all existing queries and mutations on the right side
of GraphiQL in its **Documentation explorer**. It's also possible to
write queries and mutations directly on the left tab and check
their execution by clicking **Execute query** button on the top left:

![GraphiQL interface](img/graphiql_explorer_v12_4.png)

We use [Apollo] and [Vue Apollo][vue-apollo] for working with GraphQL
on the frontend.

## Apollo Client

To save duplicated clients getting created in different apps, we have a
[default client][default-client] that should be used. This setups the
Apollo client with the correct URL and also sets the CSRF headers.

Default client accepts two parameters: `resolvers` and `config`.

- `resolvers` parameter is created to accept an object of resolvers for [local state management](#local-state-with-apollo) queries and mutations
- `config` parameter takes an object of configuration settings:
  - `cacheConfig` field accepts an optional object of settings to [customize Apollo cache](https://github.com/apollographql/apollo-client/tree/master/packages/apollo-cache-inmemory#configuration)
  - `baseUrl` allows us to pass a URL for GraphQL endpoint different from our main endpoint (i.e.`${gon.relative_url_root}/api/graphql`)
  - `assumeImmutableResults` (set to `false` by default) - this setting, when set to `true`, will assume that every single operation on updating Apollo Cache is immutable. It also sets `freezeResults` to `true`, so any attempt on mutating Apollo Cache will throw a console warning in development environment. Please ensure you're following the immutability pattern on cache update operations before setting this option to `true`.

## GraphQL Queries

To save query compilation at runtime, webpack can directly import `.graphql`
files. This allows webpack to preprocess the query at compile time instead
of the client doing compilation of queries.

To distinguish queries from mutations and fragments, the following naming convention is recommended:

- `allUsers.query.graphql` for queries;
- `addUser.mutation.graphql` for mutations;
- `basicUser.fragment.graphql` for fragments.

### Fragments

Fragments are a way to make your complex GraphQL queries more readable and re-usable. Here is an example of GraphQL fragment:

```javascript
fragment DesignListItem on Design {
  id
  image
  event
  filename
  notesCount
}
```

Fragments can be stored in separate files, imported and used in queries, mutations or other fragments.

```javascript
#import "./designList.fragment.graphql"
#import "./diffRefs.fragment.graphql"

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

To use Vue Apollo, import the [Vue Apollo][vue-apollo] plugin as well
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

Read more about [Vue Apollo][vue-apollo] in the [Vue Apollo documentation](https://vue-apollo.netlify.com/guide/).

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

```
fragment VersionListItem on DesignVersion {
  id
  sha
}
```

We need to fetch also version author and the 'created at' property to display them in the versions dropdown but these changes are still not implemented in our API. We can change the existing fragment to get a mocked response for these new fields:

```
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

Read more about local state management with Apollo in the [Vue Apollo documentation](https://vue-apollo.netlify.com/guide/local-state.html#local-state).

### Testing

#### Mocking response as component data

With [Vue test utils][vue-test-utils] it is easy to quickly test components that
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
const mutate = jest.fn(() => Promise.resolve());
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

## Usage outside of Vue

It is also possible to use GraphQL outside of Vue by directly importing
and using the default client with queries.

```javascript
import defaultClient from '~/lib/graphql';
import query from './query.graphql';

defaultClient.query(query)
  .then(result => console.log(result));
```

Read more about the [Apollo] client in the [Apollo documentation](https://www.apollographql.com/docs/tutorial/client/).

[Apollo]: https://www.apollographql.com/
[vue-apollo]: https://github.com/Akryum/vue-apollo/
[feature-flags]: ../feature_flags.md
[default-client]: https://gitlab.com/gitlab-org/gitlab/blob/master/app/assets/javascripts/lib/graphql.js
[vue-test-utils]: https://vue-test-utils.vuejs.org/
[apollo-link-state]: https://www.apollographql.com/docs/link/links/state.html
