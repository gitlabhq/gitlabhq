<script>
import { mapActions } from 'vuex';
import tooltip from '~/vue_shared/directives/tooltip';
import Icon from '~/vue_shared/components/icon.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import StageButton from './stage_button.vue';
import UnstageButton from './unstage_button.vue';
import { viewerTypes } from '../../constants';
import { getCommitIconMap } from '../../utils';

export default {
  components: {
    Icon,
    StageButton,
    UnstageButton,
    FileIcon,
  },
  directives: {
    tooltip,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
    actionComponent: {
      type: String,
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
    ...mapActions([
      'discardFileChanges',
      'updateViewer',
      'openPendingTab',
      'unstageChange',
      'stageChange',
    ]),
    openFileInEditor() {
      if (this.file.type === 'tree') return null;

      return this.openPendingTab({
        file: this.file,
        keyPrefix: this.keyPrefix,
      }).then(changeViewer => {
        if (changeViewer) {
          this.updateViewer(viewerTypes.diff);
        }
      });
    },
    fileAction() {
      if (this.file.staged) {
        this.unstageChange(this.file.path);
      } else {
        this.stageChange(this.file.path);
      }
    },
  },
};
</script>

<template>
  <div class="multi-file-commit-list-item position-relative">
    <div
      v-tooltip
      :title="tooltipTitle"
      :class="{
        'is-active': isActive,
      }"
      class="multi-file-commit-list-path w-100 border-0 ml-0 mr-0"
      role="button"
      @dblclick="fileAction"
      @click="openFileInEditor"
    >
      <span class="multi-file-commit-list-file-path d-flex align-items-center">
        <file-icon :file-name="file.name" class="append-right-8" />
        {{ file.name }}
      </span>
      <div class="ml-auto d-flex align-items-center">
        <div class="d-flex align-items-center ide-commit-list-changed-icon">
          <icon :name="iconName" :size="16" :css-classes="iconClass" />
        </div>
      </div>
    </div>
  </div>
</template>
