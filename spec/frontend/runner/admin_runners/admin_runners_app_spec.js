import Vue from 'vue';
import { GlToast, GlLink } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import {
  extendedWrapper,
  shallowMountExtended,
  mountExtended,
} from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/flash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { updateHistory } from '~/lib/utils/url_utility';

import AdminRunnersApp from '~/runner/admin_runners/admin_runners_app.vue';
import RunnerTypeTabs from '~/runner/components/runner_type_tabs.vue';
import RunnerFilteredSearchBar from '~/runner/components/runner_filtered_search_bar.vue';
import RunnerList from '~/runner/components/runner_list.vue';
import RunnerStats from '~/runner/components/stat/runner_stats.vue';
import RunnerActionsCell from '~/runner/components/cells/runner_actions_cell.vue';
import RegistrationDropdown from '~/runner/components/registration/registration_dropdown.vue';
import RunnerPagination from '~/runner/components/runner_pagination.vue';

import {
  ADMIN_FILTERED_SEARCH_NAMESPACE,
  CREATED_ASC,
  CREATED_DESC,
  DEFAULT_SORT,
  INSTANCE_TYPE,
  GROUP_TYPE,
  PROJECT_TYPE,
  PARAM_KEY_STATUS,
  PARAM_KEY_TAG,
  STATUS_ACTIVE,
  RUNNER_PAGE_SIZE,
} from '~/runner/constants';
import adminRunnersQuery from '~/runner/graphql/list/admin_runners.query.graphql';
import adminRunnersCountQuery from '~/runner/graphql/list/admin_runners_count.query.graphql';
import { captureException } from '~/runner/sentry_utils';
import FilteredSearch from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

import { runnersData, runnersCountData, runnersDataPaginated } from '../mock_data';

const mockRegistrationToken = 'MOCK_REGISTRATION_TOKEN';

jest.mock('~/flash');
jest.mock('~/runner/sentry_utils');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  updateHistory: jest.fn(),
}));

Vue.use(VueApollo);
Vue.use(GlToast);

describe('AdminRunnersApp', () => {
  let wrapper;
  let mockRunnersQuery;
  let mockRunnersCountQuery;

  const findRunnerStats = () => wrapper.findComponent(RunnerStats);
  const findRunnerActionsCell = () => wrapper.findComponent(RunnerActionsCell);
  const findRegistrationDropdown = () => wrapper.findComponent(RegistrationDropdown);
  const findRunnerTypeTabs = () => wrapper.findComponent(RunnerTypeTabs);
  const findRunnerList = () => wrapper.findComponent(RunnerList);
  const findRunnerPagination = () => extendedWrapper(wrapper.findComponent(RunnerPagination));
  const findRunnerPaginationPrev = () =>
    findRunnerPagination().findByLabelText('Go to previous page');
  const findRunnerPaginationNext = () => findRunnerPagination().findByLabelText('Go to next page');
  const findRunnerFilteredSearchBar = () => wrapper.findComponent(RunnerFilteredSearchBar);
  const findFilteredSearch = () => wrapper.findComponent(FilteredSearch);

  const createComponent = ({ props = {}, mountFn = shallowMountExtended } = {}) => {
    const handlers = [
      [adminRunnersQuery, mockRunnersQuery],
      [adminRunnersCountQuery, mockRunnersCountQuery],
    ];

    wrapper = mountFn(AdminRunnersApp, {
      apolloProvider: createMockApollo(handlers),
      propsData: {
        registrationToken: mockRegistrationToken,
        ...props,
      },
    });
  };

  beforeEach(async () => {
    setWindowLocation('/admin/runners');

    mockRunnersQuery = jest.fn().mockResolvedValue(runnersData);
    mockRunnersCountQuery = jest.fn().mockResolvedValue(runnersCountData);
    createComponent();
    await waitForPromises();
  });

  afterEach(() => {
    mockRunnersQuery.mockReset();
    mockRunnersCountQuery.mockReset();
    wrapper.destroy();
  });

  it('shows total runner counts', async () => {
    createComponent({ mountFn: mountExtended });

    await waitForPromises();

    const stats = findRunnerStats().text();

    expect(stats).toMatch('Online runners 4');
    expect(stats).toMatch('Offline runners 4');
    expect(stats).toMatch('Stale runners 4');
  });

  it('shows the runner tabs with a runner count for each type', async () => {
    mockRunnersCountQuery.mockImplementation(({ type }) => {
      let count;
      switch (type) {
        case INSTANCE_TYPE:
          count = 3;
          break;
        case GROUP_TYPE:
          count = 2;
          break;
        case PROJECT_TYPE:
          count = 1;
          break;
        default:
          count = 6;
          break;
      }
      return Promise.resolve({ data: { runners: { count } } });
    });

    createComponent({ mountFn: mountExtended });
    await waitForPromises();

    expect(findRunnerTypeTabs().text()).toMatchInterpolatedText(
      `All 6 Instance 3 Group 2 Project 1`,
    );
  });

  it('shows the runner tabs with a formatted runner count', async () => {
    mockRunnersCountQuery.mockImplementation(({ type }) => {
      let count;
      switch (type) {
        case INSTANCE_TYPE:
          count = 3000;
          break;
        case GROUP_TYPE:
          count = 2000;
          break;
        case PROJECT_TYPE:
          count = 1000;
          break;
        default:
          count = 6000;
          break;
      }
      return Promise.resolve({ data: { runners: { count } } });
    });

    createComponent({ mountFn: mountExtended });
    await waitForPromises();

    expect(findRunnerTypeTabs().text()).toMatchInterpolatedText(
      `All 6,000 Instance 3,000 Group 2,000 Project 1,000`,
    );
  });

  it('shows the runner setup instructions', () => {
    expect(findRegistrationDropdown().props('registrationToken')).toBe(mockRegistrationToken);
    expect(findRegistrationDropdown().props('type')).toBe(INSTANCE_TYPE);
  });

  it('shows the runners list', () => {
    expect(findRunnerList().props('runners')).toEqual(runnersData.data.runners.nodes);
  });

  it('runner item links to the runner admin page', async () => {
    createComponent({ mountFn: mountExtended });

    await waitForPromises();

    const { id, shortSha } = runnersData.data.runners.nodes[0];
    const numericId = getIdFromGraphQLId(id);

    const runnerLink = wrapper.find('tr [data-testid="td-summary"]').find(GlLink);

    expect(runnerLink.text()).toBe(`#${numericId} (${shortSha})`);
    expect(runnerLink.attributes('href')).toBe(`http://localhost/admin/runners/${numericId}`);
  });

  it('renders runner actions for each runner', async () => {
    createComponent({ mountFn: mountExtended });

    await waitForPromises();

    const runnerActions = wrapper.find('tr [data-testid="td-actions"]').find(RunnerActionsCell);

    const runner = runnersData.data.runners.nodes[0];

    expect(runnerActions.props()).toEqual({
      runner,
      editUrl: runner.editAdminUrl,
    });
  });

  it('requests the runners with no filters', () => {
    expect(mockRunnersQuery).toHaveBeenLastCalledWith({
      status: undefined,
      type: undefined,
      sort: DEFAULT_SORT,
      first: RUNNER_PAGE_SIZE,
    });
  });

  it('sets tokens in the filtered search', () => {
    createComponent({ mountFn: mountExtended });

    expect(findFilteredSearch().props('tokens')).toEqual([
      expect.objectContaining({
        type: PARAM_KEY_STATUS,
        options: expect.any(Array),
      }),
      expect.objectContaining({
        type: PARAM_KEY_TAG,
        recentSuggestionsStorageKey: `${ADMIN_FILTERED_SEARCH_NAMESPACE}-recent-tags`,
      }),
    ]);
  });

  describe('Single runner row', () => {
    let showToast;

    const mockRunner = runnersData.data.runners.nodes[0];
    const { id: graphqlId, shortSha } = mockRunner;
    const id = getIdFromGraphQLId(graphqlId);

    beforeEach(async () => {
      mockRunnersQuery.mockClear();

      createComponent({ mountFn: mountExtended });
      showToast = jest.spyOn(wrapper.vm.$root.$toast, 'show');

      await waitForPromises();
    });

    it('Links to the runner page', async () => {
      const runnerLink = wrapper.find('tr [data-testid="td-summary"]').find(GlLink);

      expect(runnerLink.text()).toBe(`#${id} (${shortSha})`);
      expect(runnerLink.attributes('href')).toBe(`http://localhost/admin/runners/${id}`);
    });

    it('When runner is deleted, data is refetched and a toast message is shown', async () => {
      expect(mockRunnersQuery).toHaveBeenCalledTimes(1);

      findRunnerActionsCell().vm.$emit('deleted', { message: 'Runner deleted' });

      expect(mockRunnersQuery).toHaveBeenCalledTimes(2);

      expect(showToast).toHaveBeenCalledTimes(1);
      expect(showToast).toHaveBeenCalledWith('Runner deleted');
    });
  });

  describe('when a filter is preselected', () => {
    beforeEach(async () => {
      setWindowLocation(`?status[]=${STATUS_ACTIVE}&runner_type[]=${INSTANCE_TYPE}&tag[]=tag1`);

      createComponent();
      await waitForPromises();
    });

    it('sets the filters in the search bar', () => {
      expect(findRunnerFilteredSearchBar().props('value')).toEqual({
        runnerType: INSTANCE_TYPE,
        filters: [
          { type: 'status', value: { data: STATUS_ACTIVE, operator: '=' } },
          { type: 'tag', value: { data: 'tag1', operator: '=' } },
        ],
        sort: 'CREATED_DESC',
        pagination: { page: 1 },
      });
    });

    it('requests the runners with filter parameters', () => {
      expect(mockRunnersQuery).toHaveBeenLastCalledWith({
        status: STATUS_ACTIVE,
        type: INSTANCE_TYPE,
        tagList: ['tag1'],
        sort: DEFAULT_SORT,
        first: RUNNER_PAGE_SIZE,
      });
    });
  });

  describe('when a filter is selected by the user', () => {
    beforeEach(() => {
      findRunnerFilteredSearchBar().vm.$emit('input', {
        runnerType: null,
        filters: [{ type: PARAM_KEY_STATUS, value: { data: STATUS_ACTIVE, operator: '=' } }],
        sort: CREATED_ASC,
      });
    });

    it('updates the browser url', () => {
      expect(updateHistory).toHaveBeenLastCalledWith({
        title: expect.any(String),
        url: 'http://test.host/admin/runners?status[]=ACTIVE&sort=CREATED_ASC',
      });
    });

    it('requests the runners with filters', () => {
      expect(mockRunnersQuery).toHaveBeenLastCalledWith({
        status: STATUS_ACTIVE,
        sort: CREATED_ASC,
        first: RUNNER_PAGE_SIZE,
      });
    });
  });

  it('when runners have not loaded, shows a loading state', () => {
    createComponent();
    expect(findRunnerList().props('loading')).toBe(true);
  });

  describe('when no runners are found', () => {
    beforeEach(async () => {
      mockRunnersQuery = jest.fn().mockResolvedValue({
        data: {
          runners: { nodes: [] },
        },
      });
      createComponent();
      await waitForPromises();
    });

    it('shows a message for no results', async () => {
      expect(wrapper.text()).toContain('No runners found');
    });
  });

  describe('when runners query fails', () => {
    beforeEach(async () => {
      mockRunnersQuery = jest.fn().mockRejectedValue(new Error('Error!'));
      createComponent();
      await waitForPromises();
    });

    it('error is shown to the user', async () => {
      expect(createAlert).toHaveBeenCalledTimes(1);
    });

    it('error is reported to sentry', async () => {
      expect(captureException).toHaveBeenCalledWith({
        error: new Error('Error!'),
        component: 'AdminRunnersApp',
      });
    });
  });

  describe('Pagination', () => {
    beforeEach(async () => {
      mockRunnersQuery = jest.fn().mockResolvedValue(runnersDataPaginated);

      createComponent({ mountFn: mountExtended });
      await waitForPromises();
    });

    it('more pages can be selected', () => {
      expect(findRunnerPagination().text()).toMatchInterpolatedText('Previous Next');
    });

    it('cannot navigate to the previous page', () => {
      expect(findRunnerPaginationPrev().attributes('aria-disabled')).toBe('true');
    });

    it('navigates to the next page', async () => {
      await findRunnerPaginationNext().trigger('click');

      expect(mockRunnersQuery).toHaveBeenLastCalledWith({
        sort: CREATED_DESC,
        first: RUNNER_PAGE_SIZE,
        after: runnersDataPaginated.data.runners.pageInfo.endCursor,
      });
    });
  });
});
