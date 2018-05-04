<script>
import { mapActions } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import StageButton from './stage_button.vue';
import UnstageButton from './unstage_button.vue';

export default {
  components: {
    Icon,
    StageButton,
    UnstageButton,
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
  },
  computed: {
    iconName() {
      const prefix = this.stagedList ? '-solid' : '';
      return this.file.tempFile ? `file-addition${prefix}` : `file-modified${prefix}`;
    },
    iconClass() {
      return `multi-file-${this.file.tempFile ? 'addition' : 'modified'} append-right-8`;
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
        keyPrefix: this.keyPrefix.toLowerCase(),
      }).then(changeViewer => {
        if (changeViewer) {
          this.updateViewer('diff');
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
  <div class="multi-file-commit-list-item">
    <button
      type="button"
      class="multi-file-commit-list-path"
      @dblclick="fileAction"
      @click="openFileInEditor"
    >
      <span class="multi-file-commit-list-file-path">
        <icon
          :name="iconName"
          :size="16"
          :css-classes="iconClass"
        />{{ file.path }}
      </span>
    </button>
    <component
      :is="actionComponent"
      :path="file.path"
    />
  </div>
</template>
