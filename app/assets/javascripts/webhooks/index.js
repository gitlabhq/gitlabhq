import Vue from 'vue';
import { parseBoolean, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import WebhookFormApp from './components/webhook_form_app.vue';
import TestDropdown from './components/test_dropdown.vue';

export default () => {
  const el = document.querySelector('.js-vue-webhook-form');

  if (!el) {
    return null;
  }

  const {
    name: initialName,
    description: initialDescription,
    url: initialUrl,
    urlVariables,
    secretToken: initialSecretToken,
    customHeaders,
    hasGroup,
    triggers: initialTriggers,
    isNewHook,
  } = el.dataset;

  return new Vue({
    el,
    name: 'WebhookFormRoot',
    render(createElement) {
      return createElement(WebhookFormApp, {
        props: {
          initialName,
          initialDescription,
          initialSecretToken,
          initialUrl,
          initialUrlVariables: JSON.parse(urlVariables),
          initialCustomHeaders: JSON.parse(customHeaders),
          initialTriggers: convertObjectPropsToCamelCase(JSON.parse(initialTriggers)),
          hasGroup: parseBoolean(hasGroup),
          isNewHook: parseBoolean(isNewHook),
        },
      });
    },
  });
};

const initHookTestDropdown = (el) => {
  const { items, size } = el.dataset;

  return new Vue({
    el,
    render(h) {
      return h(TestDropdown, {
        props: {
          items: JSON.parse(items),
          size,
        },
      });
    },
  });
};

export const initHookTestDropdowns = (selector = '.js-webhook-test-dropdown') =>
  document.querySelectorAll(selector).forEach(initHookTestDropdown);
