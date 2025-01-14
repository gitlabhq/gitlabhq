import { GlBadge } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { toggleQueryPollingByVisibility } from '~/graphql_shared/utils';
import PipelineFailedJobsWidget from '~/ci/pipelines_page/components/failure_widget/pipeline_failed_jobs_widget.vue';
import FailedJobsList from '~/ci/pipelines_page/components/failure_widget/failed_jobs_list.vue';
import getPipelineFailedJobsCount from '~/ci/pipelines_page/graphql/queries/get_pipeline_failed_jobs_count.query.graphql';
import { failedJobsCountMock, failedJobsCountMockActive } from './mock';

Vue.use(VueApollo);
jest.mock('~/alert');
jest.mock('~/graphql_shared/utils');

describe('PipelineFailedJobsWidget component', () => {
  let wrapper;

  const defaultProps = {
    pipelineIid: 1,
    pipelinePath: '/pipelines/1',
    projectPath: 'namespace/project/',
  };

  const defaultProvide = {
    fullPath: 'namespace/project/',
    graphqlPath: 'api/graphql',
  };

  const defaultHandler = jest.fn().mockResolvedValue(failedJobsCountMock);
  const activeHandler = jest.fn().mockResolvedValue(failedJobsCountMockActive);

  const createMockApolloProvider = (handler) => {
    const requestHandlers = [[getPipelineFailedJobsCount, handler]];

    return createMockApollo(requestHandlers);
  };

  const createComponent = ({ props = {}, provide = {}, handler = defaultHandler } = {}) => {
    wrapper = shallowMountExtended(PipelineFailedJobsWidget, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...defaultProvide,
        ...provide,
      },
      stubs: { CrudComponent },
      apolloProvider: createMockApolloProvider(handler),
    });
  };

  const findFailedJobsButton = () => wrapper.findByTestId('toggle-button');
  const findFailedJobsList = () => wrapper.findComponent(FailedJobsList);
  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findCount = () => wrapper.findComponent(GlBadge);
  const findFeedbackButton = () => wrapper.findByTestId('feedback-button');

  describe('when there are failed jobs', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('renders the show failed jobs button with correct count', () => {
      expect(findFailedJobsButton().exists()).toBe(true);
      expect(findCount().text()).toBe('4');
    });

    it('does not render the failed jobs widget', () => {
      expect(findFailedJobsList().exists()).toBe(false);
    });
  });

  const CSS_BORDER_CLASSES = 'is-collapsed gl-border-transparent hover:gl-border-default';

  describe('when the job button is clicked', () => {
    beforeEach(async () => {
      createComponent();

      await findFailedJobsButton().vm.$emit('click');
    });

    it('renders the failed jobs widget', () => {
      expect(findFailedJobsList().exists()).toBe(true);
    });

    it('removes the CSS border classes', () => {
      expect(findCrudComponent().attributes('class')).not.toContain(CSS_BORDER_CLASSES);
    });

    it('the failed jobs button has the correct "aria-expanded" attribute value', () => {
      expect(findFailedJobsButton().attributes('aria-expanded')).toBe('true');
    });

    it('displays feedback button', () => {
      expect(findFeedbackButton().exists()).toBe(true);
    });
  });

  describe('when the job details are not expanded', () => {
    beforeEach(() => {
      createComponent();
    });

    it('has the CSS border classes', () => {
      expect(findCrudComponent().attributes('class')).toContain(CSS_BORDER_CLASSES);
    });

    it('the failed jobs button has the correct "aria-expanded" attribute value', () => {
      expect(findFailedJobsButton().attributes('aria-expanded')).toBe('false');
    });

    it('does not display feedback button', () => {
      expect(findFeedbackButton().exists()).toBe(false);
    });
  });

  describe('"aria-controls" attribute', () => {
    it('is set and identifies the correct element', () => {
      createComponent();

      expect(findFailedJobsButton().attributes('aria-controls')).toBe(
        'pipeline-failed-jobs-widget',
      );
      expect(findCrudComponent().attributes('id')).toBe('pipeline-failed-jobs-widget');
    });
  });

  describe('polling', () => {
    it('does not poll for failed jobs count when pipeline is inactive', async () => {
      createComponent();

      await waitForPromises();

      expect(defaultHandler).toHaveBeenCalledTimes(1);

      jest.advanceTimersByTime(10000);

      await waitForPromises();

      expect(defaultHandler).toHaveBeenCalledTimes(1);
    });

    it('polls for failed jobs count when pipeline is active', async () => {
      createComponent({ handler: activeHandler });

      await waitForPromises();

      expect(activeHandler).toHaveBeenCalledTimes(1);

      jest.advanceTimersByTime(10000);

      await waitForPromises();

      expect(activeHandler).toHaveBeenCalledTimes(2);
    });

    it('should set up toggle visibility when pipeline is active', async () => {
      createComponent({ handler: activeHandler });

      await waitForPromises();

      expect(toggleQueryPollingByVisibility).toHaveBeenCalled();
    });
  });

  describe('job retry', () => {
    it.each`
      active   | handler
      ${true}  | ${activeHandler}
      ${false} | ${defaultHandler}
    `(
      'stops polling and restarts polling: $active if pipeline is active: $active',
      async ({ active, handler }) => {
        createComponent({ handler });

        await waitForPromises();

        const stopPollingSpy = jest.spyOn(
          wrapper.vm.$apollo.queries.failedJobsCount,
          'stopPolling',
        );
        const startPollingSpy = jest.spyOn(
          wrapper.vm.$apollo.queries.failedJobsCount,
          'startPolling',
        );

        await findFailedJobsButton().vm.$emit('click');

        await findFailedJobsList().vm.$emit('job-retried');

        expect(stopPollingSpy).toHaveBeenCalled();

        await waitForPromises();

        if (active) {
          expect(startPollingSpy).toHaveBeenCalled();
        } else {
          expect(startPollingSpy).not.toHaveBeenCalled();
        }
      },
    );

    it('refetches failed jobs count', async () => {
      createComponent();

      await waitForPromises();

      expect(defaultHandler).toHaveBeenCalledTimes(1);

      await findFailedJobsButton().vm.$emit('click');

      findFailedJobsList().vm.$emit('job-retried');

      expect(defaultHandler).toHaveBeenCalledTimes(2);
    });
  });
});
