import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton, GlDisclosureDropdown, GlDropdownDivider, GlLoadingIcon } from '@gitlab/ui';

import { mountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/alert';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import JobDropdownItem from '~/ci/common/private/job_dropdown_item.vue';
import PipelineStageDropdown from '~/ci/pipeline_mini_graph/pipeline_stage_dropdown.vue';

import getPipelineStageJobsQuery from '~/ci/pipeline_mini_graph/graphql/queries/get_pipeline_stage_jobs.query.graphql';
import { mockPipelineStageJobs, pipelineStage, pipelineStageJobsFetchError } from './mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('PipelineStageDropdown', () => {
  let wrapper;
  let pipelineStageResponse;

  const defaultProps = {
    stage: pipelineStage,
  };

  const createComponent = ({ pipelineStageHandler = pipelineStageResponse, props = {} } = {}) => {
    const handlers = [[getPipelineStageJobsQuery, pipelineStageHandler]];
    const mockApollo = createMockApollo(handlers);

    wrapper = mountExtended(PipelineStageDropdown, {
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
  const findDropdownDivider = () => wrapper.findComponent(GlDropdownDivider);
  const findJobDropdownItems = () => wrapper.findAllComponents(JobDropdownItem);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findStageDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

  const findDropdownHeader = () => wrapper.findByTestId('pipeline-stage-dropdown-menu-title');
  const findJobList = () => wrapper.findByTestId('pipeline-mini-graph-dropdown-menu-list');
  const findMergeTrainMessage = () => wrapper.findByTestId('merge-train-message');

  const clickStageDropdown = async () => {
    await findDropdownButton().trigger('click');
    await waitForPromises;
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
      await clickStageDropdown();

      expect(findDropdownHeader().text()).toBe('Stage: build');
    });

    it('emits miniGraphStageClick', async () => {
      await clickStageDropdown();

      expect(wrapper.emitted('miniGraphStageClick')).toHaveLength(1);
    });

    it('has fired the stage query', async () => {
      await clickStageDropdown();
      const { stage } = defaultProps;

      expect(pipelineStageResponse).toHaveBeenCalledWith({ id: stage.id });
    });

    describe('and query is loading', () => {
      it('renders a loading icon and no list', async () => {
        createComponent();
        await clickStageDropdown();

        expect(findLoadingIcon().exists()).toBe(true);
        expect(findJobList().exists()).toBe(false);
      });
    });

    describe('and query is successful', () => {
      beforeEach(async () => {
        await clickStageDropdown();
      });

      it('renders a list and no loading icon', () => {
        expect(findLoadingIcon().exists()).toBe(false);
        expect(findJobList().exists()).toBe(true);
      });

      it('should render 2 job items', () => {
        expect(findJobDropdownItems().exists()).toBe(true);
        expect(findJobDropdownItems()).toHaveLength(2);
      });

      it('emits jobActionExecuted', () => {
        findJobDropdownItems().at(0).vm.$emit('jobActionExecuted');
        expect(wrapper.emitted('jobActionExecuted')).toHaveLength(1);
      });
    });

    describe('and query is not successful', () => {
      const failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

      it('throws an error for the pipeline query', async () => {
        await createComponent({ pipelineStageHandler: failedHandler });
        await clickStageDropdown();
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({ message: pipelineStageJobsFetchError });
      });
    });
  });

  describe('when there are failed jobs', () => {
    beforeEach(async () => {
      pipelineStageResponse.mockResolvedValue(mockPipelineStageJobs);
      await createComponent();
      await clickStageDropdown();
      await waitForPromises();
    });

    it('renders failed jobs title', () => {
      expect(wrapper.findByText('Failed jobs').exists()).toBe(true);
    });

    it('renders divider', () => {
      expect(findDropdownDivider().exists()).toBe(true);
    });
  });

  describe('when there are no failed jobs', () => {
    beforeEach(async () => {
      const withoutFailedJob = { ...mockPipelineStageJobs };
      withoutFailedJob.data.ciPipelineStage.jobs.nodes = [
        mockPipelineStageJobs.data.ciPipelineStage.jobs.nodes[0],
      ];

      pipelineStageResponse.mockResolvedValue(withoutFailedJob);
      await createComponent();
      await clickStageDropdown();
      await waitForPromises();
    });

    it('does not render failed jobs title', () => {
      expect(wrapper.findByText('Failed jobs').exists()).toBe(false);
    });

    it('does not render divider', () => {
      expect(findDropdownDivider().exists()).toBe(false);
    });
  });

  describe('polling', () => {
    beforeEach(async () => {
      pipelineStageResponse.mockResolvedValue(mockPipelineStageJobs);
      await createComponent();
      await clickStageDropdown();
      await waitForPromises();
    });

    it('starts polling when dropdown is open', () => {
      expect(pipelineStageResponse).toHaveBeenCalledTimes(1);

      jest.advanceTimersByTime(8000);

      expect(pipelineStageResponse).toHaveBeenCalledTimes(2);
    });

    it('stops polling when dropdown is closed', async () => {
      expect(pipelineStageResponse).toHaveBeenCalledTimes(1);

      jest.advanceTimersByTime(8000);

      expect(pipelineStageResponse).toHaveBeenCalledTimes(2);

      await clickStageDropdown();
      await waitForPromises();

      jest.advanceTimersByTime(8000);

      expect(pipelineStageResponse).toHaveBeenCalledTimes(2);
    });
  });

  describe('merge train message', () => {
    it('does not display a message if the pipeline is not part of a merge train', async () => {
      await createComponent();
      await clickStageDropdown();

      expect(findMergeTrainMessage().exists()).toBe(false);
    });

    it('displays a message if the pipeline is part of a merge train', async () => {
      await createComponent({
        props: { isMergeTrain: true },
      });
      await clickStageDropdown();
      await waitForPromises();

      expect(findMergeTrainMessage().exists()).toBe(true);
    });
  });
});
