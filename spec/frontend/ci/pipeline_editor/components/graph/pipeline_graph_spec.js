import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { setHTMLFixture } from 'helpers/fixtures';
import { CI_CONFIG_STATUS_VALID } from '~/ci/pipeline_editor/constants';
import LinksInner from '~/ci/pipeline_details/graph/components/links_inner.vue';
import LinksLayer from '~/ci/common/private/job_links_layer.vue';
import JobPill from '~/ci/pipeline_editor/components/graph/job_pill.vue';
import PipelineGraph from '~/ci/pipeline_editor/components/graph/pipeline_graph.vue';
import StageName from '~/ci/pipeline_editor/components/graph/stage_name.vue';
import { pipelineData, singleStageData } from './mock_data';

describe('pipeline graph component', () => {
  const defaultProps = { pipelineData };
  let wrapper;

  const containerId = 'pipeline-graph-container-0';
  setHTMLFixture(`<div id="${containerId}"></div>`);

  const createComponent = (props = defaultProps) => {
    return shallowMount(PipelineGraph, {
      propsData: {
        ...props,
      },
      stubs: { LinksLayer, LinksInner },
      data() {
        return {
          measurements: {
            width: 1000,
            height: 1000,
          },
        };
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findAllJobPills = () => wrapper.findAllComponents(JobPill);
  const findAllStageNames = () => wrapper.findAllComponents(StageName);
  const findLinksLayer = () => wrapper.findComponent(LinksLayer);
  const findPipelineGraph = () => wrapper.find('[data-testid="graph-container"]');

  describe('with `VALID` status', () => {
    beforeEach(() => {
      wrapper = createComponent({
        pipelineData: {
          status: CI_CONFIG_STATUS_VALID,
          stages: [{ name: 'hello', groups: [] }],
        },
      });
    });

    it('renders the graph with no status error', () => {
      expect(findAlert().exists()).toBe(false);
      expect(findPipelineGraph().exists()).toBe(true);
      expect(findLinksLayer().exists()).toBe(true);
    });
  });

  describe('with only one stage', () => {
    beforeEach(() => {
      wrapper = createComponent({ pipelineData: singleStageData });
    });

    it('renders the right number of stage titles', () => {
      const expectedStagesLength = singleStageData.stages.length;

      expect(findAllStageNames()).toHaveLength(expectedStagesLength);
    });

    it('renders the right number of job pills', () => {
      // We count the number of jobs in the mock data
      const expectedJobsLength = singleStageData.stages.reduce((acc, val) => {
        return acc + val.groups.length;
      }, 0);

      expect(findAllJobPills()).toHaveLength(expectedJobsLength);
    });
  });

  describe('with multiple stages and jobs', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the right number of stage titles', () => {
      const expectedStagesLength = pipelineData.stages.length;

      expect(findAllStageNames()).toHaveLength(expectedStagesLength);
    });

    it('renders the right number of job pills', () => {
      // We count the number of jobs in the mock data
      const expectedJobsLength = pipelineData.stages.reduce((acc, val) => {
        return acc + val.groups.length;
      }, 0);

      expect(findAllJobPills()).toHaveLength(expectedJobsLength);
    });
  });
});
