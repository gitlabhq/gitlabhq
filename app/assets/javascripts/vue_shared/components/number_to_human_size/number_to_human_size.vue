<script>
import { getPreferredLocales } from '~/locale';
import { numberToHumanSizeSplit } from '~/lib/utils/number_utils';

export default {
  name: 'NumberToHumanSize',
  props: {
    value: {
      type: Number,
      required: true,
    },
    fractionDigits: {
      type: Number,
      required: false,
      default: 1,
    },
    labelClass: {
      type: String,
      required: false,
      default: null,
    },
    locale: {
      type: Array,
      required: false,
      default: () => getPreferredLocales(),
    },
    plainZero: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    formattedValue() {
      if (this.plainZero && this.value === 0) {
        return ['0'];
      }
      return numberToHumanSizeSplit({
        size: this.value,
        digits: this.fractionDigits,
        locale: this.locale,
      });
    },
    number() {
      return this.formattedValue[0];
    },
    label() {
      return this.formattedValue[1];
    },
  },
};
</script>
<template>
  <span>
    <span>{{ number }}</span>
    <span v-if="label" :class="labelClass">{{ label }}</span>
  </span>
</template>
