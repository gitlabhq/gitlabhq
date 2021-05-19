import '~/commons';
import { GlTable } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import PipelineMiniGraph from '~/pipelines/components/pipelines_list/pipeline_mini_graph.vue';
import PipelineOperations from '~/pipelines/components/pipelines_list/pipeline_operations.vue';
import PipelineTriggerer from '~/pipelines/components/pipelines_list/pipeline_triggerer.vue';
import PipelineUrl from '~/pipelines/components/pipelines_list/pipeline_url.vue';
import PipelinesTable from '~/pipelines/components/pipelines_list/pipelines_table.vue';
import PipelinesTimeago from '~/pipelines/components/pipelines_list/time_ago.vue';

import eventHub from '~/pipelines/event_hub';
import CiBadge from '~/vue_shared/components/ci_badge_link.vue';
import CommitComponent from '~/vue_shared/components/commit.vue';

jest.mock('~/pipelines/event_hub');

describe('Pipelines Table', () => {
  let pipeline;
  let wrapper;

  const jsonFixtureName = 'pipelines/pipelines.json';

  const defaultProps = {
    pipelines: [],
    viewType: 'root',
  };

  const createMockPipeline = () => {
    const { pipelines } = getJSONFixture(jsonFixtureName);
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

  const findGlTable = () => wrapper.findComponent(GlTable);
  const findStatusBadge = () => wrapper.findComponent(CiBadge);
  const findPipelineInfo = () => wrapper.findComponent(PipelineUrl);
  const findTriggerer = () => wrapper.findComponent(PipelineTriggerer);
  const findCommit = () => wrapper.findComponent(CommitComponent);
  const findPipelineMiniGraph = () => wrapper.findComponent(PipelineMiniGraph);
  const findTimeAgo = () => wrapper.findComponent(PipelinesTimeago);
  const findActions = () => wrapper.findComponent(PipelineOperations);

  const findTableRows = () => wrapper.findAllByTestId('pipeline-table-row');
  const findStatusTh = () => wrapper.findByTestId('status-th');
  const findPipelineTh = () => wrapper.findByTestId('pipeline-th');
  const findTriggererTh = () => wrapper.findByTestId('triggerer-th');
  const findCommitTh = () => wrapper.findByTestId('commit-th');
  const findStagesTh = () => wrapper.findByTestId('stages-th');
  const findTimeAgoTh = () => wrapper.findByTestId('timeago-th');
  const findActionsTh = () => wrapper.findByTestId('actions-th');

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
      expect(findGlTable().exists()).toBe(true);
    });

    it('should render table head with correct columns', () => {
      expect(findStatusTh().text()).toBe('Status');
      expect(findPipelineTh().text()).toBe('Pipeline');
      expect(findTriggererTh().text()).toBe('Triggerer');
      expect(findCommitTh().text()).toBe('Commit');
      expect(findStagesTh().text()).toBe('Stages');
      expect(findTimeAgoTh().text()).toBe('Duration');
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

    describe('triggerer cell', () => {
      it('should render the pipeline triggerer', () => {
        expect(findTriggerer().exists()).toBe(true);
      });
    });

    describe('commit cell', () => {
      it('should render commit information', () => {
        expect(findCommit().exists()).toBe(true);
      });

      it('should display and link to commit', () => {
        expect(findCommit().text()).toContain(pipeline.commit.short_id);
        expect(findCommit().props('commitUrl')).toBe(pipeline.commit.commit_path);
      });

      it('should display the commit author', () => {
        expect(findCommit().props('author')).toEqual(pipeline.commit.author);
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

          createComponent({ pipelines: [pipeline] }, true);
        });

        it('stages are not rendered', () => {
          expect(findPipelineMiniGraph().exists()).toBe(false);
        });
      });

      it('should not update dropdown', () => {
        expect(findPipelineMiniGraph().props('updateDropdown')).toBe(false);
      });

      it('when update graph dropdown is set, should update graph dropdown', () => {
        createComponent({ pipelines: [pipeline], updateGraphDropdown: true }, true);

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
    });
  });
});
