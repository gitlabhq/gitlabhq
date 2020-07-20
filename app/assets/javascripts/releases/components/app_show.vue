<script>
import { mapState, mapActions } from 'vuex';
import { GlSkeletonLoading } from '@gitlab/ui';
import ReleaseBlock from './release_block.vue';

export default {
  name: 'ReleaseShowApp',
  components: {
    GlSkeletonLoading,
    ReleaseBlock,
  },
  computed: {
    ...mapState('detail', ['isFetchingRelease', 'fetchError', 'release']),
  },
  created() {
    this.fetchRelease();
  },
  methods: {
    ...mapActions('detail', ['fetchRelease']),
  },
};
</script>
<template>
  <div class="gl-mt-3">
    <gl-skeleton-loading v-if="isFetchingRelease" />

    <release-block v-else-if="!fetchError" :release="release" />
  </div>
</template>
