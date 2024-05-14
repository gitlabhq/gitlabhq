import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupsList from '~/vue_shared/components/groups_list/groups_list.vue';
import GroupsListItem from '~/vue_shared/components/groups_list/groups_list_item.vue';
import { TIMESTAMP_TYPE_CREATED_AT } from '~/vue_shared/components/resource_lists/constants';
import { groups } from './mock_data';

describe('GroupsList', () => {
  let wrapper;

  const defaultPropsData = {
    groups,
    listItemClass: 'gl-px-5',
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(GroupsList, {
      propsData: defaultPropsData,
    });
  };

  it('renders list with `GroupsListItem` component', () => {
    createComponent();

    const groupsListItemWrappers = wrapper.findAllComponents(GroupsListItem).wrappers;
    const expectedProps = groupsListItemWrappers.map((groupsListItemWrapper) =>
      groupsListItemWrapper.props(),
    );
    const expectedClasses = groupsListItemWrappers.map((groupsListItemWrapper) =>
      groupsListItemWrapper.classes(),
    );

    expect(expectedProps).toEqual(
      defaultPropsData.groups.map((group) => ({
        group,
        showGroupIcon: false,
        timestampType: TIMESTAMP_TYPE_CREATED_AT,
      })),
    );
    expect(expectedClasses).toEqual(
      defaultPropsData.groups.map(() => [defaultPropsData.listItemClass]),
    );
  });

  describe('when `GroupsListItem` emits `delete` event', () => {
    const [firstGroup] = defaultPropsData.groups;

    beforeEach(() => {
      createComponent();

      wrapper.findComponent(GroupsListItem).vm.$emit('delete', firstGroup);
    });

    it('emits `delete` event', () => {
      expect(wrapper.emitted('delete')).toEqual([[firstGroup]]);
    });
  });
});
