<script>
import { GlDropdown, GlButton, GlIcon, GlForm, GlFormGroup, GlFormCheckbox } from '@gitlab/ui';
import { mapGetters, mapActions, mapState } from 'vuex';
import { createAlert } from '~/alert';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import { scrollToElement } from '~/lib/utils/common_utils';
import Autosave from '~/autosave';

export default {
  components: {
    GlDropdown,
    GlButton,
    GlIcon,
    GlForm,
    GlFormGroup,
    GlFormCheckbox,
    MarkdownField,
    ApprovalPassword: () => import('ee_component/batch_comments/components/approval_password.vue'),
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
    };
  },
  computed: {
    ...mapGetters(['getNotesData', 'getNoteableData', 'noteableType', 'getCurrentUserLastNote']),
    ...mapState('batchComments', ['shouldAnimateReviewButton']),
  },
  watch: {
    'noteData.approve': function noteDataApproveWatch() {
      setTimeout(() => {
        this.repositionDropdown();
      });
    },
  },
  mounted() {
    this.autosave = new Autosave(
      this.$refs.textarea,
      `submit_review_dropdown/${this.getNoteableData.id}`,
    );
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

      try {
        await this.publishReview(this.noteData);

        this.autosave.reset();

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
      <gl-form-group label-for="review-note-body" label-class="gl-mb-2">
        <template #label>
          {{ __('Summary comment (optional)') }}
        </template>
        <div class="common-note-form gfm-form">
          <div class="comment-warning-wrapper-large gl-border-0 gl-bg-white gl-overflow-hidden">
            <markdown-field
              :is-submitting="isSubmitting"
              :add-spacing-classes="false"
              :textarea-value="noteData.note"
              :markdown-preview-path="getNoteableData.preview_note_path"
              :markdown-docs-path="getNotesData.markdownDocsPath"
              :quick-actions-docs-path="getNotesData.quickActionsDocsPath"
              :restricted-tool-bar-items="$options.restrictedToolbarItems"
              :force-autosize="false"
              class="js-no-autosize"
            >
              <template #textarea>
                <textarea
                  id="review-note-body"
                  ref="textarea"
                  v-model="noteData.note"
                  dir="auto"
                  :disabled="isSubmitting"
                  name="review[note]"
                  class="note-textarea js-gfm-input markdown-area"
                  data-supports-quick-actions="true"
                  data-testid="comment-textarea"
                  :aria-label="__('Comment')"
                  :placeholder="__('Write a comment or drag your files here…')"
                  @keydown.meta.enter="submitReview"
                  @keydown.ctrl.enter="submitReview"
                ></textarea>
              </template>
            </markdown-field>
          </div>
        </div>
      </gl-form-group>
      <template v-if="getNoteableData.current_user.can_approve">
        <gl-form-checkbox v-model="noteData.approve" data-testid="approve_merge_request">
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
      <div class="gl-display-flex gl-justify-content-start gl-mt-5">
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
