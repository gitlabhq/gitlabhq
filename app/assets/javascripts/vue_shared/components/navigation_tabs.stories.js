import NavigationTabs from './navigation_tabs.vue';

export default {
  component: NavigationTabs,
  title: 'vue_shared/components/navigation_tabs',
};

const Template = (args, { argTypes }) => ({
  components: { NavigationTabs },
  props: Object.keys(argTypes),
  template: '<NavigationTabs v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  tabs: [
    {
      name: 'Enabled deploy keys',
      scope: 'enabledKeys',
      isActive: true,
    },
    {
      name: 'Privately accessible deploy keys',
      scope: 'availableProjectKeys',
      isActive: false,
    },
  ],
  scope: 'deployKeys',
};
