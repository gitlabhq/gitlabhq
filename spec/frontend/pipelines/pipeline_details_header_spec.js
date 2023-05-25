import { GlBadge, GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PipelineDetailsHeader from '~/pipelines/components/pipeline_details_header.vue';
import TimeAgo from '~/pipelines/components/pipelines_list/time_ago.vue';
import CiBadgeLink from '~/vue_shared/components/ci_badge_link.vue';
import getPipelineDetailsQuery from '~/pipelines/graphql/queries/get_pipeline_header_data.query.graphql';
import { pipelineHeaderSuccess, pipelineHeaderRunning } from './mock_data';

Vue.use(VueApollo);

describe('Pipeline details header', () => {
  let wrapper;

  const successHandler = jest.fn().mockResolvedValue(pipelineHeaderSuccess);
  const runningHandler = jest.fn().mockResolvedValue(pipelineHeaderRunning);

  const findStatus = () => wrapper.findComponent(CiBadgeLink);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTimeAgo = () => wrapper.findComponent(TimeAgo);
  const findAllBadges = () => wrapper.findAllComponents(GlBadge);
  const findPipelineName = () => wrapper.findByTestId('pipeline-name');
  const findTotalJobs = () => wrapper.findByTestId('total-jobs');
  const findComputeCredits = () => wrapper.findByTestId('compute-credits');
  const findCommitLink = () => wrapper.findByTestId('commit-link');
  const findPipelineRunningText = () => wrapper.findByTestId('pipeline-running-text').text();
  const findPipelineRefText = () => wrapper.findByTestId('pipeline-ref-text').text();

  const defaultHandlers = [[getPipelineDetailsQuery, successHandler]];

  const defaultProvideOptions = {
    pipelineIid: 1,
    paths: {
      pipelinesPath: '/namespace/my-project/-/pipelines',
      fullProject: '/namespace/my-project',
      triggeredByPath: '',
    },
  };

  const defaultProps = {
    name: 'Ruby 3.0 master branch pipeline',
    totalJobs: '50',
    computeCredits: '0.65',
    yamlErrors: 'errors',
    failureReason: 'pipeline failed',
    badges: {
      schedule: true,
      child: false,
      latest: true,
      mergeTrainPipeline: false,
      invalid: false,
      failed: false,
      autoDevops: false,
      detached: false,
      stuck: false,
    },
    refText:
      'For merge request <a class="mr-iid" href="/root/ci-project/-/merge_requests/1">!1</a> to merge <a class="ref-name" href="/root/ci-project/-/commits/test">test</a>',
  };

  const createMockApolloProvider = (handlers) => {
    return createMockApollo(handlers);
  };

  const createComponent = (handlers = defaultHandlers, props = defaultProps) => {
    wrapper = shallowMountExtended(PipelineDetailsHeader, {
      provide: {
        ...defaultProvideOptions,
      },
      propsData: {
        ...props,
      },
      apolloProvider: createMockApolloProvider(handlers),
    });
  };

  describe('loading state', () => {
    it('shows a loading state while graphQL is fetching initial data', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('defaults', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('does not display loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('displays pipeline status', () => {
      expect(findStatus().exists()).toBe(true);
    });

    it('displays pipeline name', () => {
      expect(findPipelineName().text()).toBe(defaultProps.name);
    });

    it('displays total jobs', () => {
      expect(findTotalJobs().text()).toBe('50 Jobs');
    });

    it('has link to commit', () => {
      const {
        data: {
          project: { pipeline },
        },
      } = pipelineHeaderSuccess;

      expect(findCommitLink().attributes('href')).toBe(pipeline.commit.webPath);
    });

    it('displays correct badges', () => {
      expect(findAllBadges()).toHaveLength(2);
      expect(wrapper.findByText('latest').exists()).toBe(true);
      expect(wrapper.findByText('Scheduled').exists()).toBe(true);
    });

    it('displays ref text', () => {
      expect(findPipelineRefText()).toBe('For merge request !1 to merge test');
    });
  });

  describe('finished pipeline', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('displays compute credits', () => {
      expect(findComputeCredits().text()).toBe('0.65');
    });

    it('displays time ago', () => {
      expect(findTimeAgo().exists()).toBe(true);
    });
  });

  describe('running pipeline', () => {
    beforeEach(async () => {
      createComponent([[getPipelineDetailsQuery, runningHandler]]);

      await waitForPromises();
    });

    it('does not display compute credits', () => {
      expect(findComputeCredits().exists()).toBe(false);
    });

    it('does not display time ago', () => {
      expect(findTimeAgo().exists()).toBe(false);
    });

    it('displays pipeline running text', () => {
      expect(findPipelineRunningText()).toBe('In progress, queued for 3600 seconds');
    });
  });
});
