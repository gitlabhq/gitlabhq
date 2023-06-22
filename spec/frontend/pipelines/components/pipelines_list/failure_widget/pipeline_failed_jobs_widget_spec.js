import Vue from 'vue';
import VueApollo from 'vue-apollo';

import { GlButton, GlIcon, GlLoadingIcon, GlPopover, GlToast } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PipelineFailedJobsWidget from '~/pipelines/components/pipelines_list/failure_widget/pipeline_failed_jobs_widget.vue';
import { createAlert } from '~/alert';
import WidgetFailedJobRow from '~/pipelines/components/pipelines_list/failure_widget/widget_failed_job_row.vue';
import * as utils from '~/pipelines/components/pipelines_list/failure_widget/utils';
import getPipelineFailedJobs from '~/pipelines/graphql/queries/get_pipeline_failed_jobs.query.graphql';
import { failedJobsMock, failedJobsMock2 } from './mock';

Vue.use(VueApollo);
Vue.use(GlToast);

jest.mock('~/alert');

describe('PipelineFailedJobsWidget component', () => {
  let wrapper;
  let mockFailedJobsResponse;
  const showToast = jest.fn();

  const defaultProps = {
    pipelineIid: 1,
    pipelinePath: '/pipelines/1',
  };

  const defaultProvide = {
    fullPath: 'namespace/project/',
  };

  const createComponent = ({ props = {}, provide } = {}) => {
    const handlers = [[getPipelineFailedJobs, mockFailedJobsResponse]];
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
      mocks: {
        $toast: {
          show: showToast,
        },
      },
    });
  };

  const findAllHeaders = () => wrapper.findAllByTestId('header');
  const findFailedJobsButton = () => wrapper.findComponent(GlButton);
  const findFailedJobRows = () => wrapper.findAllComponents(WidgetFailedJobRow);
  const findInfoIcon = () => wrapper.findComponent(GlIcon);
  const findInfoPopover = () => wrapper.findComponent(GlPopover);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  beforeEach(() => {
    mockFailedJobsResponse = jest.fn();
  });

  describe('ui', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the show failed jobs button', () => {
      expect(findFailedJobsButton().exists()).toBe(true);
      expect(findFailedJobsButton().text()).toBe('Show failed jobs');
    });

    it('renders the info icon', () => {
      expect(findInfoIcon().exists()).toBe(true);
    });

    it('renders the info popover', () => {
      expect(findInfoPopover().exists()).toBe(true);
    });

    it('does not show the list of failed jobs', () => {
      expect(findFailedJobRows()).toHaveLength(0);
    });
  });

  describe('when loading failed jobs', () => {
    beforeEach(async () => {
      mockFailedJobsResponse.mockResolvedValue(failedJobsMock);
      createComponent();
      await findFailedJobsButton().vm.$emit('click');
    });

    it('shows a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when failed jobs have loaded', () => {
    beforeEach(async () => {
      mockFailedJobsResponse.mockResolvedValue(failedJobsMock);
      jest.spyOn(utils, 'sortJobsByStatus');

      createComponent();

      await findFailedJobsButton().vm.$emit('click');
      await waitForPromises();
    });

    it('does not renders a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders table column', () => {
      expect(findAllHeaders()).toHaveLength(4);
    });

    it('shows the list of failed jobs', () => {
      expect(findFailedJobRows()).toHaveLength(
        failedJobsMock.data.project.pipeline.jobs.nodes.length,
      );
    });

    it('calls sortJobsByStatus', () => {
      expect(utils.sortJobsByStatus).toHaveBeenCalledWith(
        failedJobsMock.data.project.pipeline.jobs.nodes,
      );
    });
  });

  describe('when an error occurs loading jobs', () => {
    const errorMessage = "We couldn't fetch jobs for you because you are not qualified";

    beforeEach(async () => {
      mockFailedJobsResponse.mockRejectedValue({ message: errorMessage });

      createComponent();

      await findFailedJobsButton().vm.$emit('click');
      await waitForPromises();
    });
    it('does not renders a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('calls create Alert with the error message and danger variant', () => {
      expect(createAlert).toHaveBeenCalledWith({ message: errorMessage, variant: 'danger' });
    });
  });

  describe('when `refetch-jobs` job is fired from the widget', () => {
    beforeEach(async () => {
      mockFailedJobsResponse.mockResolvedValueOnce(failedJobsMock);
      mockFailedJobsResponse.mockResolvedValueOnce(failedJobsMock2);

      createComponent();

      await findFailedJobsButton().vm.$emit('click');
      await waitForPromises();
    });

    it('refetches all failed jobs', async () => {
      expect(findFailedJobRows()).not.toHaveLength(
        failedJobsMock2.data.project.pipeline.jobs.nodes.length,
      );

      await findFailedJobRows().at(0).vm.$emit('job-retried', 'job-name');
      await waitForPromises();

      expect(findFailedJobRows()).toHaveLength(
        failedJobsMock2.data.project.pipeline.jobs.nodes.length,
      );
    });

    it('shows a toast message', async () => {
      await findFailedJobRows().at(0).vm.$emit('job-retried', 'job-name');
      await waitForPromises();

      expect(showToast).toHaveBeenCalledWith('job-name job is being retried');
    });
  });
});
