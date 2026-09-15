import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import TransferProjectForm from './components/transfer_project_form.vue';

export default () => {
  const el = document.querySelector('.js-transfer-project-form');
  if (!el) {
    return false;
  }

  Vue.use(VueApollo);

  const {
    projectId: resourceId,
    targetFormId,
    targetHiddenInputId,
    buttonText: confirmButtonText = '',
    phrase: confirmationPhrase = '',
    confirmDangerMessage = '',
    additionalInformation = '',
    showUserTransferLocations,
  } = el.dataset;

  return initVueApp({
    el,
    name: 'TransferProjectFormRoot',
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    provide: {
      confirmDangerMessage,
      additionalInformation,
      resourceId,
      htmlConfirmationMessage: true,
    },
    component: TransferProjectForm,
    props: {
      confirmButtonText,
      confirmationPhrase,
      showUserTransferLocations: parseBoolean(showUserTransferLocations),
      targetFormId,
      targetHiddenInputId,
    },
  });
};
