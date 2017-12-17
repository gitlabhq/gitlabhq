import Vue from 'vue';
import Flash from '../flash';
import PipelinesMediator from './pipeline_details_mediatior';
import pipelineGraph from './components/graph/graph_component.vue';
import pipelineHeader from './components/header_component.vue';
import eventHub from './event_hub';

document.addEventListener('DOMContentLoaded', () => {
  const dataset = document.querySelector('.js-pipeline-details-vue').dataset;

  const mediator = new PipelinesMediator({ endpoint: dataset.endpoint, isSubscribed: dataset.isSubscribed });

  mediator.fetchPipeline();

  // eslint-disable-next-line
  new Vue({
    el: '#js-pipeline-graph-vue',
    data() {
      return {
        mediator,
      };
    },
    components: {
      pipelineGraph,
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

  // eslint-disable-next-line
  new Vue({
    el: '#js-pipeline-header-vue',
    data() {
      return {
        mediator,
      };
    },
    components: {
      pipelineHeader,
    },
    created() {
      eventHub.$on('headerPostAction', this.postAction);
      eventHub.$on('setIsSubscribed', this.setIsSubscribed);
    },
    beforeDestroy() {
      eventHub.$off('headerPostAction', this.postAction);
      eventHub.$off('setIsSubscribed', this.setIsSubscribed);
    },
    methods: {
      postAction(action) {
        this.mediator.service.postAction(action.path)
          .then(() => this.mediator.refreshPipeline())
          .catch(() => new Flash('An error occurred while making the request.'));
      },

      setIsSubscribed(isSubscribed) {
        this.mediator.state.isSubscribed = isSubscribed;
      },
    },
    render(createElement) {
      return createElement('pipeline-header', {
        props: {
          isLoading: this.mediator.state.isLoading,
          isSubscribed: this.mediator.state.isSubscribed,
          pipeline: this.mediator.store.state.pipeline,
        },
      });
    },
  });
});
