import { GlEmptyState, GlPagination, GlLoadingIcon, GlFilteredSearchToken } from '@gitlab/ui';
import AxiosMockAdapter from 'axios-mock-adapter';
import events from 'test_fixtures/controller/users/activity.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { DEFAULT_PER_PAGE } from '~/api';
import axios from '~/lib/utils/axios_utils';
import OrganizationsActivityApp from '~/organizations/activity/components/app.vue';
import {
  CONTRIBUTION_TYPE_FILTER_TYPE,
  RECENT_SEARCHES_STORAGE_KEY,
  FILTERED_SEARCH_NAMESPACE,
} from '~/organizations/activity/filters';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearch from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import ContributionEvents from '~/contribution_events/components/contribution_events.vue';
import { createAlert } from '~/alert';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';
import {
  MOCK_ALL_EVENT,
  MOCK_EVENT_TYPES,
  MOCK_SELECTED_CONTRIBUTION_TYPE,
  MOCK_CONTRIBUTION_TYPE_VALUE,
} from '../mock_data';

jest.mock('~/alert');

const defaultProps = {
  organizationActivityPath: '/-/organizations/default/activity.json',
  organizationActivityEventTypes: MOCK_EVENT_TYPES,
  organizationActivityAllEvent: MOCK_ALL_EVENT,
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
  const findFilteredSearch = () => wrapper.findComponent(FilteredSearch);

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
          event_filter: MOCK_ALL_EVENT,
        },
      });
    });
  });

  describe('events', () => {
    beforeEach(async () => {
      axiosMock
        .onGet(defaultProps.organizationActivityPath)
        .reply(HTTP_STATUS_OK, { events, has_next_page: true });
      jest.spyOn(axios, 'get');

      createComponent();
      await waitForPromises();

      axios.get.mockClear();
    });

    it('when new page is fetched, calls API with correct params, and does not set page until after call resolves', async () => {
      findGlPagination().vm.$emit('input', 3);

      expect(axios.get).toHaveBeenCalledWith(defaultProps.organizationActivityPath, {
        params: {
          offset: 2 * DEFAULT_PER_PAGE,
          limit: DEFAULT_PER_PAGE,
          event_filter: MOCK_ALL_EVENT,
        },
      });

      expect(findGlPagination().props('value')).toBe(1);
      await waitForPromises();
      expect(findGlPagination().props('value')).toBe(3);
    });

    it('when filter is updated with empty value, calls API with event_filter: all', () => {
      findFilteredSearch().vm.$emit('onFilter', []);

      expect(axios.get).toHaveBeenCalledWith(defaultProps.organizationActivityPath, {
        params: {
          offset: 0,
          limit: DEFAULT_PER_PAGE,
          event_filter: MOCK_ALL_EVENT,
        },
      });
    });

    it(`when filter is updated with ${MOCK_SELECTED_CONTRIBUTION_TYPE.type}: ${MOCK_CONTRIBUTION_TYPE_VALUE.data}, calls API with event_filter: ${MOCK_CONTRIBUTION_TYPE_VALUE.data}`, () => {
      findFilteredSearch().vm.$emit('onFilter', [MOCK_SELECTED_CONTRIBUTION_TYPE]);

      expect(axios.get).toHaveBeenCalledWith(defaultProps.organizationActivityPath, {
        params: {
          offset: 0,
          limit: DEFAULT_PER_PAGE,
          event_filter: MOCK_CONTRIBUTION_TYPE_VALUE.data,
        },
      });
    });
  });

  describe('filtered search', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders with correct params and available tokens', () => {
      const expectedTokens = [
        {
          title: 'Contribution type',
          icon: 'comparison',
          type: CONTRIBUTION_TYPE_FILTER_TYPE,
          unique: true,
          token: GlFilteredSearchToken,
          operators: OPERATORS_IS,
          options: MOCK_EVENT_TYPES,
        },
      ];

      expect(findFilteredSearch().props('recentSearchesStorageKey')).toBe(
        RECENT_SEARCHES_STORAGE_KEY,
      );
      expect(findFilteredSearch().props('namespace')).toBe(FILTERED_SEARCH_NAMESPACE);
      expect(findFilteredSearch().props('tokens')).toStrictEqual(expectedTokens);
    });
  });

  describe('when activity API request is loading', () => {
    beforeEach(() => {
      axiosMock
        .onGet(defaultProps.organizationActivityPath)
        .reply(HTTP_STATUS_OK, { events, has_next_page: false });

      createComponent();
    });

    it('renders loading icon', () => {
      expect(findGlLoadingIcon().exists()).toBe(true);
    });

    it('renders filtered search bar', () => {
      expect(findFilteredSearch().exists()).toBe(true);
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
        .reply(HTTP_STATUS_OK, { events: [], has_next_page: false });

      createComponent();
      await waitForPromises();
    });

    it('does not render loading icon', () => {
      expect(findGlLoadingIcon().exists()).toBe(false);
    });

    it('renders filtered search bar', () => {
      expect(findFilteredSearch().exists()).toBe(true);
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
        .reply(HTTP_STATUS_OK, { events, has_next_page: false });

      createComponent();
      await waitForPromises();
    });

    it('does not render loading icon', () => {
      expect(findGlLoadingIcon().exists()).toBe(false);
    });

    it('renders filtered search bar', () => {
      expect(findFilteredSearch().exists()).toBe(true);
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
