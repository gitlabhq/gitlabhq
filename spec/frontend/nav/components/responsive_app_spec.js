import { shallowMount } from '@vue/test-utils';
import { range } from 'lodash';
import ResponsiveApp from '~/nav/components/responsive_app.vue';
import eventHub, { EVENT_RESPONSIVE_TOGGLE } from '~/nav/event_hub';
import { TEST_NAV_DATA } from '../mock_data';

describe('~/nav/components/responsive_app.vue', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(ResponsiveApp, {
      propsData: {
        navData: TEST_NAV_DATA,
      },
    });
  };
  const triggerResponsiveToggle = () => eventHub.$emit(EVENT_RESPONSIVE_TOGGLE);

  const hasBodyResponsiveOpen = () => document.body.classList.contains('top-nav-responsive-open');

  beforeEach(() => {
    // Add test class to reset state + assert that we're adding classes correctly
    document.body.className = 'test-class';
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      times | expectation
      ${0}  | ${false}
      ${1}  | ${true}
      ${2}  | ${false}
    `(
      'with responsive toggle event triggered $times, body responsive open = $expectation',
      ({ times, expectation }) => {
        range(times).forEach(triggerResponsiveToggle);

        expect(hasBodyResponsiveOpen()).toBe(expectation);
      },
    );
  });

  describe('when destroyed', () => {
    beforeEach(() => {
      createComponent();
      wrapper.destroy();
    });

    it('responsive toggle event does nothing', () => {
      triggerResponsiveToggle();

      expect(hasBodyResponsiveOpen()).toBe(false);
    });
  });
});
