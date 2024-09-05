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
  <div class="gl-flex gl-justify-between">
    <div class="gl-flex gl-flex-wrap gl-items-center gl-gap-3 gl-text-sm gl-text-secondary">
      <span>{{ reference }}</span>
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
