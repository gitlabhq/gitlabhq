import * as Sentry from '@sentry/browser';
import { createLocalVue, mount, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import { updateHistory } from '~/lib/utils/url_utility';

import RunnerFilteredSearchBar from '~/runner/components/runner_filtered_search_bar.vue';
import RunnerList from '~/runner/components/runner_list.vue';
import RunnerManualSetupHelp from '~/runner/components/runner_manual_setup_help.vue';
import RunnerPagination from '~/runner/components/runner_pagination.vue';
import RunnerTypeHelp from '~/runner/components/runner_type_help.vue';

import {
  CREATED_ASC,
  CREATED_DESC,
  DEFAULT_SORT,
  INSTANCE_TYPE,
  PARAM_KEY_STATUS,
  STATUS_ACTIVE,
  RUNNER_PAGE_SIZE,
} from '~/runner/constants';
import getRunnersQuery from '~/runner/graphql/get_runners.query.graphql';
import RunnerListApp from '~/runner/runner_list/runner_list_app.vue';

import { runnersData } from '../mock_data';

const mockRegistrationToken = 'MOCK_REGISTRATION_TOKEN';
const mockActiveRunnersCount = 2;
const mocKRunners = runnersData.data.runners.nodes;
const mockPageInfo = runnersData.data.runners.pageInfo;

jest.mock('@sentry/browser');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  updateHistory: jest.fn(),
}));

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('RunnerListApp', () => {
  let wrapper;
  let mockRunnersQuery;
  let originalLocation;

  const findRunnerTypeHelp = () => wrapper.findComponent(RunnerTypeHelp);
  const findRunnerManualSetupHelp = () => wrapper.findComponent(RunnerManualSetupHelp);
  const findRunnerList = () => wrapper.findComponent(RunnerList);
  const findRunnerPagination = () => wrapper.findComponent(RunnerPagination);
  const findRunnerFilteredSearchBar = () => wrapper.findComponent(RunnerFilteredSearchBar);

  const createComponentWithApollo = ({ props = {}, mountFn = shallowMount } = {}) => {
    const handlers = [[getRunnersQuery, mockRunnersQuery]];

    wrapper = mountFn(RunnerListApp, {
      localVue,
      apolloProvider: createMockApollo(handlers),
      propsData: {
        activeRunnersCount: mockActiveRunnersCount,
        registrationToken: mockRegistrationToken,
        ...props,
      },
    });
  };

  const setQuery = (query) => {
    window.location.href = `${TEST_HOST}/admin/runners/${query}`;
    window.location.search = query;
  };

  beforeAll(() => {
    originalLocation = window.location;
    Object.defineProperty(window, 'location', { writable: true, value: { href: '', search: '' } });
  });

  afterAll(() => {
    window.location = originalLocation;
  });

  beforeEach(async () => {
    setQuery('');

    Sentry.withScope.mockImplementation((fn) => {
      const scope = { setTag: jest.fn() };
      fn(scope);
    });

    mockRunnersQuery = jest.fn().mockResolvedValue(runnersData);
    createComponentWithApollo();
    await waitForPromises();
  });

  afterEach(() => {
    mockRunnersQuery.mockReset();
    wrapper.destroy();
  });

  it('shows the runners list', () => {
    expect(mocKRunners).toMatchObject(findRunnerList().props('runners'));
  });

  it('requests the runners with no filters', () => {
    expect(mockRunnersQuery).toHaveBeenLastCalledWith({
      status: undefined,
      type: undefined,
      sort: DEFAULT_SORT,
      first: RUNNER_PAGE_SIZE,
    });
  });

  it('shows the runner type help', () => {
    expect(findRunnerTypeHelp().exists()).toBe(true);
  });

  it('shows the runner setup instructions', () => {
    expect(findRunnerManualSetupHelp().exists()).toBe(true);
    expect(findRunnerManualSetupHelp().props('registrationToken')).toBe(mockRegistrationToken);
  });

  describe('when a filter is preselected', () => {
    beforeEach(async () => {
      window.location.search = `?status[]=${STATUS_ACTIVE}&runner_type[]=${INSTANCE_TYPE}`;

      createComponentWithApollo();
      await waitForPromises();
    });

    it('sets the filters in the search bar', () => {
      expect(findRunnerFilteredSearchBar().props('value')).toEqual({
        filters: [
          { type: 'status', value: { data: STATUS_ACTIVE, operator: '=' } },
          { type: 'runner_type', value: { data: INSTANCE_TYPE, operator: '=' } },
        ],
        sort: 'CREATED_DESC',
        pagination: { page: 1 },
      });
    });

    it('requests the runners with filter parameters', () => {
      expect(mockRunnersQuery).toHaveBeenLastCalledWith({
        status: STATUS_ACTIVE,
        type: INSTANCE_TYPE,
        sort: DEFAULT_SORT,
        first: RUNNER_PAGE_SIZE,
      });
    });
  });

  describe('when a filter is selected by the user', () => {
    beforeEach(() => {
      findRunnerFilteredSearchBar().vm.$emit('input', {
        filters: [{ type: PARAM_KEY_STATUS, value: { data: 'ACTIVE', operator: '=' } }],
        sort: CREATED_ASC,
      });
    });

    it('updates the browser url', () => {
      expect(updateHistory).toHaveBeenLastCalledWith({
        title: expect.any(String),
        url: 'http://test.host/admin/runners/?status[]=ACTIVE&sort=CREATED_ASC',
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

  describe('when no runners are found', () => {
    beforeEach(async () => {
      mockRunnersQuery = jest.fn().mockResolvedValue({ data: { runners: { nodes: [] } } });
      createComponentWithApollo();
      await waitForPromises();
    });

    it('shows a message for no results', async () => {
      expect(wrapper.text()).toContain('No runners found');
    });
  });

  it('when runners have not loaded, shows a loading state', () => {
    createComponentWithApollo();
    expect(findRunnerList().props('loading')).toBe(true);
  });

  describe('when runners query fails', () => {
    beforeEach(async () => {
      mockRunnersQuery = jest.fn().mockRejectedValue(new Error());
      createComponentWithApollo();

      await waitForPromises();
    });

    it('error is reported to sentry', async () => {
      expect(Sentry.withScope).toHaveBeenCalled();
      expect(Sentry.captureException).toHaveBeenCalled();
    });
  });

  describe('Pagination', () => {
    beforeEach(() => {
      createComponentWithApollo({ mountFn: mount });
    });

    it('more pages can be selected', () => {
      expect(findRunnerPagination().text()).toMatchInterpolatedText('Prev Next');
    });

    it('cannot navigate to the previous page', () => {
      expect(findRunnerPagination().find('[aria-disabled]').text()).toBe('Prev');
    });

    it('navigates to the next page', async () => {
      const nextPageBtn = findRunnerPagination().find('a');
      expect(nextPageBtn.text()).toBe('Next');

      await nextPageBtn.trigger('click');

      expect(mockRunnersQuery).toHaveBeenLastCalledWith({
        sort: CREATED_DESC,
        first: RUNNER_PAGE_SIZE,
        after: expect.any(String),
      });

      expect(mockRunnersQuery).toHaveBeenLastCalledWith({
        sort: CREATED_DESC,
        first: RUNNER_PAGE_SIZE,
        after: mockPageInfo.endCursor,
      });
    });
  });
});
