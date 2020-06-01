<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import { GlModal, GlModalDirective } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import PreviewDropdown from './preview_dropdown.vue';

export default {
  components: {
    LoadingButton,
    GlModal,
    PreviewDropdown,
  },
  directives: {
    'gl-modal': GlModalDirective,
  },
  computed: {
    ...mapGetters(['isNotesFetched']),
    ...mapState('batchComments', ['isDiscarding']),
    ...mapGetters('batchComments', ['draftsCount']),
  },
  watch: {
    isNotesFetched() {
      if (this.isNotesFetched) {
        this.expandAllDiscussions();
      }
    },
  },
  methods: {
    ...mapActions('batchComments', ['discardReview', 'expandAllDiscussions']),
  },
  modalId: 'discard-draft-review',
  text: sprintf(
    s__(
      `BatchComments|You're about to discard your review which will delete all of your pending comments.
      The deleted comments %{strong_start}cannot%{strong_end} be restored.`,
    ),
    {
      strong_start: '<strong>',
      strong_end: '</strong>',
    },
    false,
  ),
};
</script>
<template>
  <div v-show="draftsCount > 0">
    <nav class="review-bar-component">
      <div class="review-bar-content qa-review-bar">
        <preview-dropdown />
        <loading-button
          v-gl-modal="$options.modalId"
          :loading="isDiscarding"
          :label="__('Discard review')"
          class="qa-discard-review float-right"
        />
      </div>
    </nav>
    <gl-modal
      :title="s__('BatchComments|Discard review?')"
      :ok-title="s__('BatchComments|Delete all pending comments')"
      :modal-id="$options.modalId"
      title-tag="h4"
      ok-variant="danger qa-modal-delete-pending-comments"
      @ok="discardReview"
    >
      <p v-html="$options.text"></p>
    </gl-modal>
  </div>
</template>
