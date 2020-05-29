import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';
import { GlAlert } from '@gitlab/ui';
import Dag from '~/pipelines/components/dag/dag.vue';
import DagGraph from '~/pipelines/components/dag/dag_graph.vue';

import {
  DEFAULT,
  PARSE_FAILURE,
  LOAD_FAILURE,
  UNSUPPORTED_DATA,
} from '~/pipelines/components/dag//constants';
import { mockBaseData, tooSmallGraph, unparseableGraph } from './mock_data';

describe('Pipeline DAG graph wrapper', () => {
  let wrapper;
  let mock;
  const getAlert = () => wrapper.find(GlAlert);
  const getGraph = () => wrapper.find(DagGraph);
  const getErrorText = type => wrapper.vm.$options.errorTexts[type];

  const dataPath = '/root/test/pipelines/90/dag.json';

  const createComponent = (propsData = {}) => {
    if (wrapper?.destroy) {
      wrapper.destroy();
    }

    wrapper = shallowMount(Dag, {
      propsData,
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
  });

  describe('when there is a dataUrl', () => {
    describe('but the data fetch fails', () => {
      beforeEach(() => {
        mock.onGet(dataPath).replyOnce(500);
        createComponent({ graphUrl: dataPath });
      });

      it('shows the LOAD_FAILURE alert and not the graph', () => {
        return wrapper.vm
          .$nextTick()
          .then(waitForPromises)
          .then(() => {
            expect(getAlert().exists()).toBe(true);
            expect(getAlert().text()).toBe(getErrorText(LOAD_FAILURE));
            expect(getGraph().exists()).toBe(false);
          });
      });
    });

    describe('the data fetch succeeds but the parse fails', () => {
      beforeEach(() => {
        mock.onGet(dataPath).replyOnce(200, unparseableGraph);
        createComponent({ graphUrl: dataPath });
      });

      it('shows the PARSE_FAILURE alert and not the graph', () => {
        return wrapper.vm
          .$nextTick()
          .then(waitForPromises)
          .then(() => {
            expect(getAlert().exists()).toBe(true);
            expect(getAlert().text()).toBe(getErrorText(PARSE_FAILURE));
            expect(getGraph().exists()).toBe(false);
          });
      });
    });

    describe('and the data fetch and parse succeeds', () => {
      beforeEach(() => {
        mock.onGet(dataPath).replyOnce(200, mockBaseData);
        createComponent({ graphUrl: dataPath });
      });

      it('shows the graph and not the alert', () => {
        return wrapper.vm
          .$nextTick()
          .then(waitForPromises)
          .then(() => {
            expect(getAlert().exists()).toBe(false);
            expect(getGraph().exists()).toBe(true);
          });
      });
    });

    describe('the data fetch and parse succeeds, but the resulting graph is too small', () => {
      beforeEach(() => {
        mock.onGet(dataPath).replyOnce(200, tooSmallGraph);
        createComponent({ graphUrl: dataPath });
      });

      it('shows the UNSUPPORTED_DATA alert and not the graph', () => {
        return wrapper.vm
          .$nextTick()
          .then(waitForPromises)
          .then(() => {
            expect(getAlert().exists()).toBe(true);
            expect(getAlert().text()).toBe(getErrorText(UNSUPPORTED_DATA));
            expect(getGraph().exists()).toBe(false);
          });
      });
    });
  });
});
