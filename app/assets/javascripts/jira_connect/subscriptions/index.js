import '~/webpack';

import setConfigs from '@gitlab/ui/dist/config';
import Vue from 'vue';
import Translate from '~/vue_shared/translate';

import JiraConnectApp from './components/app.vue';
import createStore from './store';
import { sizeToParent } from './utils';

export function initJiraConnect() {
  const el = document.querySelector('.js-jira-connect-app');
  if (!el) {
    return null;
  }

  setConfigs();
  Vue.use(Translate);

  const {
    groupsPath,
    subscriptions,
    subscriptionsPath,
    gitlabUserPath,
    oauthMetadata,
    publicKeyStorageEnabled,
  } = el.dataset;
  sizeToParent();

  const store = createStore({ subscriptions: JSON.parse(subscriptions) });

  return new Vue({
    el,
    store,
    provide: {
      groupsPath,
      subscriptionsPath,
      gitlabUserPath,
      oauthMetadata: oauthMetadata ? JSON.parse(oauthMetadata) : null,
      publicKeyStorageEnabled,
    },
    render(createElement) {
      return createElement(JiraConnectApp);
    },
  });
}

initJiraConnect();
