<script>
import $ from 'jquery';
import { mapActions } from 'vuex';
import { __ } from '~/locale';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import ChangedFileIcon from '../changed_file_icon.vue';

export default {
  components: {
    FileIcon,
    ChangedFileIcon,
  },
  props: {
    activeFile: {
      type: Object,
      required: true,
    },
  },
  computed: {
    activeButtonText() {
      return this.activeFile.staged ? __('Unstage') : __('Stage');
    },
    isStaged() {
      return !this.activeFile.changed && this.activeFile.staged;
    },
  },
  methods: {
    ...mapActions(['stageChange', 'unstageChange']),
    actionButtonClicked() {
      if (this.activeFile.staged) {
        this.unstageChange(this.activeFile.path);
      } else {
        this.stageChange(this.activeFile.path);
      }
    },
    showDiscardModal() {
      $(document.getElementById(`discard-file-${this.activeFile.path}`)).modal('show');
    },
  },
};
</script>

<template>
  <div class="d-flex ide-commit-editor-header align-items-center">
    <file-icon
      :file-name="activeFile.name"
      :size="16"
      class="mr-2"
    />
    <strong class="mr-2">
      {{ activeFile.path }}
    </strong>
    <changed-file-icon
      :file="activeFile"
    />
    <div class="ml-auto">
      <button
        v-if="!isStaged"
        type="button"
        class="btn btn-remove btn-inverted append-right-8"
        @click="showDiscardModal"
      >
        {{ __('Discard') }}
      </button>
      <button
        :class="{
          'btn-success': !isStaged,
          'btn-warning': isStaged
        }"
        type="button"
        class="btn btn-inverted"
        @click="actionButtonClicked"
      >
        {{ activeButtonText }}
      </button>
    </div>
  </div>
</template>
