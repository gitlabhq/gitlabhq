<script>
import { GlTooltipDirective } from '@gitlab/ui';

import ItemMilestone from '~/issuable/components/issue_milestone.vue';
import WorkItemRolledUpCount from '~/work_items/components/work_item_links/work_item_rolled_up_count.vue';

import { WIDGET_TYPE_MILESTONE, WIDGET_TYPE_HIERARCHY } from '../../constants';

export default {
  components: {
    ItemMilestone,
    WorkItemRolledUpCount,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    iid: {
      type: String,
      required: true,
    },
    reference: {
      type: String,
      required: true,
    },
    metadataWidgets: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    milestone() {
      return this.metadataWidgets[WIDGET_TYPE_MILESTONE]?.milestone;
    },
    hierarchyWidget() {
      return this.metadataWidgets[WIDGET_TYPE_HIERARCHY];
    },
    showRolledUpCounts() {
      return this.hierarchyWidget && this.rolledUpCountsByType.length > 0;
    },
    rolledUpCountsByType() {
      return this.hierarchyWidget?.rolledUpCountsByType || [];
    },
  },
};
</script>

<template>
  <div class="gl-justify-between sm:gl-flex">
    <div
      class="gl-mb-2 gl-flex gl-flex-wrap gl-items-center gl-gap-x-3 gl-gap-y-2 gl-text-sm gl-text-subtle sm:gl-mb-0"
    >
      <span>{{ reference }}</span>
      <work-item-rolled-up-count
        v-if="showRolledUpCounts"
        hide-count-when-zero
        :rolled-up-counts-by-type="rolledUpCountsByType"
        info-type="detailed"
      />
      <item-milestone
        v-if="milestone"
        :milestone="milestone"
        class="gl-flex gl-max-w-15 !gl-cursor-help gl-items-center gl-gap-2 gl-leading-normal !gl-no-underline"
      />
      <slot name="left-metadata"></slot>
    </div>
    <div>
      <slot name="right-metadata"></slot>
    </div>
  </div>
</template>
