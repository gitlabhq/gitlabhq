import { nextTick } from 'vue';
import { GlLink } from '@gitlab/ui';
import { createLocalVue, shallowMount, mount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/flash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { updateHistory } from '~/lib/utils/url_utility';

import RunnerFilteredSearchBar from '~/runner/components/runner_filtered_search_bar.vue';
import RunnerList from '~/runner/components/runner_list.vue';
import RunnerStats from '~/runner/components/stat/runner_stats.vue';
import RegistrationDropdown from '~/runner/components/registration/registration_dropdown.vue';
import RunnerPagination from '~/runner/components/runner_pagination.vue';

import {
  CREATED_ASC,
  CREATED_DESC,
  DEFAULT_SORT,
  INSTANCE_TYPE,
  GROUP_TYPE,
  PARAM_KEY_STATUS,
  STATUS_ACTIVE,
  RUNNER_PAGE_SIZE,
} from '~/runner/constants';
import getGroupRunnersQuery from '~/runner/graphql/get_group_runners.query.graphql';
import getGroupRunnersCountQuery from '~/runner/graphql/get_group_runners_count.query.graphql';
import GroupRunnersApp from '~/runner/group_runners/group_runners_app.vue';
import { captureException } from '~/runner/sentry_utils';
import FilteredSearch from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import { groupRunnersData, groupRunnersDataPaginated, groupRunnersCountData } from '../mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

const mockGroupFullPath = 'group1';
const mockRegistrationToken = 'AABBCC';
const mockGroupRunnersLimitedCount = groupRunnersData.data.group.runners.edges.length;

jest.mock('~/flash');
jest.mock('~/runner/sentry_utils');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  updateHistory: jest.fn(),
}));

describe('GroupRunnersApp', () => {
  let wrapper;
  let mockGroupRunnersQuery;
  let mockGroupRunnersCountQuery;

  const findRunnerStats = () => wrapper.findComponent(RunnerStats);
  const findRegistrationDropdown = () => wrapper.findComponent(RegistrationDropdown);
  const findRunnerList = () => wrapper.findComponent(RunnerList);
  const findRunnerPagination = () => extendedWrapper(wrapper.findComponent(RunnerPagination));
  const findRunnerPaginationPrev = () =>
    findRunnerPagination().findByLabelText('Go to previous page');
  const findRunnerPaginationNext = () => findRunnerPagination().findByLabelText('Go to next page');
  const findRunnerFilteredSearchBar = () => wrapper.findComponent(RunnerFilteredSearchBar);
  const findFilteredSearch = () => wrapper.findComponent(FilteredSearch);

  const createComponent = ({ props = {}, mountFn = shallowMount } = {}) => {
    const handlers = [
      [getGroupRunnersQuery, mockGroupRunnersQuery],
      [getGroupRunnersCountQuery, mockGroupRunnersCountQuery],
    ];

    wrapper = mountFn(GroupRunnersApp, {
      localVue,
      apolloProvider: createMockApollo(handlers),
      propsData: {
        registrationToken: mockRegistrationToken,
        groupFullPath: mockGroupFullPath,
        groupRunnersLimitedCount: mockGroupRunnersLimitedCount,
        ...props,
      },
    });
  };

  beforeEach(async () => {
    setWindowLocation(`/groups/${mockGroupFullPath}/-/runners`);

    mockGroupRunnersQuery = jest.fn().mockResolvedValue(groupRunnersData);
    mockGroupRunnersCountQuery = jest.fn().mockResolvedValue(groupRunnersCountData);

    createComponent();
    await waitForPromises();
  });

  it('shows total runner counts', async () => {
    createComponent({ mountFn: mount });

    await waitForPromises();

    const stats = findRunnerStats().text();

    expect(stats).toMatch('Online runners 2');
    expect(stats).toMatch('Offline runners 2');
    expect(stats).toMatch('Stale runners 2');
  });

  it('shows the runner setup instructions', () => {
    expect(findRegistrationDropdown().props('registrationToken')).toBe(mockRegistrationToken);
    expect(findRegistrationDropdown().props('type')).toBe(GROUP_TYPE);
  });

  it('shows the runners list', () => {
    const runners = findRunnerList().props('runners');
    expect(runners).toEqual(groupRunnersData.data.group.runners.edges.map(({ node }) => node));
  });

  it('runner item links to the runner group page', async () => {
    const { webUrl, node } = groupRunnersData.data.group.runners.edges[0];
    const { id, shortSha } = node;

    createComponent({ mountFn: mount });

    await waitForPromises();

    const runnerLink = wrapper.find('tr [data-testid="td-summary"]').find(GlLink);
    expect(runnerLink.text()).toBe(`#${getIdFromGraphQLId(id)} (${shortSha})`);
    expect(runnerLink.attributes('href')).toBe(webUrl);
  });

  it('requests the runners with group path and no other filters', () => {
    expect(mockGroupRunnersQuery).toHaveBeenLastCalledWith({
      groupFullPath: mockGroupFullPath,
      status: undefined,
      type: undefined,
      sort: DEFAULT_SORT,
      first: RUNNER_PAGE_SIZE,
    });
  });

  it('sets tokens in the filtered search', () => {
    createComponent({ mountFn: mount });

    const tokens = findFilteredSearch().props('tokens');

    expect(tokens).toHaveLength(1);
    expect(tokens[0]).toEqual(
      expect.objectContaining({
        type: PARAM_KEY_STATUS,
        options: expect.any(Array),
      }),
    );
  });

  describe('when a filter is preselected', () => {
    beforeEach(async () => {
      setWindowLocation(`?status[]=${STATUS_ACTIVE}&runner_type[]=${INSTANCE_TYPE}`);

      createComponent();
      await waitForPromises();
    });

    it('sets the filters in the search bar', () => {
      expect(findRunnerFilteredSearchBar().props('value')).toEqual({
        runnerType: INSTANCE_TYPE,
        filters: [{ type: 'status', value: { data: STATUS_ACTIVE, operator: '=' } }],
        sort: 'CREATED_DESC',
        pagination: { page: 1 },
      });
    });

    it('requests the runners with filter parameters', () => {
      expect(mockGroupRunnersQuery).toHaveBeenLastCalledWith({
        groupFullPath: mockGroupFullPath,
        status: STATUS_ACTIVE,
        type: INSTANCE_TYPE,
        sort: DEFAULT_SORT,
        first: RUNNER_PAGE_SIZE,
      });
    });
  });

  describe('when a filter is selected by the user', () => {
    beforeEach(async () => {
      findRunnerFilteredSearchBar().vm.$emit('input', {
        runnerType: null,
        filters: [{ type: PARAM_KEY_STATUS, value: { data: STATUS_ACTIVE, operator: '=' } }],
        sort: CREATED_ASC,
      });

      await nextTick();
    });

    it('updates the browser url', () => {
      expect(updateHistory).toHaveBeenLastCalledWith({
        title: expect.any(String),
        url: 'http://test.host/groups/group1/-/runners?status[]=ACTIVE&sort=CREATED_ASC',
      });
    });

    it('requests the runners with filters', () => {
      expect(mockGroupRunnersQuery).toHaveBeenLastCalledWith({
        groupFullPath: mockGroupFullPath,
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
      mockGroupRunnersQuery = jest.fn().mockResolvedValue({
        data: {
          group: {
            runners: { nodes: [] },
          },
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
      mockGroupRunnersQuery = jest.fn().mockRejectedValue(new Error('Error!'));
      createComponent();
    });

    it('error is shown to the user', async () => {
      expect(createAlert).toHaveBeenCalledTimes(1);
    });

    it('error is reported to sentry', async () => {
      expect(captureException).toHaveBeenCalledWith({
        error: new Error('Network error: Error!'),
        component: 'GroupRunnersApp',
      });
    });
  });

  describe('Pagination', () => {
    beforeEach(() => {
      mockGroupRunnersQuery = jest.fn().mockResolvedValue(groupRunnersDataPaginated);

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

      expect(mockGroupRunnersQuery).toHaveBeenLastCalledWith({
        groupFullPath: mockGroupFullPath,
        sort: CREATED_DESC,
        first: RUNNER_PAGE_SIZE,
        after: groupRunnersDataPaginated.data.group.runners.pageInfo.endCursor,
      });
    });
  });
});
