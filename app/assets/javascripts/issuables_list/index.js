import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import IssuableListRootApp from './components/issuable_list_root_app.vue';
import IssuablesListApp from './components/issuables_list_app.vue';

function mountIssuableListRootApp() {
  const el = document.querySelector('.js-projects-issues-root');

  if (!el) {
    return false;
  }

  Vue.use(VueApollo);

  const defaultClient = createDefaultClient();
  const apolloProvider = new VueApollo({
    defaultClient,
  });

  return new Vue({
    el,
    apolloProvider,
    render(createComponent) {
      return createComponent(IssuableListRootApp, {
        props: {
          canEdit: parseBoolean(el.dataset.canEdit),
          isJiraConfigured: parseBoolean(el.dataset.isJiraConfigured),
          issuesPath: el.dataset.issuesPath,
          projectPath: el.dataset.projectPath,
        },
      });
    },
  });
}

function mountIssuablesListApp() {
  if (!gon.features?.vueIssuablesList) {
    return;
  }

  document.querySelectorAll('.js-issuables-list').forEach(el => {
    const { canBulkEdit, ...data } = el.dataset;

    return new Vue({
      el,
      render(createElement) {
        return createElement(IssuablesListApp, {
          props: {
            ...data,
            canBulkEdit: Boolean(canBulkEdit),
          },
        });
      },
    });
  });
}

export default function initIssuablesList() {
  mountIssuableListRootApp();
  mountIssuablesListApp();
}
