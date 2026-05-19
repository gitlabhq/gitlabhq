---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Storybook
---

The Storybook for the `gitlab-org/gitlab` project is available on our [GitLab Pages site](https://gitlab-org.gitlab.io/gitlab/storybook/).

## Storybook in local development

Storybook dependencies and configuration are located under the `storybook/` directory.

To build and launch Storybook locally, in the root directory of the `gitlab` project:

1. Install Storybook dependencies:

   ```shell
   yarn storybook:install
   ```

1. Build the Storybook site:

   ```shell
   yarn storybook:start
   ```

1. Test Storybook entries:

   ```shell
   yarn storybook:dev:test
   ```

Discover more details about automated accessibility tests with [Accessibility Storybook tests](accessibility/storybook_tests.md).

## Adding components to Storybook

Stories can be added for any Vue component in the `gitlab` repository.

To add a story:

1. Create a new `.stories.js` file in the same directory as the Vue component.
   The filename should have the same prefix as the Vue component.

   ```txt
   vue_shared/
   ├─ components/
   │  ├─ sidebar
   │  |  ├─ todo_toggle
   │  |  |  ├─ todo_button.vue
   │  │  |  ├─ todo_button.stories.js
   ```

1. Stories should demonstrate each significantly different UI state related to the component's exposed props and events.

For instructions on how to write stories, refer to the [official Storybook instructions](https://storybook.js.org/docs/writing-stories/)

> [!note]
> Specify the `title` field of the story as the component's file path from the `javascripts/` directory, without the `/components` part.
> For example, if the component is located at `app/assets/javascripts/vue_shared/components/sidebar/todo_toggle/todo_button.vue`,
> specify the story `title` as `vue_shared/sidebar/todo_toggle/todo_button`.
> If the component is located in the `ee/` directory, make sure to prefix the story's title with `ee/` as well.
> This will ensure the Storybook navigation maps closely to our internal directory structure.

## Mocking GraphQL queries and mutations

To write a story for a component that uses Apollo Client for GraphQL, use `createMockApollo` from `helpers/mock_apollo_helper`.
Pass it an array of `[query, handlerFn]` tuples — each handler receives the query variables and must return a `Promise` resolving to the expected response shape.

```javascript
import createMockApollo from 'helpers/mock_apollo_helper';
import myQuery from './graphql/my_query.query.graphql';
import MyComponent from './my_component.vue';

const MOCK_DATA = [{ id: '1', name: 'Example' }];

export default {
  component: MyComponent,
  title: 'path/to/my_component',
};

const Template = (args, { argTypes }) => ({
  components: { MyComponent },
  apolloProvider: createMockApollo([
    [
      myQuery,
      () =>
        Promise.resolve({
          data: {
            currentUser: {
              id: 'gid://gitlab/User/1',
              items: { nodes: MOCK_DATA },
            },
          },
        }),
    ],
  ]),
  props: Object.keys(argTypes),
  template: '<my-component v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {};
```

Each story variant can pass a different handler to simulate distinct states such as loading, empty, or error:

```javascript
export const Empty = (args, { argTypes }) => ({
  components: { MyComponent },
  apolloProvider: createMockApollo([
    [myQuery, () => Promise.resolve({ data: { currentUser: { id: '1', items: { nodes: [] } } } })],
  ]),
  props: Object.keys(argTypes),
  template: '<my-component v-bind="$props" />',
});

export const LoadingState = (args, { argTypes }) => ({
  components: { MyComponent },
  apolloProvider: createMockApollo([[myQuery, () => new Promise(() => {})]]),
  props: Object.keys(argTypes),
  template: '<my-component v-bind="$props" />',
});
```

## Using a Vuex store

To write a story for a component that requires access to a Vuex store, use the `createVuexStore` method provided in
the Story context.

```javascript
import { withVuexStore } from 'storybook_addons/vuex_store';
import DurationChart from './duration-chart.vue';

const Template = (_, { argTypes, createVuexStore }) => {
  return {
    components: { DurationChart },
    store: createVuexStore({
      state: {},
      getters: {},
      modules: {},
    }),
    props: Object.keys(argTypes),
    template: '<duration-chart />',
  };
};

export default {
  component: DurationChart,
  title: 'ee/analytics/cycle_analytics/components/duration_chart',
  decorators: [withVuexStore],
};

export const Default = Template.bind({});

Default.args = {};
```
