<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import getCommitIconMap from '../../commit_icon';
import { viewerTypes } from '../../constants';

export default {
  components: {
    GlIcon,
    FileIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
    keyPrefix: {
      type: String,
      required: false,
      default: '',
    },
    stagedList: {
      type: Boolean,
      required: false,
      default: false,
    },
    activeFileKey: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    iconName() {
      // name: '-solid' is a false positive: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26#possible-false-positives
      // eslint-disable-next-line @gitlab/require-i18n-strings
      const suffix = this.stagedList ? '-solid' : '';

      return `${getCommitIconMap(this.file).icon}${suffix}`;
    },
    iconClass() {
      return `${getCommitIconMap(this.file).class} ml-auto mr-auto`;
    },
    fullKey() {
      return `${this.keyPrefix}-${this.file.key}`;
    },
    isActive() {
      return this.activeFileKey === this.fullKey;
    },
    tooltipTitle() {
      return this.file.path === this.file.name ? '' : this.file.path;
    },
  },
  methods: {
    ...mapActions(['discardFileChanges', 'updateViewer', 'openPendingTab']),
    openFileInEditor() {
      if (this.file.type === 'tree') return null;

      return this.openPendingTab({
        file: this.file,
        keyPrefix: this.keyPrefix,
      }).then((changeViewer) => {
        if (changeViewer) {
          this.updateViewer(viewerTypes.diff);
        }
      });
    },
  },
};
</script>

<template>
  <div class="multi-file-commit-list-item position-relative">
    <div
      v-gl-tooltip
      :title="tooltipTitle"
      :class="{
        'is-active': isActive,
      }"
      class="multi-file-commit-list-path border-0 ml-0 mr-0 gl-w-full"
      role="button"
      @click="openFileInEditor"
    >
      <span class="multi-file-commit-list-file-path !gl-flex gl-items-center">
        <file-icon :file-name="file.name" class="gl-mr-3" />
        <template v-if="file.prevName && file.prevName !== file.name">
          {{ file.prevName }} &#x2192;
        </template>
        {{ file.name }}
      </span>
      <div class="ml-auto gl-flex gl-items-center">
        <div class="ide-commit-list-changed-icon gl-flex gl-items-center">
          <gl-icon :name="iconName" :size="16" :class="iconClass" />
        </div>
      </div>
    </div>
  </div>
</template>
