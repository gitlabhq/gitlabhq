import { GlButton } from '@gitlab/ui';
import DynamicPanel from './dynamic_panel.vue';

const withPanelContainer = () => ({
  template: `
    <div
      class="page-with-panels contextual-panel paneled-view gl-border gl-min-h-20">
      <story />
    </div>
  `,
});

export default {
  component: DynamicPanel,
  title: 'vue_shared/dynamic_panel',
  decorators: [withPanelContainer],
  parameters: {
    docs: {
      description: {
        component: `
The Dynamic panel component is a panel layout for showing contextual, detailed content
alongside a page's main content. In the app, mount it into the contextual panel region as the direct child of a
\`MountingPortal\` with the \`mount-to="#contextual-panel-portal"\` and \`append\` props.

See [Page layouts](https://docs.gitlab.com/development/fe_guide/page_layouts/) for full guidance.
        `,
      },
    },
  },
  argTypes: {
    header: {
      control: 'text',
      description: 'Text to display in the panel header. The `header` slot takes precedence.',
      table: { category: 'props', type: { summary: 'string' }, defaultValue: { summary: 'null' } },
    },
    default: {
      control: false,
      description: 'Main panel body content.',
      table: { category: 'slots', type: { summary: 'slot' } },
    },
    headerSlot: {
      name: 'header',
      control: false,
      description: 'Custom header markup. Takes precedence over the `header` prop.',
      table: { category: 'slots', type: { summary: 'slot' } },
    },
    actions: {
      control: false,
      description:
        'Panel header actions, rendered next to the built-in close and maximize buttons.',
      table: { category: 'slots', type: { summary: 'slot' } },
    },
    footer: {
      control: false,
      description: 'Panel footer content. The footer renders only when this slot has content.',
      table: { category: 'slots', type: { summary: 'slot' } },
    },
    close: {
      action: 'close',
      control: false,
      description: 'Emitted when the close button is clicked.',
      table: { category: 'events', type: { summary: 'void' } },
    },
    maximize: {
      action: 'maximize',
      control: false,
      description: 'Emitted with the click `MouseEvent` when the maximize button is clicked.',
      table: { category: 'events', type: { summary: 'MouseEvent' } },
    },
  },
};

const Template = (args, { argTypes }) => ({
  components: { DynamicPanel },
  props: Object.keys(argTypes),
  template: `
    <dynamic-panel v-bind="$props" @close="close" @maximize="maximize">
      Panel content goes here.
    </dynamic-panel>
  `,
});

export const Default = Template.bind({});
Default.args = {
  header: 'Dynamic panel',
};

export const WithHeaderSlot = (args, { argTypes }) => ({
  components: { DynamicPanel },
  props: Object.keys(argTypes),
  template: `
    <dynamic-panel v-bind="$props" @close="close" @maximize="maximize">
      <template #header>
        Header with <i>custom items</i>
      </template>
      Panel content goes here.
    </dynamic-panel>
  `,
});
WithHeaderSlot.args = {};

export const WithActionsSlot = (args, { argTypes }) => ({
  components: { DynamicPanel, GlButton },
  props: Object.keys(argTypes),
  template: `
    <dynamic-panel v-bind="$props" @close="close" @maximize="maximize">
      <template #actions>
        <gl-button icon="pencil" category="tertiary" aria-label="Edit" />
      </template>
      Panel content goes here.
    </dynamic-panel>
  `,
});
WithActionsSlot.args = {
  header: 'Dynamic panel',
};

export const WithFooterSlot = (args, { argTypes }) => ({
  components: { DynamicPanel, GlButton },
  props: Object.keys(argTypes),
  template: `
    <dynamic-panel v-bind="$props" @close="close" @maximize="maximize">
      Panel content goes here.
      <template #footer>
        <div class="gl-flex gl-gap-3 gl-justify-end">
          <gl-button>Cancel</gl-button>
          <gl-button variant="confirm">Save</gl-button>
        </div>
      </template>
    </dynamic-panel>
  `,
});
WithFooterSlot.args = {
  header: 'Dynamic panel',
};
