import { makeContainer } from 'storybook_addons/make_container';
import { copyToClipboard } from '~/lib/utils/copy_to_clipboard';
import ListActions from './list_actions.vue';
import {
  ACTION_COPY_ID,
  ACTION_ARCHIVE,
  ACTION_DELETE,
  ACTION_DELETE_IMMEDIATELY,
  ACTION_EDIT,
  ACTION_LEAVE,
  ACTION_RESTORE,
  ACTION_UNARCHIVE,
  ACTION_REQUEST_ACCESS,
  ACTION_WITHDRAW_ACCESS_REQUEST,
} from './constants';

export default {
  component: ListActions,
  title: 'vue_shared/list_actions',
  decorators: [makeContainer({ height: '115px' })],
  parameters: {
    docs: {
      description: {
        component: `
This component renders actions used by lists of resources such as groups and projects. 
Supported actions are defined in \`~/vue_shared/components/list_actions/constants.js\`.
This component accepts an \`actions\` prop that can extend \`DEFAULT_ACTION_ITEM_DEFINITIONS\` in 
\`~/vue_shared/components/list_actions/constants.js\`.
The \`availableActions\` prop defines what actions to render. This prop will generally be set by checking
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
    [ACTION_COPY_ID]: {
      action: async () => {
        try {
          await copyToClipboard('1');
          // eslint-disable-next-line no-alert
          alert('ID copied to clipboard.');
        } catch (error) {
          // eslint-disable-next-line no-console
          console.log(error);
        }
      },
    },
    [ACTION_EDIT]: {
      href: '/?path=/story/vue-shared-list-actions--default',
    },
    [ACTION_ARCHIVE]: {
      // eslint-disable-next-line no-alert
      action: () => alert('Archived'),
    },
    [ACTION_UNARCHIVE]: {
      // eslint-disable-next-line no-alert
      action: () => alert('Unarchived'),
    },
    [ACTION_RESTORE]: {
      // eslint-disable-next-line no-alert
      action: () => alert('Restored'),
    },
    [ACTION_DELETE]: {
      // eslint-disable-next-line no-alert
      action: () => alert('Deleted'),
    },
    [ACTION_DELETE_IMMEDIATELY]: {
      // eslint-disable-next-line no-alert
      action: () => alert('Deleted immediately'),
    },
    [ACTION_LEAVE]: {
      text: 'Leave group',
      // eslint-disable-next-line no-alert
      action: () => alert('Group left'),
    },
    [ACTION_REQUEST_ACCESS]: {
      // eslint-disable-next-line no-alert
      action: () => alert('Access requested'),
    },
    [ACTION_WITHDRAW_ACCESS_REQUEST]: {
      // eslint-disable-next-line no-alert
      action: () => alert('Access request withdrawn'),
    },
  },
  availableActions: [
    ACTION_COPY_ID,
    ACTION_ARCHIVE,
    ACTION_DELETE,
    ACTION_DELETE_IMMEDIATELY,
    ACTION_EDIT,
    ACTION_LEAVE,
    ACTION_RESTORE,
    ACTION_UNARCHIVE,
    ACTION_REQUEST_ACCESS,
    ACTION_WITHDRAW_ACCESS_REQUEST,
  ],
};
