<script>
import { GlLabel } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
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
    selectedLabels: {
      type: Array,
      required: true,
    },
    allowLabelRemove: {
      type: Boolean,
      required: true,
    },
    allowScopedLabels: {
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
      this.$emit('onLabelRemove', getIdFromGraphQLId(labelId));
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
        v-for="label in selectedLabels"
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
