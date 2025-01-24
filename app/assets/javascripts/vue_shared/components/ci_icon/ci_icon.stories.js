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
    detailsPath: 'https://gitlab.com/',
  },
};

export const WithText = Template.bind({});
WithText.args = {
  status: {
    icon: 'status_success',
    text: 'Success',
    detailsPath: 'https://gitlab.com/',
  },
  showStatusText: true,
};

export const WithTooltip = Template.bind({});
WithTooltip.args = {
  status: {
    icon: 'status_success',
    text: 'Success',
    detailsPath: 'https://gitlab.com/',
  },
  showTooltip: true,
};

export const NoLink = Template.bind({});
NoLink.args = {
  status: {
    icon: 'status_success',
    text: 'Success',
    detailsPath: 'https://gitlab.com/',
  },
  useLink: false,
};

export const Variants = (args, { argTypes }) => ({
  components: { CiIcon },
  props: Object.keys(argTypes),
  template: `
    <div class="gl-flex gl-gap-2">
      <ci-icon
        v-for="status in variants"
        :status="status"
        v-bind="$props"
      />
    </div>
  `,
});
Variants.args = {
  variants: [
    {
      icon: 'status_success',
      text: 'Success',
      detailsPath: 'https://gitlab.com/',
    },
    {
      icon: 'status_warning',
      text: 'Warning',
      detailsPath: 'https://gitlab.com/',
    },
    {
      icon: 'status_pending',
      text: 'Pending',
      detailsPath: 'https://gitlab.com/',
    },
    {
      icon: 'status_failed',
      text: 'Failed',
      detailsPath: 'https://gitlab.com/',
    },
    {
      icon: 'status_running',
      text: 'Running',
      detailsPath: 'https://gitlab.com/',
    },
    {
      icon: 'status_created',
      text: 'Created',
      detailsPath: 'https://gitlab.com/',
    },
    {
      icon: 'status_canceled',
      text: 'Canceled',
      detailsPath: 'https://gitlab.com/',
    },
    {
      icon: 'status_skipped',
      text: 'Skipped',
      detailsPath: 'https://gitlab.com/',
    },
  ],
};
