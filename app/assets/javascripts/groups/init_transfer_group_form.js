import Vue from 'vue';
import { sprintf } from '~/locale';
import { parseBoolean } from '~/lib/utils/common_utils';
import TransferGroupForm, { i18n } from './components/transfer_group_form.vue';

const prepareGroups = (rawGroups) => {
  if (!rawGroups) {
    return { group: [] };
  }

  const group = JSON.parse(rawGroups).map(({ id, text: humanName }) => ({
    id,
    humanName,
  }));

  return { group };
};

export default () => {
  const el = document.querySelector('.js-transfer-group-form');
  if (!el) {
    return false;
  }

  const {
    targetFormId = null,
    buttonText: confirmButtonText = '',
    groupName = '',
    parentGroups,
    isPaidGroup,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      confirmDangerMessage: sprintf(i18n.confirmationMessage, { group_name: groupName }),
    },
    render(createElement) {
      return createElement(TransferGroupForm, {
        props: {
          parentGroups: prepareGroups(parentGroups),
          isPaidGroup: parseBoolean(isPaidGroup),
          confirmButtonText,
          confirmationPhrase: groupName,
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
