<script>
import { GlDrawer, GlResizeObserverDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import Tracking from '~/tracking';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { getDrawerBodyHeight } from '../utils/get_drawer_body_height';
import FeaturedCarousel from './featured_carousel.vue';
import OtherUpdates from './other_updates.vue';

const trackingMixin = Tracking.mixin();

export default {
  components: {
    GlDrawer,
    FeaturedCarousel,
    OtherUpdates,
  },
  directives: {
    GlResizeObserver: GlResizeObserverDirective,
  },
  mixins: [trackingMixin, glFeatureFlagsMixin()],
  props: {
    versionDigest: {
      type: String,
      required: false,
      default: undefined,
    },
    initialReadArticles: {
      type: Array,
      required: false,
      default: () => [],
    },
    markAsReadPath: {
      type: String,
      required: false,
      default: undefined,
    },
    mostRecentReleaseItemsCount: {
      type: Number,
      required: true,
    },
    withClose: {
      type: Function,
      required: false,
      default: () => {},
    },
    updateHelpMenuUnreadBadge: {
      type: Function,
      required: false,
      default: () => {},
    },
  },
  computed: {
    ...mapState(['open', 'features', 'pageInfo', 'drawerBodyHeight', 'fetching', 'readArticles']),
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
  },
  watch: {
    readArticles(newVal) {
      this.updateHelpMenuUnreadBadge(this.mostRecentReleaseItemsCount - newVal.length);
    },
  },
  created() {
    this.setReadArticles(this.initialReadArticles);
  },
  mounted() {
    this.openDrawer(this.versionDigest);
    this.fetchFreshItems();

    const body = document.querySelector('body');
    const { namespaceId } = body.dataset;

    this.track('click_whats_new_drawer', {
      label: 'namespace_id',
      value: namespaceId,
      property: 'navigation_top',
    });
  },
  methods: {
    ...mapActions([
      'openDrawer',
      'closeDrawer',
      'fetchItems',
      'setDrawerBodyHeight',
      'setReadArticles',
    ]),
    bottomReached() {
      const page = this.pageInfo.nextPage;
      if (page) {
        this.fetchFreshItems(page);
      }
    },
    focusDrawer() {
      this.$refs.drawer.$el.focus();
    },
    handleResize() {
      const height = getDrawerBodyHeight(this.$refs.drawer.$el);
      this.setDrawerBodyHeight(height);
    },
    fetchFreshItems(page) {
      const { versionDigest } = this;

      this.fetchItems({ page, versionDigest });
    },
    close() {
      if (this.withClose) {
        this.withClose();
      }

      this.closeDrawer();
    },
  },
};
</script>

<template>
  <div>
    <gl-drawer
      ref="drawer"
      v-gl-resize-observer="handleResize"
      aria-labelledby="whats-new-drawer-heading"
      tabindex="0"
      class="whats-new-drawer gl-leading-reset focus:gl-focus"
      :header-height="getDrawerHeaderHeight"
      :z-index="700"
      :open="open"
      @opened="focusDrawer"
      @close="close"
    >
      <template #title>
        <h3 id="whats-new-drawer-heading" class="gl-heading-3-fixed gl-my-3 gl-ml-3">
          {{ __("What's new at GitLab") }}
        </h3>
      </template>

      <div>
        <featured-carousel class="featured-carousel" />

        <other-updates
          :features="features"
          :read-articles="readArticles"
          :total-articles-to-read="mostRecentReleaseItemsCount"
          :mark-as-read-path="markAsReadPath"
          :fetching="fetching"
          :drawer-body-height="drawerBodyHeight"
          class="other-updates gl-pt-3"
          @bottomReached="bottomReached"
        />
      </div>
    </gl-drawer>
    <div v-if="open" class="whats-new-modal-backdrop modal-backdrop" @click="close"></div>
  </div>
</template>
