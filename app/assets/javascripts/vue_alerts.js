import Vue from 'vue';
import { setCookie, parseBoolean } from '~/lib/utils/common_utils';

import DismissibleAlert from '~/vue_shared/components/dismissible_alert.vue';

const getCookieExpirationPeriod = (expirationPeriod) => {
  const defaultExpirationPeriod = 30;
  const alertExpirationPeriod = Number(expirationPeriod);

  return !expirationPeriod || Number.isNaN(alertExpirationPeriod)
    ? defaultExpirationPeriod
    : alertExpirationPeriod;
};

const mountVueAlert = (el) => {
  const props = {
    html: el.innerHTML,
  };
  const attrs = {
    ...el.dataset,
    dismissible: parseBoolean(el.dataset.dismissible),
  };
  const { dismissCookieName, dismissCookieExpire } = el.dataset;

  return new Vue({
    el,
    render(createElement) {
      return createElement(DismissibleAlert, {
        props,
        attrs,
        on: {
          alertDismissed() {
            if (!dismissCookieName) {
              return;
            }
            setCookie(dismissCookieName, true, {
              expires: getCookieExpirationPeriod(dismissCookieExpire),
            });
          },
        },
      });
    },
  });
};

export default () => [...document.querySelectorAll('.js-vue-alert')].map(mountVueAlert);
