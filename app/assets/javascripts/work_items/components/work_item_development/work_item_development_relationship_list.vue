<script>
import { GlButton } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

import WorkItemDevelopmentMrItem from './work_item_development_mr_item.vue';

const DEFAULT_RENDER_COUNT = 3;

export default {
  components: {
    WorkItemDevelopmentMrItem,
    GlButton,
  },
  props: {
    workItemDevWidget: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      showLess: true,
    };
  },
  computed: {
    list() {
      // keeping as a separate prop , will be appending with FF and branches
      return [...this.mergeRequests];
    },
    mergeRequests() {
      return this.workItemDevWidget.closingMergeRequests?.nodes || [];
    },
    hiddenItemsLabel() {
      const { moreCount } = this;
      return sprintf(__('+ %{moreCount} more'), { moreCount });
    },
    renderShowMoreSection() {
      return this.list.length > DEFAULT_RENDER_COUNT;
    },
    moreCount() {
      return this.list.length - DEFAULT_RENDER_COUNT;
    },
    uncollapsedItems() {
      return this.showLess && this.list.length > DEFAULT_RENDER_COUNT
        ? this.list.slice(0, DEFAULT_RENDER_COUNT)
        : this.list;
    },
  },
  mounted() {
    // render the popovers of the merge requests
    renderGFM(this.$refs['list-body']);
  },
  methods: {
    itemComponent(item) {
      return this.isMergeRequest(item) ? WorkItemDevelopmentMrItem : 'li';
    },
    isMergeRequest(item) {
      return item.fromMrDescription !== undefined;
    },
    async toggleShowLess() {
      this.showLess = !this.showLess;
      await this.$nextTick();
      renderGFM(this.$refs['list-body']);
    },
    itemId(item) {
      return item.id || item.mergeRequest.id;
    },
    itemObject(item) {
      return this.isMergeRequest(item) ? item.mergeRequest : item;
    },
  },
};
</script>
<template>
  <div>
    <ul ref="list-body" class="gl-list-none gl-m-0 gl-p-0" data-testid="work-item-dev-items-list">
      <li v-for="item in uncollapsedItems" :key="itemId(item)" class="gl-mr-3">
        <component :is="itemComponent(item)" :merge-request="itemObject(item)" />
      </li>
    </ul>
    <gl-button
      v-if="renderShowMoreSection"
      category="tertiary"
      size="small"
      @click="toggleShowLess"
    >
      <template v-if="showLess">
        {{ hiddenItemsLabel }}
      </template>
      <template v-else>{{ __('- show less') }}</template>
    </gl-button>
  </div>
</template>
