import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';
import { GlAlert } from '@gitlab/ui';
import Dag from '~/pipelines/components/dag/dag.vue';

describe('Pipeline DAG graph', () => {
  let wrapper;
  let axiosMock;
  const getAlert = () => wrapper.find(GlAlert);
  const getGraph = () => wrapper.find('[data-testid="dag-graph-container"]');

  const dataPath = 'root/test/pipelines/90/dag.json';

  const createComponent = (propsData = {}, method = mount) => {
    axiosMock = new MockAdapter(axios);

    if (wrapper?.destroy) {
      wrapper.destroy();
    }

    wrapper = method(Dag, {
      propsData,
      data() {
        return {
          showFailureAlert: false,
        };
      },
    });
  };

  afterEach(() => {
    axiosMock.restore();
    wrapper.destroy();
    wrapper = null;
  });

  describe('when there is no dataUrl', () => {
    beforeEach(() => {
      createComponent({ graphUrl: undefined });
    });

    it('shows the alert and not the graph', () => {
      expect(getAlert().exists()).toBe(true);
      expect(getGraph().exists()).toBe(false);
    });
  });

  describe('when there is a dataUrl', () => {
    beforeEach(() => {
      createComponent({ graphUrl: dataPath });
    });

    it('shows the graph and not the alert', () => {
      expect(getAlert().exists()).toBe(false);
      expect(getGraph().exists()).toBe(true);
    });

    describe('but the data fetch fails', () => {
      beforeEach(() => {
        axiosMock.onGet(dataPath).replyOnce(500);
        createComponent({ graphUrl: dataPath });
      });

      it('shows the alert and not the graph', () => {
        return wrapper.vm
          .$nextTick()
          .then(waitForPromises)
          .then(() => {
            expect(getAlert().exists()).toBe(true);
            expect(getGraph().exists()).toBe(false);
          });
      });
    });
  });
});
