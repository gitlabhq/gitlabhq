import DismissibleFeedbackAlert from './dismissible_feedback_alert.vue';

export default {
  title: 'vue_shared/dismissible_feedback_alert',
  component: DismissibleFeedbackAlert,
  argTypes: {
    // Controls for the component props
    featureName: {
      control: 'text',
      description: 'Used to generate the unique local storage key',
    },
    // GlAlert inherited attributes (via v-bind="$attrs")
    title: {
      control: 'text',
    },
    variant: {
      control: { type: 'select' },
      options: ['info', 'warning', 'danger', 'success', 'tip'],
    },
    // Logs the @dismiss event to the Storybook Actions panel
    dismiss: { action: 'dismissed' },
  },
};

const Template = (args, { argTypes }) => ({
  components: { DismissibleFeedbackAlert },
  props: Object.keys(argTypes),
  template: `
    <dismissible-feedback-alert v-bind="$props" @dismiss="dismiss">
      {{ $props.defaultSlot }}
    </dismissible-feedback-alert>
  `,
});

export const Default = Template.bind({});
Default.args = {
  featureName: 'user_feedback_survey',
  title: 'How are we doing?',
  variant: 'info',
  defaultSlot: 'Please take a moment to rate your experience with the new dashboard.',
};

export const CriticalNotice = Template.bind({});
CriticalNotice.args = {
  featureName: 'security_update_notice',
  title: 'Action Required',
  variant: 'danger',
  defaultSlot: 'Your attention is required for a security configuration update.',
};

export const PersistentWarning = Template.bind({});
PersistentWarning.args = {
  featureName: 'storage_limit_warning',
  title: 'Storage Capacity',
  variant: 'warning',
  defaultSlot: 'You are reaching 90% of your storage quota.',
};
