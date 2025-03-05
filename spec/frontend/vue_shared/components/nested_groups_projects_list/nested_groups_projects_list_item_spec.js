import { GlButton } from '@gitlab/ui';
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

  const findNestedGroupsProjectsList = () => wrapper.findComponent(NestedGroupsProjectsList);
  const findToggleButton = () => wrapper.findComponent(GlButton);

  describe('when item type is group', () => {
    it('renders GroupsListItem component with correct props', () => {
      createComponent();

      expect(wrapper.findComponent(GroupsListItem).props()).toMatchObject({
        showGroupIcon: true,
        group: subgroupA,
        listItemClass: null,
      });
    });

    describe('when item has children', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders NestedGroupsProjectsList component', () => {
        expect(findNestedGroupsProjectsList().exists()).toBe(true);
      });

      describe('when NestedGroupsProjectsList emits load-children event', () => {
        it('emits load-children event', () => {
          findNestedGroupsProjectsList().vm.$emit('load-children', 1);

          expect(wrapper.emitted('load-children')).toEqual([[1]]);
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
        expect(findNestedGroupsProjectsList().exists()).toBe(false);
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
        listItemClass: 'gl-pl-7',
      });
    });
  });

  describe('when toggle is expanded', () => {
    describe('when children have not yet been loaded', () => {
      beforeEach(() => {
        createComponent();
        findToggleButton().vm.$emit('click');
      });

      it('emits load-children event', () => {
        expect(wrapper.emitted('load-children')).toEqual([[subgroupA.id]]);
      });

      describe('when children are loading', () => {
        beforeEach(async () => {
          await wrapper.setProps({
            item: {
              ...subgroupA,
              childrenLoading: true,
            },
          });
        });

        it('sets loading prop to true', () => {
          expect(findToggleButton().props('loading')).toBe(true);
        });
      });

      describe('when children are loaded', () => {
        beforeEach(async () => {
          await wrapper.setProps({
            item: {
              ...subgroupA,
              children: subgroupA.childrenToLoad,
            },
          });
        });

        it('passes children to NestedGroupsProjectsList component', () => {
          expect(findNestedGroupsProjectsList().props()).toEqual({
            items: subgroupA.childrenToLoad,
          });
        });

        it('updates button icon to chevron-down', () => {
          expect(findToggleButton().props('icon')).toBe('chevron-down');
        });
      });
    });

    describe('when children have already been loaded', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            item: {
              ...subgroupA,
              children: subgroupA.childrenToLoad,
            },
          },
        });
        findToggleButton().vm.$emit('click');
      });

      it('does not emit load-children event', () => {
        expect(wrapper.emitted('load-children')).toBeUndefined();
      });
    });
  });
});
