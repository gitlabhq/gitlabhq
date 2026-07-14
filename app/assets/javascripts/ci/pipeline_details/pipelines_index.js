import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import {
  buildUrlWithCurrentLocation,
  historyReplaceState,
  parseBoolean,
} from '~/lib/utils/common_utils';
import { doesHashExistInUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import Translate from '~/vue_shared/translate';
import PipelinesApp from '~/ci/pipelines_page/pipelines_app.vue';

Vue.use(Translate);
Vue.use(GlToast);
Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const initPipelinesIndex = (selector = '#pipelines-list-vue') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const {
    fullPath,
    newPipelinePath,
    resetCachePath,
    pipelinesAnalyticsPath,
    identityVerificationRequired,
    identityVerificationPath,
    visibilityPipelineIdType,
    params,
    projectId,
    defaultBranchName,
    pipelineSchedulesPath,
    suggestedCiTemplates,
    canCreatePipeline,
    showJenkinsCiPrompt,
    usesExternalConfig,
    pipelineEditorPath,
    projectPipelinesEtagPath,
    hasGitlabCi,
  } = el.dataset;

  return new Vue({
    el,
    name: 'PipelinesAppRoot',
    apolloProvider,
    provide: {
      fullPath,
      newPipelinePath,
      resetCachePath,
      pipelinesAnalyticsPath,
      identityVerificationRequired: parseBoolean(identityVerificationRequired),
      identityVerificationPath,
      projectId,
      defaultBranchName,
      pipelineSchedulesPath,
      suggestedCiTemplates: JSON.parse(suggestedCiTemplates),
      canCreatePipeline: parseBoolean(canCreatePipeline),
      showJenkinsCiPrompt: parseBoolean(showJenkinsCiPrompt),
      usesExternalConfig: parseBoolean(usesExternalConfig),
      hasGitlabCi: parseBoolean(hasGitlabCi),
      pipelineEditorPath,
      projectPipelinesEtagPath,
    },
    created() {
      if (doesHashExistInUrl('delete_success')) {
        this.$toast.show(__('The pipeline has been deleted'));
        historyReplaceState(buildUrlWithCurrentLocation());
      }
    },
    render(createElement) {
      return createElement(PipelinesApp, {
        props: {
          defaultVisibilityPipelineIdType: visibilityPipelineIdType,
          params: JSON.parse(params),
        },
      });
    },
  });
};
