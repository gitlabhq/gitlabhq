<script>
import { GlBadge } from '@gitlab/ui';
import { mapGetters } from 'vuex';

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
