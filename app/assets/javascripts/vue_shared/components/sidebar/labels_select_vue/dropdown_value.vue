<script>
import { mapState } from 'vuex';
import { GlLabel } from '@gitlab/ui';

import { isScopedLabel } from '~/lib/utils/common_utils';

export default {
  components: {
    GlLabel,
  },
  computed: {
    ...mapState(['selectedLabels', 'allowScopedLabels', 'labelsFilterBasePath']),
  },
  methods: {
    labelFilterUrl(label) {
      return `${this.labelsFilterBasePath}?label_name[]=${encodeURIComponent(label.title)}`;
    },
    scopedLabel(label) {
      return this.allowScopedLabels && isScopedLabel(label);
    },
  },
};
</script>

<template>
  <div
    :class="{
      'has-labels': selectedLabels.length,
    }"
    class="hide-collapsed value issuable-show-labels js-value"
  >
    <span v-if="!selectedLabels.length" class="text-secondary">
      <slot></slot>
    </span>
    <template v-for="label in selectedLabels" v-else>
      <gl-label
        :key="label.id"
        :title="label.title"
        :description="label.description"
        :background-color="label.color"
        :target="labelFilterUrl(label)"
        :scoped="scopedLabel(label)"
        tooltip-placement="top"
      />
    </template>
  </div>
</template>
