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
import Pipelines from '~/ci/pipelines_page/pipelines.vue';
import PipelinesStore from './stores/pipelines_store';

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
    endpoint,
    artifactsEndpoint,
    artifactsEndpointPlaceholder,
    pipelineSchedulesPath,
    newPipelinePath,
    pipelineEditorPath,
    suggestedCiTemplates,
    canCreatePipeline,
    hasGitlabCi,
    resetCachePath,
    projectId,
    defaultBranchName,
    params,
    fullPath,
    visibilityPipelineIdType,
    showJenkinsCiPrompt,
    identityVerificationPath,
    identityVerificationRequired,
    pipelinesAnalyticsPath,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      artifactsEndpoint,
      artifactsEndpointPlaceholder,
      canCreatePipeline: parseBoolean(canCreatePipeline),
      defaultBranchName,
      fullPath,
      manualActionsLimit: 50,
      pipelineEditorPath,
      pipelineSchedulesPath,
      pipelinesAnalyticsPath,
      projectId,
      identityVerificationPath,
      identityVerificationRequired: parseBoolean(identityVerificationRequired),
      suggestedCiTemplates: JSON.parse(suggestedCiTemplates),
      showJenkinsCiPrompt: parseBoolean(showJenkinsCiPrompt),
    },
    data() {
      return {
        store: new PipelinesStore(),
      };
    },
    created() {
      if (doesHashExistInUrl('delete_success')) {
        this.$toast.show(__('The pipeline has been deleted'));
        historyReplaceState(buildUrlWithCurrentLocation());
      }
    },
    render(createElement) {
      return createElement(Pipelines, {
        props: {
          defaultVisibilityPipelineIdType: visibilityPipelineIdType,
          endpoint,
          hasGitlabCi: parseBoolean(hasGitlabCi),
          newPipelinePath,
          params: JSON.parse(params),
          resetCachePath,
          store: this.store,
        },
      });
    },
  });
};
