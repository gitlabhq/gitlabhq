import Vue from 'vue';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown/timezone_dropdown.vue';

export const initTimezoneDropdown = () => {
  const el = document.querySelector('.js-timezone-dropdown');

  if (!el) {
    return null;
  }

  const { timezoneData, initialValue, name } = el.dataset;
  const timezones = JSON.parse(timezoneData);

  const timezoneDropdown = new Vue({
    el,
    data() {
      return {
        value: initialValue,
      };
    },
    render(h) {
      return h(TimezoneDropdown, {
        props: {
          value: this.value,
          timezoneData: timezones,
          name,
        },
        class: 'gl-md-form-input-lg',
      });
    },
  });

  return timezoneDropdown;
};
