import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NestedGroupsProjectsList from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list.vue';
import NestedGroupsProjectsListItem from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list_item.vue';
import ProjectsListItem from '~/vue_shared/components/projects_list/projects_list_item.vue';
import GroupsListItem from '~/vue_shared/components/groups_list/groups_list_item.vue';
import {
  projectA,
  subgroupA,
  subgroupB,
} from '~/vue_shared/components/nested_groups_projects_list/mock_data';

describe('NestedGroupsProjectsListItem', () => {
  let wrapper;

  const defaultPropsData = {
    item: subgroupA,
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(NestedGroupsProjectsListItem, {
      propsData: { ...defaultPropsData, ...propsData },
    });
  };

  describe('when item type is group', () => {
    it('renders GroupsListItem component with correct props', () => {
      createComponent();

      expect(wrapper.findComponent(GroupsListItem).props()).toMatchObject({
        showGroupIcon: true,
        group: subgroupA,
      });
    });

    describe('when item has children', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders NestedGroupsProjectsList component with correct props', () => {
        expect(wrapper.findComponent(NestedGroupsProjectsList).props()).toEqual({
          items: subgroupA.children,
        });
      });
    });

    describe('when item does not have children', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            item: subgroupB,
          },
        });
      });

      it('does not render NestedGroupsProjectsList component', () => {
        expect(wrapper.findComponent(NestedGroupsProjectsList).exists()).toBe(false);
      });
    });
  });

  describe('when item type is project', () => {
    beforeEach(() => {
      createComponent({ propsData: { item: projectA } });
    });

    it('renders ProjectsListItem component', () => {
      expect(wrapper.findComponent(ProjectsListItem).props()).toMatchObject({
        showProjectIcon: true,
        project: projectA,
      });
    });
  });
});
