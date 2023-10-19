import Vue from 'vue';
import VueApollo from 'vue-apollo';
import MrWidgetOptions from 'any_else_ce/vue_merge_request_widget/mr_widget_options.vue';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import Translate from '../vue_shared/translate';

Vue.use(Translate);
Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(
    {},
    {
      cacheConfig: {
        typePolicies: {
          MergeRequestApprovalState: {
            merge: true,
          },
        },
      },
    },
  ),
});

export default () => {
  if (gl.mrWidget) return;

  gl.mrWidgetData.gitlabLogo = gon.gitlab_logo;
  gl.mrWidgetData.defaultAvatarUrl = gon.default_avatar_url;

  const dismissalDescriptions = JSON.parse(gl.mrWidgetData.dismissal_descriptions || '{}');

  // This is a false violation of @gitlab/no-runtime-template-compiler, since it
  // creates a new Vue instance by spreading a _valid_ Vue component definition
  // into the Vue constructor.
  // eslint-disable-next-line @gitlab/no-runtime-template-compiler
  const vm = new Vue({
    el: '#js-vue-mr-widget',
    provide: {
      artifactsEndpoint: gl.mrWidgetData.artifacts_endpoint,
      artifactsEndpointPlaceholder: gl.mrWidgetData.artifacts_endpoint_placeholder,
      falsePositiveDocUrl: gl.mrWidgetData.false_positive_doc_url,
      canViewFalsePositive: parseBoolean(gl.mrWidgetData.can_view_false_positive),
      canCreatePipelineInTargetProject: parseBoolean(
        gl.mrWidgetData.can_create_pipeline_in_target_project,
      ),
      commitPathTemplate: gl.mrWidgetData.commit_path_template,
      dismissalDescriptions,
    },
    ...MrWidgetOptions,
    apolloProvider,
  });

  window.gl.mrWidget = {
    checkStatus: vm.checkStatus,
  };
};
