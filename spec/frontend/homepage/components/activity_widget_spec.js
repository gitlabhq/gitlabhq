import { GlSkeletonLoader } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ActivityWidget from '~/homepage/components/activity_widget.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import axios from '~/lib/utils/axios_utils';
import { localTimeAgo } from '~/lib/utils/datetime_utility';
import VisibilityChangeDetector from '~/homepage/components/visibility_change_detector.vue';

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/lib/utils/datetime_utility');

describe('ActivityWidget', () => {
  let wrapper;
  let mockAxios;

  const MOCK_CURRENT_USERNAME = 'administrator';

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findErrorMessage = () =>
    wrapper.findByText(
      'Your activity feed is not available. Please refresh the page to try again.',
    );
  const findEmptyState = () => wrapper.findByTestId('empty-state');
  const findEventsList = () => wrapper.findByTestId('events-list');
  const findDetector = () => wrapper.findComponent(VisibilityChangeDetector);
  const findAllActivityLink = () => wrapper.find('a[href="/foo/bar"]');

  function createWrapper() {
    gon.current_username = MOCK_CURRENT_USERNAME;
    wrapper = shallowMountExtended(ActivityWidget, {
      propsData: {
        activityPath: '/foo/bar',
      },
    });
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
    expect(findErrorMessage().exists()).toBe(false);
    expect(findEmptyState().exists()).toBe(false);
    expect(findEventsList().exists()).toBe(false);
  });

  it('shows an error message if the request errors out', async () => {
    mockAxios
      .onGet(`/users/${MOCK_CURRENT_USERNAME}/activity?limit=5&is_personal_homepage=1`)
      .reply(500);
    createWrapper();
    await waitForPromises();

    expect(findErrorMessage().exists()).toBe(true);
    expect(findEmptyState().exists()).toBe(false);
    expect(findSkeletonLoader().exists()).toBe(false);
    expect(findEventsList().exists()).toBe(false);
    expect(Sentry.captureException).toHaveBeenCalled();
    expect(findErrorMessage().exists()).toBe(true);
  });

  it('shows an empty state if the user has no activity yet', async () => {
    mockAxios
      .onGet(`/users/${MOCK_CURRENT_USERNAME}/activity?limit=5&is_personal_homepage=1`)
      .reply(200, '');
    createWrapper();
    await waitForPromises();

    expect(findEmptyState().text()).toMatchInterpolatedText(
      'Start creating merge requests, pushing code, commenting in issues, and doing other work to view a feed of your activity here.',
    );
  });

  it('shows the events list when the request resolves', async () => {
    const EVENT_TESTID = 'mock-event';
    const EVENT_TEXT = 'Some event';

    mockAxios
      .onGet(`/users/${MOCK_CURRENT_USERNAME}/activity?limit=5&is_personal_homepage=1`)
      .reply(200, {
        html: `<li data-testid="${EVENT_TESTID}">${EVENT_TEXT}</li>`,
      });
    createWrapper();
    await waitForPromises();

    expect(findEventsList().exists()).toBe(true);
    expect(findErrorMessage().exists()).toBe(false);
    expect(findEmptyState().exists()).toBe(false);
    expect(findSkeletonLoader().exists()).toBe(false);

    expect(wrapper.findByTestId(EVENT_TESTID).exists()).toBe(true);
    expect(wrapper.findByTestId(EVENT_TESTID).text()).toBe(EVENT_TEXT);
  });

  it('initializes timeago when timestamps are inserted', async () => {
    const timestampHtml =
      '<time class="js-timeago" title="Jul 4, 2025 12:09pm" datetime="2025-07-04T12:09:51Z" tabindex="0" aria-label="Jul 4, 2025 12:09pm" data-toggle="tooltip" data-placement="top" data-container="body">Jul 04, 2025</time>';
    mockAxios
      .onGet(`/users/${MOCK_CURRENT_USERNAME}/activity?limit=5&is_personal_homepage=1`)
      .reply(200, {
        html: timestampHtml,
      });
    createWrapper();
    await waitForPromises();

    const timestampEls = wrapper.vm.$el.querySelectorAll('.js-timeago');
    expect(timestampEls).toHaveLength(1);
    expect(localTimeAgo).toHaveBeenCalledWith(timestampEls);
  });

  it('shows a link to all activity', () => {
    createWrapper();

    expect(findAllActivityLink().text()).toBe('All activity');
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
