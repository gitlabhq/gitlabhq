<script>
import { GlButton } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { TYPENAME_FEATURE_FLAG } from '~/graphql_shared/constants';

import WorkItemDevelopmentMrItem from './work_item_development_mr_item.vue';
import WorkItemDevelopmentBranchItem from './work_item_development_branch_item.vue';

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
    isModal: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    list() {
      return [...this.sortedFeatureFlags, ...this.mergeRequests, ...this.relatedBranches];
    },
    relatedBranches() {
      return this.workItemDevWidget.relatedBranches?.nodes || [];
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
      } else if (this.isBranch(item)) {
        component = WorkItemDevelopmentBranchItem;
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
    isBranch(item) {
      // eslint-disable-next-line no-underscore-dangle
      return item.__typename === 'WorkItemRelatedBranch';
    },
    async toggleShowLess() {
      this.showLess = !this.showLess;
      await this.$nextTick();
      renderGFM(this.$refs['list-body']);
    },
    itemId(item) {
      return item?.id || item?.mergeRequest?.id || uniqueId('branch-id-');
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
      <li
        v-for="item in list"
        :key="itemId(item)"
        class="gl-border-b gl-py-4 first:!gl-pt-0 last:gl-border-none last:!gl-pb-0"
      >
        <component :is="itemComponent(item)" :item-content="itemObject(item)" :is-modal="isModal" />
      </li>
    </ul>
  </div>
</template>
