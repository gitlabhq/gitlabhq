import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton, GlDisclosureDropdown, GlLoadingIcon } from '@gitlab/ui';

import { mountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/alert';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import JobItem from '~/ci/pipeline_mini_graph/job_item.vue';
import PipelineStage from '~/ci/pipeline_mini_graph/pipeline_stage.vue';

import getPipelineStageJobsQuery from '~/ci/pipeline_mini_graph/graphql/queries/get_pipeline_stage_jobs.query.graphql';
import { mockPipelineStageJobs, pipelineStage, pipelineStageJobsFetchError } from './mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('PipelineStage', () => {
  let wrapper;
  let pipelineStageResponse;

  const defaultProps = {
    pipelineEtag: '/etag',
    stage: pipelineStage,
  };

  const createComponent = ({ pipelineStageHandler = pipelineStageResponse, props = {} } = {}) => {
    const handlers = [[getPipelineStageJobsQuery, pipelineStageHandler]];
    const mockApollo = createMockApollo(handlers);

    wrapper = mountExtended(PipelineStage, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        ...defaultProps,
        ...props,
      },
      apolloProvider: mockApollo,
    });

    return waitForPromises();
  };

  const findCiIcon = () => wrapper.findComponent(CiIcon);
  const findDropdownButton = () => wrapper.findComponent(GlButton);
  const findJobItems = () => wrapper.findAllComponents(JobItem);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findStageDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

  const findDropdownHeader = () => wrapper.findByTestId('pipeline-stage-dropdown-menu-title');
  const findJobList = () => wrapper.findByTestId('pipeline-stage-dropdown-menu-list');
  const findMergeTrainMessage = () => wrapper.findByTestId('merge-train-message');

  const openStageDropdown = async () => {
    await findDropdownButton().trigger('click');
  };

  beforeEach(() => {
    pipelineStageResponse = jest.fn();
    createComponent();
  });

  describe('when mounted', () => {
    it('renders the dropdown', () => {
      expect(findStageDropdown().exists()).toBe(true);
    });

    it('has not fired the stage query', () => {
      expect(pipelineStageResponse).not.toHaveBeenCalled();
    });
  });

  describe('dropdown appearance', () => {
    it('renders the icon', () => {
      expect(findCiIcon().exists()).toBe(true);
    });

    it('has the correct status', () => {
      expect(findCiIcon().props('status')).toEqual(pipelineStage.detailedStatus);
    });

    it('renders the correct tooltip text', () => {
      const tooltip = getBinding(findDropdownButton().element, 'gl-tooltip');
      const tooltipText = `${pipelineStage.name}: ${pipelineStage.detailedStatus.tooltip}`;

      expect(findDropdownButton().attributes('title')).toBe(tooltipText);
      expect(tooltip.value).toBe(tooltipText);
    });
  });

  describe('when dropdown is clicked', () => {
    beforeEach(async () => {
      await createComponent();
      pipelineStageResponse.mockResolvedValue(mockPipelineStageJobs);
    });

    it('has the correct header title', async () => {
      await openStageDropdown();

      expect(findDropdownHeader().text()).toBe('Stage: build');
    });

    it('has fired the stage query', async () => {
      await openStageDropdown();
      const { stage } = defaultProps;

      expect(pipelineStageResponse).toHaveBeenCalledWith({ id: stage.id });
    });

    describe('and query is loading', () => {
      it('renders a loading icon and no list', async () => {
        createComponent();
        await openStageDropdown();

        expect(findLoadingIcon().exists()).toBe(true);
        expect(findJobList().exists()).toBe(false);
      });
    });

    describe('and query is successful', () => {
      beforeEach(async () => {
        await openStageDropdown();
        await waitForPromises();
      });

      it('renders a list and no loading icon', () => {
        expect(findLoadingIcon().exists()).toBe(false);
        expect(findJobList().exists()).toBe(true);
      });

      it('should render 2 job items', () => {
        expect(findJobItems().exists()).toBe(true);
        expect(findJobItems()).toHaveLength(2);
      });
    });
    describe('and query is not successful', () => {
      const failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

      it('throws an error for the pipeline query', async () => {
        await createComponent({ pipelineStageHandler: failedHandler });
        await openStageDropdown();
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({ message: pipelineStageJobsFetchError });
      });
    });
  });

  describe('merge train message', () => {
    it('does not display a message if the pipeline is not part of a merge train', async () => {
      await createComponent();
      await openStageDropdown();

      expect(findMergeTrainMessage().exists()).toBe(false);
    });
    it('displays a message if the pipeline is part of a merge train', async () => {
      await createComponent({
        props: { isMergeTrain: true },
      });
      await openStageDropdown();
      await waitForPromises();

      expect(findMergeTrainMessage().exists()).toBe(true);
    });
  });
});
