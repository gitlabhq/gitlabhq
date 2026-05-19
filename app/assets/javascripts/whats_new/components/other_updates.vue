<script>
import { GlButton } from '@gitlab/ui';
import { mapActions } from 'pinia';
import axios from '~/lib/utils/axios_utils';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { useWhatsNew } from '../store';
import Feature from './feature.vue';
import SkeletonLoader from './skeleton_loader.vue';

export default {
  name: 'OtherUpdates',
  components: {
    GlButton,
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
    readArticles: {
      type: Array,
      required: false,
      default: () => [],
    },
    totalArticlesToRead: {
      type: Number,
      required: true,
    },
    markAsReadPath: {
      type: String,
      required: false,
      default: null,
    },
    pageInfo: {
      type: Object,
      required: true,
    },
  },
  emits: ['load-more', 'close-drawer'],
  data() {
    return {
      previousButtonCount: 0,
    };
  },
  watch: {
    fetching(newVal, oldVal) {
      if (oldVal && !newVal && this.previousButtonCount > 0) {
        this.focusFirstNewItem();
      }
    },
  },
  methods: {
    ...mapActions(useWhatsNew, ['setReadArticles']),
    loadMore() {
      this.previousButtonCount = this.getArticleToggleButtons().length;
      this.$emit('load-more');
    },
    getArticleToggleButtons() {
      return (
        this.$refs.featureList?.querySelectorAll('[data-testid="whats-new-article-toggle"]') || []
      );
    },
    focusFirstNewItem() {
      this.$nextTick(() => {
        const buttons = this.getArticleToggleButtons();
        const firstNewButton = buttons[this.previousButtonCount];
        if (firstNewButton) {
          firstNewButton.focus();
        }
      });
    },
    showUnread(index) {
      return index <= this.totalArticlesToRead && !this.readArticles.includes(index);
    },
    markAsRead(index) {
      if (isLoggedIn() && this.markAsReadPath) {
        axios
          .post(this.markAsReadPath, { article_id: index })
          .then(() => {
            this.setReadArticles([...this.readArticles, index]);
          })
          .catch((error) => Sentry.captureException(error));
      }
    },
    closeDrawer() {
      this.$emit('close-drawer');
    },
  },
};
</script>

<template>
  <div>
    <template v-if="features.length || !fetching">
      <div ref="featureList" class="gl-p-0">
        <feature
          v-for="(feature, index) in features"
          :key="feature.name"
          :feature="feature"
          :show-unread="showUnread(index)"
          @mark-article-as-read="markAsRead(index)"
          @close-drawer="closeDrawer"
        />
      </div>

      <div v-if="pageInfo.nextPage" class="gl-mb-6 gl-mt-5 gl-flex gl-justify-center">
        <gl-button
          data-testid="load-more-button"
          size="small"
          category="tertiary"
          variant="confirm"
          :loading="fetching"
          @click="loadMore"
        >
          {{ __('Load more') }}
        </gl-button>
      </div>
    </template>
    <div v-else class="gl-mt-5">
      <skeleton-loader />
    </div>
  </div>
</template>
