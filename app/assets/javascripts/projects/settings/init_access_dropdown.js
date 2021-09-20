import Vue from 'vue';
import AccessDropdown from './components/access_dropdown.vue';

export const initAccessDropdown = (el, options) => {
  if (!el) {
    return false;
  }

  const { accessLevelsData, accessLevel } = options;

  return new Vue({
    el,
    render(createElement) {
      const vm = this;
      return createElement(AccessDropdown, {
        props: {
          accessLevel,
          accessLevelsData: accessLevelsData.roles,
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
