<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import NoteableNote from '~/notes/components/noteable_note.vue';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import PublishButton from './publish_button.vue';

export default {
  components: {
    NoteableNote,
    PublishButton,
    Icon,
    LoadingButton,
  },
  props: {
    draft: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isEditingDraft: false,
    };
  },
  computed: {
    ...mapState('batchComments', ['isPublishing']),
    ...mapGetters(['isDiscussionResolved']),
    ...mapGetters('batchComments', ['isPublishingDraft']),
    resolvedStatusMessage() {
      let message;
      const discussionResolved = this.isDiscussionResolved(this.draft.discussion_id);
      const discussionToBeResolved = this.draft.resolve_discussion;

      if (discussionToBeResolved) {
        if (discussionResolved) {
          message = s__('MergeRequests|Discussion stays resolved.');
        } else {
          message = s__('MergeRequests|Discussion will be resolved.');
        }
      } else if (discussionResolved) {
        message = s__('MergeRequests|Discussion will be unresolved.');
      } else {
        message = s__('MergeRequests|Discussion stays unresolved.');
      }

      return message;
    },
    componentClasses() {
      return this.draft.resolve_discussion
        ? 'is-resolving-discussion'
        : 'is-unresolving-discussion';
    },
    draftCommands() {
      return this.draft.references.commands;
    },
  },
  methods: {
    ...mapActions('batchComments', ['deleteDraft', 'updateDraft', 'publishSingleDraft']),
    update(data) {
      this.updateDraft(data);
    },
    publishNow() {
      this.publishSingleDraft(this.draft.id);
    },
    handleEditing() {
      this.isEditingDraft = true;
    },
    handleNotEditing() {
      this.isEditingDraft = false;
    },
  },
};
</script>
<template>
  <article
    :class="componentClasses"
    class="draft-note-component"
  >
    <header class="draft-note-header">
      <strong class="badge draft-pending-label">
        {{ __('Pending') }}
      </strong>
      <p
        v-if="draft.discussion_id"
        class="draft-note-resolution"
      >
        <Icon
          :size="16"
          name="status_success"
        />
        {{ __(resolvedStatusMessage) }}
      </p>
    </header>
    <ul class="notes draft-notes">
      <noteable-note
        :note="draft"
        class="draft-note"
        @handleEdit="handleEditing"
        @cancelForm="handleNotEditing"
        @updateSuccess="handleNotEditing"
        @handleDeleteNote="deleteDraft"
        @handleUpdateNote="update"
      />
    </ul>

    <template
      v-if="!isEditingDraft"
    >
      <div
        v-if="draftCommands"
        class="referenced-commands draft-note-commands"
        v-html="draftCommands"
      >
      </div>

      <p class="draft-note-actions">
        <publish-button
          class="btn btn-success btn-inverted"
        />
        <loading-button
          :loading="isPublishingDraft(draft.id) || isPublishing"
          :label="__('Add comment now')"
          container-class="btn btn-inverted"
          @click="publishNow"
        />
      </p>
    </template>
  </article>
</template>
