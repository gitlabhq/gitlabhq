<script>
import { GlDropdown, GlButton, GlIcon, GlForm, GlFormCheckbox } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapActions, mapState } from 'vuex';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { scrollToElement } from '~/lib/utils/common_utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { CLEAR_AUTOSAVE_ENTRY_EVENT } from '~/vue_shared/constants';
import markdownEditorEventHub from '~/vue_shared/components/markdown/eventhub';
import { trackSavedUsingEditor } from '~/vue_shared/components/markdown/tracking';

export default {
  components: {
    GlDropdown,
    GlButton,
    GlIcon,
    GlForm,
    GlFormCheckbox,
    MarkdownEditor,
    ApprovalPassword: () => import('ee_component/batch_comments/components/approval_password.vue'),
    SummarizeMyReview: () =>
      import('ee_component/batch_comments/components/summarize_my_review.vue'),
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    canSummarize: { default: false },
  },
  data() {
    return {
      isSubmitting: false,
      noteData: {
        noteable_type: '',
        noteable_id: '',
        note: '',
        approve: false,
        approval_password: '',
      },
      formFieldProps: {
        id: 'review-note-body',
        name: 'review[note]',
        placeholder: __('Write a comment or drag your files here…'),
        'aria-label': __('Comment'),
        'data-testid': 'comment-textarea',
      },
    };
  },
  computed: {
    ...mapGetters(['getNotesData', 'getNoteableData', 'noteableType', 'getCurrentUserLastNote']),
    ...mapState('batchComments', ['shouldAnimateReviewButton']),
    autocompleteDataSources() {
      return gl.GfmAutoComplete?.dataSources;
    },
    autosaveKey() {
      return `submit_review_dropdown/${this.getNoteableData.id}`;
    },
  },
  watch: {
    'noteData.approve': function noteDataApproveWatch() {
      setTimeout(() => {
        this.repositionDropdown();
      });
    },
  },
  mounted() {
    this.noteData.noteable_type = this.noteableType;
    this.noteData.noteable_id = this.getNoteableData.id;

    // We override the Bootstrap Vue click outside behaviour
    // to allow for clicking in the autocomplete dropdowns
    // without this override the submit dropdown will close
    // whenever a item in the autocomplete dropdown is clicked
    const originalClickOutHandler = this.$refs.submitDropdown.$refs.dropdown.clickOutHandler;
    this.$refs.submitDropdown.$refs.dropdown.clickOutHandler = (e) => {
      if (!e.target.closest('.atwho-container')) {
        originalClickOutHandler(e);
      }
    };
  },
  methods: {
    ...mapActions('batchComments', ['publishReview']),
    repositionDropdown() {
      this.$refs.submitDropdown?.$refs.dropdown?.updatePopper();
    },
    async submitReview() {
      this.isSubmitting = true;

      trackSavedUsingEditor(this.$refs.markdownEditor.isContentEditorActive, 'MergeRequest_review');

      try {
        await this.publishReview(this.noteData);

        markdownEditorEventHub.$emit(CLEAR_AUTOSAVE_ENTRY_EVENT, this.descriptionAutosaveKey);

        if (window.mrTabs && (this.noteData.note || this.noteData.approve)) {
          if (this.noteData.note) {
            window.location.hash = `note_${this.getCurrentUserLastNote.id}`;
          }

          window.mrTabs.tabShown('show');

          setTimeout(() =>
            scrollToElement(document.getElementById(`note_${this.getCurrentUserLastNote.id}`)),
          );
        }
      } catch (e) {
        if (e.data?.message) {
          createAlert({ message: e.data.message, captureError: true });
        }
      }

      this.isSubmitting = false;
    },
    updateNote(note) {
      this.noteData.note = note;
    },
  },
  restrictedToolbarItems: ['full-screen'],
};
</script>

<template>
  <gl-dropdown
    ref="submitDropdown"
    right
    dropup
    class="submit-review-dropdown"
    :class="{ 'submit-review-dropdown-animated': shouldAnimateReviewButton }"
    data-qa-selector="submit_review_dropdown"
    variant="info"
    category="primary"
  >
    <template #button-content>
      {{ __('Finish review') }}
      <gl-icon class="dropdown-chevron" name="chevron-up" />
    </template>
    <gl-form data-testid="submit-gl-form" @submit.prevent="submitReview">
      <div class="gl-display-flex gl-mb-4 gl-align-items-center">
        <label for="review-note-body" class="gl-mb-0">
          {{ __('Summary comment (optional)') }}
        </label>
        <summarize-my-review
          v-if="canSummarize"
          :id="getNoteableData.id"
          class="gl-ml-auto"
          @input="updateNote"
        />
      </div>
      <div class="common-note-form gfm-form">
        <markdown-editor
          ref="markdownEditor"
          v-model="noteData.note"
          :enable-content-editor="Boolean(glFeatures.contentEditorOnIssues)"
          class="js-no-autosize"
          :is-submitting="isSubmitting"
          :render-markdown-path="getNoteableData.preview_note_path"
          :markdown-docs-path="getNotesData.markdownDocsPath"
          :form-field-props="formFieldProps"
          enable-autocomplete
          :autocomplete-data-sources="autocompleteDataSources"
          :disabled="isSubmitting"
          :restricted-tool-bar-items="$options.restrictedToolbarItems"
          :force-autosize="false"
          :autosave-key="autosaveKey"
          supports-quick-actions
          @input="$emit('input', $event)"
          @keydown.meta.enter="submitReview"
          @keydown.ctrl.enter="submitReview"
        />
      </div>
      <template v-if="getNoteableData.current_user.can_approve">
        <gl-form-checkbox
          v-model="noteData.approve"
          data-testid="approve_merge_request"
          class="gl-mt-4"
        >
          {{ __('Approve merge request') }}
        </gl-form-checkbox>
        <approval-password
          v-if="getNoteableData.require_password_to_approve"
          v-show="noteData.approve"
          v-model="noteData.approval_password"
          class="gl-mt-3"
          data-testid="approve_password"
        />
      </template>
      <div class="gl-display-flex gl-justify-content-start gl-mt-4">
        <gl-button
          :loading="isSubmitting"
          variant="confirm"
          type="submit"
          class="js-no-auto-disable"
          data-testid="submit-review-button"
          data-qa-selector="submit_review_button"
        >
          {{ __('Submit review') }}
        </gl-button>
      </div>
    </gl-form>
  </gl-dropdown>
</template>
