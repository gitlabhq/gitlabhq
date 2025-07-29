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
  methods: {
    bottomReached() {
      this.$emit('bottomReached');
    },
  },
};
</script>

<template>
  <div>
    <h5 class="gl-m-3 gl-pt-0">{{ __('Other updates') }}</h5>

    <template v-if="features.length || !fetching">
      <gl-infinite-scroll
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
