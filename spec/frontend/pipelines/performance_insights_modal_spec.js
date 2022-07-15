import { GlAlert, GlLink, GlModal } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import PerformanceInsightsModal from '~/pipelines/components/performance_insights_modal.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import getPerformanceInsights from '~/pipelines/graphql/queries/get_performance_insights.query.graphql';
import {
  mockPerformanceInsightsResponse,
  mockPerformanceInsightsNextPageResponse,
} from './graph/mock_data';

Vue.use(VueApollo);

describe('Performance insights modal', () => {
  let wrapper;

  const findModal = () => wrapper.findComponent(GlModal);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLink = () => wrapper.findComponent(GlLink);
  const findQueuedCardData = () => wrapper.findByTestId('insights-queued-card-data');
  const findQueuedCardLink = () => wrapper.findByTestId('insights-queued-card-link');
  const findExecutedCardData = () => wrapper.findByTestId('insights-executed-card-data');
  const findExecutedCardLink = () => wrapper.findByTestId('insights-executed-card-link');
  const findSlowJobsStage = (index) => wrapper.findAllByTestId('insights-slow-job-stage').at(index);
  const findSlowJobsLink = (index) => wrapper.findAllByTestId('insights-slow-job-link').at(index);

  const getPerformanceInsightsHandler = jest
    .fn()
    .mockResolvedValue(mockPerformanceInsightsResponse);

  const getPerformanceInsightsNextPageHandler = jest
    .fn()
    .mockResolvedValue(mockPerformanceInsightsNextPageResponse);

  const requestHandlers = [[getPerformanceInsights, getPerformanceInsightsHandler]];

  const createComponent = (handlers = requestHandlers) => {
    wrapper = shallowMountExtended(PerformanceInsightsModal, {
      provide: {
        pipelineIid: '1',
        pipelineProjectPath: 'root/ci-project',
      },
      apolloProvider: createMockApollo(handlers),
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('without next page', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('displays modal', () => {
      expect(findModal().exists()).toBe(true);
    });

    it('does not dispaly alert', () => {
      expect(findAlert().exists()).toBe(false);
    });

    describe('queued duration card', () => {
      it('displays card data', () => {
        expect(trimText(findQueuedCardData().text())).toBe('4.9 days');
      });
      it('displays card link', () => {
        expect(findQueuedCardLink().attributes('href')).toBe(
          '/root/lots-of-jobs-project/-/pipelines/98',
        );
      });
    });

    describe('executed duration card', () => {
      it('displays card data', () => {
        expect(trimText(findExecutedCardData().text())).toBe('trigger_job');
      });
      it('displays card link', () => {
        expect(findExecutedCardLink().attributes('href')).toBe(
          '/root/lots-of-jobs-project/-/pipelines/98',
        );
      });
    });

    describe('slow jobs', () => {
      it.each`
        index | expectedStage | expectedName                | expectedLink
        ${0}  | ${'build'}    | ${'wait_job'}               | ${'/root/ci-project/-/jobs/2493'}
        ${1}  | ${'deploy'}   | ${'artifact_job'}           | ${'/root/ci-project/-/jobs/2501'}
        ${2}  | ${'test'}     | ${'allow_failure_test_job'} | ${'/root/ci-project/-/jobs/2497'}
        ${3}  | ${'build'}    | ${'large_log_output'}       | ${'/root/ci-project/-/jobs/2495'}
        ${4}  | ${'build'}    | ${'build_job'}              | ${'/root/ci-project/-/jobs/2494'}
      `(
        'should display slow job correctly',
        ({ index, expectedStage, expectedName, expectedLink }) => {
          expect(findSlowJobsStage(index).text()).toBe(expectedStage);
          expect(findSlowJobsLink(index).text()).toBe(expectedName);
          expect(findSlowJobsLink(index).attributes('href')).toBe(expectedLink);
        },
      );
    });
  });

  describe('limit alert', () => {
    it('displays limit alert when there is a next page', async () => {
      createComponent([[getPerformanceInsights, getPerformanceInsightsNextPageHandler]]);

      await waitForPromises();

      expect(findAlert().exists()).toBe(true);
      expect(findLink().attributes('href')).toBe(
        'https://gitlab.com/gitlab-org/gitlab/-/issues/365902',
      );
    });
  });
});
