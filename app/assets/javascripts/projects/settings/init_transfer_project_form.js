import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import TransferProjectForm from './components/transfer_project_form.vue';

export default () => {
  const el = document.querySelector('.js-transfer-project-form');
  if (!el) {
    return false;
  }

  Vue.use(VueApollo);

  const {
    projectId: resourceId,
    targetFormId = null,
    targetHiddenInputId = null,
    buttonText: confirmButtonText = '',
    phrase: confirmationPhrase = '',
    confirmDangerMessage = '',
    additionalInformation = '',
    showUserTransferLocations,
  } = el.dataset;

  return new Vue({
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
    render(createElement) {
      return createElement(TransferProjectForm, {
        props: {
          confirmButtonText,
          confirmationPhrase,
          showUserTransferLocations: parseBoolean(showUserTransferLocations),
        },
        on: {
          selectTransferLocation: (id) => {
            if (targetHiddenInputId && document.getElementById(targetHiddenInputId)) {
              document.getElementById(targetHiddenInputId).value = id;
            }
          },
          confirm: () => {
            if (targetFormId) document.getElementById(targetFormId)?.submit();
          },
        },
      });
    },
  });
};
