import { TEST_HOST } from 'helpers/test_constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import getGroups from '../graphql/groups.query.graphql';
import GroupsDropdownFilter from './groups_dropdown_filter.vue';

export default {
  component: GroupsDropdownFilter,
  title: 'analytics/shared/components/groups_dropdown_filter',
};

const nodes = [
  {
    id: 'gid://gitlab/Group/1',
    name: 'Gitlab Org',
    fullPath: 'gitlab-org',
    avatarUrl: `${TEST_HOST}/images/home/nasa.svg`,
  },
  {
    id: 'gid://gitlab/Group/2',
    name: 'Gitlab Com',
    fullPath: 'gitlab-com',
    avatarUrl: null,
  },
  {
    id: 'gid://gitlab/Group/3',
    name: 'Foo',
    fullPath: 'gitlab-foo',
    avatarUrl: null,
  },
];

const mockApolloProvider = () =>
  createMockApollo([[getGroups, () => ({ data: { groups: { nodes } } })]]);

const Template = (args, { argTypes }) => ({
  components: { GroupsDropdownFilter },
  apolloProvider: mockApolloProvider(),
  props: Object.keys(argTypes),
  template: `
    <div style="height:200px;" class="gl-py-3">
      <groups-dropdown-filter v-bind="$props" />
    </div>`,
});

export const Default = Template.bind({});
Default.args = {};

export const MultiSelect = Template.bind({});
MultiSelect.args = {
  multiSelect: true,
};
