
## Vuex
To manage the state of an application you may use [Vuex][vuex-docs].

_Note:_ All of the below is explained in more detail in the official [Vuex documentation][vuex-docs].

### Separation of concerns
Vuex is composed of State, Getters, Mutations, Actions and Modules.

When a user clicks on an action, we need to `dispatch` it. This action will `commit` a mutation that will change the state.
_Note:_ The action itself will not update the state, only a mutation should update the state.

#### File structure
When using Vuex at GitLab, separate this concerns into different files to improve readability. If you can, separate the Mutation Types as well:

```
└── store
  ├── index.js          # where we assemble modules and export the store
  ├── actions.js        # actions
  ├── mutations.js      # mutations
  ├── getters.js        # getters
  └── mutation_types.js # mutation types
```
The following examples show an application that lists and adds users to the state.

##### `index.js`
This is the entry point for our store. You can use the following as a guide:

```javascript
import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';

Vue.use(Vuex);

export default new Vuex.Store({
  actions,
  getters,
  mutations,
  state: {
    users: [],
  },
});
```
_Note:_ If the state of the application is too complex, an individual file for the state may be better.

#### `actions.js`
An action is a playload of information to send data from our application to our store.
They are the only source of information for the store.

An action is usually composed by a `type` and a `payload` and they describe what happened.
By enforcing that every change is described as an action lets us have a clear understantid of what is going on in the app.

An action represents something that will trigger a state change, for example, when the user enters the page we need to load resources.

In this file, we will write the actions (both sync and async) that will call the respective mutations:

```javascript
  import * as types from './mutation_types';
  import axios from '~/lib/utils/axios-utils';

  export const requestUsers = ({ commit }) => commit(types.REQUEST_USERS);
  export const receiveUsersSuccess = ({ commit }, data) => commit(types.RECEIVE_USERS_SUCCESS, data);
  export const receiveUsersError = ({ commit }, error) => commit(types.REQUEST_USERS_ERROR, error);

  export const fetchUsers = ({ state, dispatch }) => {
    dispatch('requestUsers');

    axios.get(state.endoint)
      .then(({ data }) => dispatch('receiveUsersSuccess', data))
      .catch((error) => dispatch('receiveUsersError', error));
  }

  export const requestAddUser = ({ commit }) => commit(types.REQUEST_ADD_USER);
  export const receiveAddUserSuccess = ({ commit }, data) => commit(types.RECEIVE_ADD_USER_SUCCESS, data);
  export const receiveAddUserError = ({ commit }, error) => commit(types.REQUEST_ADD_USER_ERROR, error);

  export const addUser = ({ state, dispatch }, user) => {
    dispatch('requestAddUser');

    axios.post(state.endoint, user)
      .then(({ data }) => dispatch('receiveAddUserSuccess', data))
      .catch((error) => dispatch('receiveAddUserError', error));
  }

```

##### Actions Pattern: `request` and `receive` namespaces
When a request is made we often want to show a loading state to the user.

Instead of creating an action to toggle the loading state and dispatch it in the component,
create:
1. A sync action `requestSomething`, to toggle the loading state
1. A sync action `receiveSomethingSuccess`, to handle the success callback
1. A sync action `receiveSomethingError`, to handle the error callback
1. An async action `fetchSomething` to make the request.

The component MUST only dispatch the `fetchNamespace` action.
The `fetch` action will be responsible to dispatch `requestNamespace`, `receiveNamespaceSuccess` and `receiveNamespaceError`

By following this patter we guarantee:
1. All aplications follow the same pattern, making it easier for anyone to maintain the code
1. All data in the application follows the same lifecycle pattern
1. Actions are contained and human friendly
1. Unit tests are easier
1. Actions are simple and straightforward

##### Dispatching actions
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

#### `mutations.js`
The mutations specify how the application state changes in response to actions sent to the store.
The only way to actually change state in a Vuex store is by committing a mutation.

**It's a good idea to think of the state shape before writing any code.**

Remember that actions only describe the fact that something happened, they don't describe how the application state changes.

**Never commit a mutation directly from a component**

```javascript
  import * as types from './mutation_types';

  export default {
    [types.ADD_USER](state, user) {
      state.users.push(user);
    },
  };
```



#### `getters.js`
Sometimes we may need to get derived state based on store state, like filtering for a specific prop.
This can be done through the `getters`:

```javascript
// get all the users with pets
export getUsersWithPets = (state, getters) => {
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

#### `mutations_types.js`
From [vuex mutations docs][vuex-mutations]:
> It is a commonly seen pattern to use constants for mutation types in various Flux implementations. This allows the code to take advantage of tooling like linters, and putting all constants in a single file allows your collaborators to get an at-a-glance view of what mutations are possible in the entire application.

```javascript
export const ADD_USER = 'ADD_USER';
```

### How to include the store in your application
The store should be included in the main component of your application:
```javascript
  // app.vue
  import store from 'store'; // it will include the index.js file

  export default {
    name: 'application',
    store,
    ...
  };
```

### Vuex Gotchas
1. Do not call a mutation directly. Always use an action to commit a mutation. Doing so will keep consistency through out the application. From Vuex docs:

  >  why don't we just call store.commit('action') directly? Well, remember that mutations must be synchronous? Actions aren't. We can perform asynchronous operations inside an action.

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
Refer to [vuex docs][vuex-testing] regarding testing Actions, Getters and Mutations.

#### Testing components that need a store
Smaller components might use `store` properties to access the data.
In order to write unit tests for those components, we need to include the store and provide the correct state:

```javascript
//component_spec.js
import Vue from 'vue';
import store from './store';
import component from './component.vue'

describe('component', () => {
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

    // populate the store
    store.dipatch('addUser', user);

    vm = new Component({
      store,
      propsData: props,
    }).$mount();
  });
});
```

[vuex-docs]: https://vuex.vuejs.org
[vuex-structure]: https://vuex.vuejs.org/en/structure.html
[vuex-mutations]: https://vuex.vuejs.org/en/mutations.html
[vuex-testing]: https://vuex.vuejs.org/en/testing.html