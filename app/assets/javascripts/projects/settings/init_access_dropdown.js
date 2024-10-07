import Vue from 'vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import AccessDropdown from './components/access_dropdown.vue';

export const initAccessDropdown = (el, options) => {
  if (!el) {
    return null;
  }

  const { accessLevelsData, ...props } = options;
  const { label, disabled, preselectedItems = '[]' } = el.dataset || {};
  let preselected = [];

  try {
    preselected = JSON.parse(preselectedItems);
  } catch (e) {
    Sentry.captureException(e);
  }

  return new Vue({
    el,
    name: 'AccessDropdownRoot',
    data() {
      return { preselected };
    },
    disabled,
    methods: {
      setPreselectedItems(items) {
        this.preselected = items;
      },
    },
    render(createElement) {
      const vm = this;
      return createElement(AccessDropdown, {
        props: {
          label,
          disabled,
          accessLevelsData: accessLevelsData.roles,
          preselectedItems: this.preselected,
          ...props,
        },
        on: {
          select(selected) {
            vm.$emit('select', selected);
          },
          shown() {
            vm.$emit('shown');
          },
          hidden() {
            vm.$emit('hidden');
          },
        },
      });
    },
  });
};
