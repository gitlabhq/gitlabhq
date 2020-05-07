# Vuex

When there's a clear benefit to separating state management from components (e.g. due to state complexity) we recommend using [Vuex](https://vuex.vuejs.org) over any other Flux pattern. Otherwise, feel free to manage state within the components.

Vuex should be strongly considered when:

- You expect multiple parts of the application to react to state changes
- There's a need to share data between multiple components
- There are complex interactions with Backend, e.g. multiple API calls
- The app involves interacting with backend via both traditional REST API and GraphQL (especially when moving the REST API over to GraphQL is a pending backend task)

_Note:_ All of the below is explained in more detail in the official [Vuex documentation](https://vuex.vuejs.org).

## Separation of concerns

Vuex is composed of State, Getters, Mutations, Actions, and Modules.

When a user clicks on an action, we need to `dispatch` it. This action will `commit` a mutation that will change the state.
_Note:_ The action itself will not update the state, only a mutation should update the state.

## File structure

When using Vuex at GitLab, separate these concerns into different files to improve readability:

```plaintext
└── store
  ├── index.js          # where we assemble modules and export the store
  ├── actions.js        # actions
  ├── mutations.js      # mutations
  ├── getters.js        # getters
  ├── state.js          # state
  └── mutation_types.js # mutation types
```

The following example shows an application that lists and adds users to the state.
(For a more complex example implementation take a look at the security applications store in [here](https://gitlab.com/gitlab-org/gitlab/tree/master/ee/app/assets/javascripts/vue_shared/security_reports/store))

### `index.js`

This is the entry point for our store. You can use the following as a guide:

```javascript
import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

Vue.use(Vuex);

export const createStore = () => new Vuex.Store({
  actions,
  getters,
  mutations,
  state,
});
export default createStore();
```

### `state.js`

The first thing you should do before writing any code is to design the state.

Often we need to provide data from haml to our Vue application. Let's store it in the state for better access.

```javascript
  export default () => ({
    endpoint: null,

    isLoading: false,
    error: null,

    isAddingUser: false,
    errorAddingUser: false,

    users: [],
  });
```

#### Access `state` properties

You can use `mapState` to access state properties in the components.

### `actions.js`

An action is a payload of information to send data from our application to our store.

An action is usually composed by a `type` and a `payload` and they describe what happened. Unlike [mutations](#mutationsjs), actions can contain asynchronous operations - that's why we always need to handle asynchronous logic in actions.

In this file, we will write the actions that will call mutations for handling a list of users:

```javascript
  import * as types from './mutation_types';
  import axios from '~/lib/utils/axios_utils';
  import createFlash from '~/flash';

  export const fetchUsers = ({ state, dispatch }) => {
    commit(types.REQUEST_USERS);

    axios.get(state.endpoint)
      .then(({ data }) => commit(types.RECEIVE_USERS_SUCCESS, data))
      .catch((error) => {
        commit(types.RECEIVE_USERS_ERROR, error)
        createFlash('There was an error')
      });
  }

  export const addUser = ({ state, dispatch }, user) => {
    commit(types.REQUEST_ADD_USER);

    axios.post(state.endpoint, user)
      .then(({ data }) => commit(types.RECEIVE_ADD_USER_SUCCESS, data))
      .catch((error) => commit(types.REQUEST_ADD_USER_ERROR, error));
  }
```

#### Dispatching actions

To dispatch an action from a component, use the `mapActions` helper:

```javascript
import { mapActions } from 'vuex';

{
  methods: {
    ...mapActions([
      'addUser',
    ]),
    onClickUser(user) {
      this.addUser(user);
    },
  },
};
```

### `mutations.js`

The mutations specify how the application state changes in response to actions sent to the store.
The only way to change state in a Vuex store should be by committing a mutation.

**It's a good idea to think of the state before writing any code.**

Remember that actions only describe that something happened, they don't describe how the application state changes.

**Never commit a mutation directly from a component**

Instead, you should create an action that will commit a mutation.

```javascript
  import * as types from './mutation_types';

  export default {
    [types.REQUEST_USERS](state) {
      state.isLoading = true;
    },
    [types.RECEIVE_USERS_SUCCESS](state, data) {
      // Do any needed data transformation to the received payload here
      state.users = data;
      state.isLoading = false;
    },
    [types.RECEIVE_USERS_ERROR](state, error) {
      state.isLoading = false;
    },
    [types.REQUEST_ADD_USER](state, user) {
      state.isAddingUser = true;
    },
    [types.RECEIVE_ADD_USER_SUCCESS](state, user) {
      state.isAddingUser = false;
      state.users.push(user);
    },
    [types.REQUEST_ADD_USER_ERROR](state, error) {
      state.isAddingUser = false;
      state.errorAddingUser = error;
    },
  };
```

#### Naming Pattern: `REQUEST` and `RECEIVE` namespaces

When a request is made we often want to show a loading state to the user.

Instead of creating an mutation to toggle the loading state, we should:

1. A mutation with type `REQUEST_SOMETHING`, to toggle the loading state
1. A mutation with type `RECEIVE_SOMETHING_SUCCESS`, to handle the success callback
1. A mutation with type `RECEIVE_SOMETHING_ERROR`, to handle the error callback
1. An action `fetchSomething` to make the request and commit mutations on mentioned cases
    1. In case your application does more than a `GET` request you can use these as examples:
        - `POST`: `createSomething`
        - `PUT`: `updateSomething`
        - `DELETE`: `deleteSomething`

As a result, we can dispatch the `fetchNamespace` action from the component and it will be responsible to commit  `REQUEST_NAMESPACE`, `RECEIVE_NAMESPACE_SUCCESS` and `RECEIVE_NAMESPACE_ERROR` mutations.

> Previously, we were dispatching actions from the `fetchNamespace` action instead of committing mutation, so please don't be confused if you find a different pattern in the older parts of the codebase. However, we encourage leveraging a new pattern whenever you write new Vuex stores

By following this pattern we guarantee:

1. All applications follow the same pattern, making it easier for anyone to maintain the code
1. All data in the application follows the same lifecycle pattern
1. Unit tests are easier

### `getters.js`

Sometimes we may need to get derived state based on store state, like filtering for a specific prop.
Using a getter will also cache the result based on dependencies due to [how computed props work](https://vuejs.org/v2/guide/computed.html#Computed-Caching-vs-Methods)
This can be done through the `getters`:

```javascript
// get all the users with pets
export const getUsersWithPets = (state, getters) => {
  return state.users.filter(user => user.pet !== undefined);
};
```

To access a getter from a component, use the `mapGetters` helper:

```javascript
import { mapGetters } from 'vuex';

{
  computed: {
    ...mapGetters([
      'getUsersWithPets',
    ]),
  },
};
```

### `mutation_types.js`

From [vuex mutations docs](https://vuex.vuejs.org/guide/mutations.html):
> It is a commonly seen pattern to use constants for mutation types in various Flux implementations. This allows the code to take advantage of tooling like linters, and putting all constants in a single file allows your collaborators to get an at-a-glance view of what mutations are possible in the entire application.

```javascript
export const ADD_USER = 'ADD_USER';
```

### Initializing a store's state

It's common for a Vuex store to need some initial state before its `action`s can
be used. Often this includes data like API endpoints, documentation URLs, or
IDs.

To set this initial state, pass it as a parameter to your store's creation
function when mounting your Vue component:

```javascript
// in the Vue app's initialization script (e.g. mount_show.js)

import Vue from 'vue';
import createStore from './stores';
import AwesomeVueApp from './components/awesome_vue_app.vue'

export default () => {
  const el = document.getElementById('js-awesome-vue-app');

  return new Vue({
    el,
    store: createStore(el.dataset),
    render: h => h(AwesomeVueApp)
  });
};
```

The store function, in turn, can pass this data along to the state's creation
function:

```javascript
// in store/index.js

import * as actions from './actions';
import mutations from './mutations';
import createState from './state';

export default initialState => ({
  actions,
  mutations,
  state: createState(initialState),
});
```

And the state function can accept this initial data as a parameter and bake it
into the `state` object it returns:

```javascript
// in store/state.js

export default ({
  projectId,
  documentationPath,
  anOptionalProperty = true
}) => ({
  projectId,
  documentationPath,
  anOptionalProperty,

  // other state properties here
});
```

#### Why not just ...spread the initial state?

The astute reader will see an opportunity to cut out a few lines of code from
the example above:

```javascript
// Don't do this!

export default initialState => ({
  ...initialState,

  // other state properties here
});
```

We've made the conscious decision to avoid this pattern to aid in the
discoverability and searchability of our frontend codebase. The reasoning for
this is described in [this
discussion](https://gitlab.com/gitlab-org/frontend/rfcs/-/issues/56#note_302514865):

> Consider a `someStateKey` is being used in the store state. You _may_ not be
> able to grep for it directly if it was provided only by `el.dataset`. Instead,
> you'd have to grep for `some_state_key`, since it could have come from a rails
> template. The reverse is also true: if you're looking at a rails template, you
> might wonder what uses `some_state_key`, but you'd _have_ to grep for
> `someStateKey`

### Communicating with the Store

```javascript
<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import store from './store';

export default {
  store,
  computed: {
    ...mapGetters([
      'getUsersWithPets'
    ]),
    ...mapState([
      'isLoading',
      'users',
      'error',
    ]),
  },
  methods: {
    ...mapActions([
      'fetchUsers',
      'addUser',
    ]),

    onClickAddUser(data) {
      this.addUser(data);
    }
  },

  created() {
    this.fetchUsers()
  }
}
</script>
<template>
  <ul>
    <li v-if="isLoading">
      Loading...
    </li>
    <li v-else-if="error">
      {{ error }}
    </li>
    <template v-else>
      <li
        v-for="user in users"
        :key="user.id"
      >
        {{ user }}
      </li>
    </template>
  </ul>
</template>
```

### Vuex Gotchas

1. Do not call a mutation directly. Always use an action to commit a mutation. Doing so will keep consistency throughout the application. From Vuex docs:

   > Why don't we just call store.commit('action') directly? Well, remember that mutations must be synchronous? Actions aren't. We can perform asynchronous operations inside an action.

   ```javascript
     // component.vue

     // bad
     created() {
       this.$store.commit('mutation');
     }

     // good
     created() {
       this.$store.dispatch('action');
     }
   ```

1. Use mutation types instead of hardcoding strings. It will be less error prone.
1. The State will be accessible in all components descending from the use where the store is instantiated.

### Testing Vuex

#### Testing Vuex concerns

Refer to [vuex docs](https://vuex.vuejs.org/guide/testing.html) regarding testing Actions, Getters and Mutations.

#### Testing components that need a store

Smaller components might use `store` properties to access the data.
In order to write unit tests for those components, we need to include the store and provide the correct state:

```javascript
//component_spec.js
import Vue from 'vue';
import { createStore } from './store';
import component from './component.vue'

describe('component', () => {
  let store;
  let vm;
  let Component;

  beforeEach(() => {
    Component = Vue.extend(issueActions);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should show a user', () => {
    const user = {
      name: 'Foo',
      age: '30',
    };

    store = createStore();

    // populate the store
    store.dispatch('addUser', user);

    vm = new Component({
      store,
      propsData: props,
    }).$mount();
  });
});
```

#### Testing Vuex actions and getters

Because we're currently using [`babel-plugin-rewire`](https://github.com/speedskater/babel-plugin-rewire), you may encounter the following error when testing your Vuex actions and getters:
`[vuex] actions should be function or object with "handler" function`

To prevent this error from happening, you need to export an empty function as `default`:

```javascript
// getters.js or actions.js

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
```

### Two way data binding

When storing form data in Vuex, it is sometimes necessary to update the value stored. The store should never be mutated directly, and an action should be used instead.
In order to still use `v-model` in our code, we need to create computed properties in this form:

```javascript
export default {
  computed: {
    someValue: {
      get() {
        return this.$store.state.someValue;
      },
      set(value) {
        this.$store.dispatch("setSomeValue", value);
      }
    }
  }
};
```

An alternative is to use `mapState` and `mapActions`:

```javascript
export default {
  computed: {
    ...mapState(['someValue']),
    localSomeValue: {
      get() {
        return this.someValue;
      },
      set(value) {
        this.setSomeValue(value)
      }
    }
  },
  methods: {
    ...mapActions(['setSomeValue'])
  }
};
```

Adding a few of these properties becomes cumbersome, and makes the code more repetitive with more tests to write. To simplify this there is a helper in `~/vuex_shared/bindings.js`

The helper can be used like so:

```javascript
// this store is non-functional and only used to give context to the example
export default {
  state: {
    baz: '',
    bar: '',
    foo: ''
  },
  actions: {
    updateBar() {...}
    updateAll() {...}
  },
  getters: {
    getFoo() {...}
  }
}
```

```javascript
import { mapComputed } from '~/vuex_shared/bindings'
export default {
  computed: {
    /**
     * @param {(string[]|Object[])} list - list of string matching state keys or list objects
     * @param {string} list[].key - the key matching the key present in the vuex state
     * @param {string} list[].getter - the name of the getter, leave it empty to not use a getter
     * @param {string} list[].updateFn - the name of the action, leave it empty to use the default action
     * @param {string} defaultUpdateFn - the default function to dispatch
     * @param {string} root - optional key of the state where to search fo they keys described in list
     * @returns {Object} a dictionary with all the computed properties generated
    */
    ...mapComputed(
      [
        'baz',
        { key: 'bar', updateFn: 'updateBar' }
        { key: 'foo', getter: 'getFoo' },
      ],
      'updateAll',
    ),
  }
}
```

`mapComputed` will then generate the appropriate computed properties that get the data from the store and dispatch the correct action when updated.
