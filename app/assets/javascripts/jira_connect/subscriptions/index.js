import '../../webpack';

import setConfigs from '@gitlab/ui/dist/config';
import Vue from 'vue';
import GlFeatureFlagsPlugin from '~/vue_shared/gl_feature_flags_plugin';
import Translate from '~/vue_shared/translate';

import JiraConnectApp from './components/app.vue';
import createStore from './store';
import { getGitlabSignInURL, sizeToParent } from './utils';

const store = createStore();

/**
 * Add `return_to` query param to all HAML-defined GitLab sign in links.
 */
const updateSignInLinks = async () => {
  await Promise.all(
    Array.from(document.querySelectorAll('.js-jira-connect-sign-in')).map(async (el) => {
      const updatedLink = await getGitlabSignInURL(el.getAttribute('href'));
      el.setAttribute('href', updatedLink);
    }),
  );
};

export async function initJiraConnect() {
  await updateSignInLinks();

  const el = document.querySelector('.js-jira-connect-app');
  if (!el) {
    return null;
  }

  setConfigs();
  Vue.use(Translate);
  Vue.use(GlFeatureFlagsPlugin);

  const { groupsPath, subscriptions, subscriptionsPath, usersPath } = el.dataset;
  sizeToParent();

  return new Vue({
    el,
    store,
    provide: {
      groupsPath,
      subscriptions: JSON.parse(subscriptions),
      subscriptionsPath,
      usersPath,
    },
    render(createElement) {
      return createElement(JiraConnectApp);
    },
  });
}

document.addEventListener('DOMContentLoaded', initJiraConnect);
