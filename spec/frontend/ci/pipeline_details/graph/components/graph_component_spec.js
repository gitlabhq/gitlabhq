import { shallowMount } from '@vue/test-utils';
import mockPipelineResponse from 'test_fixtures/pipelines/pipeline_details.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { LAYER_VIEW, STAGE_VIEW } from '~/ci/pipeline_details/graph/constants';
import PipelineGraph from '~/ci/pipeline_details/graph/components/graph_component.vue';
import JobItem from '~/ci/pipeline_details/graph/components/job_item.vue';
import LinkedPipelinesColumn from '~/ci/pipeline_details/graph/components/linked_pipelines_column.vue';
import StageColumnComponent from '~/ci/pipeline_details/graph/components/stage_column_component.vue';
import { calculatePipelineLayersInfo } from '~/ci/pipeline_details/graph/utils';
import LinksLayer from '~/ci/common/private/job_links_layer.vue';

import { generateResponse, pipelineWithUpstreamDownstream } from '../mock_data';

describe('graph component', () => {
  let wrapper;

  const findDownstreamColumn = () => wrapper.findByTestId('downstream-pipelines');
  const findLinkedColumns = () => wrapper.findAllComponents(LinkedPipelinesColumn);
  const findLinksLayer = () => wrapper.findComponent(LinksLayer);
  const findStageColumns = () => wrapper.findAllComponents(StageColumnComponent);
  const findStageNameInJob = () => wrapper.findByTestId('stage-name-in-job');
  const findPipelineContainer = () => wrapper.findByTestId('pipeline-container');
  const findRootGraphLayout = () => wrapper.findByTestId('stage-column');
  const findStageColumnTitle = () => wrapper.findByTestId('stage-column-title');
  const findJobItem = () => wrapper.findComponent(JobItem);

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
    glFeatures = {
      newPipelineGraph: false,
    },
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
      stubs: {
        'links-inner': true,
        'linked-pipeline': true,
        'job-item': true,
        'job-group-dropdown': true,
        ...stubOverride,
      },
      provide: {
        glFeatures,
      },
    });
  };

  describe('with data', () => {
    beforeEach(() => {
      createComponent({ mountFn: mountExtended });
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

    describe('when column request an update to the retry confirmation modal', () => {
      beforeEach(() => {
        findStageColumns().at(0).vm.$emit('setSkipRetryModal');
      });

      it('setSkipRetryModal is emitted', () => {
        expect(wrapper.emitted().setSkipRetryModal).toHaveLength(1);
      });
    });

    describe('when links are present', () => {
      beforeEach(() => {
        createComponent({
          mountFn: mountExtended,
          stubOverride: { 'job-item': false },
          data: { hoveredJobName: 'test_a' },
        });
        findLinksLayer().vm.$emit('highlightedJobsChange', ['test_c', 'build_c']);
      });

      it('dims unrelated jobs', () => {
        expect(findLinksLayer().emitted().highlightedJobsChange).toHaveLength(1);
        expect(findJobItem().classes('gl-opacity-3')).toBe(true);
      });
    });
  });

  describe('when linked pipelines are not present', () => {
    beforeEach(() => {
      createComponent({ mountFn: mountExtended });
    });

    it('should not render a linked pipelines column', () => {
      expect(findLinkedColumns()).toHaveLength(0);
    });
  });

  describe('when linked pipelines are present', () => {
    beforeEach(() => {
      createComponent({
        mountFn: mountExtended,
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
        mountFn: mountExtended,
        stubOverride: {
          'job-item': false,
          'job-group-dropdown': false,
        },
        props: {
          viewType: LAYER_VIEW,
          computedPipelineInfo: calculatePipelineLayersInfo(defaultProps.pipeline, 'layer', ''),
        },
      });
    });

    it('displays the stage name on the job', () => {
      expect(findStageNameInJob().exists()).toBe(true);
    });
  });

  describe('downstream pipelines', () => {
    beforeEach(() => {
      createComponent({
        mountFn: mountExtended,
        props: {
          pipeline: pipelineWithUpstreamDownstream(mockPipelineResponse),
        },
      });
    });

    it('filters pipelines spawned from the same trigger job', () => {
      // The mock data has one downstream with `retried: true and one
      // with retried false. We filter the `retried: true` out so we
      // should only pass one downstream
      expect(findDownstreamColumn().props().linkedPipelines).toHaveLength(1);
    });
  });

  describe.each`
    name          | value    | state
    ${'disabled'} | ${false} | ${'should not'}
    ${'enabled'}  | ${true}  | ${'should'}
  `('With feature flag newPipelineGraph $name', ({ value, state }) => {
    beforeEach(() => {
      createComponent({
        mountFn: mountExtended,
        stubOverride: { 'job-item': false, StageColumnComponent },
        glFeatures: {
          newPipelineGraph: value,
        },
        stubs: {
          StageColumnComponent,
        },
      });
    });

    it(`${state} add class pipeline-graph-container on wrapper`, () => {
      expect(findPipelineContainer().classes('pipeline-graph-container')).toBe(value);
    });

    it(`${state} add class is-stage-view on rootGraphLayout`, () => {
      expect(findRootGraphLayout().classes('is-stage-view')).toBe(value);
    });

    it(`${state} add titleClasses on stageColumnTitle`, () => {
      const titleClasses = [
        'gl-font-weight-bold',
        'gl-pipeline-job-width',
        'gl-text-truncate',
        'gl-line-height-36',
        'gl-pl-4',
        'gl-mb-n2',
      ];
      const legacyTitleClasses = [
        'gl-font-weight-bold',
        'gl-pipeline-job-width',
        'gl-text-truncate',
        'gl-line-height-36',
        'gl-pl-3',
      ];
      const checkClasses = value ? titleClasses : legacyTitleClasses;

      expect(findStageColumnTitle().classes()).toEqual(expect.arrayContaining(checkClasses));
    });

    it(`${state} add jobClasses on findJobItem`, () => {
      const jobClasses = [
        'gl-p-3',
        'gl-border-0',
        'gl-bg-transparent',
        'gl-rounded-base',
        'gl-hover-bg-gray-50',
        'gl-focus-bg-gray-50',
        'gl-hover-text-gray-900',
        'gl-focus-text-gray-900',
      ];
      const legacyJobClasses = [
        'gl-p-3',
        'gl-border-gray-100',
        'gl-border-solid',
        'gl-border-1',
        'gl-bg-white',
        'gl-rounded-7',
        'gl-hover-bg-gray-50',
        'gl-focus-bg-gray-50',
        'gl-hover-text-gray-900',
        'gl-focus-text-gray-900',
        'gl-hover-border-gray-200',
        'gl-focus-border-gray-200',
      ];
      const checkClasses = value ? jobClasses : legacyJobClasses;

      expect(findJobItem().props('cssClassJobName')).toEqual(expect.arrayContaining(checkClasses));
    });
  });
});
