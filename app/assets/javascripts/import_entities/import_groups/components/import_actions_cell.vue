<script>
import {
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlIcon,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';

export default {
  components: {
    GlIcon,
    GlButton,
    GlDropdown,
    GlDropdownItem,
  },
  directives: {
    GlTooltip,
  },
  props: {
    isProjectsImportEnabled: {
      type: Boolean,
      required: true,
    },
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
      v-if="isProjectsImportEnabled && isAvailableForImport"
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
    <gl-button
      v-else-if="isAvailableForImport"
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
