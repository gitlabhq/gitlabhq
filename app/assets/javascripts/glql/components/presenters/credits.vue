<script>
import { formatCredits } from '../../utils/value_format';

export default {
  name: 'CreditsPresenter',
  props: {
    data: {
      required: true,
      type: Number,
    },
  },
  computed: {
    formatted() {
      return formatCredits(this.data);
    },
  },
};
</script>
<template>
  <span>{{ formatted }}</span>
</template>
