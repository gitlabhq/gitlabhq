import ExperimentBadge from './experiment_badge.vue';

export default {
  component: ExperimentBadge,
  title: 'vue_shared/experiment-badge',
};

const template = `
    <div style="height:600px;" class="gl-flex gl-justify-center gl-items-center">
      <experiment-badge />
    </div>
  `;

const Template = (args, { argTypes }) => ({
  components: { ExperimentBadge },
  data() {
    return { value: args.value };
  },
  props: Object.keys(argTypes),
  template,
});

export const Default = Template.bind({});
Default.args = {};
