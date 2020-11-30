import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import createMockApollo from 'jest/helpers/mock_apollo_helper';
import PipelineGraphWrapper from '~/pipelines/components/graph/graph_component_wrapper.vue';
import PipelineGraph from '~/pipelines/components/graph/graph_component.vue';
import getPipelineDetails from '~/pipelines/graphql/queries/get_pipeline_details.query.graphql';
import { mockPipelineResponse } from './mock_data';

const defaultProvide = {
  pipelineProjectPath: 'frog/amphibirama',
  pipelineIid: '22',
};

describe('Pipeline graph wrapper', () => {
  Vue.use(VueApollo);

  let wrapper;
  const getAlert = () => wrapper.find(GlAlert);
  const getLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const getGraph = () => wrapper.find(PipelineGraph);

  const createComponent = ({
    apolloProvider,
    data = {},
    provide = defaultProvide,
    mountFn = shallowMount,
  } = {}) => {
    wrapper = mountFn(PipelineGraphWrapper, {
      provide,
      apolloProvider,
      data() {
        return {
          ...data,
        };
      },
    });
  };

  const createComponentWithApollo = (
    getPipelineDetailsHandler = jest.fn().mockResolvedValue(mockPipelineResponse),
  ) => {
    const requestHandlers = [[getPipelineDetails, getPipelineDetailsHandler]];

    const apolloProvider = createMockApollo(requestHandlers);
    createComponent({ apolloProvider });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when data is loading', () => {
    it('displays the loading icon', () => {
      createComponentWithApollo();
      expect(getLoadingIcon().exists()).toBe(true);
    });

    it('does not display the alert', () => {
      createComponentWithApollo();
      expect(getAlert().exists()).toBe(false);
    });

    it('does not display the graph', () => {
      createComponentWithApollo();
      expect(getGraph().exists()).toBe(false);
    });
  });

  describe('when data has loaded', () => {
    beforeEach(async () => {
      createComponentWithApollo();
      jest.runOnlyPendingTimers();
      await wrapper.vm.$nextTick();
    });

    it('does not display the loading icon', () => {
      expect(getLoadingIcon().exists()).toBe(false);
    });

    it('does not display the alert', () => {
      expect(getAlert().exists()).toBe(false);
    });

    it('displays the graph', () => {
      expect(getGraph().exists()).toBe(true);
    });
  });

  describe('when there is an error', () => {
    beforeEach(async () => {
      createComponentWithApollo(jest.fn().mockRejectedValue(new Error('GraphQL error')));
      jest.runOnlyPendingTimers();
      await wrapper.vm.$nextTick();
    });

    it('does not display the loading icon', () => {
      expect(getLoadingIcon().exists()).toBe(false);
    });

    it('displays the alert', () => {
      expect(getAlert().exists()).toBe(true);
    });

    it('does not display the graph', () => {
      expect(getGraph().exists()).toBe(false);
    });
  });
});
