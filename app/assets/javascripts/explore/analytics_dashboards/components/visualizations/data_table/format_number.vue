<script>
import { isNil } from 'lodash-es';
import { formatNumber } from '~/locale';

export default {
  name: 'FormatNumber',
  props: {
    value: {
      type: Number,
      required: false,
      default: undefined,
    },
    fractionDigits: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    formattedValue() {
      const { value, fractionDigits } = this;

      if (isNil(value)) return '-';

      return formatNumber(value, {
        minimumFractionDigits: fractionDigits,
        maximumFractionDigits: fractionDigits,
      });
    },
  },
};
</script>
<template>
  <div>
    {{ formattedValue }}
  </div>
</template>
