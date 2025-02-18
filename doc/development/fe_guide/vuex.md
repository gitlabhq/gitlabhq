---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Vuex
---

## DEPRECATED

**[Vuex](https://vuex.vuejs.org) is deprecated at GitLab** and no new Vuex stores should be created.
You can still maintain existing Vuex stores but we strongly recommend [migrating away from Vuex entirely](migrating_from_vuex.md).

The rest of the information included on this page is explained in more detail in the
official [Vuex documentation](https://vuex.vuejs.org).

## Separation of concerns

Vuex is composed of State, Getters, Mutations, Actions, and Modules.

When a user selects an action, we need to `dispatch` it. This action `commits` a mutation that changes the state. The action itself does not update the state; only a mutation should update the state.

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

The following example shows an application that lists and adds users to the
state. (For a more complex example implementation, review the security
applications stored in this [repository](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/app/assets/javascripts/vue_shared/security_reports/store)).

### `index.js`

This is the entry point for our store. You can use the following as a guide:

```javascript
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

export const createStore = () =>
  new Vuex.Store({
    actions,
    getters,
    mutations,
    state,
  });
```

### `state.js`

The first thing you should do before writing any code is to design the state.

Often we need to provide data from HAML to our Vue application. Let's store it in the state for better access.

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

In this file, we write the actions that call mutations for handling a list of users:

```javascript
  import * as types from './mutation_types';
  import axios from '~/lib/utils/axios_utils';
  import { createAlert } from '~/alert';

  export const fetchUsers = ({ state, dispatch }) => {
    commit(types.REQUEST_USERS);

    axios.get(state.endpoint)
      .then(({ data }) => commit(types.RECEIVE_USERS_SUCCESS, data))
      .catch((error) => {
        commit(types.RECEIVE_USERS_ERROR, error)
        createAlert({ message: 'There was an error' })
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
The only way to change state in a Vuex store is by committing a mutation.

Most mutations are committed from an action using `commit`. If you don't have any
asynchronous operations, you can call mutations from a component using the `mapMutations` helper.

See the Vuex documentation for examples of [committing mutations from components](https://vuex.vuejs.org/guide/mutations.html#committing-mutations-in-components).

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

As a result, we can dispatch the `fetchNamespace` action from the component and it is responsible to commit `REQUEST_NAMESPACE`, `RECEIVE_NAMESPACE_SUCCESS` and `RECEIVE_NAMESPACE_ERROR` mutations.

> Previously, we were dispatching actions from the `fetchNamespace` action instead of committing mutation, so don't be confused if you find a different pattern in the older parts of the codebase. However, we encourage leveraging a new pattern whenever you write new Vuex stores.

By following this pattern we guarantee:

1. All applications follow the same pattern, making it easier for anyone to maintain the code.
1. All data in the application follows the same lifecycle pattern.
1. Unit tests are easier.

#### Updating complex state

Sometimes, especially when the state is complex, is really hard to traverse the state to precisely update what the mutation needs to update.
Ideally a `vuex` state should be as normalized/decoupled as possible but this is not always the case.

It's important to remember that the code is much easier to read and maintain when the `portion of the mutated state` is selected and mutated in the mutation itself.

Given this state:

```javascript
   export default () => ({
    items: [
      {
        id: 1,
        name: 'my_issue',
        closed: false,
      },
      {
        id: 2,
        name: 'another_issue',
        closed: false,
      }
    ]
});
```

It may be tempting to write a mutation like so:

```javascript
// Bad
export default {
  [types.MARK_AS_CLOSED](state, item) {
    Object.assign(item, {closed: true})
  }
}
```

While this approach works it has several dependencies:

- Correct selection of `item` in the component/action.
- The `item` property is already declared in the `closed` state.
  - A new `confidential` property would not be reactive.
- Noting that `item` is referenced by `items`.

A mutation written like this is harder to maintain and more error prone. We should rather write a mutation like this:

```javascript
// Good
export default {
  [types.MARK_AS_CLOSED](state, itemId) {
    const item = state.items.find(x => x.id === itemId);

    if (!item) {
      return;
    }

    Vue.set(item, 'closed', true);
  },
};
```

This approach is better because:

- It selects and updates the state in the mutation, which is more maintainable.
- It has no external dependencies, if the correct `itemId` is passed the state is correctly updated.
- It does not have reactivity caveats, as we generate a new `item` to avoid coupling to the initial state.

A mutation written like this is easier to maintain. In addition, we avoid errors due to the limitation of the reactivity system.

### `getters.js`

Sometimes we may need to get derived state based on store state, like filtering for a specific prop.
Using a getter also caches the result based on dependencies due to [how computed props work](https://v2.vuejs.org/v2/guide/computed.html#Computed-Caching-vs-Methods)
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

From [Vuex mutations documentation](https://vuex.vuejs.org/guide/mutations.html):
> It is a commonly seen pattern to use constants for mutation types in various Flux implementations.
> This allows the code to take advantage of tooling like linters, and putting all constants in a
> single file allows your collaborators to get an at-a-glance view of what mutations are possible
> in the entire application.

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
// in the Vue app's initialization script (for example, mount_show.js)

import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { createStore } from './stores';
import AwesomeVueApp from './components/awesome_vue_app.vue'

Vue.use(Vuex);

export default () => {
  const el = document.getElementById('js-awesome-vue-app');

  return new Vue({
    el,
    name: 'AwesomeVueRoot',
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

The astute reader sees an opportunity to cut out a few lines of code from
the example above:

```javascript
// Don't do this!

export default initialState => ({
  ...initialState,

  // other state properties here
});
```

We made the conscious decision to avoid this pattern to improve the ability to
discover and search our frontend codebase. The same applies
when [providing data to a Vue app](vue.md#providing-data-from-haml-to-javascript). The reasoning for this is described in
[this discussion](https://gitlab.com/gitlab-org/frontend/rfcs/-/issues/56#note_302514865):

> Consider a `someStateKey` is being used in the store state. You _may_ not be
> able to grep for it directly if it was provided only by `el.dataset`. Instead,
> you'd have to grep for `some_state_key`, because it could have come from a Rails
> template. The reverse is also true: if you're looking at a rails template, you
> might wonder what uses `some_state_key`, but you'd _have_ to grep for
> `someStateKey`.

### Communicating with the Store

```javascript
<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState, mapGetters } from 'vuex';

export default {
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

### Testing Vuex

#### Testing Vuex concerns

Refer to [Vuex documentation](https://vuex.vuejs.org/guide/testing.html) regarding testing Actions, Getters and Mutations.

#### Testing components that need a store

Smaller components might use `store` properties to access the data. To write unit tests for those
components, we need to include the store and provide the correct state:

```javascript
//component_spec.js
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { mount } from '@vue/test-utils';
import { createStore } from './store';
import Component from './component.vue'

Vue.use(Vuex);

describe('component', () => {
  let store;
  let wrapper;

  const createComponent = () => {
    store = createStore();

    wrapper = mount(Component, {
      store,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('should show a user', async () => {
    const user = {
      name: 'Foo',
      age: '30',
    };

    // populate the store
    await store.dispatch('addUser', user);

    expect(wrapper.text()).toContain(user.name);
  });
});
```

Some test files may still use the
[deprecated `createLocalVue` function](https://gitlab.com/gitlab-org/gitlab/-/issues/220482)
from `@vue/test-utils` and `localVue.use(Vuex)`. This is unnecessary, and should be
avoided or removed when possible.

### Two way data binding

When storing form data in Vuex, it is sometimes necessary to update the value stored. The store
should never be mutated directly, and an action should be used instead.
To use `v-model` in our code, we need to create computed properties in this form:

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

Adding a few of these properties becomes cumbersome, and makes the code more repetitive with more tests to write. To simplify this there is a helper in `~/vuex_shared/bindings.js`.

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
    updateBar() {...},
    updateAll() {...},
  },
  getters: {
    getFoo() {...},
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
     * @param {string|function} root - optional key of the state where to search for they keys described in list
     * @returns {Object} a dictionary with all the computed properties generated
    */
    ...mapComputed(
      [
        'baz',
        { key: 'bar', updateFn: 'updateBar' },
        { key: 'foo', getter: 'getFoo' },
      ],
      'updateAll',
    ),
  }
}
```

`mapComputed` then generates the appropriate computed properties that get the data from the store and dispatch the correct action when updated.

In the event that the `root` of the key is more than one-level deep you can use a function to retrieve the relevant state object.

For instance, with a store like:

```javascript
// this store is non-functional and only used to give context to the example
export default {
  state: {
    foo: {
      qux: {
        baz: '',
        bar: '',
        foo: '',
      },
    },
  },
  actions: {
    updateBar() {...},
    updateAll() {...},
  },
  getters: {
    getFoo() {...},
  }
}
```

The `root` could be:

```javascript
import { mapComputed } from '~/vuex_shared/bindings'
export default {
  computed: {
    ...mapComputed(
      [
        'baz',
        { key: 'bar', updateFn: 'updateBar' },
        { key: 'foo', getter: 'getFoo' },
      ],
      'updateAll',
      (state) => state.foo.qux,
    ),
  }
}
```
