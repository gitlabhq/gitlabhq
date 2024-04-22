import { GlSearchBoxByType, GlSkeletonLoader } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { sprintf } from '~/locale';
import {
  I18N_ASSIGNED_PROJECTS,
  I18N_CLEAR_FILTER_PROJECTS,
  I18N_FILTER_PROJECTS,
  I18N_NO_PROJECTS_FOUND,
  RUNNER_DETAILS_PROJECTS_PAGE_SIZE,
} from '~/ci/runner/constants';
import RunnerProjects from '~/ci/runner/components/runner_projects.vue';
import RunnerAssignedItem from '~/ci/runner/components/runner_assigned_item.vue';
import RunnerPagination from '~/ci/runner/components/runner_pagination.vue';
import { captureException } from '~/ci/runner/sentry_utils';

import runnerProjectsQuery from '~/ci/runner/graphql/show/runner_projects.query.graphql';

import { runnerData, runnerProjectsData } from '../mock_data';

jest.mock('~/alert');
jest.mock('~/ci/runner/sentry_utils');

const mockRunner = runnerData.data.runner;
const mockRunnerWithProjects = runnerProjectsData.data.runner;
const mockProjects = mockRunnerWithProjects.projects.nodes;

Vue.use(VueApollo);

describe('RunnerProjects', () => {
  let wrapper;
  let mockRunnerProjectsQuery;

  const findHeading = () => wrapper.find('h3');
  const findGlSkeletonLoading = () => wrapper.findComponent(GlSkeletonLoader);
  const findGlSearchBoxByType = () => wrapper.findComponent(GlSearchBoxByType);
  const findRunnerAssignedItems = () => wrapper.findAllComponents(RunnerAssignedItem);
  const findRunnerPagination = () => wrapper.findComponent(RunnerPagination);

  const createComponent = ({ mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(RunnerProjects, {
      apolloProvider: createMockApollo([[runnerProjectsQuery, mockRunnerProjectsQuery]]),
      propsData: {
        runner: mockRunner,
      },
    });
  };

  beforeEach(() => {
    mockRunnerProjectsQuery = jest.fn();
  });

  afterEach(() => {
    mockRunnerProjectsQuery.mockReset();
  });

  it('Requests runner projects', async () => {
    createComponent();

    await waitForPromises();

    expect(mockRunnerProjectsQuery).toHaveBeenCalledTimes(1);
    expect(mockRunnerProjectsQuery).toHaveBeenCalledWith({
      id: mockRunner.id,
      search: '',
      sort: 'ID_ASC',
      first: RUNNER_DETAILS_PROJECTS_PAGE_SIZE,
    });
  });

  it('Shows a filter box', () => {
    createComponent();

    expect(findGlSearchBoxByType().attributes()).toMatchObject({
      clearbuttontitle: I18N_CLEAR_FILTER_PROJECTS,
      debounce: '500',
      placeholder: I18N_FILTER_PROJECTS,
    });
  });

  describe('When there are projects assigned', () => {
    beforeEach(async () => {
      mockRunnerProjectsQuery.mockResolvedValueOnce(runnerProjectsData);

      createComponent();
      await waitForPromises();
    });

    it('Shows a heading', () => {
      const expected = sprintf(I18N_ASSIGNED_PROJECTS, { projectCount: mockProjects.length });

      expect(findHeading().text()).toBe(expected);
    });

    it('Shows projects', () => {
      expect(findRunnerAssignedItems().length).toBe(mockProjects.length);
    });

    it('Shows a project', () => {
      const item = findRunnerAssignedItems().at(0);
      const { webUrl, name, nameWithNamespace, avatarUrl } = mockProjects[0];

      expect(item.props()).toMatchObject({
        href: webUrl,
        name,
        fullName: nameWithNamespace,
        avatarUrl,
      });
    });

    describe('When "Next" page is clicked', () => {
      beforeEach(async () => {
        findRunnerPagination().vm.$emit('input', { page: 3, after: 'AFTER_CURSOR' });

        await waitForPromises();
      });

      it('A new page is requested', () => {
        expect(mockRunnerProjectsQuery).toHaveBeenCalledTimes(2);
        expect(mockRunnerProjectsQuery).toHaveBeenLastCalledWith({
          id: mockRunner.id,
          search: '',
          sort: 'ID_ASC',
          first: RUNNER_DETAILS_PROJECTS_PAGE_SIZE,
          after: 'AFTER_CURSOR',
        });
      });

      it('When "Prev" page is clicked, the previous page is requested', async () => {
        findRunnerPagination().vm.$emit('input', { page: 2, before: 'BEFORE_CURSOR' });

        await waitForPromises();

        expect(mockRunnerProjectsQuery).toHaveBeenCalledTimes(3);
        expect(mockRunnerProjectsQuery).toHaveBeenLastCalledWith({
          id: mockRunner.id,
          search: '',
          sort: 'ID_ASC',
          last: RUNNER_DETAILS_PROJECTS_PAGE_SIZE,
          before: 'BEFORE_CURSOR',
        });
      });

      it('When user filters after paginating, the first page is requested', async () => {
        findGlSearchBoxByType().vm.$emit('input', 'my search');
        await waitForPromises();

        expect(mockRunnerProjectsQuery).toHaveBeenCalledTimes(3);
        expect(mockRunnerProjectsQuery).toHaveBeenLastCalledWith({
          id: mockRunner.id,
          search: 'my search',
          sort: 'ID_ASC',
          first: RUNNER_DETAILS_PROJECTS_PAGE_SIZE,
        });
      });
    });

    describe('When user filters', () => {
      it('Filtered results are requested', async () => {
        expect(mockRunnerProjectsQuery).toHaveBeenCalledTimes(1);

        findGlSearchBoxByType().vm.$emit('input', 'my search');
        await waitForPromises();

        expect(mockRunnerProjectsQuery).toHaveBeenCalledTimes(2);
        expect(mockRunnerProjectsQuery).toHaveBeenLastCalledWith({
          id: mockRunner.id,
          search: 'my search',
          sort: 'ID_ASC',
          first: RUNNER_DETAILS_PROJECTS_PAGE_SIZE,
        });
      });

      it('Filtered results are not requested for short searches', async () => {
        expect(mockRunnerProjectsQuery).toHaveBeenCalledTimes(1);

        findGlSearchBoxByType().vm.$emit('input', 'm');
        await waitForPromises();

        findGlSearchBoxByType().vm.$emit('input', 'my');
        await waitForPromises();

        expect(mockRunnerProjectsQuery).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('When loading', () => {
    it('shows loading indicator and no other content', () => {
      createComponent();

      expect(findGlSkeletonLoading().exists()).toBe(true);

      expect(wrapper.findByText(I18N_NO_PROJECTS_FOUND).exists()).toBe(false);
      expect(findRunnerAssignedItems().length).toBe(0);

      expect(findRunnerPagination().attributes('disabled')).toBeDefined();
      expect(findGlSearchBoxByType().props('isLoading')).toBe(true);
    });
  });

  describe('When there are no projects', () => {
    beforeEach(async () => {
      mockRunnerProjectsQuery.mockResolvedValueOnce({
        data: {
          runner: {
            id: mockRunner.id,
            projectCount: 0,
            projects: {
              nodes: [],
              pageInfo: {
                hasNextPage: false,
                hasPreviousPage: false,
                startCursor: '',
                endCursor: '',
              },
            },
          },
        },
      });

      createComponent();
      await waitForPromises();
    });

    it('Shows a "None" label', () => {
      expect(wrapper.findByText(I18N_NO_PROJECTS_FOUND).exists()).toBe(true);
    });
  });

  describe('When an error occurs', () => {
    beforeEach(async () => {
      mockRunnerProjectsQuery.mockRejectedValue(new Error('Error!'));

      createComponent();
      await waitForPromises();
    });

    it('shows an error', () => {
      expect(createAlert).toHaveBeenCalled();
    });

    it('reports an error', () => {
      expect(captureException).toHaveBeenCalledWith({
        component: 'RunnerProjects',
        error: expect.any(Error),
      });
    });
  });
});
