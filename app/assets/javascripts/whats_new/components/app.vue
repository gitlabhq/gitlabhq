<script>
import { GlDrawer } from '@gitlab/ui';
import { mapState, mapActions } from 'pinia';
import Tracking from '~/tracking';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { useWhatsNew } from '../store';
import OtherUpdates from './other_updates.vue';

const trackingMixin = Tracking.mixin();

export default {
  components: {
    GlDrawer,
    OtherUpdates,
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
    ...mapState(useWhatsNew, ['open', 'features', 'pageInfo', 'fetching', 'readArticles']),
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
    this.fetchInitialItems();

    const body = document.querySelector('body');
    const { namespaceId } = body.dataset;

    this.track('click_whats_new_drawer', {
      label: 'namespace_id',
      value: namespaceId,
      property: 'navigation_top',
    });
  },
  methods: {
    ...mapActions(useWhatsNew, ['openDrawer', 'closeDrawer', 'fetchItems', 'setReadArticles']),
    handleLoadMore() {
      const page = this.pageInfo.nextPage;
      if (page) {
        this.fetchFreshItems(page);
      }
    },
    focusDrawer() {
      this.$refs.drawer.$el.focus();
    },
    async fetchInitialItems() {
      const { versionDigest } = this;
      const INITIAL_PAGES = 3;

      for (let i = 0; i < INITIAL_PAGES; i += 1) {
        // eslint-disable-next-line no-await-in-loop
        await this.fetchItems({
          page: i === 0 ? undefined : this.pageInfo.nextPage,
          versionDigest,
        });
        if (!this.pageInfo.nextPage) break;
      }
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
        <h3 id="whats-new-drawer-heading" class="gl-heading-3-fixed gl-m-0">
          {{ __("What's new at GitLab") }}
        </h3>
      </template>

      <div>
        <other-updates
          :features="features"
          :read-articles="readArticles"
          :total-articles-to-read="mostRecentReleaseItemsCount"
          :mark-as-read-path="markAsReadPath"
          :fetching="fetching"
          :page-info="pageInfo"
          class="other-updates"
          @load-more="handleLoadMore"
          @close-drawer="closeDrawer"
        />
      </div>
    </gl-drawer>
    <div v-if="open" class="whats-new-modal-backdrop modal-backdrop" @click="close"></div>
  </div>
</template>
