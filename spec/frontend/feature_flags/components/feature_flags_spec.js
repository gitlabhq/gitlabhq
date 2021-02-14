import { GlAlert, GlEmptyState, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vuex from 'vuex';
import { TEST_HOST } from 'spec/test_constants';
import Api from '~/api';
import ConfigureFeatureFlagsModal from '~/feature_flags/components/configure_feature_flags_modal.vue';
import FeatureFlagsComponent from '~/feature_flags/components/feature_flags.vue';
import FeatureFlagsTab from '~/feature_flags/components/feature_flags_tab.vue';
import FeatureFlagsTable from '~/feature_flags/components/feature_flags_table.vue';
import UserListsTable from '~/feature_flags/components/user_lists_table.vue';
import { FEATURE_FLAG_SCOPE, USER_LIST_SCOPE } from '~/feature_flags/constants';
import createStore from '~/feature_flags/store/index';
import axios from '~/lib/utils/axios_utils';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';
import { getRequestData, userList } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

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
    newUserListPath: '/user-list/new',
    unleashApiUrl: `${TEST_HOST}/api/unleash`,
    projectName: 'fakeProjectName',
    errorStateSvgPath: '/assets/illustrations/feature_flag.svg',
  };

  const mockState = {
    endpoint: `${TEST_HOST}/endpoint.json`,
    projectId: '8',
    unleashApiInstanceId: 'oP6sCNRqtRHmpy1gw2-F',
  };

  let wrapper;
  let mock;
  let store;

  const factory = (provide = mockData, fn = shallowMount) => {
    store = createStore(mockState);
    wrapper = fn(FeatureFlagsComponent, {
      localVue,
      store,
      provide,
      stubs: {
        FeatureFlagsTab,
      },
    });
  };

  const configureButton = () => wrapper.find('[data-testid="ff-configure-button"]');
  const newButton = () => wrapper.find('[data-testid="ff-new-button"]');
  const newUserListButton = () => wrapper.find('[data-testid="ff-new-list-button"]');
  const limitAlert = () => wrapper.find(GlAlert);

  beforeEach(() => {
    mock = new MockAdapter(axios);
    jest.spyOn(Api, 'fetchFeatureFlagUserLists').mockResolvedValue({
      data: [userList],
      headers: {
        'x-next-page': '2',
        'x-page': '1',
        'X-Per-Page': '8',
        'X-Prev-Page': '',
        'X-TOTAL': '40',
        'X-Total-Pages': '5',
      },
    });
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
    wrapper = null;
  });

  describe('when limit exceeded', () => {
    const provideData = { ...mockData, featureFlagsLimitExceeded: true };

    beforeEach((done) => {
      mock
        .onGet(`${TEST_HOST}/endpoint.json`, { params: { scope: FEATURE_FLAG_SCOPE, page: '1' } })
        .reply(200, getRequestData, {});
      factory(provideData);
      setImmediate(done);
    });

    it('makes the new feature flag button do nothing if clicked', () => {
      expect(newButton().exists()).toBe(true);
      expect(newButton().props('disabled')).toBe(false);
      expect(newButton().props('href')).toBe(undefined);
    });

    it('shows a feature flags limit reached alert', () => {
      expect(limitAlert().exists()).toBe(true);
      expect(limitAlert().find(GlSprintf).attributes('message')).toContain(
        'Feature flags limit reached',
      );
    });

    describe('when the alert is dismissed', () => {
      beforeEach(async () => {
        await limitAlert().vm.$emit('dismiss');
      });

      it('hides the alert', async () => {
        expect(limitAlert().exists()).toBe(false);
      });

      it('re-shows the alert if the new feature flag button is clicked', async () => {
        await newButton().vm.$emit('click');

        expect(limitAlert().exists()).toBe(true);
      });
    });
  });

  describe('without permissions', () => {
    const provideData = {
      ...mockData,
      canUserConfigure: false,
      canUserRotateToken: false,
      newFeatureFlagPath: null,
      newUserListPath: null,
    };

    beforeEach((done) => {
      mock
        .onGet(`${TEST_HOST}/endpoint.json`, { params: { scope: FEATURE_FLAG_SCOPE, page: '1' } })
        .reply(200, getRequestData, {});
      factory(provideData);
      setImmediate(done);
    });

    it('does not render configure button', () => {
      expect(configureButton().exists()).toBe(false);
    });

    it('does not render new feature flag button', () => {
      expect(newButton().exists()).toBe(false);
    });

    it('does not render new user list button', () => {
      expect(newUserListButton().exists()).toBe(false);
    });
  });

  describe('loading state', () => {
    it('renders a loading icon', () => {
      mock
        .onGet(`${TEST_HOST}/endpoint.json`, { params: { scope: FEATURE_FLAG_SCOPE, page: '1' } })
        .replyOnce(200, getRequestData, {});

      factory();

      const loadingElement = wrapper.find(GlLoadingIcon);

      expect(loadingElement.exists()).toBe(true);
      expect(loadingElement.props('label')).toEqual('Loading feature flags');
    });
  });

  describe('successful request', () => {
    describe('without feature flags', () => {
      let emptyState;

      beforeEach(async () => {
        mock.onGet(mockState.endpoint, { params: { scope: FEATURE_FLAG_SCOPE, page: '1' } }).reply(
          200,
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
        await wrapper.vm.$nextTick();

        emptyState = wrapper.find(GlEmptyState);
      });

      it('should render the empty state', async () => {
        expect(emptyState.exists()).toBe(true);
      });

      it('renders configure button', () => {
        expect(configureButton().exists()).toBe(true);
      });

      it('renders new feature flag button', () => {
        expect(newButton().exists()).toBe(true);
      });

      it('renders new user list button', () => {
        expect(newUserListButton().exists()).toBe(true);
        expect(newUserListButton().attributes('href')).toBe('/user-list/new');
      });

      describe('in feature flags tab', () => {
        it('renders generic title', () => {
          expect(emptyState.props('title')).toEqual('Get started with feature flags');
        });
      });
    });

    describe('with paginated feature flags', () => {
      beforeEach((done) => {
        mock
          .onGet(mockState.endpoint, { params: { scope: FEATURE_FLAG_SCOPE, page: '1' } })
          .replyOnce(200, getRequestData, {
            'x-next-page': '2',
            'x-page': '1',
            'X-Per-Page': '2',
            'X-Prev-Page': '',
            'X-TOTAL': '37',
            'X-Total-Pages': '5',
          });

        factory();
        jest.spyOn(store, 'dispatch');
        setImmediate(done);
      });

      it('should render a table with feature flags', () => {
        const table = wrapper.find(FeatureFlagsTable);
        expect(table.exists()).toBe(true);
        expect(table.props(FEATURE_FLAG_SCOPE)).toEqual(
          expect.arrayContaining([
            expect.objectContaining({
              name: getRequestData.feature_flags[0].name,
              description: getRequestData.feature_flags[0].description,
            }),
          ]),
        );
      });

      it('should toggle a flag when receiving the toggle-flag event', () => {
        const table = wrapper.find(FeatureFlagsTable);

        const [flag] = table.props(FEATURE_FLAG_SCOPE);
        table.vm.$emit('toggle-flag', flag);

        expect(store.dispatch).toHaveBeenCalledWith('toggleFeatureFlag', flag);
      });

      it('renders configure button', () => {
        expect(configureButton().exists()).toBe(true);
      });

      it('renders new feature flag button', () => {
        expect(newButton().exists()).toBe(true);
      });

      it('renders new user list button', () => {
        expect(newUserListButton().exists()).toBe(true);
        expect(newUserListButton().attributes('href')).toBe('/user-list/new');
      });

      describe('pagination', () => {
        it('should render pagination', () => {
          expect(wrapper.find(TablePagination).exists()).toBe(true);
        });

        it('should make an API request when page is clicked', () => {
          jest.spyOn(wrapper.vm, 'updateFeatureFlagOptions');
          wrapper.find(TablePagination).vm.change(4);

          expect(wrapper.vm.updateFeatureFlagOptions).toHaveBeenCalledWith({
            scope: FEATURE_FLAG_SCOPE,
            page: '4',
          });
        });

        it('should make an API request when using tabs', () => {
          jest.spyOn(wrapper.vm, 'updateFeatureFlagOptions');
          wrapper.find('[data-testid="user-lists-tab"]').vm.$emit('changeTab');

          expect(wrapper.vm.updateFeatureFlagOptions).toHaveBeenCalledWith({
            scope: USER_LIST_SCOPE,
            page: '1',
          });
        });
      });
    });

    describe('in user lists tab', () => {
      beforeEach((done) => {
        factory();
        setImmediate(done);
      });
      beforeEach(() => {
        wrapper.find('[data-testid="user-lists-tab"]').vm.$emit('changeTab');
        return wrapper.vm.$nextTick();
      });

      it('should display the user list table', () => {
        expect(wrapper.find(UserListsTable).exists()).toBe(true);
      });

      it('should set the user lists to display', () => {
        expect(wrapper.find(UserListsTable).props('userLists')).toEqual([userList]);
      });
    });
  });

  describe('unsuccessful request', () => {
    beforeEach((done) => {
      mock
        .onGet(mockState.endpoint, { params: { scope: FEATURE_FLAG_SCOPE, page: '1' } })
        .replyOnce(500, {});
      Api.fetchFeatureFlagUserLists.mockRejectedValueOnce();

      factory();
      setImmediate(done);
    });

    it('should render error state', () => {
      const emptyState = wrapper.find(GlEmptyState);
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

    it('renders new user list button', () => {
      expect(newUserListButton().exists()).toBe(true);
      expect(newUserListButton().attributes('href')).toBe('/user-list/new');
    });
  });

  describe('rotate instance id', () => {
    beforeEach((done) => {
      mock
        .onGet(`${TEST_HOST}/endpoint.json`, { params: { scope: FEATURE_FLAG_SCOPE, page: '1' } })
        .reply(200, getRequestData, {});
      factory();
      setImmediate(done);
    });

    it('should fire the rotate action when a `token` event is received', () => {
      const actionSpy = jest.spyOn(wrapper.vm, 'rotateInstanceId');
      const modal = wrapper.find(ConfigureFeatureFlagsModal);
      modal.vm.$emit('token');

      expect(actionSpy).toHaveBeenCalled();
    });
  });
});
