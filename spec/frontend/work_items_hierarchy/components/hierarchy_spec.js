import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlBadge } from '@gitlab/ui';
import Hierarchy from '~/work_items_hierarchy/components/hierarchy.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import RESPONSE from '~/work_items_hierarchy/static_response';
import { workItemTypes } from '~/work_items_hierarchy/constants';

Vue.use(VueApollo);

describe('WorkItemsHierarchy Hierarchy', () => {
  let wrapper;

  const workItemsFromResponse = (response) => {
    return response.reduce(
      (itemTypes, item) => {
        const key = item.available ? 'available' : 'unavailable';
        itemTypes[key].push({
          ...item,
          ...workItemTypes[item.type],
          nestedTypes: item.nestedTypes
            ? item.nestedTypes.map((type) => workItemTypes[type])
            : null,
        });
        return itemTypes;
      },
      { available: [], unavailable: [] },
    );
  };

  const createComponent = (props = {}) => {
    wrapper = extendedWrapper(
      mount(Hierarchy, {
        propsData: {
          workItemTypes: props.workItemTypes,
          ...props,
        },
      }),
    );
  };

  describe('available structure', () => {
    let items = [];

    beforeEach(() => {
      items = workItemsFromResponse(RESPONSE.ultimate).available;
      createComponent({ workItemTypes: items });
    });

    it('renders all work items', () => {
      expect(wrapper.findAllByTestId('work-item-wrapper')).toHaveLength(items.length);
    });

    it('does not render badges', () => {
      expect(wrapper.findComponent(GlBadge).exists()).toBe(false);
    });
  });

  describe('unavailable structure', () => {
    let items = [];

    beforeEach(() => {
      items = workItemsFromResponse(RESPONSE.premium).unavailable;
      createComponent({ workItemTypes: items });
    });

    it('renders all work items', () => {
      expect(wrapper.findAllByTestId('work-item-wrapper')).toHaveLength(items.length);
    });

    it('renders license badges for all work items', () => {
      expect(wrapper.findAllComponents(GlBadge)).toHaveLength(items.length);
    });

    it('does not render svg icon for linking', () => {
      expect(wrapper.findByTestId('hierarchy-rounded-arrow-tail').exists()).toBe(false);
      expect(wrapper.findByTestId('level-up-icon').exists()).toBe(false);
    });
  });

  describe('nested work items', () => {
    describe.each`
      licensePlan   | arrowTailVisible | levelUpIconVisible | arrowDownIconVisible
      ${'ultimate'} | ${true}          | ${true}            | ${true}
      ${'premium'}  | ${false}         | ${false}           | ${true}
      ${'free'}     | ${false}         | ${false}           | ${false}
    `(
      'when $licensePlan license',
      ({ licensePlan, arrowTailVisible, levelUpIconVisible, arrowDownIconVisible }) => {
        let items = [];
        beforeEach(() => {
          items = workItemsFromResponse(RESPONSE[licensePlan]).available;
          createComponent({ workItemTypes: items });
        });

        it(`${arrowTailVisible ? 'render' : 'does not render'} arrow tail svg`, () => {
          expect(wrapper.findByTestId('hierarchy-rounded-arrow-tail').exists()).toBe(
            arrowTailVisible,
          );
        });

        it(`${levelUpIconVisible ? 'render' : 'does not render'} arrow tail svg`, () => {
          expect(wrapper.findByTestId('level-up-icon').exists()).toBe(levelUpIconVisible);
        });

        it(`${arrowDownIconVisible ? 'render' : 'does not render'} arrow tail svg`, () => {
          expect(wrapper.findByTestId('arrow-down-icon').exists()).toBe(arrowDownIconVisible);
        });
      },
    );
  });
});
