<script>
import { GlBadge } from '@gitlab/ui';
import { mapState } from 'pinia';
import { useBatchComments } from '~/batch_comments/store';

export default {
  components: {
    GlBadge,
  },
  props: {
    variant: {
      type: String,
      required: false,
      default: 'info',
    },
  },
  computed: {
    ...mapState(useBatchComments, ['draftsCount']),
  },
};
</script>
<template>
  <gl-badge :variant="variant" class="gl-ml-2">
    {{ draftsCount }}
    <span class="sr-only"> {{ n__('draft', 'drafts', draftsCount) }} </span>
  </gl-badge>
</template>
