import ErrorsAlert from './errors_alert.vue';

export default {
  component: ErrorsAlert,
  title: 'vue_shared/errors_alert',
};

const defaultArgs = {
  errors: ['The item could not be created.'],
};

const Template = (args, { argTypes }) => ({
  components: { ErrorsAlert },
  props: Object.keys(argTypes),
  template: `<errors-alert v-bind="$props" />`,
});

export const Default = Template.bind({});
Default.args = {
  ...defaultArgs,
};

export const ErrorsList = Template.bind({});
ErrorsList.args = {
  ...defaultArgs,
  errors: ['The item could not be created.', 'The item could not be updated.'],
};

export const WithTitle = Template.bind({});
WithTitle.args = {
  ...defaultArgs,
  title: 'Following errors occured:',
};
