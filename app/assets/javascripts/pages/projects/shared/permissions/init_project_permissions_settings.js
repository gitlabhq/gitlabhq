import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import settingsPanel from './components/settings_panel.vue';

Vue.use(VueApollo);

export function initProjectPermissionsSettings() {
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const mountPoint = document.querySelector('.js-project-permissions-form');
  const componentPropsEl = document.querySelector('.js-project-permissions-form-data');

  if (!mountPoint) return null;

  const componentProps = JSON.parse(componentPropsEl.innerHTML);

  const {
    additionalInformation,
    confirmButtonText,
    confirmDangerMessage,
    htmlConfirmationMessage,
    showVisibilityConfirmModal,
    targetFormId,
    phrase: confirmationPhrase,
  } = mountPoint.dataset;

  return initVueApp({
    el: mountPoint,
    name: 'ProjectPermissionsRoot',
    apolloProvider,
    provide: {
      additionalInformation,
      confirmDangerMessage,
      confirmButtonText,
      htmlConfirmationMessage: parseBoolean(htmlConfirmationMessage),
      groupPathRegex: new RegExp(`^(${componentProps.groupPathRegex})$`),
    },
    component: settingsPanel,
    props: {
      ...componentProps,
      confirmationPhrase,
      showVisibilityConfirmModal: parseBoolean(showVisibilityConfirmModal),
    },
    events: {
      confirm: () => {
        if (targetFormId) document.getElementById(targetFormId)?.submit();
      },
    },
  });
}
