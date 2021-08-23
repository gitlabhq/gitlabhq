import { createLocalVue, shallowMount, mount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
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
  PARAM_KEY_RUNNER_TYPE,
  STATUS_ACTIVE,
  RUNNER_PAGE_SIZE,
} from '~/runner/constants';
import getGroupRunnersQuery from '~/runner/graphql/get_group_runners.query.graphql';
import GroupRunnersApp from '~/runner/group_runners/group_runners_app.vue';
import { captureException } from '~/runner/sentry_utils';
import FilteredSearch from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import { groupRunnersData, groupRunnersDataPaginated } from '../mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

const mockGroupFullPath = 'group1';
const mockRegistrationToken = 'AABBCC';
const mockRunners = groupRunnersData.data.group.runners.nodes;
const mockGroupRunnersLimitedCount = mockRunners.length;

jest.mock('~/flash');
jest.mock('~/runner/sentry_utils');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  updateHistory: jest.fn(),
}));

describe('GroupRunnersApp', () => {
  let wrapper;
  let mockGroupRunnersQuery;

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
    const handlers = [[getGroupRunnersQuery, mockGroupRunnersQuery]];

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

    createComponent();
    await waitForPromises();
  });

  it('shows the runner type help', () => {
    expect(findRunnerTypeHelp().exists()).toBe(true);
  });

  it('shows the runner setup instructions', () => {
    expect(findRunnerManualSetupHelp().props('registrationToken')).toBe(mockRegistrationToken);
  });

  it('shows the runners list', () => {
    expect(findRunnerList().props('runners')).toEqual(groupRunnersData.data.group.runners.nodes);
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

    expect(findFilteredSearch().props('tokens')).toEqual([
      expect.objectContaining({
        type: PARAM_KEY_STATUS,
        options: expect.any(Array),
      }),
      expect.objectContaining({
        type: PARAM_KEY_RUNNER_TYPE,
        options: expect.any(Array),
      }),
    ]);
  });

  describe('shows the active runner count', () => {
    it('with a regular value', () => {
      createComponent({ mountFn: mount });

      expect(findRunnerFilteredSearchBar().text()).toMatch(
        `Runners in this group: ${mockGroupRunnersLimitedCount}`,
      );
    });

    it('at the limit', () => {
      createComponent({ props: { groupRunnersLimitedCount: 1000 }, mountFn: mount });

      expect(findRunnerFilteredSearchBar().text()).toMatch(`Runners in this group: 1,000`);
    });

    it('over the limit', () => {
      createComponent({ props: { groupRunnersLimitedCount: 1001 }, mountFn: mount });

      expect(findRunnerFilteredSearchBar().text()).toMatch(`Runners in this group: 1,000+`);
    });
  });

  describe('when a filter is preselected', () => {
    beforeEach(async () => {
      setWindowLocation(`?status[]=${STATUS_ACTIVE}&runner_type[]=${INSTANCE_TYPE}`);

      createComponent();
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
    beforeEach(() => {
      findRunnerFilteredSearchBar().vm.$emit('input', {
        filters: [{ type: PARAM_KEY_STATUS, value: { data: STATUS_ACTIVE, operator: '=' } }],
        sort: CREATED_ASC,
      });
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
      expect(createFlash).toHaveBeenCalledTimes(1);
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
