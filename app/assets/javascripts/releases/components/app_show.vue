<script>
import { mapState, mapActions } from 'vuex';
import ReleaseBlock from './release_block.vue';
import ReleaseSkeletonLoader from './release_skeleton_loader.vue';

export default {
  name: 'ReleaseShowApp',
  components: {
    ReleaseBlock,
    ReleaseSkeletonLoader,
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
    <release-skeleton-loader v-if="isFetchingRelease" />

    <release-block v-else-if="!fetchError" :release="release" />
  </div>
</template>
