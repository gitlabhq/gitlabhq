import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import Dag from './components/dag/dag.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

const createDagApp = () => {
  const el = document.querySelector('#js-pipeline-dag-vue');

  if (!window.gon?.features?.dagPipelineTab || !el) {
    return;
  }

  const { pipelineProjectPath, pipelineIid, emptySvgPath, dagDocPath } = el?.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      Dag,
    },
    apolloProvider,
    provide: {
      pipelineProjectPath,
      pipelineIid,
      emptySvgPath,
      dagDocPath,
    },
    render(createElement) {
      return createElement('dag', {});
    },
  });
};

export default createDagApp;
