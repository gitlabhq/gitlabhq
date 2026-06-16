import DashboardsListItemActions from './dashboards_list_item_actions.vue';

export default {
  component: DashboardsListItemActions,
  title: 'vue_shared/components/dashboards_list/dashboards_list_item_actions',
};

const Template = (args) => ({
  components: { DashboardsListItemActions },
  setup() {
    return { args };
  },
  template: '<div class="gl-min-h-10"><dashboards-list-item-actions v-bind="args" /></div>',
});

export const Default = Template.bind({});
Default.args = {
  actionLabel: 'Actions',
};
