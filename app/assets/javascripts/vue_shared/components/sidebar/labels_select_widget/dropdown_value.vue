<script>
import { GlLabel } from '@gitlab/ui';
import { sortBy } from 'lodash';
import { isScopedLabel } from '~/lib/utils/common_utils';

export default {
  components: {
    GlLabel,
  },
  inject: ['allowScopedLabels'],
  props: {
    disableLabels: {
      type: Boolean,
      required: false,
      default: false,
    },
    selectedLabels: {
      type: Array,
      required: true,
    },
    allowLabelRemove: {
      type: Boolean,
      required: true,
    },
    labelsFilterBasePath: {
      type: String,
      required: true,
    },
    labelsFilterParam: {
      type: String,
      required: true,
    },
  },
  computed: {
    sortedSelectedLabels() {
      return sortBy(this.selectedLabels, (label) => (isScopedLabel(label) ? 0 : 1));
    },
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
    removeLabel(labelId) {
      this.$emit('onLabelRemove', labelId);
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
    data-testid="value-wrapper"
  >
    <span v-if="!selectedLabels.length" class="text-secondary" data-testid="empty-placeholder">
      <slot></slot>
    </span>
    <template v-else>
      <gl-label
        v-for="label in sortedSelectedLabels"
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
        @close="removeLabel(label.id)"
      />
    </template>
  </div>
</template>
