import { shallowMount } from '@vue/test-utils';
import EmptyState from '~/monitoring/components/empty_state.vue';

function createComponent(props) {
  return shallowMount(EmptyState, {
    propsData: {
      ...props,
      settingsPath: '/settingsPath',
      clustersPath: '/clustersPath',
      documentationPath: '/documentationPath',
      emptyGettingStartedSvgPath: '/path/to/getting-started.svg',
      emptyLoadingSvgPath: '/path/to/loading.svg',
      emptyNoDataSvgPath: '/path/to/no-data.svg',
      emptyNoDataSmallSvgPath: '/path/to/no-data-small.svg',
      emptyUnableToConnectSvgPath: '/path/to/unable-to-connect.svg',
    },
  });
}

describe('EmptyState', () => {
  it('shows gettingStarted state', () => {
    const wrapper = createComponent({
      selectedState: 'gettingStarted',
    });

    expect(wrapper.element).toMatchSnapshot();
  });

  it('shows loading state', () => {
    const wrapper = createComponent({
      selectedState: 'loading',
    });

    expect(wrapper.element).toMatchSnapshot();
  });

  it('shows unableToConnect state', () => {
    const wrapper = createComponent({
      selectedState: 'unableToConnect',
    });

    expect(wrapper.element).toMatchSnapshot();
  });
});
