import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { sprintf } from '~/locale';
import { parseBoolean } from '~/lib/utils/common_utils';
import { helpPagePath } from '~/helpers/help_page_helper';
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
    warningMessage = '',
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
      confirmDangerMessage: sprintf(
        i18n.confirmationMessage,
        {
          groupName: groupFullPath,
          codeStart: '<code>',
          codeEnd: '</code>',
          groupLinkStart: `<a href="${helpPagePath(
            'user/group/manage.html#change-a-groups-path',
          )}">`,
          groupLinkEnd: '</a>',
          documentationLinkStart: `<a href="${helpPagePath(
            'user/project/repository/_index.html#repository-path-changes',
          )}">`,
          documentationLinkEnd: '</a>',
        },
        false,
      ),
      htmlConfirmationMessage: true,
      additionalInformation: warningMessage,
      confirmButtonText: i18n.confirmButtonText,
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
