<script>
import { GlTooltipDirective } from '@gitlab/ui';

import ItemMilestone from '~/issuable/components/issue_milestone.vue';

import { WIDGET_TYPE_MILESTONE } from '../../constants';

export default {
  components: {
    ItemMilestone,
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
  },
};
</script>

<template>
  <div class="gl-display-flex gl-justify-content-space-between">
    <div class="gl-display-flex gl-flex-wrap gl-gap-2 gl-align-items-center">
      <span class="gl-text-secondary gl-font-sm">{{ reference }}</span>
      <item-milestone
        v-if="milestone"
        :milestone="milestone"
        class="gl-display-flex gl-align-items-center gl-max-w-15 gl-font-sm gl-line-height-normal gl-text-gray-900! gl-cursor-help! gl-text-decoration-none!"
      />
      <slot name="left-metadata"></slot>
    </div>
    <div>
      <slot name="right-metadata"></slot>
    </div>
  </div>
</template>
