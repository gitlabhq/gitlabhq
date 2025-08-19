<script>
import { GlInfiniteScroll } from '@gitlab/ui';
import Feature from './feature.vue';
import SkeletonLoader from './skeleton_loader.vue';

export default {
  name: 'OtherUpdates',
  components: {
    GlInfiniteScroll,
    Feature,
    SkeletonLoader,
  },
  props: {
    features: {
      type: Array,
      required: true,
    },
    fetching: {
      type: Boolean,
      required: true,
    },
    drawerBodyHeight: {
      type: Number,
      required: true,
    },
  },
  emits: ['bottomReached'],
  data() {
    return {
      initialListPopulated: false,
    };
  },
  watch: {
    fetching(newVal) {
      if (!newVal) {
        const container = this.$refs.infiniteScroll?.$refs?.infiniteContainer;
        if (!container) return;

        // fetched items do not fully populate the container
        if (container.scrollHeight <= container.clientHeight) {
          this.bottomReached();
        } else if (!this.initialListPopulated) {
          this.initialListPopulated = true;
        }
      }
    },
    initialListPopulated() {
      this.$refs.infiniteScroll.scrollUp();
    },
  },
  methods: {
    bottomReached() {
      this.$emit('bottomReached');
    },
  },
};
</script>

<template>
  <div>
    <template v-if="features.length || !fetching">
      <gl-infinite-scroll
        ref="infiniteScroll"
        :fetched-items="features.length"
        :max-list-height="drawerBodyHeight"
        class="gl-p-0"
        @bottomReached="bottomReached"
      >
        <template #items>
          <feature v-for="feature in features" :key="feature.name" :feature="feature" />
        </template>
      </gl-infinite-scroll>
    </template>
    <div v-else class="gl-mt-5">
      <skeleton-loader />
    </div>
  </div>
</template>
