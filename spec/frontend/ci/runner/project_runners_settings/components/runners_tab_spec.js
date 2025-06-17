import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlTab, GlBadge, GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import RunnerList from '~/ci/runner/components/runner_list.vue';
import RunnerPagination from '~/ci/runner/components/runner_pagination.vue';
import RunnerActionsCell from '~/ci/runner/components/cells/runner_actions_cell.vue';
import { PROJECT_TYPE } from '~/ci/runner/constants';
import { projectRunnersData, runnerJobCountData } from 'jest/ci/runner/mock_data';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import projectRunnersQuery from '~/ci/runner/graphql/list/project_runners.query.graphql';
import runnerJobCountQuery from '~/ci/runner/graphql/list/runner_job_count.query.graphql';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { captureException } from '~/ci/runner/sentry_utils';

import RunnersTab from '~/ci/runner/project_runners_settings/components/runners_tab.vue';

Vue.use(VueApollo);

jest.mock('~/ci/runner/sentry_utils');

const mockRunners = projectRunnersData.data.project.runners.edges;
const mockPageInfo = projectRunnersData.data.project.runners.pageInfo;
const mockRunnerId = getIdFromGraphQLId(mockRunners[0].node.id);
const mockRunnerSha = mockRunners[0].node.shortSha;

describe('RunnersTab', () => {
  let wrapper;
  let projectRunnersHandler;
  let runnerJobCountHandler;

  const createComponent = ({ props, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(RunnersTab, {
      propsData: {
        projectFullPath: 'group/project',
        title: 'Project',
        runnerType: PROJECT_TYPE,
        ...props,
      },
      apolloProvider: createMockApollo([
        [projectRunnersQuery, projectRunnersHandler],
        [runnerJobCountQuery, runnerJobCountHandler],
      ]),
      stubs: {
        GlTab,
      },
      slots: {
        settings: 'Some settings',
        description: 'Some description',
        empty: 'No runners found',
      },
    });

    return waitForPromises();
  };

  beforeEach(() => {
    projectRunnersHandler = jest.fn().mockResolvedValue(projectRunnersData);
    runnerJobCountHandler = jest.fn().mockResolvedValue(runnerJobCountData);
  });

  const findTab = () => wrapper.findComponent(GlTab);
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findRunnerList = () => wrapper.findComponent(RunnerList);
  const findRunnerPagination = () => wrapper.findComponent(RunnerPagination);
  const findRunnerActionsCell = () => wrapper.findComponent(RunnerActionsCell);
  const findEmptyMessage = () => wrapper.findByTestId('empty-message');

  describe('when rendered', () => {
    beforeEach(() => {
      createComponent();
    });

    it('fetches data', () => {
      expect(projectRunnersHandler).toHaveBeenCalledTimes(1);
      expect(projectRunnersHandler).toHaveBeenCalledWith({
        fullPath: 'group/project',
        type: PROJECT_TYPE,
        first: 10,
      });
    });

    it('renders the tab with the correct title', () => {
      expect(findTab().text()).toContain('Project');
    });

    it('does not show badge when count is null', () => {
      expect(findBadge().exists()).toBe(false);
    });

    it('does not render empty state', () => {
      expect(findEmptyMessage().exists()).toBe(false);
    });

    it('shows runner list in loading state', () => {
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findRunnerList().props('loading')).toBe(true);
    });

    it('shows a disabled pagination', () => {
      expect(findRunnerPagination().attributes('disabled')).toBeDefined();
    });

    it('renders settings slot', () => {
      expect(wrapper.text()).toContain('Some settings');
    });

    it('renders description slot', () => {
      expect(wrapper.findComponent(GlAlert).text()).toContain('Some description');
    });
  });

  describe('when data is fetched', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('shows badge with count when available', () => {
      expect(findBadge().text()).toBe('2');
    });

    it('does not render empty state', () => {
      expect(findEmptyMessage().exists()).toBe(false);
    });

    it('shows runner list when runners are available', () => {
      expect(findRunnerList().props('loading')).toBe(false);
      expect(findRunnerList().props('runners')).toEqual([
        expect.objectContaining({ ...mockRunners[0].node }),
        expect.objectContaining({ ...mockRunners[1].node }),
      ]);
    });

    it('shows link to runner', async () => {
      await createComponent({ mountFn: mountExtended });

      expect(wrapper.findByTestId('runner-link').attributes('href')).toBe(mockRunners[0].webUrl);
      expect(wrapper.findByTestId('runner-link').text()).toBe(
        `#${mockRunnerId} (${mockRunnerSha})`,
      );
    });

    it('shows runner actions', async () => {
      await createComponent({ mountFn: mountExtended });

      expect(findRunnerActionsCell().props()).toMatchObject({
        size: 'small',
        runner: mockRunners[0].node,
        editUrl: mockRunners[0].editUrl,
      });
    });

    describe('pagination', () => {
      it('shows pagination', () => {
        expect(findRunnerPagination().attributes('disabled')).toBeUndefined();
        expect(findRunnerPagination().props('pageInfo')).toEqual({ ...mockPageInfo });
      });

      it('changes page', async () => {
        findRunnerPagination().vm.$emit('input', { after: mockPageInfo.endCursor });

        await waitForPromises();

        expect(projectRunnersHandler).toHaveBeenCalledTimes(2);
        expect(projectRunnersHandler).toHaveBeenLastCalledWith({
          fullPath: 'group/project',
          type: PROJECT_TYPE,
          first: 10,
          after: mockPageInfo.endCursor,
        });
      });
    });
  });

  it('shows empty message with no runners', async () => {
    projectRunnersHandler.mockResolvedValue({
      data: {},
    });

    await createComponent();

    expect(findEmptyMessage().exists()).toBe(true);
    expect(findRunnerList().exists()).toBe(false);
  });

  it('emits error event when apollo query fails', async () => {
    const error = new Error('Network error');
    projectRunnersHandler.mockRejectedValue(error);

    await createComponent();

    expect(findEmptyMessage().exists()).toBe(true);
    expect(wrapper.emitted('error')).toEqual([
      [
        {
          error,
          message: 'Something went wrong while fetching runner data.',
        },
      ],
    ]);
    expect(captureException).toHaveBeenCalledWith({ error, component: 'RunnersTab' });
  });

  describe('component API', () => {
    it('refresh()', async () => {
      await createComponent();

      expect(projectRunnersHandler).toHaveBeenCalledTimes(1);

      wrapper.vm.refresh();

      expect(projectRunnersHandler).toHaveBeenCalledTimes(2);
    });
  });
});
