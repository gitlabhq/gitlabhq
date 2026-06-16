import createMockApollo from 'helpers/mock_apollo_helper';
import getGroups from '~/analytics/shared/graphql/groups.query.graphql';
import GroupsFilter from './groups_filter.vue';

export default {
  component: GroupsFilter,
  title: 'explore/analytics_dashboards/components/groups_filter',
};

const nodes = [
  {
    id: 'gid://gitlab/Group/1',
    name: 'Group 1',
    fullName: 'namespace / Group 1',
    avatarUrl: '/avatar1.png',
    fullPath: 'namespace/group-1',
  },
  {
    id: 'gid://gitlab/Group/2',
    name: 'Group 2',
    fullName: 'namespace / Group 2',
    avatarUrl: '/avatar2.png',
    fullPath: 'namespace/group-2',
  },
];

const mockApolloProvider = () =>
  createMockApollo([[getGroups, () => ({ data: { groups: { nodes } } })]]);

const Template = (args, { argTypes }) => ({
  components: { GroupsFilter },
  apolloProvider: mockApolloProvider(),
  props: Object.keys(argTypes),
  template: `
    <div style="height:200px;" class="gl-py-3">
      <groups-filter v-bind="$props" />
    </div>`,
});

export const Default = Template.bind({});
Default.args = {};

export const MultiSelect = Template.bind({});
MultiSelect.args = {
  multiSelect: true,
};
