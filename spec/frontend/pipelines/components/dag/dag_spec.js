import { mount, shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';
import { GlAlert, GlEmptyState } from '@gitlab/ui';
import Dag from '~/pipelines/components/dag/dag.vue';
import DagGraph from '~/pipelines/components/dag/dag_graph.vue';
import DagAnnotations from '~/pipelines/components/dag/dag_annotations.vue';

import {
  ADD_NOTE,
  REMOVE_NOTE,
  REPLACE_NOTES,
  DEFAULT,
  PARSE_FAILURE,
  LOAD_FAILURE,
  UNSUPPORTED_DATA,
} from '~/pipelines/components/dag//constants';
import {
  mockBaseData,
  tooSmallGraph,
  unparseableGraph,
  graphWithoutDependencies,
  singleNote,
  multiNote,
} from './mock_data';

describe('Pipeline DAG graph wrapper', () => {
  let wrapper;
  let mock;
  const getAlert = () => wrapper.find(GlAlert);
  const getAllAlerts = () => wrapper.findAll(GlAlert);
  const getGraph = () => wrapper.find(DagGraph);
  const getNotes = () => wrapper.find(DagAnnotations);
  const getErrorText = type => wrapper.vm.$options.errorTexts[type];
  const getEmptyState = () => wrapper.find(GlEmptyState);

  const dataPath = '/root/test/pipelines/90/dag.json';

  const createComponent = (propsData = {}, method = shallowMount) => {
    if (wrapper?.destroy) {
      wrapper.destroy();
    }

    wrapper = method(Dag, {
      propsData: {
        emptySvgPath: '/my-svg',
        dagDocPath: '/my-doc',
        ...propsData,
      },
      data() {
        return {
          showFailureAlert: false,
        };
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
    wrapper = null;
  });

  describe('when there is no dataUrl', () => {
    beforeEach(() => {
      createComponent({ graphUrl: undefined });
    });

    it('shows the DEFAULT alert and not the graph', () => {
      expect(getAlert().exists()).toBe(true);
      expect(getAlert().text()).toBe(getErrorText(DEFAULT));
      expect(getGraph().exists()).toBe(false);
    });

    it('does not render the empty state', () => {
      expect(getEmptyState().exists()).toBe(false);
    });
  });

  describe('when there is a dataUrl', () => {
    describe('but the data fetch fails', () => {
      beforeEach(async () => {
        mock.onGet(dataPath).replyOnce(500);
        createComponent({ graphUrl: dataPath });

        await wrapper.vm.$nextTick();

        return waitForPromises();
      });

      it('shows the LOAD_FAILURE alert and not the graph', () => {
        expect(getAlert().exists()).toBe(true);
        expect(getAlert().text()).toBe(getErrorText(LOAD_FAILURE));
        expect(getGraph().exists()).toBe(false);
      });

      it('does not render the empty state', () => {
        expect(getEmptyState().exists()).toBe(false);
      });
    });

    describe('the data fetch succeeds but the parse fails', () => {
      beforeEach(async () => {
        mock.onGet(dataPath).replyOnce(200, unparseableGraph);
        createComponent({ graphUrl: dataPath });

        await wrapper.vm.$nextTick();

        return waitForPromises();
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

    describe('and the data fetch and parse succeeds', () => {
      beforeEach(async () => {
        mock.onGet(dataPath).replyOnce(200, mockBaseData);
        createComponent({ graphUrl: dataPath }, mount);

        await wrapper.vm.$nextTick();

        return waitForPromises();
      });

      it('shows the graph and the beta alert', () => {
        expect(getAllAlerts().length).toBe(1);
        expect(getAlert().text()).toContain('This feature is currently in beta.');
        expect(getGraph().exists()).toBe(true);
      });

      it('does not render the empty state', () => {
        expect(getEmptyState().exists()).toBe(false);
      });
    });

    describe('the data fetch and parse succeeds, but the resulting graph is too small', () => {
      beforeEach(async () => {
        mock.onGet(dataPath).replyOnce(200, tooSmallGraph);
        createComponent({ graphUrl: dataPath });

        await wrapper.vm.$nextTick();

        return waitForPromises();
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

    describe('the data fetch succeeds but the returned data is empty', () => {
      beforeEach(async () => {
        mock.onGet(dataPath).replyOnce(200, graphWithoutDependencies);
        createComponent({ graphUrl: dataPath }, mount);

        await wrapper.vm.$nextTick();

        return waitForPromises();
      });

      it('does not render an error alert or the graph', () => {
        expect(getAllAlerts().length).toBe(1);
        expect(getAlert().text()).toContain('This feature is currently in beta.');
        expect(getGraph().exists()).toBe(false);
      });

      it('shows the empty dag graph state', () => {
        expect(getEmptyState().exists()).toBe(true);
      });
    });
  });

  describe('annotations', () => {
    beforeEach(async () => {
      mock.onGet(dataPath).replyOnce(200, mockBaseData);
      createComponent({ graphUrl: dataPath }, mount);

      await wrapper.vm.$nextTick();

      return waitForPromises();
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
