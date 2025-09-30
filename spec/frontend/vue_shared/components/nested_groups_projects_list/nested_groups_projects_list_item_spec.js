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
  const findGroupsListItem = () => wrapper.findComponent(GroupsListItem);
  const findProjectsListItem = () => wrapper.findComponent(ProjectsListItem);
  const findToggleButton = () => wrapper.findComponent(GlButton);
  const findMoreChildrenLink = () => wrapper.findByTestId('more-children-link');

  describe('when item type is group', () => {
    it('renders GroupsListItem component with correct props', () => {
      createComponent();

      expect(findGroupsListItem().props()).toMatchObject({
        showGroupIcon: true,
        group: topLevelGroupA,
        listItemClass: null,
        timestampType: defaultPropsData.timestampType,
        includeMicrodata: false,
      });
    });

    describe.each`
      event                 | payload
      ${'refetch'}          | ${undefined}
      ${'hover-visibility'} | ${'private'}
      ${'hover-stat'}       | ${'projects-count'}
      ${'click-avatar'}     | ${undefined}
    `('when GroupsListItem emits $event event', ({ event, payload }) => {
      beforeEach(() => {
        createComponent();
        findGroupsListItem().vm.$emit(event, payload);
      });

      it(`emits ${event} event`, () => {
        expect(wrapper.emitted(event)).toEqual([[payload]]);
      });
    });

    describe('when item has children', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders NestedGroupsProjectsList component with correct props and classes', () => {
        expect(findNestedGroupsProjectsList().props()).toMatchObject({
          timestampType: defaultPropsData.timestampType,
          includeMicrodata: false,
          items: [],
          expandedOverride: false,
        });
        expect(findNestedGroupsProjectsList().classes()).toContain('gl-hidden');
      });

      describe.each`
        event                 | payload
        ${'load-children'}    | ${1}
        ${'refetch'}          | ${undefined}
        ${'hover-visibility'} | ${'private'}
        ${'hover-stat'}       | ${'projects-count'}
        ${'click-avatar'}     | ${undefined}
      `('when NestedGroupsProjectsList emits $event event', ({ event, payload }) => {
        beforeEach(() => {
          findNestedGroupsProjectsList().vm.$emit(event, payload);
        });

        it(`emits ${event} event`, () => {
          expect(wrapper.emitted(event)).toEqual([[payload]]);
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
      expect(findProjectsListItem().props()).toMatchObject({
        showProjectIcon: true,
        project: projectA,
        listItemClass: 'gl-pl-7',
        timestampType: defaultPropsData.timestampType,
        includeMicrodata: false,
      });
    });

    describe.each`
      event                 | payload
      ${'refetch'}          | ${undefined}
      ${'hover-visibility'} | ${'private'}
      ${'hover-stat'}       | ${'projects-count'}
      ${'click-avatar'}     | ${undefined}
    `('when ProjectsListItem emits $event event', ({ event, payload }) => {
      beforeEach(() => {
        findProjectsListItem().vm.$emit(event, payload);
      });

      it(`emits ${event} event`, () => {
        expect(wrapper.emitted(event)).toEqual([[payload]]);
      });
    });
  });

  describe('when toggle is expanded', () => {
    const setup = (expandedOverride = false) => {
      createComponent({ propsData: { expandedOverride } });
      findToggleButton().vm.$emit('click');
    };

    describe('when children have not yet been loaded', () => {
      it('emits load-children event', () => {
        setup();

        expect(wrapper.emitted('load-children')).toEqual([[topLevelGroupA.id]]);
      });

      describe('when children are loading', () => {
        beforeEach(async () => {
          setup();

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
        describe('when expandedOverride is true', () => {
          beforeEach(async () => {
            setup(true);

            await wrapper.setProps({
              item: {
                ...topLevelGroupA,
                children: topLevelGroupA.childrenToLoad,
              },
            });
          });

          it('removes gl-hidden class', () => {
            expect(findNestedGroupsProjectsList().classes()).not.toContain('gl-hidden');
          });

          it('updates button icon to chevron-down', () => {
            expect(findToggleButton().props('icon')).toBe('chevron-down');
          });

          it('passes children to NestedGroupsProjectsList component', () => {
            expect(findNestedGroupsProjectsList().props()).toMatchObject({
              items: topLevelGroupA.childrenToLoad,
            });
          });
        });

        describe('when expandedOverride is false', () => {
          beforeEach(async () => {
            setup();

            await wrapper.setProps({
              item: {
                ...topLevelGroupA,
                children: topLevelGroupA.childrenToLoad,
              },
            });
          });

          it('removes gl-hidden class', () => {
            expect(findNestedGroupsProjectsList().classes()).not.toContain('gl-hidden');
          });

          it('updates button icon to chevron-down', () => {
            expect(findToggleButton().props('icon')).toBe('chevron-down');
          });

          it('passes children to NestedGroupsProjectsList component', () => {
            expect(findNestedGroupsProjectsList().props()).toMatchObject({
              items: topLevelGroupA.childrenToLoad,
            });
          });
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
    describe('when expandedOverride is true', () => {
      it('passes children to NestedGroupsProjectsList component and removes gl-hidden class', () => {
        createComponent({
          propsData: {
            item: {
              ...topLevelGroupA,
              children: topLevelGroupA.childrenToLoad,
            },
            expandedOverride: true,
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
              expandedOverride: true,
            },
          });

          expect(findMoreChildrenLink().props('href')).toBe(topLevelGroupA.webUrl);
          expect(findMoreChildrenLink().text()).toBe('View all (23 more items)');
        });
      });

      describe('when expandedOverride prop is changed to false', () => {
        it('collapses list item', async () => {
          createComponent({
            propsData: {
              item: {
                ...topLevelGroupA,
                children: topLevelGroupA.childrenToLoad,
              },
              expandedOverride: true,
            },
          });
          expect(findNestedGroupsProjectsList().classes()).not.toContain('gl-hidden');

          await wrapper.setProps({ expandedOverride: false });

          expect(findNestedGroupsProjectsList().classes()).toContain('gl-hidden');
        });
      });
    });

    describe('when expandedOverride is false', () => {
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
