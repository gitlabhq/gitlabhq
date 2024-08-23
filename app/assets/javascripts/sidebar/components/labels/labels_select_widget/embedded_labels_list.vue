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
    disabled: {
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
      return sortBy(this.selectedLabels, (label) => isScopedLabel(label));
    },
  },
  methods: {
    buildFilterUrl({ title }) {
      const { labelsFilterBasePath: basePath, labelsFilterParam: filterParam } = this;

      return `${basePath}?${filterParam}[]=${encodeURIComponent(title)}`;
    },
    scopedLabel(label) {
      return this.allowScopedLabels && isScopedLabel(label);
    },
    isLabelLocked(label) {
      // These particular labels were initialized from HAML data, so the attributes are
      // in snake case instead of camel case
      return label.lock_on_merge && this.supportsLockOnMerge;
    },
    showCloseButton(label) {
      return this.allowLabelRemove && !this.isLabelLocked(label);
    },
    removeLabel(labelId) {
      this.$emit('onLabelRemove', labelId);
    },
  },
};
</script>

<template>
  <div class="gl-mt-3" data-testid="embedded-labels-list">
    <gl-label
      v-for="label in sortedSelectedLabels"
      :key="label.id"
      class="gl-mb-2 gl-mr-2"
      :data-qa-label-name="label.title"
      :title="label.title"
      :description="label.description"
      :background-color="label.color"
      :target="buildFilterUrl(label)"
      :scoped="scopedLabel(label)"
      :show-close-button="showCloseButton(label)"
      :disabled="disabled"
      tooltip-placement="top"
      @close="removeLabel(label.id)"
    />
  </div>
</template>
