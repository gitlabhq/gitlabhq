import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import Translate from '~/vue_shared/translate';
import CleanupImageTags from './components/cleanup_image_tags.vue';
import { apolloProvider } from './graphql/index';

Vue.use(GlToast);
Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-registry-settings-cleanup-image-tags');
  if (!el) {
    return null;
  }
  const {
    isAdmin,
    enableHistoricEntries,
    projectPath,
    adminSettingsPath,
    projectSettingsPath,
    tagsRegexHelpPagePath,
    helpPagePath,
  } = el.dataset;
  return new Vue({
    el,
    apolloProvider,
    provide: {
      isAdmin: parseBoolean(isAdmin),
      enableHistoricEntries: parseBoolean(enableHistoricEntries),
      projectPath,
      adminSettingsPath,
      projectSettingsPath,
      tagsRegexHelpPagePath,
      helpPagePath,
    },
    render(createElement) {
      return createElement(CleanupImageTags, {});
    },
  });
};
