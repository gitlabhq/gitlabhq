<script>
import { mapActions } from 'vuex';
import tooltip from '~/vue_shared/directives/tooltip';
import Icon from '~/vue_shared/components/icon.vue';
import StageButton from './stage_button.vue';
import UnstageButton from './unstage_button.vue';
import { viewerTypes } from '../../constants';

export default {
  components: {
    Icon,
    StageButton,
    UnstageButton,
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
      const prefix = this.stagedList ? '-solid' : '';
      return this.file.tempFile ? `file-addition${prefix}` : `file-modified${prefix}`;
    },
    iconClass() {
      return `multi-file-${this.file.tempFile ? 'addition' : 'modified'} append-right-8`;
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
        'is-active': isActive
      }"
      class="multi-file-commit-list-path w-100 border-0 ml-0 mr-0"
      role="button"
      @dblclick="fileAction"
      @click="openFileInEditor"
    >
      <span class="multi-file-commit-list-file-path d-flex align-items-center">
        <icon
          :name="iconName"
          :size="16"
          :css-classes="iconClass"
        />{{ file.name }}
      </span>
    </div>
    <component
      :is="actionComponent"
      :path="file.path"
      class="d-flex position-absolute"
    />
  </div>
</template>
