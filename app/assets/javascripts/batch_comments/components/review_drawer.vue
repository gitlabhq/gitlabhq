<script>
import { mapActions, mapState } from 'pinia';
import {
  GlDrawer,
  GlModal,
  GlButton,
  GlFormRadioGroup,
  GlLoadingIcon,
  GlFormInput,
  GlForm,
} from '@gitlab/ui';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import PreviewItem from '~/batch_comments/components/preview_item.vue';
import { useBatchComments } from '~/batch_comments/store';
import { setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { scrollToElement } from '~/lib/utils/scroll_utils';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { fetchPolicies } from '~/lib/graphql';
import toast from '~/vue_shared/plugins/global_toast';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import MarkdownHeaderDivider from '~/vue_shared/components/markdown/header_divider.vue';
import { trackSavedUsingEditor } from '~/vue_shared/components/markdown/tracking';
import { CLEAR_AUTOSAVE_ENTRY_EVENT, CONTENT_EDITOR_PASTE } from '~/vue_shared/constants';
import markdownEditorEventHub from '~/vue_shared/components/markdown/eventhub';
import { updateText } from '~/lib/utils/text_markdown';
import { useNotes } from '~/notes/store/legacy_notes';
import userCanApproveQuery from '../queries/can_approve.query.graphql';

const REVIEW_STATES = {
  REVIEWED: 'reviewed',
  REQUESTED_CHANGES: 'requested_changes',
  APPROVED: 'approved',
};

export default {
  name: 'ReviewDrawer',
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
      update: (data) => data.project?.mergeRequest?.userPermissions ?? {},
    },
  },
  components: {
    GlDrawer,
    GlButton,
    GlFormRadioGroup,
    GlModal,
    GlLoadingIcon,
    GlFormInput,
    GlForm,
    PreviewItem,
    MarkdownEditor,
    MarkdownHeaderDivider,
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
      summarizeReviewLoading: false,
      showMarkdownEditor: false,
      userPermissions: {},
      noteData: {
        noteable_type: '',
        noteable_id: '',
        note: '',
        approve: false,
        approval_password: '',
        reviewer_state: REVIEW_STATES.REVIEWED,
      },
      discarding: false,
      showDiscardModal: false,
    };
  },
  computed: {
    ...mapState(useLegacyDiffs, ['viewDiffsFileByFile', 'projectPath']),
    ...mapState(useBatchComments, ['sortedDrafts', 'draftsCount', 'drawerOpened']),
    ...mapState(useNotes, ['getNoteableData', 'getNotesData', 'getCurrentUserLastNote']),
    getDrawerHeaderHeight() {
      if (!this.drawerOpened) return '0';

      return getContentWrapperHeight();
    },
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
          value: REVIEW_STATES.REVIEWED,
        },
        {
          html: [
            __('Approve'),
            `<p class="help-text">
              ${__('Submit feedback and approve these changes.')}
            </p>`,
          ].join('<br />'),
          value: REVIEW_STATES.APPROVED,
          disabled: !this.userPermissions.canApprove,
        },
        {
          html: [
            __('Request changes'),
            `<p class="help-text">
              ${__('Submit feedback that should be addressed before merging.')}
            </p>`,
          ].join('<br />'),
          value: REVIEW_STATES.REQUESTED_CHANGES,
        },
      ];
    },
  },
  mounted() {
    this.noteData.noteable_type = this.noteableType;
    this.noteData.noteable_id = this.getNoteableData.id;
  },
  methods: {
    ...mapActions(useLegacyDiffs, ['goToFile']),
    ...mapActions(useBatchComments, [
      'scrollToDraft',
      'setDrawerOpened',
      'publishReview',
      'publishReviewInBatches',
      'discardDrafts',
      'clearDrafts',
    ]),
    isOnLatestDiff(draft) {
      return draft.position?.head_sha === this.getNoteableData.diff_head_sha;
    },
    async onClickDraft(draft) {
      if (this.viewDiffsFileByFile) {
        await this.goToFile({ path: draft.file_path });
      }

      if (draft.position && !this.isOnLatestDiff(draft)) {
        const url = new URL(setUrlParams({ commit_id: draft.position.head_sha }));
        url.hash = `draft_${draft.id}`;
        visitUrl(url.toString());
      } else {
        await this.scrollToDraft(draft);
      }
    },
    async submitReview() {
      this.isSubmitting = true;
      if (this.userLastNoteWatcher) this.userLastNoteWatcher();

      if (this.$refs.markdownEditor) {
        trackSavedUsingEditor(
          this.$refs.markdownEditor.isContentEditorActive,
          'MergeRequest_review',
        );
      }

      try {
        const { note, reviewer_state: reviewerState } = this.noteData;

        if (this.draftsCount > 0 && this.glFeatures.mrReviewBatchSubmit) {
          await this.publishReviewInBatches(this.noteData);
        } else {
          await this.publishReview({ ...this.noteData });
        }

        markdownEditorEventHub.$emit(CLEAR_AUTOSAVE_ENTRY_EVENT, this.autosaveKey);

        this.noteData.note = '';
        this.noteData.reviewer_state = REVIEW_STATES.REVIEWED;
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
                this.setDrawerOpened(false);
                this.isSubmitting = false;
              });

              this.userLastNoteWatcher();
            },
            { deep: true },
          );
        } else {
          if (reviewerState === REVIEW_STATES.APPROVED) {
            window.mrTabs?.tabShown('show');
          }

          this.clearDrafts();
          this.setDrawerOpened(false);
          this.isSubmitting = false;
        }
      } catch (e) {
        if (e.data?.message) {
          createAlert({ message: e.data.message, captureError: true, error: e });
        }

        this.isSubmitting = false;
      }
    },
    async discardReviews() {
      this.discarding = true;

      try {
        await this.discardDrafts();

        this.setDrawerOpened(false);
        toast(__('Review discarded'));
      } finally {
        this.discarding = false;
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
  },
  DRAWER_Z_INDEX,
  modal: {
    cancelAction: { text: __('Keep review') },
    primaryAction: { text: __('Discard review'), attributes: { variant: 'danger' } },
  },
  formFieldProps: {
    id: 'review-note-body',
    name: 'review[note]',
    placeholder: __('Write a comment or drag your files here…'),
    'aria-label': __('Comment'),
    'data-testid': 'comment-textarea',
  },
  restrictedToolbarItems: ['full-screen'],
  REVIEW_STATES,
};
</script>

<template>
  <gl-drawer
    :header-height="getDrawerHeaderHeight"
    :z-index="$options.DRAWER_Z_INDEX"
    :open="drawerOpened"
    class="merge-request-review-drawer !gl-w-[100cqw] !gl-max-w-2xl"
    data-testid="review-drawer-toggle"
    @close="setDrawerOpened(false)"
  >
    <template #title>
      <h2 class="gl-heading-3 gl-m-0">{{ __('Submit your review') }}</h2>
    </template>

    <div class="gl-flex gl-h-full gl-flex-col">
      <div class="gl-border-b gl-mb-6 gl-pb-6">
        <h3 class="gl-heading-4">
          {{ __('Review approval') }}
        </h3>
        <gl-form data-testid="submit-gl-form" @submit.prevent="submitReview">
          <gl-form-radio-group
            v-model="noteData.reviewer_state"
            :options="radioGroupOptions"
            class="gl-mt-4"
            data-testid="reviewer_states"
          />
          <approval-password
            v-if="userPermissions.canApprove && getNoteableData.require_password_to_approve"
            v-show="noteData.reviewer_state === $options.REVIEW_STATES.APPROVED"
            v-model="noteData.approval_password"
            class="gl-mt-3"
            data-testid="approve_password"
          />
          <div class="common-note-form gfm-form gl-mb-5 gl-mt-3">
            <markdown-editor
              v-if="showMarkdownEditor"
              ref="markdownEditor"
              v-model="noteData.note"
              class="js-no-autosize"
              :is-submitting="isSubmitting"
              :render-markdown-path="getNoteableData.preview_note_path"
              :markdown-docs-path="getNotesData.markdownDocsPath"
              :form-field-props="$options.formFieldProps"
              enable-autocomplete
              :autocomplete-data-sources="autocompleteDataSources"
              :disabled="isSubmitting"
              :restricted-tool-bar-items="$options.restrictedToolbarItems"
              :force-autosize="false"
              :autosave-key="autosaveKey"
              supports-quick-actions
              autofocus
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
            <gl-form-input
              v-else
              class="reply-placeholder-input-field gl-mb-5 gl-mt-3"
              :placeholder="__('Add optional summary content…')"
              data-testid="placeholder-input-field"
              @focus="showMarkdownEditor = true"
            />
          </div>
          <div class="gl-mt-3 gl-flex gl-gap-3">
            <gl-button
              type="submit"
              variant="confirm"
              :loading="isSubmitting"
              class="js-no-auto-disable"
              data-testid="submit-review-button"
            >
              {{ __('Submit review') }}
            </gl-button>
            <gl-button @click="setDrawerOpened(false)">{{ __('Continue review') }}</gl-button>
          </div>
        </gl-form>
      </div>

      <div>
        <div class="gl-mb-5 gl-flex gl-items-center gl-justify-between gl-gap-3">
          <h3 class="gl-heading-4 gl-mb-0" data-testid="reviewer-drawer-heading">
            <template v-if="draftsCount > 0">
              {{ n__('%d pending comment', '%d pending comments', draftsCount) }}
            </template>
            <template v-else>
              {{ __('No pending comments') }}
            </template>
          </h3>
          <gl-button
            v-if="draftsCount > 0"
            size="small"
            category="secondary"
            :loading="discarding"
            data-testid="discard-review-btn"
            @click="showDiscardModal = true"
          >
            {{ __('Discard review') }}
          </gl-button>
        </div>

        <preview-item
          v-for="draft in sortedDrafts"
          :key="draft.id"
          :draft="draft"
          @click="onClickDraft"
        />
      </div>
    </div>

    <gl-modal
      v-model="showDiscardModal"
      modal-id="discard-review-modal"
      :title="__('Discard pending review?')"
      :action-primary="$options.modal.primaryAction"
      :action-cancel="$options.modal.cancelAction"
      data-testid="discard-review-modal"
      static
      lazy
      @primary="discardReviews"
    >
      {{
        __(
          'Are you sure you want to discard your pending review comments? This action cannot be undone.',
        )
      }}
    </gl-modal>
  </gl-drawer>
</template>
