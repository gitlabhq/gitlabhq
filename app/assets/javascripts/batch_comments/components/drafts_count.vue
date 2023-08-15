<script>
import { GlBadge } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';

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
    ...mapGetters('batchComments', ['draftsCount']),
  },
};
</script>
<template>
  <gl-badge size="sm" :variant="variant" class="gl-ml-2">
    {{ draftsCount }}
    <span class="sr-only"> {{ n__('draft', 'drafts', draftsCount) }} </span>
  </gl-badge>
</template>
