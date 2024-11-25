<script>
import { GlButton } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { TYPENAME_FEATURE_FLAG } from '~/graphql_shared/constants';

import WorkItemDevelopmentMrItem from './work_item_development_mr_item.vue';

const DEFAULT_RENDER_COUNT = 3;

export default {
  components: {
    WorkItemDevelopmentMrItem,
    WorkItemDevelopmentFfItem: () =>
      import(
        'ee_component/work_items/components/work_item_development/work_item_development_ff_item.vue'
      ),
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
      // keeping as a separate prop, will be appending with branches
      return [...this.sortedFeatureFlags, ...this.mergeRequests];
    },
    mergeRequests() {
      return this.workItemDevWidget.closingMergeRequests?.nodes || [];
    },
    featureFlags() {
      return this.workItemDevWidget.featureFlags?.nodes || [];
    },
    sortedFeatureFlags() {
      const flagsSortedByRelationshipDate = [...this.featureFlags].reverse();
      const enabledFlags = flagsSortedByRelationshipDate.filter((flag) => flag.active);
      const disabledFlags = flagsSortedByRelationshipDate.filter((flag) => !flag.active);

      return [...enabledFlags, ...disabledFlags];
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
      let component;

      if (this.isMergeRequest(item)) {
        component = WorkItemDevelopmentMrItem;
      } else if (this.isFeatureFlag(item)) {
        component = 'work-item-development-ff-item';
      } else {
        component = 'li';
      }
      return component;
    },
    isMergeRequest(item) {
      return item.fromMrDescription !== undefined;
    },
    isFeatureFlag(item) {
      // eslint-disable-next-line no-underscore-dangle
      return item.__typename === TYPENAME_FEATURE_FLAG;
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
    <ul ref="list-body" class="gl-m-0 gl-list-none gl-p-0" data-testid="work-item-dev-items-list">
      <li v-for="item in uncollapsedItems" :key="itemId(item)" class="gl-mr-3">
        <component :is="itemComponent(item)" :item-content="itemObject(item)" />
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
