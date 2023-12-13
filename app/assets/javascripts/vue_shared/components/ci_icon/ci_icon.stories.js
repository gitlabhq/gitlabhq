import CiIcon from './ci_icon.vue';

export default {
  component: CiIcon,
  title: 'vue_shared/ci_icon',
};

const Template = (args, { argTypes }) => ({
  components: { CiIcon },
  props: Object.keys(argTypes),
  template: '<ci-icon v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  status: {
    icon: 'status_success',
    text: 'Success',
    detailsPath: 'https://gitab.com/',
  },
};

export const WithText = Template.bind({});
WithText.args = {
  status: {
    icon: 'status_success',
    text: 'Success',
    detailsPath: 'https://gitab.com/',
  },
  showStatusText: true,
};
