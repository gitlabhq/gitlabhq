<script>
import { formatNumber } from '~/locale';

export default {
  name: 'NumberPresenter',
  props: {
    data: {
      required: true,
      type: Number,
    },
  },
  computed: {
    formattedNumber() {
      return formatNumber(this.data);
    },
  },
};
</script>
<template>
  <span>{{ formattedNumber }}</span>
</template>
