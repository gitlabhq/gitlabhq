import Vue from 'vue';
import ExpiresAtField from './components/expires_at_field.vue';

const getInputAttrs = el => {
  const input = el.querySelector('input');

  return {
    id: input.id,
    name: input.name,
    placeholder: input.placeholder,
  };
};

const initExpiresAtField = () => {
  const el = document.querySelector('.js-access-tokens-expires-at');

  if (!el) {
    return null;
  }

  const inputAttrs = getInputAttrs(el);

  return new Vue({
    el,
    render(h) {
      return h(ExpiresAtField, {
        props: {
          inputAttrs,
        },
      });
    },
  });
};

export default initExpiresAtField;
