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

  // eslint-disable-next-line
  new Vue({
    el: '#js-pipeline-graph-vue',
    components: {
      pipelineGraph,
    },
    data() {
      return {
        mediator,
        requestFinishedFor: null,
      };
    },
    created() {
      eventHub.$on('graphAction', this.postAction);
    },
    beforeDestroy() {
      eventHub.$off('graphAction', this.postAction);
    },
    methods: {
      postAction(action) {
        // Click was made, reset this variable
        this.requestFinishedFor = null;

        this.mediator.service
          .postAction(action)
          .then(() => {
            this.mediator.refreshPipeline();
            this.requestFinishedFor = action;
          })
          .catch(() => {
            this.requestFinishedFor = action;
            Flash(__('An error occurred while making the request.'));
          });
      },
    },
    render(createElement) {
      return createElement('pipeline-graph', {
        props: {
          isLoading: this.mediator.state.isLoading,
          pipeline: this.mediator.store.state.pipeline,
          requestFinishedFor: this.requestFinishedFor,
        },
      });
    },
  });

  // eslint-disable-next-line
  new Vue({
    el: '#js-pipeline-header-vue',
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
        this.mediator.service
          .postAction(action.path)
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
};
