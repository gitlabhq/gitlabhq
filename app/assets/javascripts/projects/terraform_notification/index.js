import Vue from 'vue';
import { parseBoolean, getCookie } from '~/lib/utils/common_utils';
import TerraformNotification from './components/terraform_notification.vue';

export default () => {
  const el = document.querySelector('.js-terraform-notification');
  const bannerDismissedKey = 'terraform_notification_dismissed';

  if (!el || parseBoolean(getCookie(bannerDismissedKey))) {
    return false;
  }

  const { terraformImagePath } = el.dataset;

  return new Vue({
    el,
    provide: {
      terraformImagePath,
      bannerDismissedKey,
    },
    render: (createElement) => createElement(TerraformNotification),
  });
};
