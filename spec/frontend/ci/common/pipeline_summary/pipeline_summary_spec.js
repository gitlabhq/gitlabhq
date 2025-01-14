import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import Visibility from 'visibilityjs';
import { GlLoadingIcon } from '@gitlab/ui';
import mockPipelineSummaryQueryResponse from 'test_fixtures/graphql/pipelines/get_pipeline_summary.query.graphql.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import PipelineMiniGraph from '~/ci/pipeline_mini_graph/pipeline_mini_graph.vue';
import PipelineSummary from '~/ci/common/pipeline_summary/pipeline_summary.vue';

import { PIPELINE_POLL_INTERVAL_DEFAULT } from '~/ci/constants';
import getPipelineSummaryQuery from '~/ci/common/pipeline_summary/graphql/queries/get_pipeline_summary.query.graphql';

Vue.use(VueApollo);
jest.mock('~/alert');
jest.mock('visibilityjs');

describe('PipelineSummary', () => {
  let wrapper;
  const pipelineSummaryHandler = jest.fn().mockResolvedValue(mockPipelineSummaryQueryResponse);

  const {
    data: {
      project: { pipeline },
    },
  } = mockPipelineSummaryQueryResponse;

  const defaultProps = {
    fullPath: 'project/path',
    iid: '12',
    pipelineEtag: '/etag',
    includeCommitInfo: true,
  };

  const createComponent = ({ props = {} } = {}) => {
    const handlers = [[getPipelineSummaryQuery, pipelineSummaryHandler]];
    const mockApollo = createMockApollo(handlers);

    wrapper = mountExtended(PipelineSummary, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      apolloProvider: mockApollo,
    });

    return waitForPromises();
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPipelineMiniGraph = () => wrapper.findComponent(PipelineMiniGraph);
  const findStatusIcon = () => wrapper.findComponent(CiIcon);
  const findTimeAgo = () => wrapper.findComponent(TimeAgoTooltip);
  const findPipelineText = () => wrapper.findByTestId('pipeline-path');
  const findCommitInfo = () => wrapper.findByTestId('commit-info');
  const findCommitPath = () => wrapper.findByTestId('commit-path');

  const getPollInterval = () => wrapper.vm.$apollo.queries.pipeline.pollInterval;

  describe('mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the loading state', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('loaded', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('renders the pipeline status icon', () => {
      expect(findStatusIcon().exists()).toBe(true);

      expect(findStatusIcon().props()).toMatchObject({
        status: pipeline.detailedStatus,
      });
    });

    it('renders the pipeline link text', () => {
      expect(findPipelineText().exists()).toBe(true);

      expect(findPipelineText().text()).toBe(`#${getIdFromGraphQLId(pipeline.id)}`);
    });

    it('assigns correct link to pipeline', () => {
      expect(findPipelineText().attributes().href).toBe(pipeline.detailedStatus.detailsPath);
    });

    it('renders the pipeline mini graph', () => {
      expect(findPipelineMiniGraph().exists()).toBe(true);

      expect(findPipelineMiniGraph().props()).toMatchObject({
        downstreamPipelines: pipeline.downstream.nodes,
        pipelinePath: pipeline.detailedStatus.detailsPath,
        pipelineStages: pipeline.stages.nodes,
        upstreamPipeline: expect.any(Object),
      });
    });

    it('renders when the pipeline completed', () => {
      expect(findTimeAgo().exists()).toBe(true);
    });
  });

  describe('commit info', () => {
    describe('when commit info is included', () => {
      beforeEach(async () => {
        await createComponent();
      });

      it('renders the commit info', () => {
        expect(findCommitInfo().exists()).toBe(true);
      });

      it('links to the correct commit path', () => {
        expect(findCommitPath().exists()).toBe(true);
        expect(findCommitPath().attributes().href).toBe(pipeline.commit.webPath);
      });
    });

    describe('when commit info is not included', () => {
      beforeEach(async () => {
        await createComponent({ props: { includeCommitInfo: false } });
      });

      it('does not render the commit info', () => {
        expect(findCommitInfo().exists()).toBe(false);
      });

      it('does not render the commit path', () => {
        expect(findCommitPath().exists()).toBe(false);
      });
    });
  });

  describe('polling', () => {
    beforeEach(async () => {
      Visibility.hidden.mockReturnValue(true);
      pipelineSummaryHandler.mockResolvedValue(mockPipelineSummaryQueryResponse);
      await createComponent();
    });

    it('increases the poll interval after each query call', () => {
      expect(pipelineSummaryHandler).toHaveBeenCalled();
      expect(getPollInterval()).toBeGreaterThan(PIPELINE_POLL_INTERVAL_DEFAULT);
    });

    it('handles visibility change for polling correctly', async () => {
      expect(getPollInterval()).toBeGreaterThan(PIPELINE_POLL_INTERVAL_DEFAULT);

      Visibility.hidden.mockReturnValue(false);
      wrapper.vm.handlePolling();
      await nextTick();

      expect(getPollInterval()).toBe(PIPELINE_POLL_INTERVAL_DEFAULT);
    });

    it('resets poll interval on job action executed', async () => {
      expect(getPollInterval()).toBeGreaterThan(PIPELINE_POLL_INTERVAL_DEFAULT);

      findPipelineMiniGraph().vm.$emit('jobActionExecuted');
      await nextTick();

      expect(getPollInterval()).toBe(PIPELINE_POLL_INTERVAL_DEFAULT);
    });
  });
});
