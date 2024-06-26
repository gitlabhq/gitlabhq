import ExperimentBadge from './experiment_badge.vue';

export default {
  component: ExperimentBadge,
  title: 'vue_shared/experiment-badge',
};

const template = `
    <div style="height:600px;" class="gl-display-flex gl-justify-content-center gl-align-items-center">
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
