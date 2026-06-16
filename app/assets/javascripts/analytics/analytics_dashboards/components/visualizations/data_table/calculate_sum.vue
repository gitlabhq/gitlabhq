<script>
import { sum } from 'lodash-es';
import { isNumeric } from '~/lib/utils/number_utils';

export default {
  name: 'CalculateSum',
  props: {
    values: {
      type: Array,
      required: true,
      validator: (values) => values.every((value) => isNumeric(value)),
    },
  },
  computed: {
    total() {
      return sum(this.values);
    },
  },
};
</script>
<template>
  <span>{{ total }}</span>
</template>
