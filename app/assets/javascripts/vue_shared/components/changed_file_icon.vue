<script>
import { GlButton, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import getCommitIconMap from '~/ide/commit_icon';
import { __ } from '~/locale';

export default {
  components: {
    GlButton,
    GlIcon,
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
      default: true,
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
    asButton: {
      type: Boolean,
      default: true,
      required: false,
    },
  },
  computed: {
    changedIcon() {
      // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
      // eslint-disable-next-line @gitlab/require-i18n-strings
      const suffix = this.file.staged && this.showStagedIcon ? '-solid' : '';

      return `${getCommitIconMap(this.file).icon}${suffix}`;
    },
    changedIconClass() {
      return `${this.changedIcon} !gl-float-left gl-block`;
    },
    tooltipTitle() {
      if (!this.showTooltip) {
        return undefined;
      }
      if (this.file.deleted) {
        return __('Deleted');
      }
      if (this.file.tempFile) {
        return __('Added');
      }
      if (this.file.changed) {
        return __('Modified');
      }

      return undefined;
    },
    showIcon() {
      return (
        this.file.changed ||
        this.file.tempFile ||
        this.file.staged ||
        this.file.deleted ||
        this.file.prevPath
      );
    },
  },
};
</script>

<template>
  <gl-button
    v-if="showIcon && asButton"
    v-gl-tooltip.right
    category="tertiary"
    size="small"
    :title="tooltipTitle"
    :class="{ '!gl-ml-auto': isCentered }"
    :aria-label="tooltipTitle"
    class="file-changed-icon !gl-min-h-0 !gl-min-w-0 !gl-bg-transparent !gl-p-0"
  >
    <gl-icon :name="changedIcon" :size="size" :class="changedIconClass" />
  </gl-button>
  <span
    v-else-if="showIcon"
    v-gl-tooltip.right="tooltipTitle"
    :class="{ '!gl-ml-auto': isCentered }"
    :aria-label="tooltipTitle"
    class="file-changed-icon"
  >
    <gl-icon :name="changedIcon" :size="size" :class="changedIconClass" />
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
