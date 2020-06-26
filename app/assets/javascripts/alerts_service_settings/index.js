import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import AlertsServiceForm from './components/alerts_service_form.vue';

export default el => {
  if (!el) {
    return null;
  }

  const {
    activated: activatedStr,
    alertsSetupUrl,
    alertsUsageUrl,
    formPath,
    authorizationKey,
    url,
    disabled,
  } = el.dataset;

  const activated = parseBoolean(activatedStr);
  const isDisabled = parseBoolean(disabled);

  return new Vue({
    el,
    render(createElement) {
      return createElement(AlertsServiceForm, {
        props: {
          alertsSetupUrl,
          alertsUsageUrl,
          initialActivated: activated,
          formPath,
          initialAuthorizationKey: authorizationKey,
          url,
          isDisabled,
        },
      });
    },
  });
};
