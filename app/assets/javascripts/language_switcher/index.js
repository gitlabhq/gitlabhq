import Vue from 'vue';
import { getCookie } from '~/lib/utils/common_utils';
import LanguageSwitcher from './components/app.vue';
import { PREFERRED_LANGUAGE_COOKIE_KEY } from './constants';

export const initLanguageSwitcher = () => {
  const el = document.querySelector('.js-language-switcher');
  if (!el) return false;
  const locales = JSON.parse(el.dataset.locales);
  const preferredLangCode = getCookie(PREFERRED_LANGUAGE_COOKIE_KEY);
  const preferredLocale = locales.find((locale) => locale.value === preferredLangCode);

  return new Vue({
    el,
    provide: {
      locales,
      preferredLocale,
    },
    render(createElement) {
      return createElement(LanguageSwitcher);
    },
  });
};
