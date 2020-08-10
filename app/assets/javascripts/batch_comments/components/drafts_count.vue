<script>
import { mapGetters } from 'vuex';
import { GlBadge } from '@gitlab/ui';

export default {
  components: {
    GlBadge,
  },
  computed: {
    ...mapGetters('batchComments', ['draftsCount']),
  },
};
</script>
<template>
  <gl-badge size="sm" variant="success">
    {{ draftsCount }}
    <span class="sr-only"> {{ n__('draft', 'drafts', draftsCount) }} </span>
  </gl-badge>
</template>
