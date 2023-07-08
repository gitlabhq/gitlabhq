import Vue from 'vue';
import VueApollo from 'vue-apollo';

import { GlButton, GlIcon, GlPopover } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PipelineFailedJobsWidget from '~/pipelines/components/pipelines_list/failure_widget/pipeline_failed_jobs_widget.vue';
import FailedJobsList from '~/pipelines/components/pipelines_list/failure_widget/failed_jobs_list.vue';
import getPipelineFailedJobsCount from '~/pipelines/graphql/queries/get_pipeline_failed_jobs_count.query.graphql';
import { createFailedJobsMockCount } from './mock';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('PipelineFailedJobsWidget component', () => {
  let wrapper;
  let mockFailedJobsResponse;

  const defaultProps = {
    isPipelineActive: false,
    pipelineIid: 1,
    pipelinePath: '/pipelines/1',
  };

  const defaultProvide = {
    fullPath: 'namespace/project/',
    graphqlPath: '/api/graphql',
  };

  const createComponent = ({ props = {}, provide } = {}) => {
    const handlers = [[getPipelineFailedJobsCount, mockFailedJobsResponse]];
    const mockApollo = createMockApollo(handlers);

    wrapper = shallowMountExtended(PipelineFailedJobsWidget, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...defaultProvide,
        ...provide,
      },
      apolloProvider: mockApollo,
    });
  };

  const findFailedJobsButton = () => wrapper.findComponent(GlButton);
  const findFailedJobsList = () => wrapper.findAllComponents(FailedJobsList);
  const findInfoIcon = () => wrapper.findComponent(GlIcon);
  const findInfoPopover = () => wrapper.findComponent(GlPopover);

  beforeEach(() => {
    mockFailedJobsResponse = jest.fn().mockResolvedValue(createFailedJobsMockCount());
  });

  describe('when it is loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the show failed jobs button with a count of 0', () => {
      expect(findFailedJobsButton().exists()).toBe(true);
      expect(findFailedJobsButton().text()).toBe('Show failed jobs (0)');
    });
  });

  describe('when the failed jobs have loaded', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('renders the show failed jobs button with correct count', () => {
      expect(findFailedJobsButton().exists()).toBe(true);
      expect(findFailedJobsButton().text()).toBe('Show failed jobs (4)');
    });

    it('renders the info icon', () => {
      expect(findInfoIcon().exists()).toBe(true);
    });

    it('renders the info popover', () => {
      expect(findInfoPopover().exists()).toBe(true);
    });

    it('does not render the failed jobs widget', () => {
      expect(findFailedJobsList().exists()).toBe(false);
    });
  });

  describe('when the job button is clicked', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();

      await findFailedJobsButton().vm.$emit('click');
    });

    it('renders the failed jobs widget', () => {
      expect(findFailedJobsList().exists()).toBe(true);
    });
  });

  describe('polling', () => {
    it.each`
      isGraphqlActive | isExpanded | shouldPoll | text
      ${true}         | ${false}   | ${true}    | ${'polls'}
      ${false}        | ${false}   | ${false}   | ${'does not poll'}
      ${true}         | ${true}    | ${false}   | ${'does not poll'}
      ${false}        | ${true}    | ${false}   | ${'does not poll'}
    `(
      `$text when isGraphqlActive: $isGraphqlActive, isExpanded: $isExpanded`,
      async ({ isGraphqlActive, isExpanded, shouldPoll }) => {
        const defaultCount = 4;
        const newCount = 1;
        const expectedCount = shouldPoll ? newCount : defaultCount;
        const expectedCallCount = shouldPoll ? 2 : 1;

        // Second result is to simulate polling with a different response
        mockFailedJobsResponse.mockResolvedValueOnce(
          createFailedJobsMockCount({ active: isGraphqlActive, count: defaultCount }),
        );
        mockFailedJobsResponse.mockResolvedValueOnce(
          createFailedJobsMockCount({ active: isGraphqlActive, count: newCount }),
        );

        createComponent();
        await waitForPromises();

        // Initially, we get the first response which is always the default
        expect(mockFailedJobsResponse).toHaveBeenCalledTimes(1);
        expect(findFailedJobsButton().text()).toBe(`Show failed jobs (${defaultCount})`);

        // If the user expands the widget, polling stops
        if (isExpanded) {
          await findFailedJobsButton().vm.$emit('click');
        }

        jest.advanceTimersByTime(10000);
        await waitForPromises();

        expect(mockFailedJobsResponse).toHaveBeenCalledTimes(expectedCallCount);
        expect(findFailedJobsButton().text()).toBe(`Show failed jobs (${expectedCount})`);
      },
    );
  });

  describe('when a REST action occurs', () => {
    const defaultCount = 4;
    const newCount = 1;

    beforeEach(() => {
      // Second result is to simulate polling with a different response
      mockFailedJobsResponse.mockResolvedValueOnce(
        createFailedJobsMockCount({ active: false, count: defaultCount }),
      );
      mockFailedJobsResponse.mockResolvedValueOnce(
        createFailedJobsMockCount({ active: false, count: newCount }),
      );
    });

    it.each([true, false])('triggers a refetch of the jobs count', async (isPipelineActive) => {
      createComponent({ props: { isPipelineActive } });
      await waitForPromises();

      // Initially, we get the first response which is always the default
      expect(mockFailedJobsResponse).toHaveBeenCalledTimes(1);
      expect(findFailedJobsButton().text()).toBe(`Show failed jobs (${defaultCount})`);

      await wrapper.setProps({ isPipelineActive: !isPipelineActive });
      await waitForPromises();

      expect(mockFailedJobsResponse).toHaveBeenCalledTimes(2);
      expect(findFailedJobsButton().text()).toBe(`Show failed jobs (${newCount})`);
    });
  });
});
