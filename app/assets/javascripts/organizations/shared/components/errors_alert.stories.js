import ErrorsAlert from './errors_alert.vue';

export default {
  component: ErrorsAlert,
  title: 'organizations/shared/components/errors_alert',
};

const defaultProps = {
  errors: ['Name must be at least 5 characters.', 'Name cannot contain special characters.'],
};

const Template = (args) => ({
  components: { ErrorsAlert },
  data() {
    return { errors: args.errors };
  },
  template: `<errors-alert v-model="errors" />`,
});

export const Default = Template.bind({});
Default.args = defaultProps;
