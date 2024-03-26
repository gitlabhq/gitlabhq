import { GlAlert, GlBadge, GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { TEST_HOST } from 'spec/test_constants';
import ConfigureFeatureFlagsModal from '~/feature_flags/components/configure_feature_flags_modal.vue';
import EmptyState from '~/feature_flags/components/empty_state.vue';
import FeatureFlagsComponent from '~/feature_flags/components/feature_flags.vue';
import FeatureFlagsTable from '~/feature_flags/components/feature_flags_table.vue';
import createStore from '~/feature_flags/store/index';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';
import { getRequestData } from '../mock_data';

Vue.use(Vuex);

describe('Feature flags', () => {
  const mockData = {
    canUserConfigure: true,
    csrfToken: 'testToken',
    featureFlagsClientExampleHelpPagePath: '/help/feature-flags#client-example',
    featureFlagsClientLibrariesHelpPagePath: '/help/feature-flags#unleash-clients',
    featureFlagsHelpPagePath: '/help/feature-flags',
    featureFlagsLimit: '200',
    featureFlagsLimitExceeded: false,
    newFeatureFlagPath: 'feature-flags/new',
    userListPath: '/user-list',
    unleashApiUrl: `${TEST_HOST}/api/unleash`,
    projectName: 'fakeProjectName',
    errorStateSvgPath: '/assets/illustrations/empty-state/empty-feature-flag-md.svg',
  };

  const mockState = {
    endpoint: `${TEST_HOST}/endpoint.json`,
    projectId: '8',
    unleashApiInstanceId: 'oP6sCNRqtRHmpy1gw2-F',
  };

  let wrapper;
  let mock;
  let store;

  const factory = (provide = mockData, fn = mountExtended) => {
    store = createStore(mockState);
    wrapper = fn(FeatureFlagsComponent, {
      store,
      provide,
      stubs: {
        EmptyState,
      },
    });
  };

  const configureButton = () => wrapper.findByTestId('ff-configure-button');
  const newButton = () => wrapper.findByTestId('ff-new-button');
  const userListButton = () => wrapper.findByTestId('ff-user-list-button');
  const limitAlert = () => wrapper.findComponent(GlAlert);
  const findTablePagination = () => wrapper.findComponent(TablePagination);
  const findFeatureFlagsTable = () => wrapper.findComponent(FeatureFlagsTable);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findTableTitle = () => wrapper.findByText('Feature flags');
  const findFeatureFlagsCountBadge = () => wrapper.findComponent(GlBadge);

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('table title', () => {
    beforeEach(() => {
      mock
        .onGet(`${TEST_HOST}/endpoint.json`, { params: { page: '1' } })
        .reply(HTTP_STATUS_OK, getRequestData, {});
      factory(mockData);
      return waitForPromises();
    });

    it('does exist', () => {
      expect(findTableTitle().exists()).toBe(true);
    });

    it('has a count badge', () => {
      expect(findFeatureFlagsCountBadge().exists()).toBe(true);
    });

    describe('with feature flags limit', () => {
      it('renders a count badge with feature flags count and limit values', () => {
        expect(findFeatureFlagsCountBadge().text()).toBe('1/200');
      });

      it('renders a count badge tooltip', () => {
        expect(findFeatureFlagsCountBadge().attributes('title')).toBe(
          'Current plan allows for 200 feature flags.',
        );
      });
    });

    describe('without feature flags limit', () => {
      beforeEach(() => {
        mock
          .onGet(`${TEST_HOST}/endpoint.json`, { params: { page: '1' } })
          .reply(HTTP_STATUS_OK, getRequestData, {});
        factory({ ...mockData, featureFlagsLimit: '0' });
        return waitForPromises();
      });

      it('renders a count badge with feature flags count value only', () => {
        expect(findFeatureFlagsCountBadge().text()).toBe('1');
      });

      it("doesn't render a count badge tooltip", () => {
        expect(findFeatureFlagsCountBadge().attributes('title')).toBe('');
      });
    });
  });

  describe('when limit exceeded', () => {
    const provideData = { ...mockData, featureFlagsLimitExceeded: true };

    beforeEach(() => {
      mock
        .onGet(`${TEST_HOST}/endpoint.json`, { params: { page: '1' } })
        .reply(HTTP_STATUS_OK, getRequestData, {});
      factory(provideData);
      return waitForPromises();
    });

    it('the new feature flag button is disabled', () => {
      expect(newButton().exists()).toBe(true);
      expect(newButton().props('disabled')).toBe(true);
    });

    it('shows a feature flags limit reached alert', () => {
      expect(limitAlert().exists()).toBe(true);
      expect(limitAlert().text()).toContain(
        "You've reached your feature flag limit (200). To add more, delete at least one feature flag, or upgrade to a higher tier.",
      );
    });
  });

  describe('without permissions', () => {
    const provideData = {
      ...mockData,
      canUserConfigure: false,
      canUserRotateToken: false,
      newFeatureFlagPath: null,
      userListPath: null,
    };

    beforeEach(() => {
      mock
        .onGet(`${TEST_HOST}/endpoint.json`, { params: { page: '1' } })
        .reply(HTTP_STATUS_OK, getRequestData, {});
      factory(provideData);
      return waitForPromises();
    });

    it('does not render configure button', () => {
      expect(configureButton().exists()).toBe(false);
    });

    it('does not render new feature flag button', () => {
      expect(newButton().exists()).toBe(false);
    });

    it('does not render view user list button', () => {
      expect(userListButton().exists()).toBe(false);
    });
  });

  describe('loading state', () => {
    it('renders a loading icon', () => {
      mock
        .onGet(`${TEST_HOST}/endpoint.json`, { params: { page: '1' } })
        .replyOnce(HTTP_STATUS_OK, getRequestData, {});

      factory();

      const loadingElement = wrapper.findComponent(GlLoadingIcon);

      expect(loadingElement.exists()).toBe(true);
      expect(loadingElement.props('label')).toEqual('Loading feature flags');
    });
  });

  describe('successful request', () => {
    describe('without feature flags', () => {
      let emptyState;

      beforeEach(async () => {
        mock.onGet(mockState.endpoint, { params: { page: '1' } }).reply(
          HTTP_STATUS_OK,
          {
            feature_flags: [],
            count: {
              all: 0,
              enabled: 0,
              disabled: 0,
            },
          },
          {},
        );

        factory();
        await waitForPromises();

        emptyState = findEmptyState();
      });

      it('should render the empty state', () => {
        expect(emptyState.exists()).toBe(true);
      });

      it('renders configure button', () => {
        expect(configureButton().exists()).toBe(true);
      });

      it('renders new feature flag button', () => {
        expect(newButton().exists()).toBe(true);
      });

      it('renders view user list button', () => {
        expect(userListButton().exists()).toBe(true);
        expect(userListButton().attributes('href')).toBe(mockData.userListPath);
      });

      describe('in feature flags tab', () => {
        it('renders generic title', () => {
          expect(emptyState.props('title')).toEqual('Get started with feature flags');
        });
      });
    });

    describe('with paginated feature flags', () => {
      beforeEach(() => {
        mock
          .onGet(mockState.endpoint, { params: { page: '1' } })
          .replyOnce(HTTP_STATUS_OK, getRequestData, {
            'x-next-page': '2',
            'x-page': '1',
            'X-Per-Page': '2',
            'X-Prev-Page': '',
            'X-TOTAL': '37',
            'X-Total-Pages': '5',
          });

        factory();
        jest.spyOn(store, 'dispatch');
        return waitForPromises();
      });

      it('should render a table with feature flags', () => {
        const table = findFeatureFlagsTable();
        expect(table.exists()).toBe(true);
        expect(table.props('featureFlags')).toEqual(
          expect.arrayContaining([
            expect.objectContaining({
              name: getRequestData.feature_flags[0].name,
              description: getRequestData.feature_flags[0].description,
            }),
          ]),
        );
      });

      it('should toggle a flag when receiving the toggle-flag event', () => {
        const table = findFeatureFlagsTable();

        const [flag] = table.props('featureFlags');
        table.vm.$emit('toggle-flag', flag);

        expect(store.dispatch).toHaveBeenCalledWith('toggleFeatureFlag', flag);
      });

      it('renders configure button', () => {
        expect(configureButton().exists()).toBe(true);
      });

      it('renders new feature flag button', () => {
        expect(newButton().exists()).toBe(true);
      });

      it('renders view user list button', () => {
        expect(userListButton().exists()).toBe(true);
        expect(userListButton().attributes('href')).toBe(mockData.userListPath);
      });

      describe('pagination', () => {
        it('should render pagination', () => {
          expect(findTablePagination().exists()).toBe(true);
        });

        it('should make an API request when page is clicked', () => {
          const axiosGet = jest.spyOn(axios, 'get');
          findTablePagination().vm.change(4);

          expect(axiosGet).toHaveBeenCalledWith('http://test.host/endpoint.json', {
            params: { page: '4' },
          });
        });
      });
    });
  });

  describe('unsuccessful request', () => {
    beforeEach(() => {
      factory();
      return waitForPromises();
    });

    it('should render error state', () => {
      const emptyState = findEmptyState();
      expect(emptyState.props('title')).toEqual('There was an error fetching the feature flags.');
      expect(emptyState.props('description')).toEqual(
        'Try again in a few moments or contact your support team.',
      );
    });

    it('renders configure button', () => {
      expect(configureButton().exists()).toBe(true);
    });

    it('renders new feature flag button', () => {
      expect(newButton().exists()).toBe(true);
    });

    it('renders view user list button', () => {
      expect(userListButton().exists()).toBe(true);
      expect(userListButton().attributes('href')).toBe(mockData.userListPath);
    });
  });

  describe('rotate instance id', () => {
    it('should fire the rotate action when a `token` event is received', () => {
      factory();
      const axiosPost = jest.spyOn(axios, 'post');
      wrapper.findComponent(ConfigureFeatureFlagsModal).vm.$emit('token');

      expect(axiosPost).toHaveBeenCalled();
    });
  });
});
