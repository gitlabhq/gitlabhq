import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Dag from './components/dag/dag.vue';

Vue.use(VueApollo);

const createDagApp = (apolloProvider) => {
  const el = document.querySelector('#js-pipeline-dag-vue');

  if (!el) {
    return;
  }

  const {
    aboutDagDocPath,
    dagDocPath,
    emptySvgPath,
    pipelineProjectPath,
    pipelineIid,
  } = el?.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      Dag,
    },
    apolloProvider,
    provide: {
      aboutDagDocPath,
      dagDocPath,
      emptySvgPath,
      pipelineProjectPath,
      pipelineIid,
    },
    render(createElement) {
      return createElement('dag', {});
    },
  });
};

export default createDagApp;
