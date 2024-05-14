import { GlEmptyState, GlPagination, GlLoadingIcon } from '@gitlab/ui';
import AxiosMockAdapter from 'axios-mock-adapter';
import events from 'test_fixtures/controller/users/activity.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { DEFAULT_PER_PAGE } from '~/api';
import axios from '~/lib/utils/axios_utils';
import OrganizationsActivityApp from '~/organizations/activity/components/app.vue';
import ContributionEvents from '~/contribution_events/components/contribution_events.vue';
import { createAlert } from '~/alert';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/alert');

const defaultProps = {
  organizationActivityPath: '/-/organizations/default/activity.json',
};

describe('OrganizationsActivityApp', () => {
  let wrapper;
  let axiosMock;

  const createComponent = () => {
    wrapper = shallowMountExtended(OrganizationsActivityApp, {
      propsData: defaultProps,
    });
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  const findGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findGlPagination = () => wrapper.findComponent(GlPagination);
  const findContributionEvents = () => wrapper.findComponent(ContributionEvents);

  describe('mounted', () => {
    beforeEach(() => {
      jest.spyOn(axios, 'get');

      createComponent();
    });

    it('calls API with correct params', () => {
      expect(axios.get).toHaveBeenCalledWith(defaultProps.organizationActivityPath, {
        params: {
          offset: 0,
          limit: DEFAULT_PER_PAGE,
        },
      });
    });
  });

  describe('events', () => {
    beforeEach(async () => {
      axiosMock
        .onGet(defaultProps.organizationActivityPath)
        .reply(200, { events, has_next_page: true });
      jest.spyOn(axios, 'get');

      createComponent();
      await waitForPromises();
    });

    it('when new page is fetched, calls API with correct params, and does not set page until after call resolves', async () => {
      findGlPagination().vm.$emit('input', 3);

      expect(axios.get).toHaveBeenCalledWith(defaultProps.organizationActivityPath, {
        params: {
          offset: 2 * DEFAULT_PER_PAGE,
          limit: DEFAULT_PER_PAGE,
        },
      });

      expect(findGlPagination().props('value')).toBe(1);
      await waitForPromises();
      expect(findGlPagination().props('value')).toBe(3);
    });
  });

  describe('when activity API request is loading', () => {
    beforeEach(() => {
      axiosMock
        .onGet(defaultProps.organizationActivityPath)
        .reply(200, { events, has_next_page: false });

      createComponent();
    });

    it('renders loading icon', () => {
      expect(findGlLoadingIcon().exists()).toBe(true);
    });

    it('does not render pagination', () => {
      expect(findGlPagination().exists()).toBe(false);
    });

    it('does not render empty state', () => {
      expect(findGlEmptyState().exists()).toBe(false);
    });
  });

  describe('when activity API request is successful and returns 0 events', () => {
    beforeEach(async () => {
      axiosMock
        .onGet(defaultProps.organizationActivityPath)
        .reply(200, { events: [], has_next_page: false });

      createComponent();
      await waitForPromises();
    });

    it('does not render loading icon', () => {
      expect(findGlLoadingIcon().exists()).toBe(false);
    });

    it('does not render pagination', () => {
      expect(findGlPagination().exists()).toBe(false);
    });

    it('renders empty state', () => {
      expect(findGlEmptyState().exists()).toBe(true);
    });
  });

  describe('when activity API request is successful and returns events', () => {
    beforeEach(async () => {
      axiosMock
        .onGet(defaultProps.organizationActivityPath)
        .reply(200, { events, has_next_page: false });

      createComponent();
      await waitForPromises();
    });

    it('does not render loading icon', () => {
      expect(findGlLoadingIcon().exists()).toBe(false);
    });

    it('renders pagination', () => {
      expect(findGlPagination().exists()).toBe(true);
    });

    it('does not render empty state', () => {
      expect(findGlEmptyState().exists()).toBe(false);
    });

    it('renders Contribution Events', () => {
      expect(findContributionEvents().exists()).toBe(true);
      expect(findContributionEvents().props('events')).toStrictEqual(events);
    });
  });

  describe('when activity API request is not successful', () => {
    beforeEach(async () => {
      axiosMock.onGet(defaultProps.organizationActivityPath).networkError();

      createComponent();
      await waitForPromises();
    });

    it('calls createAlert', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred loading the activity. Please refresh the page to try again.',
        error: new Error('Network Error'),
        captureError: true,
      });
    });
  });
});
