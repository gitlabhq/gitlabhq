import Vue, { nextTick } from 'vue';
import { GlButton, GlLink, GlToast } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import {
  extendedWrapper,
  shallowMountExtended,
  mountExtended,
} from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { updateHistory } from '~/lib/utils/url_utility';
import { upgradeStatusTokenConfig } from 'ee_else_ce/ci/runner/components/search_tokens/upgrade_status_token_config';
import { createLocalState } from '~/ci/runner/graphql/list/local_state';

import RunnerTypeTabs from '~/ci/runner/components/runner_type_tabs.vue';
import RunnerFilteredSearchBar from '~/ci/runner/components/runner_filtered_search_bar.vue';
import RunnerList from '~/ci/runner/components/runner_list.vue';
import RunnerListEmptyState from '~/ci/runner/components/runner_list_empty_state.vue';
import RunnerStats from '~/ci/runner/components/stat/runner_stats.vue';
import RunnerActionsCell from '~/ci/runner/components/cells/runner_actions_cell.vue';
import RegistrationDropdown from '~/ci/runner/components/registration/registration_dropdown.vue';
import RunnerPagination from '~/ci/runner/components/runner_pagination.vue';
import RunnerMembershipToggle from '~/ci/runner/components/runner_membership_toggle.vue';
import RunnerJobStatusBadge from '~/ci/runner/components/runner_job_status_badge.vue';

import {
  CREATED_ASC,
  CREATED_DESC,
  DEFAULT_SORT,
  I18N_STATUS_ONLINE,
  I18N_STATUS_OFFLINE,
  I18N_STATUS_STALE,
  INSTANCE_TYPE,
  GROUP_TYPE,
  JOBS_ROUTE_PATH,
  PARAM_KEY_PAUSED,
  PARAM_KEY_STATUS,
  PARAM_KEY_TAG,
  STATUS_ONLINE,
  STATUS_OFFLINE,
  STATUS_STALE,
  MEMBERSHIP_ALL_AVAILABLE,
  MEMBERSHIP_DESCENDANTS,
  RUNNER_PAGE_SIZE,
  I18N_EDIT,
} from '~/ci/runner/constants';
import groupRunnersQuery from 'ee_else_ce/ci/runner/graphql/list/group_runners.query.graphql';
import groupRunnersCountQuery from 'ee_else_ce/ci/runner/graphql/list/group_runners_count.query.graphql';
import runnerJobCountQuery from '~/ci/runner/graphql/list/runner_job_count.query.graphql';
import GroupRunnersApp from '~/ci/runner/group_runners/group_runners_app.vue';
import { captureException } from '~/ci/runner/sentry_utils';
import {
  groupRunnersData,
  groupRunnersDataPaginated,
  groupRunnersCountData,
  runnerJobCountData,
  mockRegistrationToken,
  newRunnerPath,
  emptyPageInfo,
} from '../mock_data';

Vue.use(VueApollo);
Vue.use(GlToast);

const mockGroupFullPath = 'group1';
const mockGroupRunnersEdges = groupRunnersData.data.group.runners.edges;
const mockGroupRunnersCount = mockGroupRunnersEdges.length;

const mockGroupRunnersHandler = jest.fn();
const mockGroupRunnersCountHandler = jest.fn();
const mockRunnerJobCountHandler = jest.fn();

jest.mock('~/alert');
jest.mock('~/ci/runner/sentry_utils');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  updateHistory: jest.fn(),
}));

describe('GroupRunnersApp', () => {
  let wrapper;
  const showToast = jest.fn();

  const findRunnerStats = () => wrapper.findComponent(RunnerStats);
  const findRunnerActionsCell = () => wrapper.findComponent(RunnerActionsCell);
  const findRegistrationDropdown = () => wrapper.findComponent(RegistrationDropdown);
  const findNewRunnerBtn = () => wrapper.findByText('New group runner');
  const findRunnerTypeTabs = () => wrapper.findComponent(RunnerTypeTabs);
  const findRunnerList = () => wrapper.findComponent(RunnerList);
  const findRunnerListEmptyState = () => wrapper.findComponent(RunnerListEmptyState);
  const findRunnerRow = (id) => extendedWrapper(wrapper.findByTestId(`runner-row-${id}`));
  const findRunnerPagination = () => extendedWrapper(wrapper.findComponent(RunnerPagination));
  const findRunnerPaginationNext = () => findRunnerPagination().findByText('Next');
  const findRunnerFilteredSearchBar = () => wrapper.findComponent(RunnerFilteredSearchBar);
  const findRunnerMembershipToggle = () => wrapper.findComponent(RunnerMembershipToggle);

  const createComponent = ({
    props = {},
    provide = {},
    mountFn = shallowMountExtended,
    stubs,
    ...options
  } = {}) => {
    const { cacheConfig, localMutations } = createLocalState();

    const handlers = [
      [groupRunnersQuery, mockGroupRunnersHandler],
      [groupRunnersCountQuery, mockGroupRunnersCountHandler],
      [runnerJobCountQuery, mockRunnerJobCountHandler],
    ];

    wrapper = mountFn(GroupRunnersApp, {
      apolloProvider: createMockApollo(handlers, {}, cacheConfig),
      propsData: {
        registrationToken: mockRegistrationToken,
        groupFullPath: mockGroupFullPath,
        newRunnerPath,
        ...props,
      },
      provide: {
        localMutations,
        ...provide,
      },
      stubs: {
        RunnerFilteredSearchBar: true,
        ...stubs,
      },
      mocks: {
        $toast: {
          show: showToast,
        },
      },
      ...options,
    });

    return waitForPromises();
  };

  beforeEach(() => {
    mockGroupRunnersHandler.mockResolvedValue(groupRunnersData);
    mockGroupRunnersCountHandler.mockResolvedValue(groupRunnersCountData);
    mockRunnerJobCountHandler.mockResolvedValue(runnerJobCountData);
  });

  afterEach(() => {
    mockGroupRunnersHandler.mockReset();
    mockGroupRunnersCountHandler.mockReset();
    mockRunnerJobCountHandler.mockReset();
  });

  it('shows the runner tabs with a runner count for each type', async () => {
    await createComponent({ mountFn: mountExtended });

    const tabs = findRunnerTypeTabs().text().replace(/\s+/g, ' ');
    expect(tabs).toContain(`All ${mockGroupRunnersCount}`);
    expect(tabs).toContain(`Group ${mockGroupRunnersCount}`);
    expect(tabs).toContain(`Project ${mockGroupRunnersCount}`);
    expect(tabs).not.toContain('Instance');
  });

  it('shows the runner setup instructions', () => {
    createComponent();

    expect(findRegistrationDropdown().props('registrationToken')).toBe(mockRegistrationToken);
    expect(findRegistrationDropdown().props('type')).toBe(GROUP_TYPE);
  });

  describe('show all available runners toggle', () => {
    it('shows the membership toggle', () => {
      createComponent();
      expect(findRunnerMembershipToggle().exists()).toBe(true);
    });

    it('sets the membership toggle', () => {
      setWindowLocation(`?membership[]=${MEMBERSHIP_ALL_AVAILABLE}`);

      createComponent();

      expect(findRunnerMembershipToggle().props('value')).toBe(MEMBERSHIP_ALL_AVAILABLE);
    });

    it('requests filter', async () => {
      createComponent();
      findRunnerMembershipToggle().vm.$emit('input', MEMBERSHIP_ALL_AVAILABLE);

      await waitForPromises();

      expect(mockGroupRunnersHandler).toHaveBeenLastCalledWith(
        expect.objectContaining({
          membership: MEMBERSHIP_ALL_AVAILABLE,
        }),
      );
    });
  });

  it('shows total runner counts', async () => {
    await createComponent({ mountFn: mountExtended });

    expect(mockGroupRunnersCountHandler).toHaveBeenCalledWith({
      status: STATUS_ONLINE,
      membership: MEMBERSHIP_DESCENDANTS,
      groupFullPath: mockGroupFullPath,
    });
    expect(mockGroupRunnersCountHandler).toHaveBeenCalledWith({
      status: STATUS_OFFLINE,
      membership: MEMBERSHIP_DESCENDANTS,
      groupFullPath: mockGroupFullPath,
    });
    expect(mockGroupRunnersCountHandler).toHaveBeenCalledWith({
      status: STATUS_STALE,
      membership: MEMBERSHIP_DESCENDANTS,
      groupFullPath: mockGroupFullPath,
    });

    const text = findRunnerStats().text();
    expect(text).toContain(`${I18N_STATUS_ONLINE} ${mockGroupRunnersCount}`);
    expect(text).toContain(`${I18N_STATUS_OFFLINE} ${mockGroupRunnersCount}`);
    expect(text).toContain(`${I18N_STATUS_STALE} ${mockGroupRunnersCount}`);
  });

  it('shows the runners list', async () => {
    await createComponent();

    const runners = findRunnerList().props('runners');
    expect(runners).toEqual(mockGroupRunnersEdges.map(({ node }) => node));
  });

  it('requests the runners with group path and no other filters', async () => {
    await createComponent();

    expect(mockGroupRunnersHandler).toHaveBeenLastCalledWith({
      groupFullPath: mockGroupFullPath,
      status: undefined,
      type: undefined,
      membership: MEMBERSHIP_DESCENDANTS,
      sort: DEFAULT_SORT,
      first: RUNNER_PAGE_SIZE,
    });
  });

  it('sets tokens in the filtered search', () => {
    createComponent();

    const tokens = findRunnerFilteredSearchBar().props('tokens');

    expect(tokens).toEqual([
      expect.objectContaining({
        type: PARAM_KEY_PAUSED,
        options: expect.any(Array),
      }),
      expect.objectContaining({
        type: PARAM_KEY_STATUS,
        options: expect.any(Array),
      }),
      expect.objectContaining({
        type: PARAM_KEY_TAG,
        suggestionsDisabled: true,
      }),
      upgradeStatusTokenConfig,
    ]);
  });

  describe('Single runner row', () => {
    const { webUrl, editUrl, node } = mockGroupRunnersEdges[0];
    const { id: graphqlId, shortSha, jobExecutionStatus } = node;
    const id = getIdFromGraphQLId(graphqlId);
    const COUNT_QUERIES = 6; // Smart queries that display a filtered count of runners
    const FILTERED_COUNT_QUERIES = 6; // Smart queries that display a count of runners in tabs and single stats

    beforeEach(async () => {
      await createComponent({ mountFn: mountExtended });
    });

    it('Shows job status and links to jobs', () => {
      const badge = findRunnerRow(id).findByTestId('td-status').findComponent(RunnerJobStatusBadge);

      expect(badge.props('jobStatus')).toBe(jobExecutionStatus);
      expect(badge.attributes('href')).toBe(`${webUrl}#${JOBS_ROUTE_PATH}`);
    });

    it('view link is displayed correctly', () => {
      const viewLink = findRunnerRow(id).findByTestId('td-summary').findComponent(GlLink);

      expect(viewLink.text()).toBe(`#${id} (${shortSha})`);
      expect(viewLink.attributes('href')).toBe(webUrl);
    });

    it('edit link is displayed correctly', () => {
      const editLink = findRunnerRow(id).findByTestId('td-actions').findComponent(GlButton);

      expect(editLink.attributes()).toMatchObject({
        'aria-label': I18N_EDIT,
        href: editUrl,
      });
    });

    it('When runner is paused or unpaused, some data is refetched', () => {
      expect(mockGroupRunnersCountHandler).toHaveBeenCalledTimes(COUNT_QUERIES);

      findRunnerActionsCell().vm.$emit('toggledPaused');

      expect(mockGroupRunnersCountHandler).toHaveBeenCalledTimes(
        COUNT_QUERIES + FILTERED_COUNT_QUERIES,
      );

      expect(showToast).toHaveBeenCalledTimes(0);
    });

    it('When runner is deleted, data is refetched and a toast message is shown', () => {
      findRunnerActionsCell().vm.$emit('deleted', { message: 'Runner deleted' });

      expect(showToast).toHaveBeenCalledTimes(1);
      expect(showToast).toHaveBeenCalledWith('Runner deleted');
    });
  });

  describe('when a filter is preselected', () => {
    beforeEach(async () => {
      setWindowLocation(`?status[]=${STATUS_ONLINE}&runner_type[]=${INSTANCE_TYPE}`);

      await createComponent({ mountFn: mountExtended });
    });

    it('sets the filters in the search bar', () => {
      expect(findRunnerFilteredSearchBar().props('value')).toEqual({
        runnerType: INSTANCE_TYPE,
        membership: MEMBERSHIP_DESCENDANTS,
        filters: [{ type: 'status', value: { data: STATUS_ONLINE, operator: '=' } }],
        sort: 'CREATED_DESC',
        pagination: {},
      });
    });

    it('requests the runners with filter parameters', () => {
      expect(mockGroupRunnersHandler).toHaveBeenLastCalledWith({
        groupFullPath: mockGroupFullPath,
        status: STATUS_ONLINE,
        type: INSTANCE_TYPE,
        membership: MEMBERSHIP_DESCENDANTS,
        sort: DEFAULT_SORT,
        first: RUNNER_PAGE_SIZE,
      });
    });

    it('fetches count results for requested status', () => {
      expect(mockGroupRunnersCountHandler).toHaveBeenCalledWith({
        groupFullPath: mockGroupFullPath,
        type: INSTANCE_TYPE,
        membership: MEMBERSHIP_DESCENDANTS,
        status: STATUS_ONLINE,
      });
    });
  });

  describe('when a filter is selected by the user', () => {
    beforeEach(async () => {
      await createComponent({ mountFn: mountExtended });

      findRunnerFilteredSearchBar().vm.$emit('input', {
        runnerType: null,
        membership: MEMBERSHIP_DESCENDANTS,
        filters: [{ type: PARAM_KEY_STATUS, value: { data: STATUS_ONLINE, operator: '=' } }],
        sort: CREATED_ASC,
      });

      await nextTick();
    });

    it('updates the browser url', () => {
      expect(updateHistory).toHaveBeenLastCalledWith({
        title: expect.any(String),
        url: expect.stringContaining('?status[]=ONLINE&sort=CREATED_ASC'),
      });
    });

    it('requests the runners with filters', () => {
      expect(mockGroupRunnersHandler).toHaveBeenLastCalledWith({
        groupFullPath: mockGroupFullPath,
        status: STATUS_ONLINE,
        membership: MEMBERSHIP_DESCENDANTS,
        sort: CREATED_ASC,
        first: RUNNER_PAGE_SIZE,
      });
    });

    it('fetches count results for requested status', () => {
      expect(mockGroupRunnersCountHandler).toHaveBeenCalledWith({
        groupFullPath: mockGroupFullPath,
        status: STATUS_ONLINE,
        membership: MEMBERSHIP_DESCENDANTS,
      });
    });
  });

  it('when runners have not loaded, shows a loading state', () => {
    createComponent();
    expect(findRunnerList().props('loading')).toBe(true);
    expect(findRunnerPagination().attributes('disabled')).toBeDefined();
  });

  it('runners can be deleted in bulk', () => {
    createComponent();
    expect(findRunnerList().props('checkable')).toBe(true);
  });

  describe('when no runners are found', () => {
    beforeEach(async () => {
      mockGroupRunnersHandler.mockResolvedValue({
        data: {
          group: {
            id: '1',
            runners: {
              edges: [],
              pageInfo: emptyPageInfo,
            },
          },
        },
      });
      await createComponent();
    });

    it('shows no errors', () => {
      expect(createAlert).not.toHaveBeenCalled();
    });

    it('shows an empty state', () => {
      expect(findRunnerListEmptyState().props()).toMatchObject({
        isSearchFiltered: false,
        newRunnerPath,
        registrationToken: mockRegistrationToken,
      });
    });
  });

  describe('when runners query fails', () => {
    beforeEach(async () => {
      mockGroupRunnersHandler.mockRejectedValue(new Error('Error!'));
      await createComponent();
    });

    it('error is shown to the user', () => {
      expect(createAlert).toHaveBeenCalledTimes(1);
    });

    it('error is reported to sentry', () => {
      expect(captureException).toHaveBeenCalledWith({
        error: new Error('Error!'),
        component: 'GroupRunnersApp',
      });
    });
  });

  describe('Pagination', () => {
    const { pageInfo } = groupRunnersDataPaginated.data.group.runners;

    beforeEach(async () => {
      mockGroupRunnersHandler.mockResolvedValue(groupRunnersDataPaginated);

      await createComponent({ mountFn: mountExtended });
    });

    it('passes the page info', () => {
      expect(findRunnerPagination().props('pageInfo')).toEqual(pageInfo);
    });

    it('navigates to the next page', async () => {
      await findRunnerPaginationNext().trigger('click');

      expect(mockGroupRunnersHandler).toHaveBeenLastCalledWith(
        expect.objectContaining({
          groupFullPath: mockGroupFullPath,
          membership: MEMBERSHIP_DESCENDANTS,
          sort: CREATED_DESC,
          first: RUNNER_PAGE_SIZE,
          after: pageInfo.endCursor,
        }),
      );
    });
  });

  describe('when user has permission to register group runner', () => {
    it('shows the register group runner button', () => {
      createComponent({
        props: {
          allowRegistrationToken: true,
          registrationToken: mockRegistrationToken,
        },
      });
      expect(findRegistrationDropdown().props()).toEqual({
        allowRegistrationToken: true,
        registrationToken: mockRegistrationToken,
        type: GROUP_TYPE,
      });
    });

    it('shows the create runner button', () => {
      createComponent({
        props: {
          newRunnerPath,
        },
      });

      expect(findNewRunnerBtn().attributes('href')).toBe(newRunnerPath);
    });
  });

  describe('when user has no permission to register group runner', () => {
    it('shows the create runner button', () => {
      createComponent({
        props: {
          newRunnerPath: null,
        },
      });

      expect(findNewRunnerBtn().exists()).toBe(false);
    });
  });
});
