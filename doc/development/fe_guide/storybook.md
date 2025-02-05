---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
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

   NOTE:
   Specify the `title` field of the story as the component's file path from the `javascripts/` directory, without the `/components` part.
   For example, if the component is located at `app/assets/javascripts/vue_shared/components/sidebar/todo_toggle/todo_button.vue`,
   specify the story `title` as `vue_shared/sidebar/todo_toggle/todo_button`.
   If the component is located in the `ee/` directory, make sure to prefix the story's title with `ee/` as well.
   This will ensure the Storybook navigation maps closely to our internal directory structure.

## Using GitLab REST and GraphQL APIs

You can write stories for components that use either the GitLab [REST](../../api/rest/_index.md) or
[GraphQL](../../api/graphql/_index.md) APIs.

### Set up API access token and GitLab instance URL

To add a story with API access:

1. Create a [personal access token](../../user/profile/personal_access_tokens.md) in your GitLab instance.

   NOTE:
   If you test against `gitlab.com`, make sure to use a token with `read_api` if possible and to make the token short-lived.

1. Create an `.env` file in the `storybook` directory. Use the `storybook/.env.template` file as
   a starting point.

1. Set the `API_ACCESS_TOKEN` variable to the access token that you created.

1. Set the `GITLAB_URL` variable to the GitLab instance's domain URL, for example: `http://gdk.test:3000`.

1. Start or restart your storybook.

You can also use the GitLab API Access panel in the Storybook UI to set the GitLab instance URL and access token.

### Set up API access in your stories

You should apply the `withGitLabAPIAccess` decorator to the stories that will consume GitLab APIs. This decorator
will display a badge indicating that the story won't work without providing the API access parameters:

```javascript
import { withGitLabAPIAccess } from 'storybook_addons/gitlab_api_access';
import Api from '~/api';
import { ContentEditor } from './index';

export default {
  component: ContentEditor,
  title: 'ce/content_editor/content_editor',
  decorators: [withGitLabAPIAccess],
};
```

#### Using REST API

The Storybook sets up `~/lib/utils/axios_utils` in `storybook/config/preview.js`. Components that use the REST API
should work out of the box as long as you provide a valid GitLab instance URL and access token.

#### Using GraphQL

To write a story for a component that uses the GraphQL API, use the `createVueApollo` method provided in
the Story context.

```javascript
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { withGitLabAPIAccess } from 'storybook_addons/gitlab_api_access';
import WorkspacesList from './list.vue';

Vue.use(VueApollo);

const Template = (_, { argTypes, createVueApollo }) => {
  return {
    components: { WorkspacesList },
    apolloProvider: createVueApollo(),
    provide: {
      emptyStateSvgPath: '',
    },
    props: Object.keys(argTypes),
    template: '<workspaces-list />',
  };
};

export default {
  component: WorkspacesList,
  title: 'ee/workspaces/workspaces_list',
  decorators: [withGitLabAPIAccess],
};

export const Default = Template.bind({});

Default.args = {};
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
