<script>
import { GlTooltipDirective, GlIcon } from '@gitlab/ui';
import getCommitIconMap from '~/ide/commit_icon';
import { __ } from '~/locale';

export default {
  components: {
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
  },
  computed: {
    changedIcon() {
      // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
      // eslint-disable-next-line @gitlab/require-i18n-strings
      const suffix = this.file.staged && this.showStagedIcon ? '-solid' : '';

      return `${getCommitIconMap(this.file).icon}${suffix}`;
    },
    changedIconClass() {
      return `${this.changedIcon} float-left d-block`;
    },
    tooltipTitle() {
      if (!this.showTooltip) {
        return undefined;
      } else if (this.file.deleted) {
        return __('Deleted');
      } else if (this.file.tempFile) {
        return __('Added');
      } else if (this.file.changed) {
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
  <span
    v-gl-tooltip.right
    :title="tooltipTitle"
    :class="{ 'ml-auto': isCentered }"
    class="file-changed-icon d-inline-block"
    data-qa-selector="changed_file_icon_content"
    :data-qa-title="tooltipTitle"
  >
    <gl-icon
      v-if="showIcon"
      :name="changedIcon"
      :size="size"
      :class="changedIconClass"
      use-deprecated-sizes
    />
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
