<script>
import { GlModal, GlButton } from '@gitlab/ui';
import { mapActions } from 'vuex';
import { sprintf, __ } from '~/locale';
import ChangedFileIcon from '~/vue_shared/components/changed_file_icon.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';

export default {
  components: {
    GlModal,
    GlButton,
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
    canDiscard() {
      return this.activeFile.changed || this.activeFile.staged;
    },
  },
  methods: {
    ...mapActions(['unstageChange', 'discardFileChanges']),
    showDiscardModal() {
      this.$refs.discardModal.show();
    },
    discardChanges(path) {
      this.unstageChange(path);
      this.discardFileChanges(path);
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
      <gl-button
        v-if="canDiscard"
        ref="discardButton"
        category="secondary"
        variant="danger"
        class="gl-mr-3"
        @click="showDiscardModal"
      >
        {{ __('Discard changes') }}
      </gl-button>
    </div>
    <gl-modal
      ref="discardModal"
      ok-variant="danger"
      cancel-variant="light"
      :ok-title="__('Discard changes')"
      :modal-id="discardModalId"
      :title="discardModalTitle"
      @ok="discardChanges(activeFile.path)"
    >
      {{ __("You will lose all changes you've made to this file. This action cannot be undone.") }}
    </gl-modal>
  </div>
</template>
