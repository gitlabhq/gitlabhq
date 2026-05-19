import { GlAlert } from '@gitlab/ui';
import { setHTMLFixture } from 'helpers/fixtures';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { CI_CONFIG_STATUS_VALID } from '~/ci/pipeline_editor/constants';
import LinksInner from '~/ci/pipeline_details/graph/components/links_inner.vue';
import LinksLayer from '~/ci/common/private/job_links_layer.vue';
import JobRow from '~/ci/pipeline_editor/components/graph/job_row.vue';
import PipelineGraph from '~/ci/pipeline_editor/components/graph/pipeline_graph.vue';
import { pipelineData, singleStageData } from './mock_data';

describe('pipeline graph component', () => {
  const defaultProps = { pipelineData };
  let wrapper;

  const containerId = 'pipeline-graph-container-0';
  setHTMLFixture(`<div id="${containerId}"></div>`);

  const createComponent = (props = defaultProps) => {
    return shallowMountExtended(PipelineGraph, {
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
  const findAllJobRows = () => wrapper.findAllComponents(JobRow);
  const findLinksLayer = () => wrapper.findComponent(LinksLayer);
  const findPipelineGraph = () => wrapper.findByTestId('graph-container');
  const findCardHeader = () => wrapper.findByTestId('card-header');
  const findAllCardHeaders = () => wrapper.findAllByTestId('card-header');

  describe('with `VALID` status', () => {
    beforeEach(() => {
      wrapper = createComponent(
        {
          pipelineData: {
            status: CI_CONFIG_STATUS_VALID,
            stages: [{ name: 'hello', groups: [] }],
          },
        },
        true,
      );
    });

    it('renders the graph with no status error', () => {
      expect(findAlert().exists()).toBe(false);
      expect(findPipelineGraph().exists()).toBe(true);
      expect(findLinksLayer().exists()).toBe(true);
    });
  });

  describe('with only one stage', () => {
    // We count the number of jobs in the mock data
    const expectedJobsLength = singleStageData.stages.reduce((acc, val) => {
      return acc + val.groups.length;
    }, 0);

    beforeEach(() => {
      wrapper = createComponent({ pipelineData: singleStageData });
    });

    it('renders the correct text in the card header', () => {
      expect(findCardHeader().text()).toContain('build');
      expect(findCardHeader().text()).toContain('1 job');
    });

    it('renders the right number of job rows', () => {
      expect(findAllJobRows()).toHaveLength(expectedJobsLength);
    });
  });

  describe('with multiple stages and jobs', () => {
    beforeEach(() => {
      wrapper = createComponent(defaultProps);
    });

    it('renders the right number of card headers', () => {
      const expectedStagesLength = pipelineData.stages.length;

      expect(findAllCardHeaders()).toHaveLength(expectedStagesLength);
    });

    it('renders the right number of job rows', () => {
      // We count the number of jobs in the mock data
      const expectedJobsLength = pipelineData.stages.reduce((acc, val) => {
        return acc + val.groups.length;
      }, 0);

      expect(findAllJobRows()).toHaveLength(expectedJobsLength);
    });
  });
});
