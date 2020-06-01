<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import NoteableNote from '~/notes/components/noteable_note.vue';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import PublishButton from './publish_button.vue';

export default {
  components: {
    NoteableNote,
    PublishButton,
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
    ...mapGetters('batchComments', ['isPublishingDraft']),
    draftCommands() {
      return this.draft.references.commands;
    },
  },
  mounted() {
    if (window.location.hash && window.location.hash === `#note_${this.draft.id}`) {
      this.scrollToDraft(this.draft);
    }
  },
  methods: {
    ...mapActions('batchComments', [
      'deleteDraft',
      'updateDraft',
      'publishSingleDraft',
      'scrollToDraft',
      'toggleResolveDiscussion',
    ]),
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
  <article class="draft-note-component note-wrapper">
    <ul class="notes draft-notes">
      <noteable-note
        :note="draft"
        class="draft-note"
        @handleEdit="handleEditing"
        @cancelForm="handleNotEditing"
        @updateSuccess="handleNotEditing"
        @handleDeleteNote="deleteDraft"
        @handleUpdateNote="update"
        @toggleResolveStatus="toggleResolveDiscussion(draft.id)"
      >
        <strong slot="note-header-info" class="badge draft-pending-label append-right-4">
          {{ __('Pending') }}
        </strong>
      </noteable-note>
    </ul>

    <template v-if="!isEditingDraft">
      <div
        v-if="draftCommands"
        class="referenced-commands draft-note-commands"
        v-html="draftCommands"
      ></div>

      <p class="draft-note-actions d-flex">
        <publish-button
          :show-count="true"
          :should-publish="false"
          class="btn btn-success btn-inverted append-right-8"
        />
        <loading-button
          ref="publishNowButton"
          :loading="isPublishingDraft(draft.id) || isPublishing"
          :label="__('Add comment now')"
          container-class="btn btn-inverted"
          @click="publishNow"
        />
      </p>
    </template>
  </article>
</template>
