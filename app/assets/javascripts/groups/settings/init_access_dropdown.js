import Vue from 'vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import AccessDropdown from './components/access_dropdown.vue';

export const initAccessDropdown = (el) => {
  if (!el) {
    return null;
  }

  const { label, disabled, preselectedItems } = el.dataset;
  let preselected = [];
  try {
    preselected = JSON.parse(preselectedItems);
  } catch (e) {
    Sentry.captureException(e);
  }

  return new Vue({
    el,
    render(createElement) {
      const vm = this;
      return createElement(AccessDropdown, {
        props: {
          preselectedItems: preselected,
          label,
          disabled,
        },
        on: {
          select(selected) {
            vm.$emit('select', selected);
          },
        },
      });
    },
  });
};
