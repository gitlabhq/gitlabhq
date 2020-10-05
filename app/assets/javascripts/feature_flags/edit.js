import Vue from 'vue';
import EditFeatureFlag from '~/feature_flags/components/edit_feature_flag.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

export default () => {
  const el = document.querySelector('#js-edit-feature-flag');
  const { environmentsScopeDocsPath, strategyTypeDocsPagePath } = el.dataset;

  return new Vue({
    el,
    components: {
      EditFeatureFlag,
    },
    provide: {
      environmentsScopeDocsPath,
      strategyTypeDocsPagePath,
    },
    render(createElement) {
      return createElement('edit-feature-flag', {
        props: {
          endpoint: el.dataset.endpoint,
          path: el.dataset.featureFlagsPath,
          environmentsEndpoint: el.dataset.environmentsEndpoint,
          projectId: el.dataset.projectId,
          featureFlagIssuesEndpoint: el.dataset.featureFlagIssuesEndpoint,
          userCalloutsPath: el.dataset.userCalloutsPath,
          userCalloutId: el.dataset.userCalloutId,
          showUserCallout: parseBoolean(el.dataset.showUserCallout),
        },
      });
    },
  });
};
