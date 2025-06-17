import Vue from 'vue';
import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NestedGroupsProjectsList from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list.vue';
import NestedGroupsProjectsListItem from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list_item.vue';
import ProjectsListItem from '~/vue_shared/components/projects_list/projects_list_item.vue';
import GroupsListItem from '~/vue_shared/components/groups_list/groups_list_item.vue';
import { TIMESTAMP_TYPE_UPDATED_AT } from '~/vue_shared/components/resource_lists/constants';
import {
  projectA,
  topLevelGroupA,
  topLevelGroupB,
} from '~/vue_shared/components/nested_groups_projects_list/mock_data';

// We need to globally render components to avoid circular references
// https://v2.vuejs.org/v2/guide/components-edge-cases.html#Circular-References-Between-Components
Vue.component('NestedGroupsProjectsList', NestedGroupsProjectsList);
Vue.component('NestedGroupsProjectsListItem', NestedGroupsProjectsListItem);

describe('NestedGroupsProjectsListItem', () => {
  let wrapper;

  const defaultPropsData = {
    item: topLevelGroupA,
    timestampType: TIMESTAMP_TYPE_UPDATED_AT,
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(NestedGroupsProjectsListItem, {
      propsData: { ...defaultPropsData, ...propsData },
    });
  };

  const findNestedGroupsProjectsList = () => wrapper.findComponent(NestedGroupsProjectsList);
  const findToggleButton = () => wrapper.findComponent(GlButton);
  const findMoreChildrenLink = () => wrapper.findByTestId('more-children-link');

  describe('when item type is group', () => {
    it('renders GroupsListItem component with correct props', () => {
      createComponent();

      expect(wrapper.findComponent(GroupsListItem).props()).toMatchObject({
        showGroupIcon: true,
        group: topLevelGroupA,
        listItemClass: null,
        timestampType: defaultPropsData.timestampType,
      });
    });

    describe('when item has children', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders NestedGroupsProjectsList component with correct props and classes', () => {
        expect(findNestedGroupsProjectsList().props()).toMatchObject({
          timestampType: defaultPropsData.timestampType,
          items: [],
          initialExpanded: false,
        });
        expect(findNestedGroupsProjectsList().classes()).toContain('gl-hidden');
      });

      describe('when NestedGroupsProjectsList emits load-children event', () => {
        it('emits load-children event', () => {
          findNestedGroupsProjectsList().vm.$emit('load-children', 1);

          expect(wrapper.emitted('load-children')).toEqual([[1]]);
        });
      });

      describe('when NestedGroupsProjectsList emits refetch event', () => {
        it('emits refetch event', () => {
          findNestedGroupsProjectsList().vm.$emit('refetch');

          expect(wrapper.emitted('refetch')).toEqual([[]]);
        });
      });
    });

    describe('when item does not have children', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            item: topLevelGroupB,
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
        timestampType: defaultPropsData.timestampType,
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
        expect(wrapper.emitted('load-children')).toEqual([[topLevelGroupA.id]]);
      });

      describe('when children are loading', () => {
        beforeEach(async () => {
          await wrapper.setProps({
            item: {
              ...topLevelGroupA,
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
              ...topLevelGroupA,
              children: topLevelGroupA.childrenToLoad,
            },
          });
        });

        it('passes children to NestedGroupsProjectsList component and removes gl-hidden class', () => {
          expect(findNestedGroupsProjectsList().props()).toMatchObject({
            items: topLevelGroupA.childrenToLoad,
          });
          expect(findNestedGroupsProjectsList().classes()).not.toContain('gl-hidden');
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
              ...topLevelGroupA,
              children: topLevelGroupA.childrenToLoad,
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

  describe('when children have already been loaded', () => {
    describe('when initialExpanded is true', () => {
      it('passes children to NestedGroupsProjectsList component and removes gl-hidden class', () => {
        createComponent({
          propsData: {
            item: {
              ...topLevelGroupA,
              children: topLevelGroupA.childrenToLoad,
            },
            initialExpanded: true,
          },
        });

        expect(findNestedGroupsProjectsList().props()).toMatchObject({
          items: topLevelGroupA.childrenToLoad,
        });
        expect(findNestedGroupsProjectsList().classes()).not.toContain('gl-hidden');
      });

      describe('when there are more than 20 children', () => {
        it('renders link to subgroup page', () => {
          createComponent({
            propsData: {
              item: {
                ...topLevelGroupA,
                children: topLevelGroupA.childrenToLoad,
                childrenCount: 25,
              },
              initialExpanded: true,
            },
          });

          expect(findMoreChildrenLink().props('href')).toBe(topLevelGroupA.webUrl);
          expect(findMoreChildrenLink().text()).toBe('View all (23 more items)');
        });
      });
    });

    describe('when initialExpanded is false', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            item: {
              ...topLevelGroupA,
              children: topLevelGroupA.childrenToLoad,
            },
          },
        });
      });

      it('passes children to NestedGroupsProjectsList component and adds gl-hidden class', () => {
        expect(findNestedGroupsProjectsList().props()).toMatchObject({
          items: topLevelGroupA.childrenToLoad,
        });
        expect(findNestedGroupsProjectsList().classes()).toContain('gl-hidden');
      });
    });
  });
});
