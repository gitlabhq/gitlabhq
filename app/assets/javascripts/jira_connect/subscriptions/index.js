import '~/webpack';

import setConfigs from '@gitlab/ui/src/config';
import Vue from 'vue';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { pinia } from '~/pinia/instance';
import Translate from '~/vue_shared/translate';

import JiraConnectApp from './components/app.vue';
import { useJiraConnectSubscriptions } from './store';
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

  useJiraConnectSubscriptions(pinia).$patch({ subscriptions: JSON.parse(subscriptions) });

  return initVueApp({
    el,
    name: 'JiraConnectAppRoot',
    pinia,
    provide: {
      groupsPath,
      subscriptionsPath,
      gitlabUserPath,
      oauthMetadata: oauthMetadata ? JSON.parse(oauthMetadata) : null,
      publicKeyStorageEnabled,
    },
    component: JiraConnectApp,
  });
}

initJiraConnect();
