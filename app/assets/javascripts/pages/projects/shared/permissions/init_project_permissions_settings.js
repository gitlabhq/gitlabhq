import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
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
    cascadingSettingsData,
    confirmButtonText,
    confirmDangerMessage,
    htmlConfirmationMessage,
    showVisibilityConfirmModal,
    targetFormId,
    phrase: confirmationPhrase,
  } = mountPoint.dataset;

  let cascadingSettingsDataParsed;

  try {
    cascadingSettingsDataParsed = convertObjectPropsToCamelCase(JSON.parse(cascadingSettingsData), {
      deep: true,
    });
  } catch {
    cascadingSettingsDataParsed = null;
  }

  return initVueApp({
    el: mountPoint,
    name: 'ProjectPermissionsRoot',
    apolloProvider,
    provide: {
      additionalInformation,
      cascadingSettingsData: cascadingSettingsDataParsed,
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
