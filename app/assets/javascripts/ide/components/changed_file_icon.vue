<script>
import tooltip from '~/vue_shared/directives/tooltip';
import Icon from '~/vue_shared/components/icon.vue';
import { pluralize } from '~/lib/utils/text_utility';
import { __, sprintf } from '~/locale';
import { getCommitIconMap } from '../utils';

export default {
  components: {
    Icon,
  },
  directives: {
    tooltip,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
    showTooltip: {
      type: Boolean,
      required: false,
      default: false,
    },
    showStagedIcon: {
      type: Boolean,
      required: false,
      default: false,
    },
    forceModifiedIcon: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    changedIcon() {
      const suffix = !this.file.changed && this.file.staged && !this.showStagedIcon ? '-solid' : '';

      if (this.forceModifiedIcon) return `file-modified${suffix}`;

      return `${getCommitIconMap(this.file).icon}${suffix}`;
    },
    changedIconClass() {
      return `ide-${this.changedIcon} float-left`;
    },
    tooltipTitle() {
      if (!this.showTooltip) return undefined;

      const type = this.file.tempFile ? 'addition' : 'modification';

      if (this.file.changed && !this.file.staged) {
        return sprintf(__('Unstaged %{type}'), {
          type,
        });
      } else if (!this.file.changed && this.file.staged) {
        return sprintf(__('Staged %{type}'), {
          type,
        });
      } else if (this.file.changed && this.file.staged) {
        return sprintf(__('Unstaged and staged %{type}'), {
          type: pluralize(type),
        });
      }

      return undefined;
    },
    showIcon() {
      return this.file.changed || this.file.tempFile || this.file.staged || this.file.deleted;
    },
  },
};
</script>

<template>
  <span
    v-tooltip
    :title="tooltipTitle"
    data-container="body"
    data-placement="right"
    class="ide-file-changed-icon"
  >
    <icon
      v-if="showIcon"
      :name="changedIcon"
      :size="12"
      :css-classes="changedIconClass"
    />
  </span>
</template>
