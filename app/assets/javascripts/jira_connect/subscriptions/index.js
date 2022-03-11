import '../../webpack';

import setConfigs from '@gitlab/ui/dist/config';
import Vue from 'vue';
import GlFeatureFlagsPlugin from '~/vue_shared/gl_feature_flags_plugin';
import Translate from '~/vue_shared/translate';

import JiraConnectApp from './components/app.vue';
import createStore from './store';
import { sizeToParent } from './utils';

const store = createStore();

export function initJiraConnect() {
  const el = document.querySelector('.js-jira-connect-app');
  if (!el) {
    return null;
  }

  setConfigs();
  Vue.use(Translate);
  Vue.use(GlFeatureFlagsPlugin);

  const {
    groupsPath,
    subscriptions,
    subscriptionsPath,
    usersPath,
    gitlabUserPath,
    oauthMetadata,
  } = el.dataset;
  sizeToParent();

  return new Vue({
    el,
    store,
    provide: {
      groupsPath,
      subscriptions: JSON.parse(subscriptions),
      subscriptionsPath,
      usersPath,
      gitlabUserPath,
      oauthMetadata: oauthMetadata ? JSON.parse(oauthMetadata) : null,
    },
    render(createElement) {
      return createElement(JiraConnectApp);
    },
  });
}

document.addEventListener('DOMContentLoaded', initJiraConnect);
