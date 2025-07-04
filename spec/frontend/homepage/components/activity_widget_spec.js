import { GlAlert, GlSkeletonLoader } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ActivityWidget from '~/homepage/components/activity_widget.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import axios from '~/lib/utils/axios_utils';
import VisibilityChangeDetector from '~/homepage/components/visibility_change_detector.vue';

jest.mock('~/sentry/sentry_browser_wrapper');

describe('ActivityWidget', () => {
  let wrapper;
  let mockAxios;

  const MOCK_CURRENT_USERNAME = 'administrator';

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEventsList = () => wrapper.findByTestId('events-list');
  const findDetector = () => wrapper.findComponent(VisibilityChangeDetector);

  function createWrapper() {
    gon.current_username = MOCK_CURRENT_USERNAME;
    wrapper = shallowMountExtended(ActivityWidget);
  }

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockAxios.restore();
  });

  it('shows a loading state while events are being fetched', () => {
    createWrapper();

    expect(findSkeletonLoader().exists()).toBe(true);
    expect(findAlert().exists()).toBe(false);
    expect(findEventsList().exists()).toBe(false);
  });

  it('shows an alert if the request errors out', async () => {
    mockAxios.onGet(`/users/${MOCK_CURRENT_USERNAME}/activity?limit=10`).reply(500);
    createWrapper();
    await waitForPromises();

    expect(findAlert().exists()).toBe(true);
    expect(findSkeletonLoader().exists()).toBe(false);
    expect(findEventsList().exists()).toBe(false);
    expect(Sentry.captureException).toHaveBeenCalled();
    expect(findAlert().text()).toBe(
      'The activity feed is not available. Please refresh the page to try again.',
    );
  });

  it('shows the events list when the request resolves', async () => {
    const EVENT_TESTID = 'mock-event';
    const EVENT_TEXT = 'Some event';

    mockAxios.onGet(`/users/${MOCK_CURRENT_USERNAME}/activity?limit=10`).reply(200, {
      html: `<li data-testid="${EVENT_TESTID}">${EVENT_TEXT}</li>`,
    });
    createWrapper();
    await waitForPromises();

    expect(findEventsList().exists()).toBe(true);
    expect(findAlert().exists()).toBe(false);
    expect(findSkeletonLoader().exists()).toBe(false);

    expect(wrapper.findByTestId(EVENT_TESTID).exists()).toBe(true);
    expect(wrapper.findByTestId(EVENT_TESTID).text()).toBe(EVENT_TEXT);
  });

  describe('refresh functionality', () => {
    it('refreshes on becoming visible again', async () => {
      const reloadSpy = jest.spyOn(ActivityWidget.methods, 'reload').mockImplementation(() => {});

      createWrapper();
      await waitForPromises();
      reloadSpy.mockClear();

      findDetector().vm.$emit('visible');
      await waitForPromises();

      expect(reloadSpy).toHaveBeenCalled();
      reloadSpy.mockRestore();
    });
  });
});
