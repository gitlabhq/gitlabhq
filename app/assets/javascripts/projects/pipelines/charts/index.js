import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import ProjectPipelinesCharts from './components/app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

const mountPipelineChartsApp = (el) => {
  const { projectPath } = el.dataset;

  const shouldRenderDoraCharts = parseBoolean(el.dataset.shouldRenderDoraCharts);

  return new Vue({
    el,
    name: 'ProjectPipelinesChartsApp',
    components: {
      ProjectPipelinesCharts,
    },
    apolloProvider,
    provide: {
      projectPath,
      shouldRenderDoraCharts,
    },
    render: (createElement) => createElement(ProjectPipelinesCharts, {}),
  });
};

export default () => {
  const el = document.querySelector('#js-project-pipelines-charts-app');
  return !el ? {} : mountPipelineChartsApp(el);
};
