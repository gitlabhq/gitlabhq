import PageHeading from './page_heading.vue';

export default {
  component: PageHeading,
  title: 'vue_shared/page_heading',
};

const Template = (args, { argTypes }) => ({
  components: { PageHeading },
  props: Object.keys(argTypes),
  template: `
    <page-heading v-bind="$props">
      <template #actions>
        Actions go here
      </template>
      <template #description>
        Description goes here
      </template>
    </page-heading>
  `,
});

export const Default = Template.bind({});
Default.args = {
  heading: 'Page heading',
};
