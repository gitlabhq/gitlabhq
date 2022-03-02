import { kebabCase } from 'lodash';
import Vue from 'vue';
import { GlToggle } from '@gitlab/ui';
import { parseBoolean } from '~/lib/utils/common_utils';

export const initToggle = (el) => {
  if (!el) {
    return false;
  }

  const { name, id, isChecked, disabled, isLoading, label, help, labelPosition, ...dataset } =
    el.dataset || {};

  const dataAttrs = Object.fromEntries(
    Object.entries(dataset).map(([key, value]) => [`data-${kebabCase(key)}`, value]),
  );

  return new Vue({
    el,
    props: {
      disabled: {
        type: Boolean,
        required: false,
        default: parseBoolean(disabled),
      },
      isLoading: {
        type: Boolean,
        required: false,
        default: parseBoolean(isLoading),
      },
    },
    data() {
      return {
        value: parseBoolean(isChecked),
      };
    },
    render(h) {
      return h(GlToggle, {
        props: {
          name,
          value: this.value,
          disabled: this.disabled,
          isLoading: this.isLoading,
          label,
          help,
          labelPosition,
        },
        class: el.className,
        attrs: { id, ...dataAttrs },
        on: {
          change: (newValue) => {
            this.value = newValue;
            this.$emit('change', newValue);
          },
        },
      });
    },
  });
};
