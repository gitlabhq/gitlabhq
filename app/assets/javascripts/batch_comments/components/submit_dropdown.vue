<script>
import {
  GlDisclosureDropdown,
  GlButton,
  GlIcon,
  GlForm,
  GlFormRadioGroup,
  GlLoadingIcon,
} from '@gitlab/ui';
import { mapActions, mapState } from 'pinia';
// eslint-disable-next-line no-restricted-imports
import { mapGetters as mapVuexGetters, mapState as mapVuexState } from 'vuex';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import MarkdownHeaderDivider from '~/vue_shared/components/markdown/header_divider.vue';
import { scrollToElement } from '~/lib/utils/common_utils';
import { fetchPolicies } from '~/lib/graphql';
import { CLEAR_AUTOSAVE_ENTRY_EVENT, CONTENT_EDITOR_PASTE } from '~/vue_shared/constants';
import markdownEditorEventHub from '~/vue_shared/components/markdown/eventhub';
import { trackSavedUsingEditor } from '~/vue_shared/components/markdown/tracking';
import { updateText } from '~/lib/utils/text_markdown';
import { useBatchComments } from '~/batch_comments/store';
import userCanApproveQuery from '../queries/can_approve.query.graphql';

export default {
  apollo: {
    userPermissions: {
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      query: userCanApproveQuery,
      variables() {
        return {
          projectPath: this.projectPath.replace(/^\//, ''),
          iid: `${this.getNoteableData.iid}`,
        };
      },
      update: (data) => data.project?.mergeRequest?.userPermissions,
      skip() {
        return !this.dropdownVisible;
      },
    },
  },
  components: {
    GlDisclosureDropdown,
    GlButton,
    GlIcon,
    GlForm,
    GlFormRadioGroup,
    GlLoadingIcon,
    MarkdownEditor,
    MarkdownHeaderDivider,
    ApprovalPassword: () => import('ee_component/batch_comments/components/approval_password.vue'),
    SummarizeMyReview: () =>
      import('ee_component/batch_comments/components/summarize_my_review.vue'),
  },
  inject: {
    canSummarize: { default: false },
  },
  data() {
    return {
      isSubmitting: false,
      summarizeReviewLoading: false,
      dropdownVisible: false,
      noteData: {
        noteable_type: '',
        noteable_id: '',
        note: '',
        approve: false,
        approval_password: '',
        reviewer_state: 'reviewed',
      },
      formFieldProps: {
        id: 'review-note-body',
        name: 'review[note]',
        placeholder: __('Write a comment or drag your files here…'),
        'aria-label': __('Comment'),
        'data-testid': 'comment-textarea',
      },
      userPermissions: {},
    };
  },
  computed: {
    ...mapVuexGetters([
      'getNotesData',
      'getNoteableData',
      'noteableType',
      'getCurrentUserLastNote',
    ]),
    ...mapState(useBatchComments, ['shouldAnimateReviewButton']),
    ...mapVuexState('diffs', ['projectPath']),
    autocompleteDataSources() {
      return gl.GfmAutoComplete?.dataSources;
    },
    autosaveKey() {
      return `submit_review_dropdown/${this.getNoteableData.id}`;
    },
    radioGroupOptions() {
      return [
        {
          html: [
            __('Comment'),
            `<p class="help-text">
              ${__('Submit general feedback without explicit approval.')}
            </p>`,
          ].join('<br />'),
          value: 'reviewed',
        },
        {
          html: [
            __('Approve'),
            `<p class="help-text">
              ${__('Submit feedback and approve these changes.')}
            </p>`,
          ].join('<br />'),
          value: 'approved',
          disabled: !this.userPermissions.canApprove,
        },
        {
          html: [
            __('Request changes'),
            `<p class="help-text">
              ${__('Submit feedback that should be addressed before merging.')}
            </p>`,
          ].join('<br />'),
          value: 'requested_changes',
        },
      ];
    },
  },
  watch: {
    dropdownVisible(val) {
      if (!val) {
        this.userPermissions = {};
      }
    },
    userPermissions: {
      handler() {
        this.repositionDropdown();
      },
      deep: true,
    },
  },
  mounted() {
    this.noteData.noteable_type = this.noteableType;
    this.noteData.noteable_id = this.getNoteableData.id;
  },
  methods: {
    ...mapActions(useBatchComments, ['publishReview', 'clearDrafts']),
    repositionDropdown() {
      this.$refs.submitDropdown?.$refs.dropdown?.updatePopper();
    },
    async submitReview() {
      this.isSubmitting = true;
      if (this.userLastNoteWatcher) this.userLastNoteWatcher();

      trackSavedUsingEditor(this.$refs.markdownEditor.isContentEditorActive, 'MergeRequest_review');

      try {
        const { note, reviewer_state: reviewerState } = this.noteData;

        await this.publishReview({ ...this.noteData });

        markdownEditorEventHub.$emit(CLEAR_AUTOSAVE_ENTRY_EVENT, this.autosaveKey);

        this.noteData.note = '';
        this.noteData.reviewer_state = 'reviewed';
        this.noteData.approval_password = '';

        if (note) {
          this.userLastNoteWatcher = this.$watch(
            'getCurrentUserLastNote',
            () => {
              if (note) {
                window.location.hash = `note_${this.getCurrentUserLastNote.id}`;
              }

              window.mrTabs?.tabShown('show');

              setTimeout(() => {
                scrollToElement(document.getElementById(`note_${this.getCurrentUserLastNote.id}`));

                this.clearDrafts();
              });

              this.userLastNoteWatcher();
            },
            { deep: true },
          );
        } else {
          if (reviewerState === 'approved') {
            window.mrTabs?.tabShown('show');
          }

          this.clearDrafts();
        }
      } catch (e) {
        if (e.data?.message) {
          createAlert({ message: e.data.message, captureError: true });
        }

        this.isSubmitting = false;
      }
    },
    updateNote(note) {
      const textArea = this.$el.querySelector('textarea');

      if (textArea) {
        updateText({
          textArea,
          tag: note,
          cursorOffset: 0,
          wrap: false,
        });
      } else {
        markdownEditorEventHub.$emit(CONTENT_EDITOR_PASTE, note);
      }
    },
    onBeforeClose({ originalEvent: { target }, preventDefault }) {
      if (
        target &&
        [document.querySelector('.atwho-container'), document.querySelector('.dz-hidden-input')]
          .filter(Boolean)
          .some((el) => el.contains(target))
      ) {
        preventDefault();
      }
    },
    setDropdownVisible(val) {
      this.dropdownVisible = val;
    },
  },
  restrictedToolbarItems: ['full-screen'],
};
</script>

<template>
  <gl-disclosure-dropdown
    ref="submitDropdown"
    placement="bottom-end"
    class="submit-review-dropdown"
    :class="{ 'submit-review-dropdown-animated': shouldAnimateReviewButton }"
    data-testid="submit-review-dropdown"
    fluid-width
    @beforeClose="onBeforeClose"
    @shown="setDropdownVisible(true)"
    @hidden="setDropdownVisible(false)"
  >
    <template #toggle>
      <gl-button variant="confirm" category="primary">
        {{ __('Finish review') }}
        <gl-icon class="dropdown-chevron" name="chevron-up" />
      </gl-button>
    </template>
    <template #default>
      <gl-form
        class="submit-review-dropdown-form gl-p-4"
        data-testid="submit-gl-form"
        @submit.prevent="submitReview"
      >
        <div class="gl-mb-4 gl-flex gl-items-center">
          <label for="review-note-body" class="gl-mb-0">
            {{ __('Summary comment (optional)') }}
          </label>
        </div>
        <div class="common-note-form gfm-form">
          <markdown-editor
            ref="markdownEditor"
            v-model="noteData.note"
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
          >
            <template v-if="canSummarize" #header-buttons>
              <markdown-header-divider class="gl-ml-2" />
              <summarize-my-review
                :id="getNoteableData.id"
                v-model="summarizeReviewLoading"
                @input="updateNote"
              />
            </template>
            <template v-if="summarizeReviewLoading" #toolbar>
              <div class="gl-ml-auto gl-mr-2 gl-inline-flex">
                {{ __('Generating review summary') }}
                <gl-loading-icon class="gl-ml-2 gl-mt-2" />
              </div>
            </template>
          </markdown-editor>
        </div>
        <gl-form-radio-group
          v-model="noteData.reviewer_state"
          :options="radioGroupOptions"
          class="gl-mt-4"
          data-testid="reviewer_states"
        />
        <approval-password
          v-if="userPermissions.canApprove && getNoteableData.require_password_to_approve"
          v-show="noteData.reviewer_state === 'approved'"
          v-model="noteData.approval_password"
          class="gl-mt-3"
          data-testid="approve_password"
        />
        <div class="gl-mt-4 gl-flex gl-justify-start">
          <gl-button
            :loading="isSubmitting"
            variant="confirm"
            type="submit"
            class="js-no-auto-disable"
            data-testid="submit-review-button"
          >
            {{ __('Submit review') }}
          </gl-button>
        </div>
      </gl-form>
    </template>
  </gl-disclosure-dropdown>
</template>
