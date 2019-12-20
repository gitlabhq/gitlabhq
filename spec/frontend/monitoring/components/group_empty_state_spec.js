import { shallowMount } from '@vue/test-utils';
import GroupEmptyState from '~/monitoring/components/group_empty_state.vue';
import { metricStates } from '~/monitoring/constants';

function createComponent(props) {
  return shallowMount(GroupEmptyState, {
    propsData: {
      ...props,
      documentationPath: '/path/to/docs',
      settingsPath: '/path/to/settings',
      svgPath: '/path/to/empty-group-illustration.svg',
    },
  });
}

describe('GroupEmptyState', () => {
  const supportedStates = [
    metricStates.NO_DATA,
    metricStates.TIMEOUT,
    metricStates.CONNECTION_FAILED,
    metricStates.BAD_QUERY,
    metricStates.LOADING,
    metricStates.UNKNOWN_ERROR,
    'FOO STATE', // does not fail with unknown states
  ];

  test.each(supportedStates)('Renders an empty state for %s', selectedState => {
    const wrapper = createComponent({ selectedState });

    expect(wrapper.element).toMatchSnapshot();
    // slot is not rendered by the stub, test it separately
    expect(wrapper.vm.currentState.slottedDescription).toMatchSnapshot();
  });
});
