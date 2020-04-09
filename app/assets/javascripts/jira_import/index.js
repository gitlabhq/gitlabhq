import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import App from './components/jira_import_app.vue';

Vue.use(VueApollo);

const defaultClient = createDefaultClient();

const apolloProvider = new VueApollo({
  defaultClient,
});

export default function mountJiraImportApp() {
  const el = document.querySelector('.js-jira-import-root');
  if (!el) {
    return false;
  }

  return new Vue({
    el,
    apolloProvider,
    render(createComponent) {
      return createComponent(App, {
        props: {
          isJiraConfigured: parseBoolean(el.dataset.isJiraConfigured),
          projectPath: el.dataset.projectPath,
          setupIllustration: el.dataset.setupIllustration,
        },
      });
    },
  });
}
