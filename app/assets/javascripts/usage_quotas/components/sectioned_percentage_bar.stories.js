import SectionedPercentageBar from './sectioned_percentage_bar.vue';

export default {
  component: SectionedPercentageBar,
  title: 'usage_quotas/sectioned_percentage_bar',
};

const Template = (args, { argTypes }) => ({
  components: { SectionedPercentageBar },
  props: Object.keys(argTypes),
  template: '<sectioned-percentage-bar :sections="sections" />',
});

export const Default = Template.bind({});
Default.args = {
  sections: [
    {
      id: 'artifacts',
      label: 'Artifacts',
      value: 2000,
      formattedValue: '1.95 KiB',
      cssClasses: 'gl-bg-data-viz-blue-500',
    },
    {
      id: 'repository',
      label: 'Repository',
      value: 4000,
      formattedValue: '3.90 KiB',
      cssClasses: 'gl-bg-data-viz-orange-500',
    },
    {
      id: 'packages',
      label: 'Packages',
      value: 3000,
      formattedValue: '2.93 KiB',
      cssClasses: 'gl-bg-data-viz-aqua-500',
    },
    {
      id: 'registry',
      label: 'Registry',
      value: 5000,
      formattedValue: '4.88 KiB',
      cssClasses: 'gl-bg-data-viz-green-500',
    },
  ],
};
