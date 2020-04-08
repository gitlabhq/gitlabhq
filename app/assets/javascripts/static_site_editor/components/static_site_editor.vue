<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import { GlSkeletonLoader } from '@gitlab/ui';

import EditArea from './edit_area.vue';

export default {
  components: {
    EditArea,
    GlSkeletonLoader,
  },
  computed: {
    ...mapState(['content', 'isLoadingContent']),
    ...mapGetters(['isContentLoaded']),
  },
  mounted() {
    this.loadContent();
  },
  methods: {
    ...mapActions(['loadContent']),
  },
};
</script>
<template>
  <div class="d-flex justify-content-center h-100">
    <div v-if="isLoadingContent" class="w-50 h-50 mt-2">
      <gl-skeleton-loader :width="500" :height="102">
        <rect width="500" height="16" rx="4" />
        <rect y="20" width="375" height="16" rx="4" />
        <rect x="380" y="20" width="120" height="16" rx="4" />
        <rect y="40" width="250" height="16" rx="4" />
        <rect x="255" y="40" width="150" height="16" rx="4" />
        <rect x="410" y="40" width="90" height="16" rx="4" />
      </gl-skeleton-loader>
    </div>
    <edit-area v-if="isContentLoaded" class="w-75 h-100 shadow-none" :value="content" />
  </div>
</template>
