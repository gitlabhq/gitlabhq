<script>
import { GlButton } from '@gitlab/ui';
import { unionBy, uniqueId, map } from 'lodash';
import {
  TYPENAME_FEATURE_FLAG,
  TYPENAME_MERGE_REQUEST,
  TYPENAME_WORK_ITEM_RELATED_BRANCH,
} from '~/graphql_shared/constants';
import { STATUS_OPEN, STATUS_CLOSED, STATUS_MERGED } from '~/issues/constants';

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
      return [
        ...this.sortedFeatureFlags,
        ...this.mergedMergeRequests,
        ...this.openMergeRequests,
        ...this.closedMergeRequests,
        ...this.relatedBranches,
      ];
    },
    mergeRequests() {
      return unionBy(
        map(this.closingMergeRequests, 'mergeRequest'),
        this.relatedMergeRequests,
        'id',
      );
    },
    mergedMergeRequests() {
      return this.mergeRequests.filter(({ state }) => state === STATUS_MERGED);
    },
    openMergeRequests() {
      return this.mergeRequests.filter(({ state }) => state === STATUS_OPEN);
    },
    closedMergeRequests() {
      return this.mergeRequests.filter(({ state }) => state === STATUS_CLOSED);
    },
    relatedBranches() {
      return this.workItemDevWidget.relatedBranches?.nodes || [];
    },
    relatedMergeRequests() {
      return this.workItemDevWidget.relatedMergeRequests?.nodes || [];
    },
    closingMergeRequests() {
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
      // eslint-disable-next-line no-underscore-dangle
      return item.__typename === TYPENAME_MERGE_REQUEST;
    },
    isFeatureFlag(item) {
      // eslint-disable-next-line no-underscore-dangle
      return item.__typename === TYPENAME_FEATURE_FLAG;
    },
    isBranch(item) {
      // eslint-disable-next-line no-underscore-dangle
      return item.__typename === TYPENAME_WORK_ITEM_RELATED_BRANCH;
    },
    itemId(item) {
      return item?.id || uniqueId('branch-id-');
    },
  },
};
</script>
<template>
  <div>
    <ul
      ref="list-body"
      class="gl-m-0 gl-list-none gl-p-0"
      data-testid="work-item-dev-items-list"
      :data-list-length="list.length"
    >
      <li
        v-for="item in list"
        :key="itemId(item)"
        class="gl-border-b gl-py-4 first:!gl-pt-0 last:gl-border-none last:!gl-pb-0"
      >
        <component :is="itemComponent(item)" :item-content="item" :is-modal="isModal" />
      </li>
    </ul>
  </div>
</template>
