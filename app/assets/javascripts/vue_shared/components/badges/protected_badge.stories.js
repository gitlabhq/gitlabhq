import ProtectedBadge from './protected_badge.vue';

export default {
  component: ProtectedBadge,
  title: 'vue_shared/badges/protected-badge',
};

const template = `
    <div style="height:600px;" class="gl-flex gl-justify-center gl-items-center">
      <protected-badge :tooltipText="tooltipText"/>
    </div>
  `;

const Template = (args, { argTypes }) => ({
  components: { ProtectedBadge },
  props: Object.keys(argTypes),
  template,
});

export const Default = Template.bind({});
Default.args = {};

export const WithTooltipText = Template.bind({});
WithTooltipText.args = { tooltipText: 'The resource is protected.' };
