<script>
import { GlTooltipDirective } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import { __, sprintf } from '~/locale';
import { getCommitIconMap } from '~/ide/utils';

export default {
  components: {
    Icon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
    size: {
      type: Number,
      required: false,
      default: 12,
    },
    isCentered: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    changedIcon() {
      // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
      // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
      const suffix = !this.file.changed && this.file.staged && !this.showStagedIcon ? '-solid' : '';

      return `${getCommitIconMap(this.file).icon}${suffix}`;
    },
    changedIconClass() {
      return `${this.changedIcon} float-left d-block`;
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
          type,
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
    v-gl-tooltip.right
    :title="tooltipTitle"
    :class="{ 'ml-auto': isCentered }"
    class="file-changed-icon d-inline-block"
  >
    <icon v-if="showIcon" :name="changedIcon" :size="size" :css-classes="changedIconClass" />
  </span>
</template>

<style>
.file-addition,
.file-addition-solid {
  color: #1aaa55;
}

.file-modified,
.file-modified-solid {
  color: #fc9403;
}

.file-deletion,
.file-deletion-solid {
  color: #db3b21;
}
</style>
