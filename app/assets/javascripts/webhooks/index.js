import Vue from 'vue';
import FormUrlApp from './components/form_url_app.vue';

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
