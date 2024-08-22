import PromoPageLink from './promo_page_link.vue';

export default {
  component: PromoPageLink,
  title: 'vue_shared/help_page_link',
};

const Template = (args, { argTypes }) => ({
  components: { PromoPageLink },
  props: Object.keys(argTypes),
  template: '<promo-page-link v-bind="$props">link</promo-page-link>',
});

export const Default = Template.bind({});
Default.args = {
  path: 'pricing',
};

export const LinkWithLeadingSlash = Template.bind({});
LinkWithLeadingSlash.args = {
  ...Default.args,
  path: '/sales',
};

export const CustomAttributes = Template.bind({});
CustomAttributes.args = {
  ...Default.args,
  target: '_blank',
};
