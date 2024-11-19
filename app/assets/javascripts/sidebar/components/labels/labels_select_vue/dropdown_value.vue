<script>
import { GlLabel } from '@gitlab/ui';
import { sortBy } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';

import { isScopedLabel } from '~/lib/utils/common_utils';

// @deprecated This component should only be used when there is no GraphQL API.
// In most cases you should use
// `app/assets/javascripts/sidebar/components/labels/labels_select_widget/dropdown_value.vue` instead.
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
    <span v-if="!selectedLabels.length" class="gl-text-subtle">
      <slot></slot>
    </span>
    <template v-for="label in sortedSelectedLabels" v-else>
      <gl-label
        :key="label.id"
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
