import Vue from 'vue';
import Flash from '~/flash';
import Translate from '~/vue_shared/translate';
import { __ } from '~/locale';
import PipelinesMediator from './pipeline_details_mediator';
import pipelineGraph from './components/graph/graph_component.vue';
import pipelineHeader from './components/header_component.vue';
import eventHub from './event_hub';

Vue.use(Translate);

export default () => {
  const dataset = document.querySelector('.js-pipeline-details-vue').dataset;

  const mediator = new PipelinesMediator({ endpoint: dataset.endpoint });

  mediator.fetchPipeline();

  const pipelineGraphEl = document.querySelector('#js-pipeline-graph-vue');
  if (pipelineGraphEl) {
    // eslint-disable-next-line
    new Vue({
      el: pipelineGraphEl,
      components: {
        pipelineGraph,
      },
      data() {
        return {
          mediator,
        };
      },
      render(createElement) {
        return createElement('pipeline-graph', {
          props: {
            isLoading: this.mediator.state.isLoading,
            pipeline: this.mediator.store.state.pipeline,
          },
        });
      },
    });
  }

  const pipelineHeaderEl = document.querySelector('#js-pipeline-header-vue');
  if (pipelineHeaderEl) {
    // eslint-disable-next-line
    new Vue({
      el: pipelineHeaderEl,
      components: {
        pipelineHeader,
      },
      data() {
        return {
          mediator,
        };
      },
      created() {
        eventHub.$on('headerPostAction', this.postAction);
      },
      beforeDestroy() {
        eventHub.$off('headerPostAction', this.postAction);
      },
      methods: {
        postAction(action) {
          this.mediator.service.postAction(action.path)
            .then(() => this.mediator.refreshPipeline())
            .catch(() => Flash(__('An error occurred while making the request.')));
        },
      },
      render(createElement) {
        return createElement('pipeline-header', {
          props: {
            isLoading: this.mediator.state.isLoading,
            pipeline: this.mediator.store.state.pipeline,
          },
        });
      },
    });
  }
};
