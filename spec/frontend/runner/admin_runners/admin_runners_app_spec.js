import { createLocalVue, mount, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import { updateHistory } from '~/lib/utils/url_utility';

import AdminRunnersApp from '~/runner/admin_runners/admin_runners_app.vue';
import RunnerFilteredSearchBar from '~/runner/components/runner_filtered_search_bar.vue';
import RunnerList from '~/runner/components/runner_list.vue';
import RunnerManualSetupHelp from '~/runner/components/runner_manual_setup_help.vue';
import RunnerPagination from '~/runner/components/runner_pagination.vue';
import RunnerTypeHelp from '~/runner/components/runner_type_help.vue';

import {
  ADMIN_FILTERED_SEARCH_NAMESPACE,
  CREATED_ASC,
  CREATED_DESC,
  DEFAULT_SORT,
  INSTANCE_TYPE,
  PARAM_KEY_STATUS,
  PARAM_KEY_RUNNER_TYPE,
  PARAM_KEY_TAG,
  STATUS_ACTIVE,
  RUNNER_PAGE_SIZE,
} from '~/runner/constants';
import getRunnersQuery from '~/runner/graphql/get_runners.query.graphql';
import { captureException } from '~/runner/sentry_utils';
import FilteredSearch from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

import { runnersData, runnersDataPaginated } from '../mock_data';

const mockRegistrationToken = 'MOCK_REGISTRATION_TOKEN';
const mockActiveRunnersCount = 2;

jest.mock('~/flash');
jest.mock('~/runner/sentry_utils');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  updateHistory: jest.fn(),
}));

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('AdminRunnersApp', () => {
  let wrapper;
  let mockRunnersQuery;

  const findRunnerTypeHelp = () => wrapper.findComponent(RunnerTypeHelp);
  const findRunnerManualSetupHelp = () => wrapper.findComponent(RunnerManualSetupHelp);
  const findRunnerList = () => wrapper.findComponent(RunnerList);
  const findRunnerPagination = () => extendedWrapper(wrapper.findComponent(RunnerPagination));
  const findRunnerPaginationPrev = () =>
    findRunnerPagination().findByLabelText('Go to previous page');
  const findRunnerPaginationNext = () => findRunnerPagination().findByLabelText('Go to next page');
  const findRunnerFilteredSearchBar = () => wrapper.findComponent(RunnerFilteredSearchBar);
  const findFilteredSearch = () => wrapper.findComponent(FilteredSearch);

  const createComponent = ({ props = {}, mountFn = shallowMount } = {}) => {
    const handlers = [[getRunnersQuery, mockRunnersQuery]];

    wrapper = mountFn(AdminRunnersApp, {
      localVue,
      apolloProvider: createMockApollo(handlers),
      propsData: {
        activeRunnersCount: mockActiveRunnersCount,
        registrationToken: mockRegistrationToken,
        ...props,
      },
    });
  };

  beforeEach(async () => {
    setWindowLocation('/admin/runners');

    mockRunnersQuery = jest.fn().mockResolvedValue(runnersData);
    createComponent();
    await waitForPromises();
  });

  afterEach(() => {
    mockRunnersQuery.mockReset();
    wrapper.destroy();
  });

  it('shows the runner type help', () => {
    expect(findRunnerTypeHelp().exists()).toBe(true);
  });

  it('shows the runner setup instructions', () => {
    expect(findRunnerManualSetupHelp().props('registrationToken')).toBe(mockRegistrationToken);
  });

  it('shows the runners list', () => {
    expect(findRunnerList().props('runners')).toEqual(runnersData.data.runners.nodes);
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
    createComponent({ mountFn: mount });

    expect(findFilteredSearch().props('tokens')).toEqual([
      expect.objectContaining({
        type: PARAM_KEY_STATUS,
        options: expect.any(Array),
      }),
      expect.objectContaining({
        type: PARAM_KEY_RUNNER_TYPE,
        options: expect.any(Array),
      }),
      expect.objectContaining({
        type: PARAM_KEY_TAG,
        recentTokenValuesStorageKey: `${ADMIN_FILTERED_SEARCH_NAMESPACE}-recent-tags`,
      }),
    ]);
  });

  it('shows the active runner count', () => {
    createComponent({ mountFn: mount });

    expect(findRunnerFilteredSearchBar().text()).toMatch(
      `Runners currently online: ${mockActiveRunnersCount}`,
    );
  });

  describe('when a filter is preselected', () => {
    beforeEach(async () => {
      setWindowLocation(`?status[]=${STATUS_ACTIVE}&runner_type[]=${INSTANCE_TYPE}&tag[]=tag1`);

      createComponent();
      await waitForPromises();
    });

    it('sets the filters in the search bar', () => {
      expect(findRunnerFilteredSearchBar().props('value')).toEqual({
        filters: [
          { type: 'status', value: { data: STATUS_ACTIVE, operator: '=' } },
          { type: 'runner_type', value: { data: INSTANCE_TYPE, operator: '=' } },
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
    });

    it('shows a message for no results', async () => {
      expect(wrapper.text()).toContain('No runners found');
    });
  });

  describe('when runners query fails', () => {
    beforeEach(() => {
      mockRunnersQuery = jest.fn().mockRejectedValue(new Error('Error!'));
      createComponent();
    });

    it('error is shown to the user', async () => {
      expect(createFlash).toHaveBeenCalledTimes(1);
    });

    it('error is reported to sentry', async () => {
      expect(captureException).toHaveBeenCalledWith({
        error: new Error('Network error: Error!'),
        component: 'AdminRunnersApp',
      });
    });
  });

  describe('Pagination', () => {
    beforeEach(() => {
      mockRunnersQuery = jest.fn().mockResolvedValue(runnersDataPaginated);

      createComponent({ mountFn: mount });
    });

    it('more pages can be selected', () => {
      expect(findRunnerPagination().text()).toMatchInterpolatedText('Prev Next');
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
