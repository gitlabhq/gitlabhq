import { GlAlert, GlEmptyState } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import { ADD_NOTE, REMOVE_NOTE, REPLACE_NOTES } from '~/pipelines/components/dag/constants';
import Dag from '~/pipelines/components/dag/dag.vue';
import DagAnnotations from '~/pipelines/components/dag/dag_annotations.vue';
import DagGraph from '~/pipelines/components/dag/dag_graph.vue';

import { PARSE_FAILURE, UNSUPPORTED_DATA } from '~/pipelines/constants';
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
  const getAlert = () => wrapper.find(GlAlert);
  const getAllAlerts = () => wrapper.findAll(GlAlert);
  const getGraph = () => wrapper.find(DagGraph);
  const getNotes = () => wrapper.find(DagAnnotations);
  const getErrorText = (type) => wrapper.vm.$options.errorTexts[type];
  const getEmptyState = () => wrapper.find(GlEmptyState);

  const createComponent = ({
    graphData = mockParsedGraphQLNodes,
    provideOverride = {},
    method = shallowMount,
  } = {}) => {
    if (wrapper?.destroy) {
      wrapper.destroy();
    }

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

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when a query argument is undefined', () => {
    beforeEach(() => {
      createComponent({
        provideOverride: { pipelineProjectPath: undefined },
        graphData: null,
      });
    });

    it('does not render the graph', async () => {
      expect(getGraph().exists()).toBe(false);
    });

    it('does not render the empty state', () => {
      expect(getEmptyState().exists()).toBe(false);
    });
  });

  describe('when all query variables are defined', () => {
    describe('but the parse fails', () => {
      beforeEach(async () => {
        createComponent({
          graphData: unparseableGraph,
        });
      });

      it('shows the PARSE_FAILURE alert and not the graph', () => {
        expect(getAlert().exists()).toBe(true);
        expect(getAlert().text()).toBe(getErrorText(PARSE_FAILURE));
        expect(getGraph().exists()).toBe(false);
      });

      it('does not render the empty state', () => {
        expect(getEmptyState().exists()).toBe(false);
      });
    });

    describe('parse succeeds', () => {
      beforeEach(async () => {
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
      beforeEach(async () => {
        createComponent({
          graphData: tooSmallGraph,
        });
      });

      it('shows the UNSUPPORTED_DATA alert and not the graph', () => {
        expect(getAlert().exists()).toBe(true);
        expect(getAlert().text()).toBe(getErrorText(UNSUPPORTED_DATA));
        expect(getGraph().exists()).toBe(false);
      });

      it('does not show the empty dag graph state', () => {
        expect(getEmptyState().exists()).toBe(false);
      });
    });

    describe('the returned data is empty', () => {
      beforeEach(async () => {
        createComponent({
          method: mount,
          graphData: graphWithoutDependencies,
        });
      });

      it('does not render an error alert or the graph', () => {
        expect(getAllAlerts().length).toBe(0);
        expect(getGraph().exists()).toBe(false);
      });

      it('shows the empty dag graph state', () => {
        expect(getEmptyState().exists()).toBe(true);
      });
    });
  });

  describe('annotations', () => {
    beforeEach(async () => {
      createComponent();
    });

    it('toggles on link mouseover and mouseout', async () => {
      const currentNote = singleNote['dag-link103'];

      expect(getNotes().exists()).toBe(false);

      getGraph().vm.$emit('update-annotation', { type: ADD_NOTE, data: currentNote });
      await wrapper.vm.$nextTick();
      expect(getNotes().exists()).toBe(true);

      getGraph().vm.$emit('update-annotation', { type: REMOVE_NOTE, data: currentNote });
      await wrapper.vm.$nextTick();
      expect(getNotes().exists()).toBe(false);
    });

    it('toggles on node and link click', async () => {
      expect(getNotes().exists()).toBe(false);

      getGraph().vm.$emit('update-annotation', { type: REPLACE_NOTES, data: multiNote });
      await wrapper.vm.$nextTick();
      expect(getNotes().exists()).toBe(true);

      getGraph().vm.$emit('update-annotation', { type: REPLACE_NOTES, data: {} });
      await wrapper.vm.$nextTick();
      expect(getNotes().exists()).toBe(false);
    });
  });
});
