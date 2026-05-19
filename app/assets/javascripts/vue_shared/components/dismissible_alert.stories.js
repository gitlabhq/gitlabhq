import DismissibleAlert from './dismissible_alert.vue';

export default {
  title: 'vue_shared/dismissible_alert',
  component: DismissibleAlert,
  argTypes: {
    // Define controls for the props and attributes
    variant: {
      control: { type: 'select' },
      options: ['info', 'warning', 'danger', 'success', 'tip'],
    },
    title: {
      control: 'text',
    },
    html: {
      control: 'text',
    },
    dismissible: {
      control: 'boolean',
    },
  },
};

const Template = (args, { argTypes }) => ({
  components: { DismissibleAlert },
  props: Object.keys(argTypes),
  template: `
    <dismissible-alert v-bind="$props">
      {{ $props.defaultSlot }}
    </dismissible-alert>
  `,
});

export const Default = Template.bind({});
Default.args = {
  title: 'Alert Title',
  html: 'This is an alert with <strong>HTML</strong> content.',
  variant: 'info',
  dismissible: true,
};

export const DangerVariant = Template.bind({});
DangerVariant.args = {
  title: 'Critical Issue',
  html: 'Something went wrong. <a href="#">Learn more</a>.',
  variant: 'danger',
};

export const WarningNoTitle = Template.bind({});
WarningNoTitle.args = {
  html: 'This is a warning alert without a specific title.',
  variant: 'warning',
};
