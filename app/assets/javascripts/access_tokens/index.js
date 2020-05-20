import Vue from 'vue';
import ExpiresAtField from './components/expires_at_field.vue';

const initExpiresAtField = () => {
  // eslint-disable-next-line no-new
  new Vue({
    el: document.querySelector('.js-access-tokens-expires-at'),
    components: { ExpiresAtField },
  });
};

export default initExpiresAtField;
