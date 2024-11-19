import BetaBadge from './beta_badge.vue';

export default {
  component: BetaBadge,
  title: 'vue_shared/badges/beta-badge',
};

const template = `
    <div style="height:600px;" class="gl-flex gl-justify-center gl-items-center">
      <beta-badge />
    </div>
  `;

const Template = (args, { argTypes }) => ({
  components: { BetaBadge },
  data() {
    return { value: args.value };
  },
  props: Object.keys(argTypes),
  template,
});

export const Default = Template.bind({});
Default.args = {};
