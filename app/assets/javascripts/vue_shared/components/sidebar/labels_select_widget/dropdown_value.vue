<script>
import { GlLabel } from '@gitlab/ui';
import { mapState } from 'vuex';

import { isScopedLabel } from '~/lib/utils/common_utils';

export default {
  components: {
    GlLabel,
  },
  props: {
    disableLabels: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState([
      'selectedLabels',
      'allowLabelRemove',
      'allowScopedLabels',
      'labelsFilterBasePath',
      'labelsFilterParam',
    ]),
  },
  methods: {
    labelFilterUrl(label) {
      return `${this.labelsFilterBasePath}?${this.labelsFilterParam}[]=${encodeURIComponent(
        label.title,
      )}`;
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
        data-qa-selector="selected_label_content"
        :data-qa-label-name="label.title"
        :title="label.title"
        :description="label.description"
        :background-color="label.color"
        :target="labelFilterUrl(label)"
        :scoped="scopedLabel(label)"
        :show-close-button="allowLabelRemove"
        :disabled="disableLabels"
        tooltip-placement="top"
        @close="$emit('onLabelRemove', label.id)"
      />
    </template>
  </div>
</template>
