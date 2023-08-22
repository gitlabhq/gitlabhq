import { makeContainer } from 'storybook_addons/make_container';
import ListActions from './list_actions.vue';
import { ACTION_DELETE, ACTION_EDIT } from './constants';

export default {
  component: ListActions,
  title: 'vue_shared/list_actions',
  decorators: [makeContainer({ height: '115px' })],
  parameters: {
    docs: {
      description: {
        component: `
This component renders actions used by lists of resources such as groups and projects. 
Currently it is used by \`ProjectsListItem\`. There are base actions defined in \`~/vue_shared/components/list_actions\` 
that help reduce the amount of boilerplate needed for common actions such as edit and delete. This component accepts an 
\`actions\` prop that can extend the base actions and/or add custom actions. These actions should follow the format of 
a [disclosure dropdown item](https://gitlab-org.gitlab.io/gitlab-ui/?path=/docs/base-new-dropdowns-disclosure--docs#setting-disclosure-dropdown-items).
The \`availableActions\` prop defines what actions to render and in what order. This prop will generally be set by checking
permissions of the current user.
`,
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  components: { ListActions },
  props: Object.keys(argTypes),
  template: '<list-actions v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  actions: {
    [ACTION_EDIT]: {
      href: '/?path=/story/vue-shared-list-actions--default',
    },
    [ACTION_DELETE]: {
      // eslint-disable-next-line no-console
      action: () => console.log('Deleted'),
    },
  },
  availableActions: [ACTION_EDIT, ACTION_DELETE],
};
