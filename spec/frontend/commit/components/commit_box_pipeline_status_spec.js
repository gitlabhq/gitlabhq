import { GlLoadingIcon, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import CommitBoxPipelineStatus from '~/projects/commit_box/info/components/commit_box_pipeline_status.vue';
import {
  COMMIT_BOX_POLL_INTERVAL,
  PIPELINE_STATUS_FETCH_ERROR,
} from '~/projects/commit_box/info/constants';
import getLatestPipelineStatusQuery from '~/projects/commit_box/info/graphql/queries/get_latest_pipeline_status.query.graphql';
import * as sharedGraphQlUtils from '~/graphql_shared/utils';
import { mockPipelineStatusResponse } from '../mock_data';

const mockProvide = {
  fullPath: 'root/ci-project',
  iid: '46',
  graphqlResourceEtag: '/api/graphql:pipelines/id/320',
};

Vue.use(VueApollo);

jest.mock('~/alert');

describe('Commit box pipeline status', () => {
  let wrapper;

  const statusSuccessHandler = jest.fn().mockResolvedValue(mockPipelineStatusResponse);
  const failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findStatusIcon = () => wrapper.findComponent(CiIcon);
  const findPipelineLink = () => wrapper.findComponent(GlLink);

  const advanceToNextFetch = () => {
    jest.advanceTimersByTime(COMMIT_BOX_POLL_INTERVAL);
  };

  const createMockApolloProvider = (handler) => {
    const requestHandlers = [[getLatestPipelineStatusQuery, handler]];

    return createMockApollo(requestHandlers);
  };

  const createComponent = (handler = statusSuccessHandler) => {
    wrapper = shallowMount(CommitBoxPipelineStatus, {
      provide: {
        ...mockProvide,
      },
      apolloProvider: createMockApolloProvider(handler),
    });
  };

  describe('loading state', () => {
    it('should display loading state when loading', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findStatusIcon().exists()).toBe(false);
    });
  });

  describe('loaded state', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('should display pipeline status after the query is resolved successfully', () => {
      expect(findStatusIcon().exists()).toBe(true);

      expect(findLoadingIcon().exists()).toBe(false);
      expect(createAlert).toHaveBeenCalledTimes(0);
    });

    it('should link to the latest pipeline', () => {
      const {
        data: {
          project: {
            pipeline: {
              detailedStatus: { detailsPath },
            },
          },
        },
      } = mockPipelineStatusResponse;

      expect(findPipelineLink().attributes('href')).toBe(detailsPath);
    });
  });

  describe('error state', () => {
    it('createAlert should show if there is an error fetching the pipeline status', async () => {
      createComponent(failedHandler);

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: PIPELINE_STATUS_FETCH_ERROR,
      });
    });
  });

  describe('polling', () => {
    it('polling interval is set for pipeline stages', () => {
      createComponent();

      const expectedInterval = wrapper.vm.$apollo.queries.pipelineStatus.options.pollInterval;

      expect(expectedInterval).toBe(COMMIT_BOX_POLL_INTERVAL);
    });

    it('polls for pipeline status', async () => {
      createComponent();

      await waitForPromises();

      expect(statusSuccessHandler).toHaveBeenCalledTimes(1);

      advanceToNextFetch();
      await waitForPromises();

      expect(statusSuccessHandler).toHaveBeenCalledTimes(2);

      advanceToNextFetch();
      await waitForPromises();

      expect(statusSuccessHandler).toHaveBeenCalledTimes(3);
    });

    it('toggles pipelineStatus polling with visibility check', async () => {
      jest.spyOn(sharedGraphQlUtils, 'toggleQueryPollingByVisibility');

      createComponent();

      await waitForPromises();

      expect(sharedGraphQlUtils.toggleQueryPollingByVisibility).toHaveBeenCalledWith(
        wrapper.vm.$apollo.queries.pipelineStatus,
      );
    });
  });
});
