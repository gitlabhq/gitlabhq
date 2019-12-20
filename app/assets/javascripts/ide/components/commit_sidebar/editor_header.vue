<script>
import { mapActions } from 'vuex';
import { sprintf, __ } from '~/locale';
import { GlModal } from '@gitlab/ui';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import ChangedFileIcon from '~/vue_shared/components/changed_file_icon.vue';

export default {
  components: {
    GlModal,
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
    discardModalId() {
      return `discard-file-${this.activeFile.path}`;
    },
    discardModalTitle() {
      return sprintf(__('Discard changes to %{path}?'), { path: this.activeFile.path });
    },
    actionButtonText() {
      return this.activeFile.staged ? __('Unstage') : __('Stage');
    },
    isStaged() {
      return !this.activeFile.changed && this.activeFile.staged;
    },
  },
  methods: {
    ...mapActions(['stageChange', 'unstageChange', 'discardFileChanges']),
    actionButtonClicked() {
      if (this.activeFile.staged) {
        this.unstageChange(this.activeFile.path);
      } else {
        this.stageChange(this.activeFile.path);
      }
    },
    showDiscardModal() {
      this.$refs.discardModal.show();
    },
  },
};
</script>

<template>
  <div class="d-flex ide-commit-editor-header align-items-center">
    <file-icon :file-name="activeFile.name" :size="16" class="mr-2" />
    <strong class="mr-2">
      <template v-if="activeFile.prevPath && activeFile.prevPath !== activeFile.path">
        {{ activeFile.prevPath }} &#x2192;
      </template>
      {{ activeFile.path }}
    </strong>
    <changed-file-icon :file="activeFile" :is-centered="false" />
    <div class="ml-auto">
      <button
        v-if="!isStaged"
        ref="discardButton"
        type="button"
        class="btn btn-remove btn-inverted append-right-8"
        @click="showDiscardModal"
      >
        {{ __('Discard') }}
      </button>
      <button
        ref="actionButton"
        :class="{
          'btn-success': !isStaged,
          'btn-warning': isStaged,
        }"
        type="button"
        class="btn btn-inverted"
        @click="actionButtonClicked"
      >
        {{ actionButtonText }}
      </button>
    </div>
    <gl-modal
      ref="discardModal"
      ok-variant="danger"
      cancel-variant="light"
      :ok-title="__('Discard changes')"
      :modal-id="discardModalId"
      :title="discardModalTitle"
      @ok="discardFileChanges(activeFile.path)"
    >
      {{ __("You will lose all changes you've made to this file. This action cannot be undone.") }}
    </gl-modal>
  </div>
</template>
