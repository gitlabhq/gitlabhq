import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import { dashboardEmptyStates } from '~/monitoring/constants';
import EmptyState from '~/monitoring/components/empty_state.vue';

function createComponent(props) {
  return shallowMount(EmptyState, {
    propsData: {
      settingsPath: '/settingsPath',
      clustersPath: '/clustersPath',
      documentationPath: '/documentationPath',
      emptyGettingStartedSvgPath: '/path/to/getting-started.svg',
      emptyLoadingSvgPath: '/path/to/loading.svg',
      emptyNoDataSvgPath: '/path/to/no-data.svg',
      emptyNoDataSmallSvgPath: '/path/to/no-data-small.svg',
      emptyUnableToConnectSvgPath: '/path/to/unable-to-connect.svg',
      ...props,
    },
  });
}

describe('EmptyState', () => {
  it('shows loading state with a loading icon', () => {
    const wrapper = createComponent({
      selectedState: dashboardEmptyStates.LOADING,
    });

    expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    expect(wrapper.find(GlEmptyState).exists()).toBe(false);
  });

  it('shows gettingStarted state', () => {
    const wrapper = createComponent({
      selectedState: dashboardEmptyStates.GETTING_STARTED,
    });

    expect(wrapper.element).toMatchSnapshot();
  });

  it('shows unableToConnect state', () => {
    const wrapper = createComponent({
      selectedState: dashboardEmptyStates.UNABLE_TO_CONNECT,
    });

    expect(wrapper.element).toMatchSnapshot();
  });

  it('shows noData state', () => {
    const wrapper = createComponent({
      selectedState: dashboardEmptyStates.NO_DATA,
    });

    expect(wrapper.element).toMatchSnapshot();
  });
});
