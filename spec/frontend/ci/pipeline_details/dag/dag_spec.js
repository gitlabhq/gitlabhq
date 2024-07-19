import { GlEmptyState } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { ADD_NOTE, REMOVE_NOTE, REPLACE_NOTES } from '~/ci/pipeline_details/dag/constants';
import Dag from '~/ci/pipeline_details/dag/dag.vue';
import DagAnnotations from '~/ci/pipeline_details/dag/components/dag_annotations.vue';
import DagGraph from '~/ci/pipeline_details/dag/components/dag_graph.vue';

import { PARSE_FAILURE, UNSUPPORTED_DATA } from '~/ci/pipeline_details/constants';
import {
  mockParsedGraphQLNodes,
  tooSmallGraph,
  unparseableGraph,
  graphWithoutDependencies,
  singleNote,
  multiNote,
} from './mock_data';

describe('Pipeline DAG graph wrapper', () => {
  let wrapper;
  const getDeprecationAlert = () => wrapper.findByTestId('deprecation-alert');
  const getFailureAlert = () => wrapper.findByTestId('failure-alert');
  const getAllFailureAlerts = () => wrapper.findAllByTestId('failure-alert');
  const getGraph = () => wrapper.findComponent(DagGraph);
  const getNotes = () => wrapper.findComponent(DagAnnotations);
  const getErrorText = (type) => wrapper.vm.$options.errorTexts[type];
  const getEmptyState = () => wrapper.findComponent(GlEmptyState);

  const createComponent = ({
    graphData = mockParsedGraphQLNodes,
    provideOverride = {},
    method = shallowMountExtended,
  } = {}) => {
    wrapper = method(Dag, {
      provide: {
        pipelineProjectPath: 'root/abc-dag',
        pipelineIid: '1',
        emptySvgPath: '/my-svg',
        dagDocPath: '/my-doc',
        ...provideOverride,
      },
      data() {
        return {
          graphData,
          showFailureAlert: false,
        };
      },
    });
  };

  describe('deprecation alert', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the deprecation alert', () => {
      expect(getDeprecationAlert().exists()).toBe(true);
    });

    it('dismisses the deprecation alert properly', async () => {
      getDeprecationAlert().vm.$emit('dismiss');
      await nextTick();

      expect(getDeprecationAlert().exists()).toBe(false);
    });
  });

  describe('when a query argument is undefined', () => {
    beforeEach(() => {
      createComponent({
        provideOverride: { pipelineProjectPath: undefined },
        graphData: null,
      });
    });

    it('does not render the graph', () => {
      expect(getGraph().exists()).toBe(false);
    });

    it('does not render the empty state', () => {
      expect(getEmptyState().exists()).toBe(false);
    });
  });

  describe('when all query variables are defined', () => {
    describe('but the parse fails', () => {
      beforeEach(() => {
        createComponent({
          graphData: unparseableGraph,
        });
      });

      it('shows the PARSE_FAILURE alert and not the graph', () => {
        expect(getFailureAlert().exists()).toBe(true);
        expect(getFailureAlert().text()).toBe(getErrorText(PARSE_FAILURE));
        expect(getGraph().exists()).toBe(false);
      });

      it('does not render the empty state', () => {
        expect(getEmptyState().exists()).toBe(false);
      });
    });

    describe('parse succeeds', () => {
      beforeEach(() => {
        createComponent({ method: mount });
      });

      it('shows the graph', () => {
        expect(getGraph().exists()).toBe(true);
      });

      it('does not render the empty state', () => {
        expect(getEmptyState().exists()).toBe(false);
      });
    });

    describe('parse succeeds, but the resulting graph is too small', () => {
      beforeEach(() => {
        createComponent({
          graphData: tooSmallGraph,
        });
      });

      it('shows the UNSUPPORTED_DATA alert and not the graph', () => {
        expect(getFailureAlert().exists()).toBe(true);
        expect(getFailureAlert().text()).toBe(getErrorText(UNSUPPORTED_DATA));
        expect(getGraph().exists()).toBe(false);
      });

      it('does not show the empty dag graph state', () => {
        expect(getEmptyState().exists()).toBe(false);
      });
    });

    describe('the returned data is empty', () => {
      beforeEach(() => {
        createComponent({
          method: shallowMountExtended,
          graphData: graphWithoutDependencies,
        });
      });

      it('does not render an error alert or the graph', () => {
        expect(getAllFailureAlerts().length).toBe(0);
        expect(getGraph().exists()).toBe(false);
      });

      it('shows the empty dag graph state', () => {
        expect(getEmptyState().exists()).toBe(true);
      });
    });
  });

  describe('annotations', () => {
    beforeEach(() => {
      createComponent();
    });

    it('toggles on link mouseover and mouseout', async () => {
      const currentNote = singleNote['dag-link103'];

      expect(getNotes().exists()).toBe(false);

      getGraph().vm.$emit('update-annotation', { type: ADD_NOTE, data: currentNote });
      await nextTick();
      expect(getNotes().exists()).toBe(true);

      getGraph().vm.$emit('update-annotation', { type: REMOVE_NOTE, data: currentNote });
      await nextTick();
      expect(getNotes().exists()).toBe(false);
    });

    it('toggles on node and link click', async () => {
      expect(getNotes().exists()).toBe(false);

      getGraph().vm.$emit('update-annotation', { type: REPLACE_NOTES, data: multiNote });
      await nextTick();
      expect(getNotes().exists()).toBe(true);

      getGraph().vm.$emit('update-annotation', { type: REPLACE_NOTES, data: {} });
      await nextTick();
      expect(getNotes().exists()).toBe(false);
    });
  });
});
