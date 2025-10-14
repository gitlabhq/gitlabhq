import Vue from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NestedGroupsProjectsList from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list.vue';
import NestedGroupsProjectsListItem from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list_item.vue';
import { TIMESTAMP_TYPE_UPDATED_AT } from '~/vue_shared/components/resource_lists/constants';
import { items } from '~/vue_shared/components/nested_groups_projects_list/mock_data';

// We need to globally render components to avoid circular references
// https://v2.vuejs.org/v2/guide/components-edge-cases.html#Circular-References-Between-Components
Vue.component('NestedGroupsProjectsList', NestedGroupsProjectsList);
Vue.component('NestedGroupsProjectsListItem', NestedGroupsProjectsListItem);

describe('NestedGroupsProjectsList', () => {
  let wrapper;

  const defaultPropsData = {
    items,
    timestampType: TIMESTAMP_TYPE_UPDATED_AT,
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(NestedGroupsProjectsList, {
      propsData: defaultPropsData,
    });
  };

  const findNestedGroupsProjectsListItem = () =>
    wrapper.findComponent(NestedGroupsProjectsListItem);

  beforeEach(() => {
    createComponent();
  });

  it('renders list with `NestedGroupsProjectsListItem` component', () => {
    const listItemWrappers = wrapper.findAllComponents(NestedGroupsProjectsListItem).wrappers;
    const expectedProps = listItemWrappers.map((listItemWrapper) => listItemWrapper.props());

    expect(expectedProps).toEqual(
      defaultPropsData.items.map((item) => ({
        item,
        timestampType: defaultPropsData.timestampType,
        includeMicrodata: false,
        expandedOverride: false,
      })),
    );
  });

  describe.each`
    event                 | payload
    ${'load-children'}    | ${1}
    ${'refetch'}          | ${undefined}
    ${'hover-visibility'} | ${'private'}
    ${'hover-stat'}       | ${'projects-count'}
    ${'click-avatar'}     | ${undefined}
  `('when NestedGroupsProjectsListItem emits $event event', ({ event, payload }) => {
    beforeEach(() => {
      findNestedGroupsProjectsListItem().vm.$emit(event, payload);
    });

    it(`emits ${event} event`, () => {
      expect(wrapper.emitted(event)).toEqual([[payload]]);
    });
  });
});
