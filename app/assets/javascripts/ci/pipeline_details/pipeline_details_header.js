import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { parseBoolean } from '~/lib/utils/common_utils';
import PipelineDetailsHeader from './components/pipeline_details_header.vue';

Vue.use(VueApollo);

export const createPipelineDetailsHeaderApp = (elSelector, apolloProvider, graphqlResourceEtag) => {
  const el = document.querySelector(elSelector);

  if (!el) {
    return;
  }

  const {
    fullPath,
    pipelineIid,
    pipelinesPath,
    name,
    totalJobs,
    computeMinutes,
    yamlErrors,
    failureReason,
    triggeredByPath,
    schedule,
    child,
    latest,
    mergeTrainPipeline,
    invalid,
    failed,
    autoDevops,
    detached,
    stuck,
    refText,
  } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'PipelineDetailsHeaderApp',
    apolloProvider,
    provide: {
      paths: {
        fullProject: fullPath,
        graphqlResourceEtag,
        pipelinesPath,
        triggeredByPath,
      },
      pipelineIid,
    },
    render(createElement) {
      return createElement(PipelineDetailsHeader, {
        props: {
          name,
          totalJobs,
          computeMinutes,
          yamlErrors,
          failureReason,
          refText,
          badges: {
            schedule: parseBoolean(schedule),
            child: parseBoolean(child),
            latest: parseBoolean(latest),
            mergeTrainPipeline: parseBoolean(mergeTrainPipeline),
            invalid: parseBoolean(invalid),
            failed: parseBoolean(failed),
            autoDevops: parseBoolean(autoDevops),
            detached: parseBoolean(detached),
            stuck: parseBoolean(stuck),
          },
        },
      });
    },
  });
};
