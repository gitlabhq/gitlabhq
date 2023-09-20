import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { createAlert } from '~/alert';
import PipelinesTableWrapper from '~/ci/merge_requests/components/pipelines_table_wrapper.vue';
import getMergeRequestsPipelines from '~/ci/merge_requests/graphql/queries/get_merge_request_pipelines.query.graphql';

import { mergeRequestPipelinesResponse } from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

const pipelinesLength = mergeRequestPipelinesResponse.data.project.mergeRequest.pipelines.count;

let wrapper;
let mergeRequestPipelinesRequest;
let apolloMock;

const defaultProvide = {
  graphqlPath: '/api/graphql/',
  mergeRequestId: 1,
  targetProjectFullPath: '/group/project',
};

const createComponent = () => {
  const handlers = [[getMergeRequestsPipelines, mergeRequestPipelinesRequest]];

  apolloMock = createMockApollo(handlers);

  wrapper = shallowMount(PipelinesTableWrapper, {
    apolloProvider: apolloMock,
    provide: {
      ...defaultProvide,
    },
  });

  return waitForPromises();
};

const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
const findPipelineList = () => wrapper.findAll('li');

beforeEach(() => {
  mergeRequestPipelinesRequest = jest.fn();
  mergeRequestPipelinesRequest.mockResolvedValue(mergeRequestPipelinesResponse);
});
afterEach(() => {
  apolloMock = null;
  createAlert.mockClear();
});

describe('PipelinesTableWrapper component', () => {
  describe('When queries are loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not render the pipeline list', () => {
      expect(findPipelineList()).toHaveLength(0);
    });
  });

  describe('When there is an error fetching pipelines', () => {
    beforeEach(async () => {
      mergeRequestPipelinesRequest.mockRejectedValueOnce({ error: 'API error message' });
      await createComponent();
    });
    it('shows an error message', () => {
      expect(createAlert).toHaveBeenCalledTimes(1);
      expect(createAlert).toHaveBeenCalledWith({
        message: "There was an error fetching this merge request's pipelines.",
      });
    });
  });

  describe('When queries have loaded', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('does not render the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders a pipeline list', () => {
      expect(findPipelineList()).toHaveLength(pipelinesLength);
    });
  });

  describe('polling', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('polls every 10 seconds', () => {
      expect(mergeRequestPipelinesRequest).toHaveBeenCalledTimes(1);

      jest.advanceTimersByTime(5000);

      expect(mergeRequestPipelinesRequest).toHaveBeenCalledTimes(1);

      jest.advanceTimersByTime(5000);

      expect(mergeRequestPipelinesRequest).toHaveBeenCalledTimes(2);
    });
  });
});
