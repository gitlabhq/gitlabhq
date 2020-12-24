import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
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
    stubs: {
      GlEmptyState: stubComponent(GlEmptyState, {
        template: '<div><slot name="description"></slot></div>',
      }),
    },
  });
}

describe('GroupEmptyState', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each([
    metricStates.NO_DATA,
    metricStates.TIMEOUT,
    metricStates.CONNECTION_FAILED,
    metricStates.BAD_QUERY,
    metricStates.LOADING,
    metricStates.UNKNOWN_ERROR,
    'FOO STATE', // does not fail with unknown states
  ])('given state %s', (selectedState) => {
    beforeEach(() => {
      wrapper = createComponent({ selectedState });
    });

    it('renders the slotted content', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('passes the expected props to GlEmptyState', () => {
      expect(wrapper.find(GlEmptyState).props()).toMatchSnapshot();
    });
  });
});
