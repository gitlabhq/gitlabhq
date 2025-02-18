import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import MlExperimentsIndex from '~/ml/experiment_tracking/routes/experiments/index';

Vue.use(VueApollo);

const initIndexMlExperiments = () => {
  const element = document.querySelector('#js-project-ml-experiments-index');
  if (!element) {
    return undefined;
  }

  const { projectPath, emptyStateSvgPath, mlflowTrackingUrl } = element.dataset;
  const props = {
    projectPath,
    emptyStateSvgPath,
    mlflowTrackingUrl,
  };

  const apolloProvider = new VueApollo({ defaultClient: createDefaultClient() });

  return new Vue({
    el: element,
    name: 'MlExperimentsIndexApp',
    apolloProvider,
    render(h) {
      return h(MlExperimentsIndex, { props });
    },
  });
};

initIndexMlExperiments();
