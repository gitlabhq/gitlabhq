<script>
import { GlLabel } from '@gitlab/ui';
import { isScopedLabel } from '~/lib/utils/common_utils';

export default {
  components: {
    GlLabel,
  },
  props: {
    labels: {
      type: Array,
      required: true,
    },
    labelFilterBasePath: {
      type: String,
      required: true,
    },
    enableScopedLabels: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    isEmpty() {
      return this.labels.length === 0;
    },
  },
  methods: {
    labelFilterUrl(label) {
      return `${this.labelFilterBasePath}?label_name[]=${encodeURIComponent(label.title)}`;
    },
    scopedLabelsDescription({ description = '' }) {
      return `<span class="font-weight-bold scoped-label-tooltip-title">Scoped label</span><br />${description}`;
    },
    showScopedLabels(label) {
      return this.enableScopedLabels && isScopedLabel(label);
    },
  },
};
</script>

<template>
  <div
    :class="{
      'has-labels': !isEmpty,
    }"
    class="hide-collapsed value issuable-show-labels js-value"
  >
    <span v-if="isEmpty" class="text-secondary">
      <slot>{{ __('None') }}</slot>
    </span>

    <template v-for="label in labels" v-else>
      <gl-label
        :key="label.id"
        :target="labelFilterUrl(label)"
        :background-color="label.color"
        :title="label.title"
        :description="label.description"
        :scoped="showScopedLabels(label)"
      />
    </template>
  </div>
</template>
