import { mount, createWrapper } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { getByText as getByTextHelper } from '@testing-library/dom';
import { GlDisclosureDropdownItem, GlToggle } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import NewNavToggle from '~/nav/components/new_nav_toggle.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import { mockTracking } from 'helpers/tracking_helper';

jest.mock('~/alert');

const TEST_ENDPONT = 'https://example.com/toggle';

describe('NewNavToggle', () => {
  useMockLocationHelper();

  let wrapper;
  let trackingSpy;

  const findToggle = () => wrapper.findComponent(GlToggle);
  const findDisclosureItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  const createComponent = (propsData = { enabled: false }) => {
    wrapper = mount(NewNavToggle, {
      propsData: {
        endpoint: TEST_ENDPONT,
        ...propsData,
      },
    });

    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  };

  const getByText = (text, options) =>
    createWrapper(getByTextHelper(wrapper.element, text, options));

  describe('When rendered in scope of the new navigation', () => {
    it('renders the disclosure item', () => {
      createComponent({ newNavigation: true, enabled: true });
      expect(findDisclosureItem().exists()).toBe(true);
    });

    describe('when user preference is enabled', () => {
      beforeEach(() => {
        createComponent({ newNavigation: true, enabled: true });
      });

      it('renders the toggle as enabled', () => {
        expect(findToggle().props('value')).toBe(true);
      });
    });

    describe('when user preference is disabled', () => {
      beforeEach(() => {
        createComponent({ enabled: false });
      });

      it('renders the toggle as disabled', () => {
        expect(findToggle().props('value')).toBe(false);
      });
    });

    describe.each`
      desc                                | actFn                                                 | toggleValue | trackingLabel             | trackingProperty
      ${'when toggle button is clicked'}  | ${() => findToggle().trigger('click')}                | ${false}    | ${'enable_new_nav_beta'}  | ${'navigation_top'}
      ${'when menu item text is clicked'} | ${() => getByText('New navigation').trigger('click')} | ${false}    | ${'enable_new_nav_beta'}  | ${'navigation_top'}
      ${'when toggle button is clicked'}  | ${() => findToggle().trigger('click')}                | ${true}     | ${'disable_new_nav_beta'} | ${'nav_user_menu'}
      ${'when menu item text is clicked'} | ${() => getByText('New navigation').trigger('click')} | ${true}     | ${'disable_new_nav_beta'} | ${'nav_user_menu'}
    `('$desc', ({ actFn, toggleValue, trackingLabel, trackingProperty }) => {
      let mock;

      beforeEach(() => {
        mock = new MockAdapter(axios);
        createComponent({ enabled: toggleValue });
      });

      it('reloads the page on success', async () => {
        mock.onPut(TEST_ENDPONT).reply(HTTP_STATUS_OK);

        actFn();
        await waitForPromises();

        expect(window.location.reload).toHaveBeenCalled();
      });

      it('shows an alert on error', async () => {
        mock.onPut(TEST_ENDPONT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        actFn();
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message: s__(
              'NorthstarNavigation|Could not update the new navigation preference. Please try again later.',
            ),
          }),
        );
        expect(window.location.reload).not.toHaveBeenCalled();
      });

      it('changes the toggle', async () => {
        await actFn();

        expect(findToggle().props('value')).toBe(!toggleValue);
      });

      it('tracks the Snowplow event', async () => {
        mock.onPut(TEST_ENDPONT).reply(HTTP_STATUS_OK);
        await actFn();
        await waitForPromises();
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_toggle', {
          label: trackingLabel,
          property: trackingProperty,
        });
      });

      afterEach(() => {
        mock.restore();
      });
    });
  });

  describe('When rendered in scope of the current navigation', () => {
    it('renders its title', () => {
      createComponent();
      expect(getByText('Navigation redesign').exists()).toBe(true);
    });

    describe('when user preference is enabled', () => {
      beforeEach(() => {
        createComponent({ enabled: true });
      });

      it('renders the toggle as enabled', () => {
        expect(findToggle().props('value')).toBe(true);
      });
    });

    describe('when user preference is disabled', () => {
      beforeEach(() => {
        createComponent({ enabled: false });
      });

      it('renders the toggle as disabled', () => {
        expect(findToggle().props('value')).toBe(false);
      });
    });

    describe.each`
      desc                                | actFn                                                 | toggleValue | trackingLabel             | trackingProperty
      ${'when toggle button is clicked'}  | ${() => findToggle().trigger('click')}                | ${false}    | ${'enable_new_nav_beta'}  | ${'navigation_top'}
      ${'when menu item text is clicked'} | ${() => getByText('New navigation').trigger('click')} | ${false}    | ${'enable_new_nav_beta'}  | ${'navigation_top'}
      ${'when toggle button is clicked'}  | ${() => findToggle().trigger('click')}                | ${true}     | ${'disable_new_nav_beta'} | ${'nav_user_menu'}
      ${'when menu item text is clicked'} | ${() => getByText('New navigation').trigger('click')} | ${true}     | ${'disable_new_nav_beta'} | ${'nav_user_menu'}
    `('$desc', ({ actFn, toggleValue, trackingLabel, trackingProperty }) => {
      let mock;

      beforeEach(() => {
        mock = new MockAdapter(axios);
        createComponent({ enabled: toggleValue });
      });

      it('reloads the page on success', async () => {
        mock.onPut(TEST_ENDPONT).reply(HTTP_STATUS_OK);

        actFn();
        await waitForPromises();

        expect(window.location.reload).toHaveBeenCalled();
      });

      it('shows an alert on error', async () => {
        mock.onPut(TEST_ENDPONT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        actFn();
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message: s__(
              'NorthstarNavigation|Could not update the new navigation preference. Please try again later.',
            ),
          }),
        );
        expect(window.location.reload).not.toHaveBeenCalled();
      });

      it('changes the toggle', async () => {
        await actFn();

        expect(findToggle().props('value')).toBe(!toggleValue);
      });

      it('tracks the Snowplow event', async () => {
        mock.onPut(TEST_ENDPONT).reply(HTTP_STATUS_OK);
        await actFn();
        await waitForPromises();
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_toggle', {
          label: trackingLabel,
          property: trackingProperty,
        });
      });

      afterEach(() => {
        mock.restore();
      });
    });
  });
});
