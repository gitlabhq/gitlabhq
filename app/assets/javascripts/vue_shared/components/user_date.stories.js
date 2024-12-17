import UserDate from './user_date.vue';

export default {
  component: UserDate,
  title: 'vue_shared/components/user_date',
};

const Template = (args, { argTypes }) => ({
  components: { UserDate },
  props: Object.keys(argTypes),
  template: '<UserDate v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  date: '2024-11-15T08:32:27.020Z',
  dateFormat: 'yyyy-mm-dd HH:MM:ss Z',
};
