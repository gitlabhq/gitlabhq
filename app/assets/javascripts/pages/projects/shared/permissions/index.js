import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

import { parseBoolean } from '~/lib/utils/common_utils';
import settingsPanel from './components/settings_panel.vue';

Vue.use(VueApollo);

export default function initProjectPermissionsSettings() {
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const mountPoint = document.querySelector('.js-project-permissions-form');
  const componentPropsEl = document.querySelector('.js-project-permissions-form-data');

  if (!mountPoint) return null;

  const componentProps = JSON.parse(componentPropsEl.innerHTML);

  const {
    targetFormId,
    additionalInformation,
    confirmDangerMessage,
    confirmButtonText,
    showVisibilityConfirmModal,
    htmlConfirmationMessage,
    phrase: confirmationPhrase,
  } = mountPoint.dataset;

  return new Vue({
    el: mountPoint,
    name: 'ProjectPermissionsRoot',
    apolloProvider,
    provide: {
      additionalInformation,
      confirmDangerMessage,
      confirmButtonText,
      htmlConfirmationMessage: parseBoolean(htmlConfirmationMessage),
    },
    render: (createElement) =>
      createElement(settingsPanel, {
        props: {
          ...componentProps,
          confirmationPhrase,
          showVisibilityConfirmModal: parseBoolean(showVisibilityConfirmModal),
        },
        on: {
          confirm: () => {
            if (targetFormId) document.getElementById(targetFormId)?.submit();
          },
        },
      }),
  });
}
