import { GlLoadingIcon, GlAlert } from '@gitlab/ui';

import ActivityCalendar from '~/profile/components/activity_calendar.vue';
import AjaxCache from '~/lib/utils/ajax_cache';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useFakeDate } from 'helpers/fake_date';
import { userCalendarResponse } from '../mock_data';

jest.mock('~/lib/utils/ajax_cache');
jest.mock('@gitlab/ui/dist/utils');

describe('ActivityCalendar', () => {
  // Feb 21st, 2023
  useFakeDate(2023, 1, 21);

  let wrapper;

  const defaultProvide = {
    userCalendarPath: '/users/root/calendar.json',
    utcOffset: '0',
  };

  const createComponent = () => {
    wrapper = mountExtended(ActivityCalendar, { provide: defaultProvide });
  };

  const mockSuccessfulApiRequest = () =>
    AjaxCache.retrieve.mockResolvedValueOnce(userCalendarResponse);
  const mockUnsuccessfulApiRequest = () => AjaxCache.retrieve.mockRejectedValueOnce();

  const findCalendar = () => wrapper.findByTestId('contrib-calendar');

  describe('when API request is loading', () => {
    beforeEach(() => {
      AjaxCache.retrieve.mockReturnValueOnce(new Promise(() => {}));
    });

    it('renders loading icon', () => {
      createComponent();

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });
  });

  describe('when API request is successful', () => {
    beforeEach(() => {
      mockSuccessfulApiRequest();
    });

    it('renders the calendar', async () => {
      createComponent();

      await waitForPromises();

      expect(findCalendar().exists()).toBe(true);
      expect(wrapper.findByText(ActivityCalendar.i18n.calendarHint).exists()).toBe(true);
    });
  });

  describe('when API request is not successful', () => {
    beforeEach(() => {
      mockUnsuccessfulApiRequest();
    });

    it('renders error', async () => {
      createComponent();

      await waitForPromises();

      expect(wrapper.findComponent(GlAlert).exists()).toBe(true);
    });

    describe('when retry button is clicked', () => {
      it('retries API request', async () => {
        createComponent();

        await waitForPromises();

        mockSuccessfulApiRequest();

        await wrapper.findByRole('button', { name: ActivityCalendar.i18n.retry }).trigger('click');

        await waitForPromises();

        expect(findCalendar().exists()).toBe(true);
      });
    });
  });
});
