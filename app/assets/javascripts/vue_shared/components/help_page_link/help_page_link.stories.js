import HelpPageLink from './help_page_link.vue';

export default {
  component: HelpPageLink,
  title: 'vue_shared/help_page_link',
};

const Template = (args, { argTypes }) => ({
  components: { HelpPageLink },
  props: Object.keys(argTypes),
  template: '<help-page-link v-bind="$props">link</help-page-link>',
});

export const Default = Template.bind({});
Default.args = {
  href: 'user/storage_usage_quotas',
};

export const LinkWithAnAnchor = Template.bind({});
LinkWithAnAnchor.args = {
  ...Default.args,
  anchor: 'namespace-storage-limit',
};

export const LinkWithAnchorInPath = Template.bind({});
LinkWithAnchorInPath.args = {
  ...Default.args,
  href: 'user/storage_usage_quotas#namespace-storage-limit',
};

export const CustomAttributes = Template.bind({});
CustomAttributes.args = {
  ...Default.args,
  target: '_blank',
};
