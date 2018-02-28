# Vue

For more complex frontend features, we recommend using Vue.js. It shares
some ideas with React.js as well as Angular.

To get started with Vue, read through [their documentation][vue-docs].

## When to use Vue.js

We recommend using Vue for more complex features. Here are some guidelines for when to use Vue.js:

- If you are starting a new feature or refactoring an old one that highly interacts with the DOM;
- For real time data updates;
- If you are creating a component that will be reused elsewhere;

## When not to use Vue.js

We don't want to refactor all GitLab frontend code into Vue.js, here are some guidelines for
when not to use Vue.js:

- Adding or changing static information;
- Features that highly depend on jQuery will be hard to work with Vue.js;
- Features without reactive data;

As always, the Frontend Architectural Experts are available to help with any Vue or JavaScript questions.

## Vue architecture

All new features built with Vue.js must follow a [Flux architecture][flux].
The main goal we are trying to achieve is to have only one data flow and only one data entry.
In order to achieve this goal, each Vue bundle needs a Store - where we keep all the data -,
a Service - that we use to communicate with the server - and a main Vue component.

Think of the Main Vue Component as the entry point of your application. This is the only smart
component that should exist in each Vue feature.
This component is responsible for:
1. Calling the Service to get data from the server
1. Calling the Store to store the data received
1. Mounting all the other components

  ![Vue Architecture](img/vue_arch.png)

You can also read about this architecture in vue docs about [state management][state-management]
and about [one way data flow][one-way-data-flow].

### Components, Stores and Services

In some features implemented with Vue.js, like the [issue board][issue-boards]
or [environments table][environments-table]
you can find a clear separation of concerns:

```
new_feature
├── components
│   └── component.js.es6
│   └── ...
├── store
│  └── new_feature_store.js.es6
├── service
│  └── new_feature_service.js.es6
├── new_feature_bundle.js.es6
```
_For consistency purposes, we recommend you to follow the same structure._

Let's look into each of them:

### A `*_bundle.js` file

This is the index file of your new feature. This is where the root Vue instance
of the new feature should be.

The Store and the Service should be imported and initialized in this file and
provided as a prop to the main component.

Don't forget to follow [these steps.][page_specific_javascript]

### A folder for Components

This folder holds all components that are specific of this new feature.
If you need to use or create a component that will probably be used somewhere
else, please refer to `vue_shared/components`.

A good thumb rule to know when you should create a component is to think if
it will be reusable elsewhere.

For example, tables are used in a quite amount of places across GitLab, a table
would be a good fit for a component. On the other hand, a table cell used only
in one table would not be a good use of this pattern.

You can read more about components in Vue.js site, [Component System][component-system]

### A folder for the Store

The Store is a class that allows us to manage the state in a single
source of truth. It is not aware of the service or the components.

The concept we are trying to follow is better explained by Vue documentation
itself, please read this guide: [State Management][state-management]

### A folder for the Service

The Service is a class used only to communicate with the server.
It does not store or manipulate any data. It is not aware of the store or the components.
We use [vue-resource][vue-resource-repo] to communicate with the server.

Vue Resource should only be imported in the service file.

  ```javascript
  import Vue from 'vue';
  import VueResource from 'vue-resource';

  Vue.use(VueResource);
  ```

#### Vue-resource gotchas
#### Headers
Headers are being parsed into a plain object in an interceptor.
In Vue-resource 1.x `headers` object was changed into an `Headers` object. In order to not change all old code, an interceptor was added.

If you need to write a unit test that takes the headers in consideration, you need to include an interceptor to parse the headers after your test interceptor.
You can see an example in `spec/javascripts/environments/environment_spec.js`:
  ```javascript
  import { headersInterceptor } from './helpers/vue_resource_helper';

  beforeEach(() => {
    Vue.http.interceptors.push(myInterceptor);
    Vue.http.interceptors.push(headersInterceptor);
  });

  afterEach(() => {
    Vue.http.interceptors = _.without(Vue.http.interceptors, myInterceptor);
    Vue.http.interceptors = _.without(Vue.http.interceptors, headersInterceptor);
  });
  ```

#### `.json()`
When making a request to the server, you will most likely need to access the body of the response.
Use `.json()` to convert. Because `.json()` returns a Promise the follwoing structure should be used:

  ```javascript
  service.get('url')
    .then(resp => resp.json())
    .then((data) => {
      this.store.storeData(data);
    })
    .catch(() => new Flash('Something went wrong'));
  ```

When using `Poll` (`app/assets/javascripts/lib/utils/poll.js`), the `successCallback` needs to handle `.json()` as a Promise:
  ```javascript
  successCallback: (response) => {
    return response.json().then((data) => {
      // handle the response
    });
  }
  ```

#### CSRF token
We use a Vue Resource interceptor to manage the CSRF token.
`app/assets/javascripts/vue_shared/vue_resource_interceptor.js` holds all our common interceptors.
Note: You don't need to load `app/assets/javascripts/vue_shared/vue_resource_interceptor.js`
since it's already being loaded by `common_vue.js`.

### End Result

The following example shows an  application:

```javascript
// store.js
export default class Store {

  /**
   * This is where we will iniatialize the state of our data.
   * Usually in a small SPA you don't need any options when starting the store. In the case you do
   * need guarantee it's an Object and it's documented.
   *
   * @param  {Object} options
   */
  constructor(options) {
    this.options = options;

    // Create a state object to handle all our data in the same place
    this.todos = []:
  }

  setTodos(todos = []) {
    this.todos = todos;
  }

  addTodo(todo) {
    this.todos.push(todo);
  }

  removeTodo(todoID) {
    const state = this.todos;

    const newState = state.filter((element) => {element.id !== todoID});

    this.todos = newState;
  }
}

// service.js
import Vue from 'vue';
import VueResource from 'vue-resource';
import 'vue_shared/vue_resource_interceptor';

Vue.use(VueResource);

export default class Service {
  constructor(options) {
    this.todos = Vue.resource(endpoint.todosEndpoint);
  }

  getTodos() {
    return this.todos.get();
  }

  addTodo(todo) {
    return this.todos.put(todo);
  }
}
// todo_component.vue
<script>
export default {
  props: {
    data: {
      type: Object,
      required: true,
    },
  }
}
</script>
<template>
  <div>
    <h1>
      Title: {{data.title}}
    </h1>
    <p>
      {{data.text}}
    </p>
  </div>
</template>

// todos_main_component.vue
<script>
import Store from 'store';
import Service from 'service';
import TodoComponent from 'todoComponent';
export default {
  /**
   * Although most data belongs in the store, each component it's own state.
   * We want to show a loading spinner while we are fetching the todos, this state belong
   * in the component.
   *
   * We need to access the store methods through all methods of our component.
   * We need to access the state of our store.
   */
  data() {
    const store = new Store();

    return {
      isLoading: false,
      store: store,
      todos: store.todos,
    };
  },

  components: {
    todo: TodoComponent,
  },

  created() {
    this.service = new Service('todos');

    this.getTodos();
  },

  methods: {
    getTodos() {
      this.isLoading = true;

      this.service.getTodos()
        .then(response => response.json())
        .then((response) => {
          this.store.setTodos(response);
          this.isLoading = false;
        })
        .catch(() => {
          this.isLoading = false;
          // Show an error
        });
    },

    addTodo(todo) {
      this.service.addTodo(todo)
      then(response => response.json())
      .then((response) => {
        this.store.addTodo(response);
      })
      .catch(() => {
        // Show an error
      });
    }
  }
}
</script>
<template>
  <div class="container">
    <div v-if="isLoading">
      <i
        class="fa fa-spin fa-spinner"
        aria-hidden="true" />
    </div>

    <div
      v-if="!isLoading"
      class="js-todo-list">
      <template v-for='todo in todos'>
        <todo :data="todo" />
      </template>

      <button
        @click="addTodo"
        class="js-add-todo">
        Add Todo
      </button>
    </div>
  <div>
</template>

// bundle.js
import todoComponent from 'todos_main_component.vue';

new Vue({
  el: '.js-todo-app',
  components: {
    todoComponent,
  },
  render: createElement => createElement('todo-component' {
    props: {
      someProp: [],
    }
  }),
});

```

The [issue boards service][issue-boards-service]
is a good example of this pattern.

## Style guide

Please refer to the Vue section of our [style guide](style_guide_js.md#vuejs)
for best practices while writing your Vue components and templates.

## Testing Vue Components

Each Vue component has a unique output. This output is always present in the render function.

Although we can test each method of a Vue component individually, our goal must be to test the output
of the render/template function, which represents the state at all times.

Make use of Vue Resource Interceptors to mock data returned by the service.

Here's how we would test the Todo App above:

```javascript
import component from 'todos_main_component';

describe('Todos App', () => {
  it('should render the loading state while the request is being made', () => {
    const Component = Vue.extend(component);

    const vm = new Component().$mount();

    expect(vm.$el.querySelector('i.fa-spin')).toBeDefined();
  });

  describe('with data', () => {
    // Mock the service to return data
    const interceptor = (request, next) => {
      next(request.respondWith(JSON.stringify([{
        title: 'This is a todo',
        body: 'This is the text'
      }]), {
        status: 200,
      }));
    };

    let vm;

    beforeEach(() => {
      Vue.http.interceptors.push(interceptor);

      const Component = Vue.extend(component);

      vm = new Component().$mount();
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
    });


    it('should render todos', (done) => {
      setTimeout(() => {
        expect(vm.$el.querySelectorAll('.js-todo-list div').length).toBe(1);
        done();
      }, 0);
    });
  });

  describe('add todo', () => {
    let vm;
    beforeEach(() => {
      const Component = Vue.extend(component);
      vm = new Component().$mount();
    });
    it('should add a todos', (done) => {
      setTimeout(() => {
        vm.$el.querySelector('.js-add-todo').click();

        // Add a new interceptor to mock the add Todo request
        Vue.nextTick(() => {
          expect(vm.$el.querySelectorAll('.js-todo-list div').length).toBe(2);
        });
      }, 0);
    });
  });
});
```
#### Test the component's output
The main return value of a Vue component is the rendered output. In order to test the component we
need to test the rendered output. [Vue][vue-test] guide's to unit test show us exactly that:


### Stubbing API responses
[Vue Resource Interceptors][vue-resource-interceptor] allow us to add a interceptor with
the response we need:

  ```javascript
    // Mock the service to return data
    const interceptor = (request, next) => {
      next(request.respondWith(JSON.stringify([{
        title: 'This is a todo',
        body: 'This is the text'
      }]), {
        status: 200,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(interceptor);
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
    });

    it('should do something', (done) => {
      setTimeout(() => {
        // Test received data
        done();
      }, 0);
    });
  ```

1. Headers interceptor
Refer to [this section](vue.md#headers)

1. Use `$.mount()` to mount the component

```javascript
// bad
new Component({
  el: document.createElement('div')
});

// good
new Component().$mount();
```

[vue-docs]: http://vuejs.org/guide/index.html
[issue-boards]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/app/assets/javascripts/boards
[environments-table]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/app/assets/javascripts/environments
[page_specific_javascript]: https://docs.gitlab.com/ce/development/frontend.html#page-specific-javascript
[component-system]: https://vuejs.org/v2/guide/#Composing-with-Components
[state-management]: https://vuejs.org/v2/guide/state-management.html#Simple-State-Management-from-Scratch
[one-way-data-flow]: https://vuejs.org/v2/guide/components.html#One-Way-Data-Flow
[vue-resource-repo]: https://github.com/pagekit/vue-resource
[vue-resource-interceptor]: https://github.com/pagekit/vue-resource/blob/develop/docs/http.md#interceptors
[vue-test]: https://vuejs.org/v2/guide/unit-testing.html
[issue-boards-service]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/app/assets/javascripts/boards/services/board_service.js.es6
[flux]: https://facebook.github.io/flux
