import Vue from 'vue';
import Vuex from 'vuex';
import $ from 'jquery';
import setConfigs from '@gitlab/ui/dist/config';
import Translate from '~/vue_shared/translate';
import GlFeatureFlagsPlugin from '~/vue_shared/gl_feature_flags_plugin';

import JiraConnectApp from './components/app.vue';
import { addSubscription, removeSubscription } from '~/jira_connect/api';
import createStore from './store';
import { SET_ERROR_MESSAGE } from './store/mutation_types';

Vue.use(Vuex);

const store = createStore();

/**
 * Initialize form handlers for the Jira Connect app
 */
const initJiraFormHandlers = () => {
  const reqComplete = () => {
    AP.navigator.reload();
  };

  const reqFailed = (res, fallbackErrorMessage) => {
    const { error = fallbackErrorMessage } = res || {};

    store.commit(SET_ERROR_MESSAGE, error);
  };

  if (typeof AP.getLocation === 'function') {
    AP.getLocation((location) => {
      $('.js-jira-connect-sign-in').each(function updateSignInLink() {
        const updatedLink = `${$(this).attr('href')}?return_to=${location}`;
        $(this).attr('href', updatedLink);
      });
    });
  }

  $('#add-subscription-form').on('submit', function onAddSubscriptionForm(e) {
    const addPath = $(this).attr('action');
    const namespace = $('#namespace-input').val();

    e.preventDefault();

    addSubscription(addPath, namespace)
      .then(reqComplete)
      .catch((err) => reqFailed(err.response.data, 'Failed to add namespace. Please try again.'));
  });

  $('.remove-subscription').on('click', function onRemoveSubscriptionClick(e) {
    const removePath = $(this).attr('href');
    e.preventDefault();

    removeSubscription(removePath)
      .then(reqComplete)
      .catch((err) =>
        reqFailed(err.response.data, 'Failed to remove namespace. Please try again.'),
      );
  });
};

function initJiraConnect() {
  const el = document.querySelector('.js-jira-connect-app');

  initJiraFormHandlers();

  if (!el) {
    return null;
  }

  setConfigs();
  Vue.use(Translate);
  Vue.use(GlFeatureFlagsPlugin);

  return new Vue({
    el,
    store,
    render(createElement) {
      return createElement(JiraConnectApp, {});
    },
  });
}

document.addEventListener('DOMContentLoaded', initJiraConnect);
