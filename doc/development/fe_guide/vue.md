# Vue

To get started with Vue, read through [their documentation][vue-docs].

## Examples

What is described in the following sections can be found in these examples:

- web ide: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/app/assets/javascripts/ide/stores
- security products: https://gitlab.com/gitlab-org/gitlab-ee/tree/master/ee/app/assets/javascripts/vue_shared/security_reports
- registry: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/app/assets/javascripts/registry/stores

## Vue architecture

All new features built with Vue.js must follow a [Flux architecture][flux].
The main goal we are trying to achieve is to have only one data flow and only one data entry.
In order to achieve this goal we use [vuex](#vuex).

You can also read about this architecture in vue docs about [state management][state-management]
and about [one way data flow][one-way-data-flow].

### Components and Store

In some features implemented with Vue.js, like the [issue board][issue-boards]
or [environments table][environments-table]
you can find a clear separation of concerns:

```
new_feature
├── components
│   └── component.vue
│   └── ...
├── store
│  └── new_feature_store.js
├── index.js
```
_For consistency purposes, we recommend you to follow the same structure._

Let's look into each of them:

### A `index.js` file

This is the index file of your new feature. This is where the root Vue instance
of the new feature should be.

The Store and the Service should be imported and initialized in this file and
provided as a prop to the main component.

Don't forget to follow [these steps][page_specific_javascript].

### Bootstrapping Gotchas
#### Providing data from HAML to JavaScript
While mounting a Vue application may be a need to provide data from Rails to JavaScript.
To do that, provide the data through `data` attributes in the HTML element and query them while mounting the application.

_Note:_ You should only do this while initializing the application, because the mounted element will be replaced with Vue-generated DOM.

The advantage of providing data from the DOM to the Vue instance through `props` in the `render` function
instead of querying the DOM inside the main vue component is that makes tests easier by avoiding the need to
create a fixture or an HTML element in the unit test. See the following example:

```javascript
// haml
.js-vue-app{ data: { endpoint: 'foo' }}

// index.js
document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '.js-vue-app',
  data() {
    const dataset = this.$options.el.dataset;
    return {
      endpoint: dataset.endpoint,
    };
  },
  render(createElement) {
    return createElement('my-component', {
      props: {
        endpoint: this.isLoading,
      },
    });
  },
}));
```

#### Accessing the `gl` object
When we need to query the `gl` object for data that won't change during the application's life cyle, we should do it in the same place where we query the DOM.
By following this practice, we can avoid the need to mock the `gl` object, which will make tests easier.
It should be done while initializing our Vue instance, and the data should be provided as `props` to the main component:

```javascript
document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '.js-vue-app',
  render(createElement) {
    return createElement('my-component', {
      props: {
        username: gon.current_username,
      },
    });
  },
}));
```

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

#### Vuex
Check this [page](vuex.md) for more details.

## Style guide

Please refer to the Vue section of our [style guide](style_guide_js.md#vue-js)
for best practices while writing your Vue components and templates.

## Testing Vue Components

Although we can test each method of a Vue component individually, our goal must be to test the rendered output.
What a component renders represents the state at all times, and we should be able to change method & computed prop internals without causing tests to fail.

For testing Vue components, we use [Vue Test Utils][vue-test-utils]. To mock network requests, use [axios mock adapter](axios.md#mock-axios-response-on-tests). For general Vue unit testing notes, see the [Vue Test Docs][vue-test].


### Mounting Components

Vue Test Utils provides the `mount` method, which returns a [Wrapper][vue-test-utils-wrapper].

For complex components, using `shallowMount` stubs child components. This means tests
can run faster, and we aren't testing with DOM structure of children.

Here's how we could test an example Todo App:

```javascript
import Vue from 'vue';
import { mount } from '@vue/test-utils';
import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';

describe('Todos App', () => {
  let wrapper;
  let mock;

  beforeEach(() => {
    // Create a mock adapter for stubbing axios API requests
    mock = new MockAdapter(axios);

    const Component = Vue.extend(component);

    // Mount the Component
    wrapper = mount(Component);
  });

  afterEach(() => {
    // Reset the mock adapter
    mock.restore();
  });

  it('should render the loading state while the request is being made', () => {
    expect(wrapper.find('i.fa-spin').exists()).toBe(true);
  });

  it('should render todos returned by the endpoint', done => {
    // Mock the get request on the API endpoint to return data
    mock.onGet('/todos').replyOnce(200, [
      {
        title: 'This is a todo',
        text: 'This is the text',
      },
    ]);

    Vue.nextTick(() => {
      const items = wrapper.findAll('.js-todo-list div')
      expect(items.length).toBe(1);
      expect(items[0].text()).toContain('This is the text');
      done();
    });
  });

  it('should add a todos on button click', (done) => {

    // Mock the put request and check that the sent data object is correct
    mock.onPut('/todos').replyOnce((req) => {
      expect(req.data).toContain('text');
      expect(req.data).toContain('title');

      return [201, {}];
    });

    wrapper.find('.js-add-todo').trigger('click');

    // Add a new interceptor to mock the add Todo request
    Vue.nextTick(() => {
      expect(wrapper.findAll('.js-todo-list div').length).toBe(2);
      done();
    });
  });
});
```

[vue-docs]: http://vuejs.org/guide/index.html
[vue-test-utils]: https://vue-test-utils.vuejs.org/
[vue-test-utils-wrapper]: https://vue-test-utils.vuejs.org/api/wrapper
[issue-boards]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/app/assets/javascripts/boards
[environments-table]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/app/assets/javascripts/environments
[page_specific_javascript]: https://docs.gitlab.com/ce/development/frontend.html#page-specific-javascript
[component-system]: https://vuejs.org/v2/guide/#Composing-with-Components
[state-management]: https://vuejs.org/v2/guide/state-management.html#Simple-State-Management-from-Scratch
[one-way-data-flow]: https://vuejs.org/v2/guide/components.html#One-Way-Data-Flow
[vue-test]: https://vuejs.org/v2/guide/unit-testing.html
[flux]: https://facebook.github.io/flux
[axios]: https://github.com/axios/axios
