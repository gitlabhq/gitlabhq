<script>
import { GlButton, GlIcon, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { joinPaths } from '~/lib/utils/url_utility';
import { isFinished, isInvalid, isAvailableForImport } from '../utils';

export default {
  components: {
    GlIcon,
    GlButton,
  },
  directives: {
    GlTooltip,
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
    groupPathRegex: {
      type: RegExp,
      required: true,
    },
  },
  computed: {
    fullLastImportPath() {
      return this.group.last_import_target
        ? `${this.group.last_import_target.target_namespace}/${this.group.last_import_target.new_name}`
        : null;
    },
    absoluteLastImportPath() {
      return joinPaths(gon.relative_url_root || '/', this.fullLastImportPath);
    },
    isAvailableForImport() {
      return isAvailableForImport(this.group);
    },
    isFinished() {
      return isFinished(this.group);
    },
    isInvalid() {
      return isInvalid(this.group, this.groupPathRegex);
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
      v-if="isFinished"
      v-gl-tooltip
      :size="16"
      name="information-o"
      :title="
        s__('BulkImports|Re-import creates a new group. It does not sync with the existing group.')
      "
      class="gl-ml-3"
    />
  </span>
</template>
