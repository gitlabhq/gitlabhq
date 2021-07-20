<script>
import { GlDrawer, GlInfiniteScroll, GlResizeObserverDirective } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import Tracking from '~/tracking';
import { getDrawerBodyHeight } from '../utils/get_drawer_body_height';
import Feature from './feature.vue';
import SkeletonLoader from './skeleton_loader.vue';

const trackingMixin = Tracking.mixin();

export default {
  components: {
    GlDrawer,
    GlInfiniteScroll,
    SkeletonLoader,
    Feature,
  },
  directives: {
    GlResizeObserver: GlResizeObserverDirective,
  },
  mixins: [trackingMixin],
  props: {
    versionDigest: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(['open', 'features', 'pageInfo', 'drawerBodyHeight', 'fetching']),
  },
  mounted() {
    this.openDrawer(this.versionDigest);
    this.fetchFreshItems();

    const body = document.querySelector('body');
    const namespaceId = body.getAttribute('data-namespace-id');

    this.track('click_whats_new_drawer', { label: 'namespace_id', value: namespaceId });
  },
  methods: {
    ...mapActions(['openDrawer', 'closeDrawer', 'fetchItems', 'setDrawerBodyHeight']),
    bottomReached() {
      const page = this.pageInfo.nextPage;
      if (page) {
        this.fetchFreshItems(page);
      }
    },
    handleResize() {
      const height = getDrawerBodyHeight(this.$refs.drawer.$el);
      this.setDrawerBodyHeight(height);
    },
    fetchFreshItems(page) {
      const { versionDigest } = this;

      this.fetchItems({ page, versionDigest });
    },
  },
};
</script>

<template>
  <div>
    <gl-drawer
      ref="drawer"
      v-gl-resize-observer="handleResize"
      class="whats-new-drawer gl-reset-line-height"
      :z-index="700"
      :open="open"
      @close="closeDrawer"
    >
      <template #title>
        <h4 class="page-title gl-my-2">{{ __("What's new") }}</h4>
      </template>
      <template v-if="features.length">
        <gl-infinite-scroll
          :fetched-items="features.length"
          :max-list-height="drawerBodyHeight"
          class="gl-p-0"
          @bottomReached="bottomReached"
        >
          <template #items>
            <feature v-for="feature in features" :key="feature.title" :feature="feature" />
          </template>
        </gl-infinite-scroll>
      </template>
      <div v-else class="gl-mt-5">
        <skeleton-loader />
        <skeleton-loader />
      </div>
    </gl-drawer>
    <div v-if="open" class="whats-new-modal-backdrop modal-backdrop" @click="closeDrawer"></div>
  </div>
</template>
