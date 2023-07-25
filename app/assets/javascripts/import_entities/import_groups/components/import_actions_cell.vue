<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlIcon,
  GlButtonGroup,
  GlButton,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';

export default {
  components: {
    GlIcon,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlButtonGroup,
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
  methods: {
    importGroup(extraArgs = {}) {
      this.$emit('import-group', extraArgs);
    },
  },
};
</script>

<template>
  <span class="gl-white-space-nowrap gl-inline-flex gl-align-items-center">
    <gl-button-group v-if="isAvailableForImport || isFinished">
      <gl-button
        variant="confirm"
        category="secondary"
        data-testid="import-group-button"
        @click="importGroup({ migrateProjects: true })"
        >{{ isFinished ? __('Re-import with projects') : __('Import with projects') }}</gl-button
      >
      <gl-disclosure-dropdown
        toggle-text="Import options"
        text-sr-only
        :disabled="isInvalid"
        icon="chevron-down"
        no-caret
        variant="confirm"
        category="secondary"
      >
        <gl-disclosure-dropdown-item @action="importGroup({ migrateProjects: false })">
          <template #list-item>
            {{ isFinished ? __('Re-import without projects') : __('Import without projects') }}
          </template></gl-disclosure-dropdown-item
        >
      </gl-disclosure-dropdown>
    </gl-button-group>

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
