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
- Features that highly depend on jQuery will be hard to work with Vue.js

As always, the Frontend Architectural Experts are available to help with any Vue or JavaScript questions.

## How to build a new feature with Vue.js

**Components, Stores and Services**

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

**A `*_bundle.js` file**

This is the index file of your new feature. This is where the root Vue instance
of the new feature should be.

The Store and the Service should be imported and initialized in this file and provided as a prop to the main component.

Don't forget to follow [these steps.][page_specific_javascript]

**A folder for Components**

This folder holds all components that are specific of this new feature.
If you need to use or create a component that will probably be used somewhere
else, please refer to `vue_shared/components`.

A good thumb rule to know when you should create a component is to think if
it will be reusable elsewhere.

For example, tables are used in a quite amount of places across GitLab, a table
would be a good fit for a component. On the other hand, a table cell used only
in one table would not be a good use of this pattern.

You can read more about components in Vue.js site, [Component System][component-system]

**A folder for the Store**

The Store is a class that allows us to manage the state in a single
source of truth.

The concept we are trying to follow is better explained by Vue documentation
itself, please read this guide: [State Management][state-management]

**A folder for the Service**

The Service is used only to communicate with the server.
It does not store or manipulate any data.
We use [vue-resource][vue-resource-repo] to
communicate with the server.

The [issue boards service][issue-boards-service]
is a good example of this pattern.

## Style guide

Please refer to the Vue section of our [style guide](style_guide_js.md#vuejs)
for best practices while writing your Vue components and templates.


[vue-docs]: http://vuejs.org/guide/index.html
[issue-boards]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/app/assets/javascripts/boards
[environments-table]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/app/assets/javascripts/environments
[page_specific_javascript]: https://docs.gitlab.com/ce/development/frontend.html#page-specific-javascript
[component-system]: https://vuejs.org/v2/guide/#Composing-with-Components
[state-management]: https://vuejs.org/v2/guide/state-management.html#Simple-State-Management-from-Scratch
[vue-resource-repo]: https://github.com/pagekit/vue-resource
[issue-boards-service]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/app/assets/javascripts/boards/services/board_service.js.es6
