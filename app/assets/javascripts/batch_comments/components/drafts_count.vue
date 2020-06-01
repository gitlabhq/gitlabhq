<script>
import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters('batchComments', ['draftsCount']),
  },
};
</script>
<template>
  <span class="drafts-count-component">
    <span class="drafts-count-number">{{ draftsCount }}</span>
    <span class="sr-only"> {{ n__('draft', 'drafts', draftsCount) }} </span>
  </span>
</template>
