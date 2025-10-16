import { GlLoadingIcon, GlKeysetPagination } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Pipelines from '~/ci/pipelines_page/pipelines_graphql.vue';
import PipelinesTable from '~/ci/common/pipelines_table.vue';
import getPipelinesQuery from '~/ci/pipelines_page/graphql/queries/get_pipelines.query.graphql';
import { mockPipelinesData } from './mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('Pipelines app', () => {
  let wrapper;

  const successHandler = jest.fn().mockResolvedValue(mockPipelinesData);
  const failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

  const createMockApolloProvider = (requestHandlers = [[getPipelinesQuery, successHandler]]) => {
    return createMockApollo(requestHandlers);
  };

  const createComponent = (requestHandlers) => {
    wrapper = shallowMountExtended(Pipelines, {
      provide: {
        fullPath: 'gitlab-org/gitlab',
      },
      apolloProvider: createMockApolloProvider(requestHandlers),
    });
  };

  const findTable = () => wrapper.findComponent(PipelinesTable);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
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

  describe('fetching pipelines', () => {
    it('fetches query correctly and passes pipelines to table', async () => {
      createComponent();

      expect(successHandler).toHaveBeenCalledWith({
        first: 15,
        fullPath: 'gitlab-org/gitlab',
        last: null,
        before: null,
        after: null,
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
      });
      expect(findPagination().props()).toMatchObject({});
    });
  });
});
