import Vue from 'vue';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown.vue';
import { formatUtcOffset } from '~/lib/utils/datetime_utility';

const formatTimezone = (item) => `[UTC ${formatUtcOffset(item.offset)}] ${item.name}`;

export const initTimezoneDropdown = () => {
  const el = document.querySelector('.js-timezone-dropdown');

  if (!el) {
    return null;
  }

  const { timezoneData, initialValue } = el.dataset;
  const timezones = JSON.parse(timezoneData);
  const initialTimezone = initialValue
    ? formatTimezone(timezones.find((timezone) => timezone.identifier === initialValue))
    : undefined;

  const timezoneDropdown = new Vue({
    el,
    data() {
      return {
        value: initialTimezone,
      };
    },
    render(h) {
      return h(TimezoneDropdown, {
        props: {
          value: this.value,
          timezoneData: timezones,
          name: 'user[timezone]',
        },
        class: 'gl-md-form-input-lg',
      });
    },
  });

  return timezoneDropdown;
};
