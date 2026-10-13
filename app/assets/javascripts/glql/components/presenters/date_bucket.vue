<script>
import { formatBucketDate } from '../../utils/date_bucket';

export default {
  name: 'DateBucketPresenter',
  props: {
    data: {
      required: true,
      type: String,
    },
    parameters: {
      required: true,
      type: Object,
    },
  },
  computed: {
    label() {
      // Cells have no axis to carry the year context, so always include it.
      return formatBucketDate(this.data, this.parameters.granularity, true);
    },
  },
};
</script>
<template>
  <span>{{ label }}</span>
</template>
