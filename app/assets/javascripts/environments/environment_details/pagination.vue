<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlKeysetPagination } from '@gitlab/ui';
import { setUrlParams } from '~/lib/utils/url_utility';
import { translations } from './constants';

export default {
  components: {
    GlKeysetPagination,
  },
  props: {
    pageInfo: {
      type: Object,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  translations,
  computed: {
    previousLink() {
      if (!this.pageInfo || !this.pageInfo.hasPreviousPage) {
        return '';
      }
      return setUrlParams({ before: this.pageInfo.startCursor }, window.location.href, true);
    },
    nextLink() {
      if (!this.pageInfo || !this.pageInfo.hasNextPage) {
        return '';
      }
      return setUrlParams({ after: this.pageInfo.endCursor }, window.location.href, true);
    },
    isPaginationVisible() {
      if (!this.pageInfo) {
        return false;
      }

      return this.pageInfo.hasNextPage || this.pageInfo.hasPreviousPage;
    },
  },
  methods: {
    onPrev(previousCursor) {
      this.$router.push({ query: { before: previousCursor } });
    },
    onNext(nextCursor) {
      this.$router.push({ query: { after: nextCursor } });
    },
    onPaginationClick(event) {
      // this check here is to ensure the proper default behvaior when a user ctrl/cmd + clicks the link
      if (event.shiftKey || event.ctrlKey || event.altKey || event.metaKey) {
        return;
      }
      event.preventDefault();
    },
  },
};
</script>
<template>
  <div v-if="isPaginationVisible" class="gl-flex gl-items-center gl-justify-center">
    <gl-keyset-pagination
      v-bind="pageInfo"
      :prev-button-link="previousLink"
      :next-button-link="nextLink"
      :disabled="disabled"
      @prev="onPrev"
      @next="onNext"
      @click="onPaginationClick"
    />
  </div>
</template>
