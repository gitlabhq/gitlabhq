<script>
import { GlDropdown, GlDropdownItem, GlIcon, GlTooltipDirective as GlTooltip } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
    GlDropdown,
    GlDropdownItem,
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
  methods: {
    importGroup(extraArgs = {}) {
      this.$emit('import-group', extraArgs);
    },
  },
};
</script>

<template>
  <span class="gl-white-space-nowrap gl-inline-flex gl-align-items-center">
    <gl-dropdown
      v-if="isAvailableForImport || isFinished"
      :text="isFinished ? __('Re-import with projects') : __('Import with projects')"
      :disabled="isInvalid"
      variant="confirm"
      category="secondary"
      data-qa-selector="import_group_button"
      split
      @click="importGroup({ migrateProjects: true })"
    >
      <gl-dropdown-item @click="importGroup({ migrateProjects: false })">{{
        isFinished ? __('Re-import without projects') : __('Import without projects')
      }}</gl-dropdown-item>
    </gl-dropdown>
    <gl-icon
      v-if="isFinished"
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
