import BetaBadge from './beta_badge.vue';

export default {
  component: BetaBadge,
  title: 'vue_shared/beta-badge',
};

const template = `
    <div style="height:600px;" class="gl-display-flex gl-justify-content-center gl-align-items-center">
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
