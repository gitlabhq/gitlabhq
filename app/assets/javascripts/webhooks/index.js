import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
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
    isSystemHook,
    triggers: initialTriggers,
    isNewHook,
    hasSigningToken,
    signingTokenDocsPath,
  } = el.dataset;

  return initVueApp({
    el,
    name: 'WebhookFormRoot',
    component: WebhookFormApp,
    props: {
      initialName,
      initialDescription,
      initialSecretToken,
      initialUrl,
      initialUrlVariables: JSON.parse(urlVariables),
      initialCustomHeaders: JSON.parse(customHeaders),
      initialTriggers: convertObjectPropsToCamelCase(JSON.parse(initialTriggers)),
      hasGroup: parseBoolean(hasGroup),
      isSystemHook: parseBoolean(isSystemHook),
      isNewHook: parseBoolean(isNewHook),
      hasSigningToken: parseBoolean(hasSigningToken),
      signingTokenDocsPath,
    },
  });
};

const initHookTestDropdown = (el) => {
  const { items, size } = el.dataset;

  return initVueApp({
    el,
    name: 'TestDropdownRoot',
    component: TestDropdown,
    props: {
      items: JSON.parse(items),
      size,
    },
  });
};

export const initHookTestDropdowns = (selector = '.js-webhook-test-dropdown') =>
  document.querySelectorAll(selector).forEach(initHookTestDropdown);
