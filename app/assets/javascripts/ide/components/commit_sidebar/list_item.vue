<script>
import { mapActions } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import StageButton from './stage_button.vue';
import UnstageButton from './unstage_button.vue';
import router from '../../ide_router';

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
  },
  computed: {
    iconName() {
      return this.file.tempFile ? 'file-addition' : 'file-modified';
    },
    iconClass() {
      return `multi-file-${
        this.file.tempFile ? 'addition' : 'modified'
      } append-right-8`;
    },
  },
  methods: {
    ...mapActions(['updateViewer', 'stageChange', 'unstageChange']),
    openFileInEditor() {
      this.updateViewer('diff');

      router.push(`/project${this.file.url}`);
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
