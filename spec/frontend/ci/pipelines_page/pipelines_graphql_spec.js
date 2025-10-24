import { GlEmptyState, GlLoadingIcon, GlKeysetPagination } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { createAlert } from '~/alert';
import { TEST_HOST } from 'spec/test_constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NavigationTabs from '~/vue_shared/components/navigation_tabs.vue';
import Pipelines from '~/ci/pipelines_page/pipelines_graphql.vue';
import NavigationControls from '~/ci/pipelines_page/components/nav_controls.vue';
import NoCiEmptyState from '~/ci/pipelines_page/components/empty_state/no_ci_empty_state.vue';
import PipelinesTable from '~/ci/common/pipelines_table.vue';
import getPipelinesQuery from '~/ci/pipelines_page/graphql/queries/get_pipelines.query.graphql';
import getAllPipelinesCountQuery from '~/ci/pipelines_page/graphql/queries/get_all_pipelines_count.query.graphql';
import clearRunnerCacheMutation from '~/ci/pipelines_page/graphql/mutations/clear_runner_cache.mutation.graphql';
import * as urlUtils from '~/lib/utils/url_utility';
import {
  mockPipelinesData,
  mockPipelinesCount,
  mockPipelinesDataEmpty,
  mockRunnerCacheClearPayload,
  mockRunnerCacheClearPayloadWithError,
} from './mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('Pipelines app', () => {
  let wrapper;

  const countHandler = jest.fn().mockResolvedValue(mockPipelinesCount);
  const successHandler = jest.fn().mockResolvedValue(mockPipelinesData);
  const failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));
  const emptyHandler = jest.fn().mockResolvedValue(mockPipelinesDataEmpty);
  const clearCacheMutationSuccessHandler = jest.fn().mockResolvedValue(mockRunnerCacheClearPayload);
  const clearCacheMutationFailedHandler = jest
    .fn()
    .mockResolvedValue(mockRunnerCacheClearPayloadWithError);

  const createMockApolloProvider = (
    requestHandlers = [
      [getPipelinesQuery, successHandler],
      [getAllPipelinesCountQuery, countHandler],
    ],
  ) => {
    return createMockApollo(requestHandlers);
  };

  const createComponent = (requestHandlers) => {
    wrapper = shallowMountExtended(Pipelines, {
      provide: {
        fullPath: 'gitlab-org/gitlab',
        newPipelinePath: '/gitlab-org/gitlab/-/pipelines/new',
        resetCachePath: '/gitlab-org/gitlab/-/settings/ci_cd/reset_cache',
        pipelinesAnalyticsPath: '/-/pipelines/charts',
        identityVerificationRequired: false,
        identityVerificationPath: '#',
      },
      apolloProvider: createMockApolloProvider(requestHandlers),
    });
  };

  const findTable = () => wrapper.findComponent(PipelinesTable);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findNoCiEmptyState = () => wrapper.findComponent(NoCiEmptyState);
  const findTabs = () => wrapper.findComponent(NavigationTabs);
  const findNavControls = () => wrapper.findComponent(NavigationControls);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);

  const triggerNextPage = async () => {
    findPagination().vm.$emit('next');
    await waitForPromises();
  };

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays table', async () => {
      await waitForPromises();

      expect(findTable().exists()).toBe(true);
      expect(createAlert).not.toHaveBeenCalled();
    });

    it('handles loading state', async () => {
      expect(findLoadingIcon().exists()).toBe(true);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('empty state', () => {
    it('shows error empty state when there is an error', async () => {
      createComponent([[getPipelinesQuery, failedHandler]]);

      await waitForPromises();

      expect(findEmptyState().exists()).toBe(true);
      expect(findEmptyState().props('title')).toBe('There was an error fetching the pipelines.');
    });

    it('shows tab empty state when not on the All tab', async () => {
      const dynamicHandler = jest.fn().mockImplementation((variables) => {
        if (variables.scope === 'TAGS' || variables.scope === 'FINISHED') {
          return Promise.resolve(mockPipelinesDataEmpty);
        }
        return Promise.resolve(mockPipelinesData);
      });

      createComponent([[getPipelinesQuery, dynamicHandler]]);

      await waitForPromises();

      findTabs().vm.$emit('onChangeTab', 'tags');

      await waitForPromises();

      expect(findEmptyState().exists()).toBe(true);
      expect(findEmptyState().props('title')).toBe('There are currently no pipelines.');

      findTabs().vm.$emit('onChangeTab', 'finished');

      await waitForPromises();

      expect(findEmptyState().exists()).toBe(true);
      expect(findEmptyState().props('title')).toBe('There are currently no finished pipelines.');
    });

    it('shows no ci empty state when there are no pipelines', async () => {
      createComponent([[getPipelinesQuery, emptyHandler]]);

      await waitForPromises();

      expect(findNoCiEmptyState().exists()).toBe(true);
      expect(findTable().exists()).toBe(false);
    });
  });

  describe('fetching pipelines', () => {
    it('fetches query correctly and passes pipelines to table', async () => {
      createComponent();

      expect(successHandler).toHaveBeenCalledWith({
        first: 15,
        fullPath: 'gitlab-org/gitlab',
        last: null,
        before: null,
        after: null,
        scope: null,
      });

      await waitForPromises();

      expect(findTable().props('pipelines')).toEqual(
        mockPipelinesData.data.project.pipelines.nodes,
      );
    });

    it('shows query error alert', async () => {
      createComponent([[getPipelinesQuery, failedHandler]]);

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while loading pipelines',
      });
    });
  });

  describe('tabs', () => {
    it('renders navigation tabs correctly', async () => {
      createComponent();

      await waitForPromises();

      expect(findTabs().exists()).toBe(true);
    });

    it('displays All tab pipeline count', async () => {
      createComponent();

      await waitForPromises();

      expect(findTabs().props('tabs')[0]).toStrictEqual({
        count: 2,
        isActive: true,
        name: 'All',
        scope: 'all',
      });
    });

    it.each`
      scope         | params
      ${'all'}      | ${{ scope: null }}
      ${'finished'} | ${{ scope: 'FINISHED' }}
      ${'branches'} | ${{ scope: 'BRANCHES' }}
      ${'tags'}     | ${{ scope: 'TAGS' }}
    `(
      'when the scope is $scope, then the query should be called with $params',
      async ({ scope, params }) => {
        createComponent();

        jest.spyOn(urlUtils, 'updateHistory');

        await waitForPromises();

        findTabs().vm.$emit('onChangeTab', scope);

        await waitForPromises();

        expect(successHandler).toHaveBeenCalledWith(expect.objectContaining(params));

        // inital load does not start with a scope
        if (params.scope) {
          expect(urlUtils.updateHistory).toHaveBeenCalledWith({
            url: `${TEST_HOST}/?scope=${scope}`,
          });
        }
      },
    );
  });

  describe('nav links', () => {
    it('renders navigation controls', async () => {
      createComponent();

      await waitForPromises();

      expect(findNavControls().exists()).toBe(true);
    });

    it('clears runner cache', async () => {
      createComponent([
        [getPipelinesQuery, successHandler],
        [clearRunnerCacheMutation, clearCacheMutationSuccessHandler],
      ]);

      await waitForPromises();

      findNavControls().vm.$emit('resetRunnersCache');

      expect(clearCacheMutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          projectId: 'gid://gitlab/Project/19',
        },
      });

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Project cache successfully reset.',
        variant: 'info',
      });
    });

    it('shows an error alert when clearing runner cache fails', async () => {
      createComponent([
        [getPipelinesQuery, successHandler],
        [clearRunnerCacheMutation, clearCacheMutationFailedHandler],
      ]);

      await waitForPromises();

      findNavControls().vm.$emit('resetRunnersCache');

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong while cleaning runners cache.',
      });
    });
  });

  describe('pagination', () => {
    beforeEach(() => {
      createComponent();
    });

    it('handles pagination visibility while loading', async () => {
      expect(findPagination().exists()).toBe(false);

      await waitForPromises();

      expect(findPagination().exists()).toBe(true);
    });

    it('passes correct props to pagination', async () => {
      await waitForPromises();

      expect(findPagination().props()).toMatchObject({
        startCursor: 'eyJpZCI6IjcwMSJ9',
        endCursor: 'eyJpZCI6IjY3NSJ9',
        hasNextPage: true,
        hasPreviousPage: false,
      });
    });

    it('updates query variables when going to next page', async () => {
      await waitForPromises();

      await triggerNextPage();

      expect(successHandler).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
        first: 15,
        last: null,
        before: null,
        after: 'eyJpZCI6IjY3NSJ9',
        scope: null,
      });
      expect(findPagination().props()).toMatchObject({});
    });
  });
});
