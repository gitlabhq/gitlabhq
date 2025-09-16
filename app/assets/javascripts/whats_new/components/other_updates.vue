<script>
import { GlInfiniteScroll } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import axios from '~/lib/utils/axios_utils';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { isLoggedIn } from '~/lib/utils/common_utils';
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
    ...mapActions(['setReadArticles']),
    bottomReached() {
      this.$emit('bottomReached');
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
          <feature
            v-for="(feature, index) in features"
            :key="feature.name"
            :feature="feature"
            :show-unread="showUnread(index)"
            @mark-article-as-read="markAsRead(index)"
          />
        </template>
      </gl-infinite-scroll>
    </template>
    <div v-else class="gl-mt-5">
      <skeleton-loader />
    </div>
  </div>
</template>
