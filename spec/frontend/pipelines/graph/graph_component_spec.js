import { mount, shallowMount } from '@vue/test-utils';
import { GRAPHQL, LAYER_VIEW, STAGE_VIEW } from '~/pipelines/components/graph/constants';
import PipelineGraph from '~/pipelines/components/graph/graph_component.vue';
import JobItem from '~/pipelines/components/graph/job_item.vue';
import LinkedPipelinesColumn from '~/pipelines/components/graph/linked_pipelines_column.vue';
import StageColumnComponent from '~/pipelines/components/graph/stage_column_component.vue';
import LinksLayer from '~/pipelines/components/graph_shared/links_layer.vue';
import { listByLayers } from '~/pipelines/components/parsing_utils';
import {
  generateResponse,
  mockPipelineResponse,
  pipelineWithUpstreamDownstream,
} from './mock_data';

describe('graph component', () => {
  let wrapper;

  const findLinkedColumns = () => wrapper.findAll(LinkedPipelinesColumn);
  const findLinksLayer = () => wrapper.find(LinksLayer);
  const findStageColumns = () => wrapper.findAll(StageColumnComponent);
  const findStageNameInJob = () => wrapper.find('[data-testid="stage-name-in-job"]');

  const defaultProps = {
    pipeline: generateResponse(mockPipelineResponse, 'root/fungi-xoxo'),
    showLinks: false,
    viewType: STAGE_VIEW,
    configPaths: {
      metricsPath: '',
      graphqlResourceEtag: 'this/is/a/path',
    },
  };

  const defaultData = {
    measurements: {
      width: 800,
      height: 800,
    },
  };

  const createComponent = ({
    data = {},
    mountFn = shallowMount,
    props = {},
    stubOverride = {},
  } = {}) => {
    wrapper = mountFn(PipelineGraph, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      data() {
        return {
          ...defaultData,
          ...data,
        };
      },
      provide: {
        dataMethod: GRAPHQL,
      },
      stubs: {
        'links-inner': true,
        'linked-pipeline': true,
        'job-item': true,
        'job-group-dropdown': true,
        ...stubOverride,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('with data', () => {
    beforeEach(() => {
      createComponent({ mountFn: mount });
    });

    it('renders the main columns in the graph', () => {
      expect(findStageColumns()).toHaveLength(defaultProps.pipeline.stages.length);
    });

    it('renders the links layer', () => {
      expect(findLinksLayer().exists()).toBe(true);
    });

    it('does not display stage name on the job in default (stage) mode', () => {
      expect(findStageNameInJob().exists()).toBe(false);
    });

    describe('when column requests a refresh', () => {
      beforeEach(() => {
        findStageColumns().at(0).vm.$emit('refreshPipelineGraph');
      });

      it('refreshPipelineGraph is emitted', () => {
        expect(wrapper.emitted().refreshPipelineGraph).toHaveLength(1);
      });
    });

    describe('when links are present', () => {
      beforeEach(() => {
        createComponent({
          mountFn: mount,
          stubOverride: { 'job-item': false },
          data: { hoveredJobName: 'test_a' },
        });
        findLinksLayer().vm.$emit('highlightedJobsChange', ['test_c', 'build_c']);
      });

      it('dims unrelated jobs', () => {
        const unrelatedJob = wrapper.find(JobItem);
        expect(findLinksLayer().emitted().highlightedJobsChange).toHaveLength(1);
        expect(unrelatedJob.classes('gl-opacity-3')).toBe(true);
      });
    });
  });

  describe('when linked pipelines are not present', () => {
    beforeEach(() => {
      createComponent({ mountFn: mount });
    });

    it('should not render a linked pipelines column', () => {
      expect(findLinkedColumns()).toHaveLength(0);
    });
  });

  describe('when linked pipelines are present', () => {
    beforeEach(() => {
      createComponent({
        mountFn: mount,
        props: { pipeline: pipelineWithUpstreamDownstream(mockPipelineResponse) },
      });
    });

    it('should render linked pipelines columns', () => {
      expect(findLinkedColumns()).toHaveLength(2);
    });
  });

  describe('in layers mode', () => {
    beforeEach(() => {
      createComponent({
        mountFn: mount,
        stubOverride: {
          'job-item': false,
          'job-group-dropdown': false,
        },
        props: {
          viewType: LAYER_VIEW,
          pipelineLayers: listByLayers(defaultProps.pipeline),
        },
      });
    });

    it('displays the stage name on the job', () => {
      expect(findStageNameInJob().exists()).toBe(true);
    });
  });
});
