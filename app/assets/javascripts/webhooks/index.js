import Vue from 'vue';
import FormUrlApp from './components/form_url_app.vue';

export default () => {
  const el = document.querySelector('.js-vue-webhook-form');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    name: 'WebhookFormRoot',
    render(createElement) {
      return createElement(FormUrlApp, {});
    },
  });
};
