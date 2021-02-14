import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import IssuableByEmail from './components/issuable_by_email.vue';

Vue.use(GlToast);

export default () => {
  const el = document.querySelector('.js-issueable-by-email');

  if (!el) return null;

  const {
    initialEmail,
    issuableType,
    emailsHelpPagePath,
    quickActionsHelpPath,
    markdownHelpPath,
    resetPath,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      initialEmail,
      issuableType,
      emailsHelpPagePath,
      quickActionsHelpPath,
      markdownHelpPath,
      resetPath,
    },
    render(h) {
      return h(IssuableByEmail);
    },
  });
};
