<script>
import { GlButton, GlIcon, GlTooltipDirective as GlTooltip } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
    GlButton,
  },
  directives: {
    GlTooltip,
  },
  props: {
    isFinished: {
      type: Boolean,
      required: true,
    },
    isAvailableForImport: {
      type: Boolean,
      required: true,
    },
    isInvalid: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <span class="gl-white-space-nowrap gl-inline-flex gl-align-items-center">
    <gl-button
      v-if="isAvailableForImport"
      :disabled="isInvalid"
      variant="confirm"
      category="secondary"
      data-qa-selector="import_group_button"
      @click="$emit('import-group')"
    >
      {{ isFinished ? __('Re-import') : __('Import') }}
    </gl-button>
    <gl-icon
      v-if="isAvailableForImport && isFinished"
      v-gl-tooltip
      :size="16"
      name="information-o"
      :title="
        s__('BulkImport|Re-import creates a new group. It does not sync with the existing group.')
      "
      class="gl-ml-3"
    />
  </span>
</template>
