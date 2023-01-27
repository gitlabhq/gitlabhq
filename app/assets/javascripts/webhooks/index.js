import Vue from 'vue';
import FormUrlApp from './components/form_url_app.vue';
import TestDropdown from './components/test_dropdown.vue';

export default () => {
  const el = document.querySelector('.js-vue-webhook-form');

  if (!el) {
    return null;
  }

  const { url: initialUrl, urlVariables } = el.dataset;

  return new Vue({
    el,
    name: 'WebhookFormRoot',
    render(createElement) {
      return createElement(FormUrlApp, {
        props: {
          initialUrl,
          initialUrlVariables: JSON.parse(urlVariables),
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
