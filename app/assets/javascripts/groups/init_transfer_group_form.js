import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { sprintf } from '~/locale';
import { parseBoolean } from '~/lib/utils/common_utils';
import TransferGroupForm, { i18n } from './components/transfer_group_form.vue';

export default () => {
  const el = document.querySelector('.js-transfer-group-form');
  if (!el) {
    return false;
  }

  Vue.use(VueApollo);

  const {
    targetFormId = null,
    buttonText: confirmButtonText = '',
    groupName = '',
    groupFullPath,
    groupId: resourceId,
    isPaidGroup,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    provide: {
      confirmDangerMessage: sprintf(i18n.confirmationMessage, { group_name: groupName }),
      resourceId,
    },
    render(createElement) {
      return createElement(TransferGroupForm, {
        props: {
          isPaidGroup: parseBoolean(isPaidGroup),
          confirmButtonText,
          confirmationPhrase: groupFullPath,
        },
        on: {
          confirm: () => {
            document.getElementById(targetFormId)?.submit();
          },
        },
      });
    },
  });
};
