import { GlSkeletonLoader, GlCollapsibleListbox } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ActivityWidget from '~/homepage/components/activity_widget.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import axios from '~/lib/utils/axios_utils';
import { localTimeAgo } from '~/lib/utils/datetime_utility';
import BaseWidget from '~/homepage/components/base_widget.vue';
import { InternalEvents } from '~/tracking';
import {
  EVENT_USER_CLICKS_LINK_ON_ACTIVITY_FEED,
  TRACKING_SCOPE_YOUR_ACTIVITY,
  TRACKING_SCOPE_STARRED_PROJECTS,
  TRACKING_SCOPE_FOLLOWED_USERS,
} from '~/homepage/tracking_constants';

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/lib/utils/datetime_utility');

describe('ActivityWidget', () => {
  let wrapper;
  let mockAxios;
  let trackEventSpy;

  useMockInternalEventsTracking();

  const MOCK_CURRENT_USERNAME = 'administrator';

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findActivityFeedSelector = () => wrapper.findComponent(GlCollapsibleListbox);
  const findErrorMessage = () =>
    wrapper.findByText(
      'Your activity feed is not available. Please refresh the page to try again.',
    );
  const findEmptyState = () => wrapper.findByTestId('empty-state');
  const findEventsList = () => wrapper.findByTestId('events-list');
  const findBaseWidget = () => wrapper.findComponent(BaseWidget);
  const findAllActivityLink = () => wrapper.findByText('All activity');

  function createWrapper() {
    gon.current_username = MOCK_CURRENT_USERNAME;
    wrapper = shallowMountExtended(ActivityWidget, {
      propsData: {
        activityPath: '/foo/bar',
      },
    });
  }

  beforeEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }

    mockAxios = new MockAdapter(axios);
    trackEventSpy = jest.spyOn(InternalEvents, 'trackEvent');
    jest.clearAllMocks();
    sessionStorage.clear();
    delete gon.current_username;
  });

  afterEach(() => {
    mockAxios.restore();
    wrapper?.destroy();
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

  it('populates the activity feed selector with the correct options', () => {
    createWrapper();

    expect(findActivityFeedSelector().props('items')).toEqual([
      {
        text: 'Your activity',
        value: null,
        scope: 'Your activity',
        description: 'Your contributions, like commits and work on issues and merge requests.',
      },
      {
        text: 'Starred projects',
        value: 'starred',
        scope: 'Starred projects',
        description: 'Activity in projects you have starred.',
      },
      {
        text: 'Followed users',
        value: 'followed',
        scope: 'Followed users',
        description: 'Activity from users you follow.',
      },
    ]);
  });

  it("fetches the starred projects' activity feed", async () => {
    mockAxios.onGet('*').reply(200, {
      html: '',
    });
    createWrapper();
    await waitForPromises();

    expect(mockAxios.history.get).toHaveLength(1);

    findActivityFeedSelector().vm.$emit('select', 'starred');
    await waitForPromises();

    expect(mockAxios.history.get).toHaveLength(2);
    expect(mockAxios.history.get[1].url).toBe(
      '/dashboard/activity?limit=5&offset=0&filter=starred',
    );
  });

  it("fetches the followed users' activity feed", async () => {
    mockAxios.onGet('*').reply(200, {
      html: '',
    });
    createWrapper();
    await waitForPromises();

    expect(mockAxios.history.get).toHaveLength(1);

    findActivityFeedSelector().vm.$emit('select', 'followed');
    await waitForPromises();

    expect(mockAxios.history.get).toHaveLength(2);
    expect(mockAxios.history.get[1].url).toBe(
      '/dashboard/activity?limit=5&offset=0&filter=followed',
    );
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

      findBaseWidget().vm.$emit('visible');
      await waitForPromises();

      expect(reloadSpy).toHaveBeenCalled();
      reloadSpy.mockRestore();
    });
  });

  describe('session saved filters', () => {
    beforeEach(() => {
      sessionStorage.clear();
    });

    afterEach(() => {
      sessionStorage.clear();
    });

    it('switches between different filter options and persists them', async () => {
      createWrapper();
      await waitForPromises();
      expect(sessionStorage.getItem('homepage-activity-filter')).toBe(null);

      findActivityFeedSelector().vm.$emit('select', 'starred');
      await waitForPromises();
      expect(sessionStorage.getItem('homepage-activity-filter')).toBe('starred');

      findActivityFeedSelector().vm.$emit('select', 'followed');
      await waitForPromises();
      expect(sessionStorage.getItem('homepage-activity-filter')).toBe('followed');
    });
  });

  describe('tracking events', () => {
    it('tracks event when clicking on a link with "Your activity" filter', async () => {
      mockAxios
        .onGet(`/users/${MOCK_CURRENT_USERNAME}/activity?limit=5&is_personal_homepage=1`)
        .reply(200, {
          html: '<li><a href="/project/1">Project Link</a></li>',
        });

      createWrapper();
      await waitForPromises();

      const projectLink = wrapper.findByText('Project Link');
      expect(projectLink.exists()).toBe(true);

      projectLink.element.addEventListener('click', (e) => e.preventDefault());
      await projectLink.trigger('click');

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_USER_CLICKS_LINK_ON_ACTIVITY_FEED,
        {
          label: TRACKING_SCOPE_YOUR_ACTIVITY,
        },
        undefined,
      );
    });

    it('tracks event when clicking on a link with "Starred projects" filter', async () => {
      mockAxios
        .onGet(`/users/${MOCK_CURRENT_USERNAME}/activity?limit=5&is_personal_homepage=1`)
        .reply(200, {
          html: '<li><a href="/project/1">Project Link</a></li>',
        });
      mockAxios.onGet('/dashboard/activity?limit=5&offset=0&filter=starred').reply(200, {
        html: '<li><a href="/project/1">Project Link</a></li>',
      });

      createWrapper();
      await waitForPromises();

      findActivityFeedSelector().vm.$emit('select', 'starred');
      await waitForPromises();

      const projectLink = wrapper.findByText('Project Link');
      expect(projectLink.exists()).toBe(true);

      projectLink.element.addEventListener('click', (e) => e.preventDefault());
      await projectLink.trigger('click');

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_USER_CLICKS_LINK_ON_ACTIVITY_FEED,
        {
          label: TRACKING_SCOPE_STARRED_PROJECTS,
        },
        undefined,
      );
    });

    it('tracks event when clicking on a link with "Followed users" filter', async () => {
      mockAxios.reset();

      mockAxios
        .onGet(`/users/${MOCK_CURRENT_USERNAME}/activity?limit=5&is_personal_homepage=1`)
        .reply(200, {
          html: '<li><a href="/project/1">Project Link</a></li>',
        });
      mockAxios.onGet('/dashboard/activity?limit=5&offset=0&filter=followed').reply(200, {
        html: '<li><a href="/project/1">Project Link</a></li>',
      });

      createWrapper();
      await waitForPromises();

      findActivityFeedSelector().vm.$emit('select', 'followed');
      await waitForPromises();

      const projectLink = wrapper.findByText('Project Link');
      expect(projectLink.exists()).toBe(true);

      projectLink.element.addEventListener('click', (e) => e.preventDefault());
      await projectLink.trigger('click');

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_USER_CLICKS_LINK_ON_ACTIVITY_FEED,
        {
          label: TRACKING_SCOPE_FOLLOWED_USERS,
        },
        undefined,
      );
    });

    it('uses InternalEvents mixin for tracking', () => {
      createWrapper();

      expect(wrapper.vm.trackEvent).toBeDefined();
    });
  });

  describe('tracking constants', () => {
    it('imports and uses correct tracking constants', () => {
      expect(EVENT_USER_CLICKS_LINK_ON_ACTIVITY_FEED).toBe('user_clicks_link_in_activity_feed');
      expect(TRACKING_SCOPE_YOUR_ACTIVITY).toBe('Your activity');
      expect(TRACKING_SCOPE_STARRED_PROJECTS).toBe('Starred projects');
      expect(TRACKING_SCOPE_FOLLOWED_USERS).toBe('Followed users');
    });

    it('matches scope constants with filter option text values', () => {
      createWrapper();
      const filterOptions = findActivityFeedSelector().props('items');

      expect(filterOptions[0].scope).toBe(TRACKING_SCOPE_YOUR_ACTIVITY);
      expect(filterOptions[1].scope).toBe(TRACKING_SCOPE_STARRED_PROJECTS);
      expect(filterOptions[2].scope).toBe(TRACKING_SCOPE_FOLLOWED_USERS);
    });
  });
});
