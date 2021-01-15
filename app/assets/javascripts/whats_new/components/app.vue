<script>
import { mapState, mapActions } from 'vuex';
import {
  GlDrawer,
  GlInfiniteScroll,
  GlResizeObserverDirective,
  GlTabs,
  GlTab,
  GlBadge,
  GlLoadingIcon,
} from '@gitlab/ui';
import SkeletonLoader from './skeleton_loader.vue';
import Feature from './feature.vue';
import Tracking from '~/tracking';
import { getDrawerBodyHeight } from '../utils/get_drawer_body_height';

const trackingMixin = Tracking.mixin();

export default {
  components: {
    GlDrawer,
    GlInfiniteScroll,
    GlTabs,
    GlTab,
    SkeletonLoader,
    Feature,
    GlBadge,
    GlLoadingIcon,
  },
  directives: {
    GlResizeObserver: GlResizeObserverDirective,
  },
  mixins: [trackingMixin],
  props: {
    storageKey: {
      type: String,
      required: true,
    },
    versions: {
      type: Array,
      required: true,
    },
    gitlabDotCom: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState(['open', 'features', 'pageInfo', 'drawerBodyHeight', 'fetching']),
  },
  mounted() {
    this.openDrawer(this.storageKey);
    this.fetchItems();

    const body = document.querySelector('body');
    const namespaceId = body.getAttribute('data-namespace-id');

    this.track('click_whats_new_drawer', { label: 'namespace_id', value: namespaceId });
  },
  methods: {
    ...mapActions(['openDrawer', 'closeDrawer', 'fetchItems', 'setDrawerBodyHeight']),
    bottomReached() {
      const page = this.pageInfo.nextPage;
      if (page) {
        this.fetchItems({ page });
      }
    },
    handleResize() {
      const height = getDrawerBodyHeight(this.$refs.drawer.$el);
      this.setDrawerBodyHeight(height);
    },
    featuresForVersion(version) {
      return this.features.filter((feature) => {
        return feature.release === parseFloat(version);
      });
    },
    fetchVersion(version) {
      if (this.featuresForVersion(version).length === 0) {
        this.fetchItems({ version });
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-drawer
      ref="drawer"
      v-gl-resize-observer="handleResize"
      class="whats-new-drawer"
      :z-index="700"
      :open="open"
      @close="closeDrawer"
    >
      <template #header>
        <h4 class="page-title gl-my-2">{{ __("What's new") }}</h4>
      </template>
      <template v-if="features.length">
        <gl-infinite-scroll
          v-if="gitlabDotCom"
          :fetched-items="features.length"
          :max-list-height="drawerBodyHeight"
          class="gl-p-0"
          @bottomReached="bottomReached"
        >
          <template #items>
            <feature v-for="feature in features" :key="feature.title" :feature="feature" />
          </template>
        </gl-infinite-scroll>
        <gl-tabs v-else :style="{ height: `${drawerBodyHeight}px` }" class="gl-p-0">
          <gl-tab
            v-for="(version, index) in versions"
            :key="version"
            @click="fetchVersion(version)"
          >
            <template #title>
              <span>{{ version }}</span>
              <gl-badge v-if="index === 0">{{ __('Your Version') }}</gl-badge>
            </template>
            <gl-loading-icon v-if="fetching" size="lg" class="text-center" />
            <template v-else>
              <feature
                v-for="feature in featuresForVersion(version)"
                :key="feature.title"
                :feature="feature"
              />
            </template>
          </gl-tab>
        </gl-tabs>
      </template>
      <div v-else class="gl-mt-5">
        <skeleton-loader />
        <skeleton-loader />
      </div>
    </gl-drawer>
    <div v-if="open" class="whats-new-modal-backdrop modal-backdrop"></div>
  </div>
</template>
