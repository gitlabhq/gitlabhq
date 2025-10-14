import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import mockPipelineResponse from 'test_fixtures/pipelines/pipeline_details.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import getPipelineDetails from 'shared_queries/pipelines/get_pipeline_details.query.graphql';
import {
  DOWNSTREAM,
  UPSTREAM,
  LAYER_VIEW,
  STAGE_VIEW,
} from '~/ci/pipeline_details/graph/constants';
import PipelineGraph from '~/ci/pipeline_details/graph/components/graph_component.vue';
import LinkedPipeline from '~/ci/pipeline_details/graph/components/linked_pipeline.vue';
import LinkedPipelinesColumn from '~/ci/pipeline_details/graph/components/linked_pipelines_column.vue';
import * as parsingUtils from '~/ci/pipeline_details/utils/parsing_utils';
import { LOAD_FAILURE } from '~/ci/pipeline_details/constants';

import { pipelineWithUpstreamDownstream, wrappedPipelineReturn } from '../mock_data';

const processedPipeline = pipelineWithUpstreamDownstream(mockPipelineResponse);

const firstDownstreamId = processedPipeline.downstream[0].id;
const secondDownstreamId = processedPipeline.downstream[1].id;
const mockPermissions = {
  [processedPipeline.id]: { updatePipeline: true },
  [firstDownstreamId]: { updatePipeline: true },
  [secondDownstreamId]: { updatePipeline: false },
};

describe('Linked Pipelines Column', () => {
  const defaultProps = {
    columnTitle: 'Downstream',
    linkedPipelines: processedPipeline.downstream,
    showLinks: false,
    type: DOWNSTREAM,
    viewType: STAGE_VIEW,
    configPaths: {
      metricsPath: '',
      graphqlResourceEtag: 'this/is/a/path',
    },
    userPermissions: mockPermissions,
  };

  let wrapper;
  const findLinkedColumnTitle = () => wrapper.find('[data-testid="linked-column-title"]');
  const findLinkedPipelineElements = () => wrapper.findAllComponents(LinkedPipeline);
  const findPipelineGraph = () => wrapper.findComponent(PipelineGraph);
  const findExpandButton = () => wrapper.find('[data-testid="expand-pipeline-button"]');

  Vue.use(VueApollo);

  const createComponent = ({ apolloProvider, mountFn = shallowMount, props = {} } = {}) => {
    wrapper = mountFn(LinkedPipelinesColumn, {
      apolloProvider,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const createComponentWithApollo = ({
    mountFn = shallowMount,
    getPipelineDetailsHandler = jest.fn().mockResolvedValue(wrappedPipelineReturn),
    props = {},
  } = {}) => {
    const requestHandlers = [[getPipelineDetails, getPipelineDetailsHandler]];

    const apolloProvider = createMockApollo(requestHandlers);
    createComponent({ apolloProvider, mountFn, props });
  };

  describe('it renders correctly', () => {
    beforeEach(() => {
      createComponentWithApollo();
    });

    it('renders the pipeline title', () => {
      expect(findLinkedColumnTitle().text()).toBe(defaultProps.columnTitle);
    });

    it('renders the correct number of linked pipelines', () => {
      expect(findLinkedPipelineElements()).toHaveLength(defaultProps.linkedPipelines.length);
    });
  });

  describe('click action', () => {
    const clickExpandButton = async () => {
      await findExpandButton().trigger('click');
      await waitForPromises();
    };

    describe('layer type rendering', () => {
      let layersFn;

      beforeEach(() => {
        layersFn = jest.spyOn(parsingUtils, 'listByLayers');
        createComponentWithApollo({ mountFn: mount });
      });

      it('calls listByLayers only once no matter how many times view is switched', async () => {
        expect(layersFn).not.toHaveBeenCalled();
        await clickExpandButton();
        await wrapper.setProps({ viewType: LAYER_VIEW });
        await nextTick();
        expect(layersFn).toHaveBeenCalledTimes(1);
        await wrapper.setProps({ viewType: STAGE_VIEW });
        await wrapper.setProps({ viewType: LAYER_VIEW });
        await wrapper.setProps({ viewType: STAGE_VIEW });
        expect(layersFn).toHaveBeenCalledTimes(1);
      });
    });

    describe('when graph does not use needs', () => {
      beforeEach(() => {
        const nonNeedsResponse = { ...wrappedPipelineReturn };
        nonNeedsResponse.data.project.pipeline.usesNeeds = false;

        createComponentWithApollo({
          props: {
            viewType: LAYER_VIEW,
          },
          getPipelineDetailsHandler: jest.fn().mockResolvedValue(nonNeedsResponse),
          mountFn: mount,
        });
      });

      it('shows the stage view, even when the main graph view type is layers', async () => {
        await clickExpandButton();
        expect(findPipelineGraph().props('viewType')).toBe(STAGE_VIEW);
      });
    });

    describe('downstream', () => {
      describe('when successful', () => {
        beforeEach(() => {
          createComponentWithApollo({ mountFn: mount });
        });

        it('toggles the pipeline visibility', async () => {
          expect(findPipelineGraph().exists()).toBe(false);
          await clickExpandButton();
          expect(findPipelineGraph().exists()).toBe(true);
          await clickExpandButton();
          expect(findPipelineGraph().exists()).toBe(false);
        });
      });

      describe('on error', () => {
        beforeEach(() => {
          createComponentWithApollo({
            mountFn: mount,
            getPipelineDetailsHandler: jest.fn().mockRejectedValue(new Error('GraphQL error')),
          });
        });

        it('emits the error', async () => {
          await clickExpandButton();
          expect(wrapper.emitted().error).toEqual([[{ type: LOAD_FAILURE, skipSentry: true }]]);
        });

        it('does not show the pipeline', async () => {
          expect(findPipelineGraph().exists()).toBe(false);
          await clickExpandButton();
          expect(findPipelineGraph().exists()).toBe(false);
        });
      });
    });

    describe('upstream', () => {
      const upstreamProps = {
        columnTitle: 'Upstream',
        /*
          Because the IDs need to match to work, rather
          than make new mock data, we are representing
          the upstream pipeline with the downstream data.
        */
        linkedPipelines: processedPipeline.downstream,
        type: UPSTREAM,
      };

      describe('when successful', () => {
        beforeEach(() => {
          createComponentWithApollo({
            mountFn: mount,
            props: upstreamProps,
          });
        });

        it('toggles the pipeline visibility', async () => {
          expect(findPipelineGraph().exists()).toBe(false);
          await clickExpandButton();
          expect(findPipelineGraph().exists()).toBe(true);
          await clickExpandButton();
          expect(findPipelineGraph().exists()).toBe(false);
        });
      });

      describe('on error', () => {
        beforeEach(() => {
          createComponentWithApollo({
            mountFn: mount,
            getPipelineDetailsHandler: jest.fn().mockRejectedValue(new Error('GraphQL error')),
            props: upstreamProps,
          });
        });

        it('emits the error', async () => {
          await clickExpandButton();
          expect(wrapper.emitted().error).toEqual([[{ type: LOAD_FAILURE, skipSentry: true }]]);
        });

        it('does not show the pipeline', async () => {
          expect(findPipelineGraph().exists()).toBe(false);
          await clickExpandButton();
          expect(findPipelineGraph().exists()).toBe(false);
        });
      });
    });
  });

  describe('permissions handling', () => {
    const clickExpandButton = async () => {
      await findExpandButton().trigger('click');
      await waitForPromises();
    };

    describe('when permissions are provided via props', () => {
      beforeEach(() => {
        createComponentWithApollo({
          mountFn: mount,
          props: {
            userPermissions: mockPermissions,
          },
        });
      });

      it('passes correct permissions to each linked pipeline', () => {
        const linkedPipelines = findLinkedPipelineElements();

        expect(linkedPipelines.at(0).props('userPermissions')).toEqual({
          updatePipeline: true,
        });
        expect(linkedPipelines.at(1).props('userPermissions')).toEqual({
          updatePipeline: false,
        });
      });

      it('passes permissions to the expanded pipeline graph', async () => {
        await clickExpandButton();

        expect(findPipelineGraph().props('userPermissions')).toMatchObject({
          updatePipeline: true,
        });
      });
    });

    describe('when permissions are not provided', () => {
      beforeEach(() => {
        createComponentWithApollo({
          mountFn: mount,
          props: {
            userPermissions: {},
          },
        });
      });

      it('passes empty permissions to linked pipelines', () => {
        const linkedPipelines = findLinkedPipelineElements();

        expect(linkedPipelines.at(0).props('userPermissions')).toEqual({});
        expect(linkedPipelines.at(1).props('userPermissions')).toEqual({});
      });
    });
  });
});
