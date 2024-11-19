<script>
import { GlIcon, GlLabel, GlTooltipDirective } from '@gitlab/ui';
import { sortBy } from 'lodash';
import { isScopedLabel } from '~/lib/utils/common_utils';
import { s__, sprintf } from '~/locale';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
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
    supportsLockOnMerge: {
      type: Boolean,
      required: false,
      default: false,
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
    labelsList() {
      const labelsString = this.selectedLabels.length
        ? this.selectedLabels
            .slice(0, 5)
            .map((label) => label.title)
            .join(', ')
        : s__('LabelSelect|Labels');

      if (this.selectedLabels.length > 5) {
        return sprintf(s__('LabelSelect|%{labelsString}, and %{remainingLabelCount} more'), {
          labelsString,
          remainingLabelCount: this.selectedLabels.length - 5,
        });
      }

      return labelsString;
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
    isLabelLocked(label) {
      return label.lockOnMerge && this.supportsLockOnMerge;
    },
    showCloseButton(label) {
      return this.allowLabelRemove && !this.isLabelLocked(label);
    },
    removeLabel(labelId) {
      this.$emit('onLabelRemove', labelId);
    },
    handleCollapsedClick() {
      this.$emit('onCollapsedValueClick');
    },
  },
};
</script>

<template>
  <div
    :class="{
      'has-labels': selectedLabels.length,
    }"
    class="value issuable-show-labels js-value"
    data-testid="value-wrapper"
  >
    <div
      v-gl-tooltip.left.viewport
      :title="labelsList"
      class="sidebar-collapsed-icon"
      @click="handleCollapsedClick"
    >
      <gl-icon name="labels" />
      <span class="collapse-truncated-title gl-px-3 gl-pt-2 gl-text-sm">{{
        selectedLabels.length
      }}</span>
    </div>
    <span
      v-if="!selectedLabels.length"
      class="hide-collapsed gl-text-subtle"
      data-testid="empty-placeholder"
    >
      <slot></slot>
    </span>
    <template v-else>
      <gl-label
        v-for="label in sortedSelectedLabels"
        :key="label.id"
        class="hide-collapsed"
        data-testid="selected-label-content"
        :data-qa-label-name="label.title"
        :title="label.title"
        :description="label.description"
        :background-color="label.color"
        :target="labelFilterUrl(label)"
        :scoped="scopedLabel(label)"
        :show-close-button="showCloseButton(label)"
        :disabled="disableLabels"
        tooltip-placement="top"
        @close="removeLabel(label.id)"
      />
    </template>
  </div>
</template>
