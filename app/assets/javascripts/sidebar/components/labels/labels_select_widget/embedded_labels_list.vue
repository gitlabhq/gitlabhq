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
    showScopedLabel(label) {
      return this.allowScopedLabels && isScopedLabel(label);
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
      class="gl-mr-2 gl-mb-2"
      :data-qa-label-name="label.title"
      :title="label.title"
      :description="label.description"
      :background-color="label.color"
      :target="buildFilterUrl(label)"
      :scoped="showScopedLabel(label)"
      :show-close-button="allowLabelRemove"
      :disabled="disabled"
      tooltip-placement="top"
      @close="removeLabel(label.id)"
    />
  </div>
</template>
