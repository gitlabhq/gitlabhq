import { GlSkeletonLoader } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/flash';
import { sprintf } from '~/locale';
import {
  I18N_ASSIGNED_PROJECTS,
  I18N_NONE,
  RUNNER_DETAILS_PROJECTS_PAGE_SIZE,
} from '~/runner/constants';
import RunnerProjects from '~/runner/components/runner_projects.vue';
import RunnerAssignedItem from '~/runner/components/runner_assigned_item.vue';
import RunnerPagination from '~/runner/components/runner_pagination.vue';
import { captureException } from '~/runner/sentry_utils';

import runnerProjectsQuery from '~/runner/graphql/show/runner_projects.query.graphql';

import { runnerData, runnerProjectsData } from '../mock_data';

jest.mock('~/flash');
jest.mock('~/runner/sentry_utils');

const mockRunner = runnerData.data.runner;
const mockRunnerWithProjects = runnerProjectsData.data.runner;
const mockProjects = mockRunnerWithProjects.projects.nodes;

Vue.use(VueApollo);

describe('RunnerProjects', () => {
  let wrapper;
  let mockRunnerProjectsQuery;

  const findHeading = () => wrapper.find('h3');
  const findGlSkeletonLoading = () => wrapper.findComponent(GlSkeletonLoader);
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
    wrapper.destroy();
  });

  it('Requests runner projects', async () => {
    createComponent();

    await waitForPromises();

    expect(mockRunnerProjectsQuery).toHaveBeenCalledTimes(1);
    expect(mockRunnerProjectsQuery).toHaveBeenCalledWith({
      id: mockRunner.id,
      first: RUNNER_DETAILS_PROJECTS_PAGE_SIZE,
    });
  });

  describe('When there are projects assigned', () => {
    beforeEach(async () => {
      mockRunnerProjectsQuery.mockResolvedValueOnce(runnerProjectsData);

      createComponent();
      await waitForPromises();
    });

    it('Shows a heading', async () => {
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
        isOwner: true, // first project is always owner
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
          last: RUNNER_DETAILS_PROJECTS_PAGE_SIZE,
          before: 'BEFORE_CURSOR',
        });
      });
    });
  });

  describe('When loading', () => {
    it('shows loading indicator and no other content', () => {
      createComponent();

      expect(findGlSkeletonLoading().exists()).toBe(true);

      expect(wrapper.findByText(I18N_NONE).exists()).toBe(false);
      expect(findRunnerAssignedItems().length).toBe(0);

      expect(findRunnerPagination().attributes('disabled')).toBe('true');
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
      expect(wrapper.findByText(I18N_NONE).exists()).toBe(true);
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
