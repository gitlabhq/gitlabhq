import '~/commons';
import { GlTableLite } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import fixture from 'test_fixtures/pipelines/pipelines.json';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import PipelineMiniGraph from '~/pipelines/components/pipelines_list/pipeline_mini_graph.vue';
import PipelineOperations from '~/pipelines/components/pipelines_list/pipeline_operations.vue';
import PipelineTriggerer from '~/pipelines/components/pipelines_list/pipeline_triggerer.vue';
import PipelineUrl from '~/pipelines/components/pipelines_list/pipeline_url.vue';
import PipelinesTable from '~/pipelines/components/pipelines_list/pipelines_table.vue';
import PipelinesTimeago from '~/pipelines/components/pipelines_list/time_ago.vue';
import {
  PipelineKeyOptions,
  BUTTON_TOOLTIP_RETRY,
  BUTTON_TOOLTIP_CANCEL,
} from '~/pipelines/constants';

import eventHub from '~/pipelines/event_hub';
import CiBadge from '~/vue_shared/components/ci_badge_link.vue';

jest.mock('~/pipelines/event_hub');

describe('Pipelines Table', () => {
  let pipeline;
  let wrapper;

  const defaultProps = {
    pipelines: [],
    viewType: 'root',
    pipelineKeyOption: PipelineKeyOptions[0],
  };

  const createMockPipeline = () => {
    // Clone fixture as it could be modified by tests
    const { pipelines } = JSON.parse(JSON.stringify(fixture));
    return pipelines.find((p) => p.user !== null && p.commit !== null);
  };

  const createComponent = (props = {}) => {
    wrapper = extendedWrapper(
      mount(PipelinesTable, {
        propsData: {
          ...defaultProps,
          ...props,
        },
      }),
    );
  };

  const findGlTableLite = () => wrapper.findComponent(GlTableLite);
  const findStatusBadge = () => wrapper.findComponent(CiBadge);
  const findPipelineInfo = () => wrapper.findComponent(PipelineUrl);
  const findTriggerer = () => wrapper.findComponent(PipelineTriggerer);
  const findPipelineMiniGraph = () => wrapper.findComponent(PipelineMiniGraph);
  const findTimeAgo = () => wrapper.findComponent(PipelinesTimeago);
  const findActions = () => wrapper.findComponent(PipelineOperations);

  const findTableRows = () => wrapper.findAllByTestId('pipeline-table-row');
  const findStatusTh = () => wrapper.findByTestId('status-th');
  const findPipelineTh = () => wrapper.findByTestId('pipeline-th');
  const findStagesTh = () => wrapper.findByTestId('stages-th');
  const findActionsTh = () => wrapper.findByTestId('actions-th');
  const findRetryBtn = () => wrapper.findByTestId('pipelines-retry-button');
  const findCancelBtn = () => wrapper.findByTestId('pipelines-cancel-button');

  beforeEach(() => {
    pipeline = createMockPipeline();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('Pipelines Table', () => {
    beforeEach(() => {
      createComponent({ pipelines: [pipeline], viewType: 'root' });
    });

    it('displays table', () => {
      expect(findGlTableLite().exists()).toBe(true);
    });

    it('should render table head with correct columns', () => {
      expect(findStatusTh().text()).toBe('Status');
      expect(findPipelineTh().text()).toBe('Pipeline');
      expect(findStagesTh().text()).toBe('Stages');
      expect(findActionsTh().text()).toBe('Actions');
    });

    it('should display a table row', () => {
      expect(findTableRows()).toHaveLength(1);
    });

    describe('status cell', () => {
      it('should render a status badge', () => {
        expect(findStatusBadge().exists()).toBe(true);
      });

      it('should render status badge with correct path', () => {
        expect(findStatusBadge().attributes('href')).toBe(pipeline.path);
      });
    });

    describe('pipeline cell', () => {
      it('should render pipeline information', () => {
        expect(findPipelineInfo().exists()).toBe(true);
      });

      it('should display the pipeline id', () => {
        expect(findPipelineInfo().text()).toContain(`#${pipeline.id}`);
      });
    });

    describe('stages cell', () => {
      it('should render a pipeline mini graph', () => {
        expect(findPipelineMiniGraph().exists()).toBe(true);
      });

      it('should render the right number of stages', () => {
        const stagesLength = pipeline.details.stages.length;
        expect(
          findPipelineMiniGraph().findAll('[data-testid="mini-pipeline-graph-dropdown"]'),
        ).toHaveLength(stagesLength);
      });

      describe('when pipeline does not have stages', () => {
        beforeEach(() => {
          pipeline = createMockPipeline();
          pipeline.details.stages = null;

          createComponent({ pipelines: [pipeline] });
        });

        it('stages are not rendered', () => {
          expect(findPipelineMiniGraph().exists()).toBe(false);
        });
      });

      it('should not update dropdown', () => {
        expect(findPipelineMiniGraph().props('updateDropdown')).toBe(false);
      });

      it('when update graph dropdown is set, should update graph dropdown', () => {
        createComponent({ pipelines: [pipeline], updateGraphDropdown: true });

        expect(findPipelineMiniGraph().props('updateDropdown')).toBe(true);
      });

      it('when action request is complete, should refresh table', () => {
        findPipelineMiniGraph().vm.$emit('pipelineActionRequestComplete');

        expect(eventHub.$emit).toHaveBeenCalledWith('refreshPipelinesTable');
      });
    });

    describe('duration cell', () => {
      it('should render duration information', () => {
        expect(findTimeAgo().exists()).toBe(true);
      });
    });

    describe('operations cell', () => {
      it('should render pipeline operations', () => {
        expect(findActions().exists()).toBe(true);
      });

      it('should render retry action tooltip', () => {
        expect(findRetryBtn().attributes('title')).toBe(BUTTON_TOOLTIP_RETRY);
      });

      it('should render cancel action tooltip', () => {
        expect(findCancelBtn().attributes('title')).toBe(BUTTON_TOOLTIP_CANCEL);
      });
    });

    describe('triggerer cell', () => {
      it('should render the pipeline triggerer', () => {
        expect(findTriggerer().exists()).toBe(true);
      });
    });
  });
});
