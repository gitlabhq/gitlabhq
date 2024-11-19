import HoverBadge from './hover_badge.vue';

export default {
  component: HoverBadge,
  title: 'vue_shared/badges/hover-badge',
};

const template = `
    <div style="height:600px;" class="gl-flex gl-justify-center gl-items-center">
      <hover-badge v-bind="$props" />
    </div>
  `;

const Template = (args, { argTypes }) => ({
  components: { HoverBadge },
  data() {
    return { value: args.value };
  },
  props: Object.keys(argTypes),
  template,
});

const defaultProps = {
  title: 'Badge title',
  label: 'A label',
};

export const Default = Template.bind({});
Default.args = defaultProps;
