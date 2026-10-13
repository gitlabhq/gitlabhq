import Footnote from './footnote.vue';

export default {
  component: Footnote,
  title: 'glql/components/common/footnote',
  argTypes: {},
};

const Template = () => ({
  components: { Footnote },
  template: '<footnote />',
});

export const Default = Template.bind({});
