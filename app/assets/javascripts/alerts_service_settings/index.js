import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import AlertsServiceForm from './components/alerts_service_form.vue';

export default el => {
  if (!el) {
    return null;
  }

  const { activated: activatedStr, formPath, authorizationKey, url, learnMoreUrl } = el.dataset;
  const activated = parseBoolean(activatedStr);

  return new Vue({
    el,
    render(createElement) {
      return createElement(AlertsServiceForm, {
        props: {
          initialActivated: activated,
          formPath,
          learnMoreUrl,
          initialAuthorizationKey: authorizationKey,
          url,
        },
      });
    },
  });
};
