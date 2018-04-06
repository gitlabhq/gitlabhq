<script>
import tooltip from '~/vue_shared/directives/tooltip';
import icon from '~/vue_shared/components/icon.vue';
import { pluralize } from '~/lib/utils/text_utility';
import { __, sprintf } from '~/locale';

export default {
  components: {
    icon,
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
  },
  computed: {
    changedIcon() {
      return this.file.tempFile ? 'file-addition' : 'file-modified';
    },
    changedIconClass() {
      return `multi-${this.changedIcon}`;
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
      :name="changedIcon"
      :size="12"
      :css-classes="changedIconClass"
    />
  </span>
</template>
