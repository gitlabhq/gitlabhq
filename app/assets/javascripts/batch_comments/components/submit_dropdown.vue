<script>
import $ from 'jquery';
import { GlDropdown, GlButton, GlIcon, GlForm, GlFormGroup } from '@gitlab/ui';
import { mapGetters, mapActions } from 'vuex';
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
    MarkdownField,
  },
  data() {
    return {
      isSubmitting: false,
      note: '',
    };
  },
  computed: {
    ...mapGetters(['getNotesData', 'getNoteableData', 'noteableType', 'getCurrentUserLastNote']),
  },
  mounted() {
    this.autosave = new Autosave(
      $(this.$refs.textarea),
      `submit_review_dropdown/${this.getNoteableData.id}`,
    );

    // We override the Bootstrap Vue click outside behaviour
    // to allow for clicking in the autocomplete dropdowns
    // without this override the submit dropdown will close
    // whenever a item in the autocomplete dropdown is clicked
    const originalClickOutHandler = this.$refs.dropdown.$refs.dropdown.clickOutHandler;
    this.$refs.dropdown.$refs.dropdown.clickOutHandler = (e) => {
      if (!e.target.closest('.atwho-container')) {
        originalClickOutHandler(e);
      }
    };
  },
  methods: {
    ...mapActions('batchComments', ['publishReview']),
    async submitReview() {
      const noteData = {
        noteable_type: this.noteableType,
        noteable_id: this.getNoteableData.id,
        note: this.note,
      };

      this.isSubmitting = true;

      await this.publishReview(noteData);

      this.autosave.reset();

      if (window.mrTabs && this.note) {
        window.location.hash = `note_${this.getCurrentUserLastNote.id}`;
        window.mrTabs.tabShown('show');

        setTimeout(() =>
          scrollToElement(document.getElementById(`note_${this.getCurrentUserLastNote.id}`)),
        );
      }

      this.isSubmitting = false;
    },
  },
  restrictedToolbarItems: ['full-screen'],
};
</script>

<template>
  <gl-dropdown
    ref="dropdown"
    right
    class="submit-review-dropdown"
    data-qa-selector="submit_review_dropdown"
    variant="info"
    category="secondary"
  >
    <template #button-content>
      {{ __('Finish review') }}
      <gl-icon class="dropdown-chevron" name="chevron-up" />
    </template>
    <gl-form data-testid="submit-gl-form" @submit.prevent="submitReview">
      <gl-form-group
        :label="__('Summary comment (optional)')"
        label-for="review-note-body"
        label-class="gl-mb-2"
      >
        <div class="common-note-form gfm-form">
          <div
            class="comment-warning-wrapper gl-border-solid gl-border-1 gl-rounded-base gl-border-gray-100"
          >
            <markdown-field
              :is-submitting="isSubmitting"
              :add-spacing-classes="false"
              :textarea-value="note"
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
                  v-model="note"
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
      <div class="gl-display-flex gl-justify-content-end gl-mt-5">
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
