<script>
import { mapState, mapActions } from 'vuex';
import {
  GlDrawer,
  GlBadge,
  GlIcon,
  GlLink,
  GlInfiniteScroll,
  GlResizeObserverDirective,
} from '@gitlab/ui';
import SkeletonLoader from './skeleton_loader.vue';
import Tracking from '~/tracking';
import { getDrawerBodyHeight } from '../utils/get_drawer_body_height';

const trackingMixin = Tracking.mixin();

export default {
  components: {
    GlDrawer,
    GlBadge,
    GlIcon,
    GlLink,
    GlInfiniteScroll,
    SkeletonLoader,
  },
  directives: {
    GlResizeObserver: GlResizeObserverDirective,
  },
  mixins: [trackingMixin],
  props: {
    storageKey: {
      type: String,
      required: true,
      default: null,
    },
  },
  computed: {
    ...mapState(['open', 'features', 'pageInfo', 'drawerBodyHeight']),
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
      if (this.pageInfo.nextPage) {
        this.fetchItems(this.pageInfo.nextPage);
      }
    },
    handleResize() {
      const height = getDrawerBodyHeight(this.$refs.drawer.$el);
      this.setDrawerBodyHeight(height);
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
      :open="open"
      @close="closeDrawer"
    >
      <template #header>
        <h4 class="page-title gl-my-2">{{ __("What's new at GitLab") }}</h4>
      </template>
      <gl-infinite-scroll
        v-if="features.length"
        :fetched-items="features.length"
        :max-list-height="drawerBodyHeight"
        class="gl-p-0"
        @bottomReached="bottomReached"
      >
        <template #items>
          <div
            v-for="feature in features"
            :key="feature.title"
            class="gl-pb-7 gl-pt-5 gl-px-5 gl-border-b-1 gl-border-b-solid gl-border-b-gray-100"
          >
            <gl-link
              :href="feature.url"
              target="_blank"
              class="whats-new-item-title-link"
              data-track-event="click_whats_new_item"
              :data-track-label="feature.title"
              :data-track-property="feature.url"
            >
              <h5 class="gl-font-lg">{{ feature.title }}</h5>
            </gl-link>
            <div v-if="feature.packages" class="gl-mb-3">
              <gl-badge
                v-for="package_name in feature.packages"
                :key="package_name"
                size="sm"
                class="whats-new-item-badge gl-mr-2"
              >
                <gl-icon name="license" />{{ package_name }}
              </gl-badge>
            </div>
            <gl-link
              :href="feature.url"
              target="_blank"
              data-track-event="click_whats_new_item"
              :data-track-label="feature.title"
              :data-track-property="feature.url"
            >
              <img
                :alt="feature.title"
                :src="feature.image_url"
                class="img-thumbnail gl-px-8 gl-py-3 whats-new-item-image"
              />
            </gl-link>
            <p class="gl-pt-3">{{ feature.body }}</p>
            <gl-link
              :href="feature.url"
              target="_blank"
              data-track-event="click_whats_new_item"
              :data-track-label="feature.title"
              :data-track-property="feature.url"
              >{{ __('Learn more') }}</gl-link
            >
          </div>
        </template>
      </gl-infinite-scroll>
      <div v-else class="gl-mt-5">
        <skeleton-loader />
        <skeleton-loader />
      </div>
    </gl-drawer>
    <div v-if="open" class="whats-new-modal-backdrop modal-backdrop"></div>
  </div>
</template>
