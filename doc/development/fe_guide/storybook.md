---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Storybook

The Storybook for the `gitlab-org/gitlab` project is available on our [GitLab Pages site](https://gitlab-org.gitlab.io/gitlab/storybook).

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
   The file name should have the same prefix as the Vue component.

    ```txt
    vue_shared/
    ├─ components/
    │  ├─ todo_button.vue
    │  ├─ todo_button.stories.js
    ```

1. Write the story as per the [official Storybook instructions](https://storybook.js.org/docs/vue/writing-stories/introduction)

   Notes:
   - Specify the `title` field of the story as the component's file path from the `javascripts/` directory,
     e.g. if the component is located at `app/assets/javascripts/vue_shared/components/todo_button.vue`, specify the `title` as
     `vue_shared/components/To-do Button`. This will ensure the Storybook navigation maps closely to our internal directory structure.
