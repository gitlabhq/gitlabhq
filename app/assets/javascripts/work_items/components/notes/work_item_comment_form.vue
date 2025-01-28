<script>
import { GlButton, GlFormCheckbox, GlTooltipDirective } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__, __ } from '~/locale';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import {
  STATE_OPEN,
  WORK_ITEM_TYPE_VALUE_TASK,
  WIDGET_TYPE_EMAIL_PARTICIPANTS,
  i18n,
} from '~/work_items/constants';
import { getDraft, clearDraft, updateDraft } from '~/lib/utils/autosave';
import { findWidget } from '~/issues/list/utils';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import glAbilitiesMixin from '~/vue_shared/mixins/gl_abilities_mixin';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import WorkItemStateToggle from '~/work_items/components/work_item_state_toggle.vue';
import CommentFieldLayout from '~/notes/components/comment_field_layout.vue';
import workItemByIidQuery from '../../graphql/work_item_by_iid.query.graphql';
import workItemEmailParticipantsByIidQuery from '../../graphql/notes/work_item_email_participants_by_iid.query.graphql';

const DOCS_WORK_ITEM_LOCKED_TASKS_PATH = helpPagePath('user/tasks.html', {
  anchor: 'lock-discussion',
});
const DOCS_WORK_ITEM_CONFIDENTIAL_TASKS_PATH = helpPagePath('user/tasks.html', {
  anchor: 'confidential-tasks',
});
const DOCS_WORK_ITEM_LOCKED_OKRS_PATH = helpPagePath('user/okrs.html', {
  anchor: 'lock-discussion',
});
const DOCS_WORK_ITEM_CONFIDENTIAL_OKRS_PATH = helpPagePath('user/okrs.html', {
  anchor: 'confidential-okrs',
});

export default {
  i18n: {
    internal: s__('Notes|Make this an internal note'),
    internalVisibility: s__(
      'Notes|Internal notes are only visible to members with the role of Planner or higher',
    ),
    addInternalNote: __('Add internal note'),
    cancelButtonText: __('Cancel'),
  },
  constantOptions: {
    markdownDocsPath: helpPagePath('user/markdown'),
  },
  components: {
    CommentFieldLayout,
    GlButton,
    MarkdownEditor,
    GlFormCheckbox,
    HelpIcon,
    WorkItemStateToggle,
    CommentTemperature: () =>
      import(
        /* webpackChunkName: 'comment_temperature' */ 'ee_component/ai/components/comment_temperature.vue'
      ),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glAbilitiesMixin()],
  props: {
    workItemId: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    ariaLabel: {
      type: String,
      required: true,
    },
    autosaveKey: {
      type: String,
      required: true,
    },
    isSubmitting: {
      type: Boolean,
      required: false,
      default: false,
    },
    initialValue: {
      type: String,
      required: false,
      default: '',
    },
    commentButtonText: {
      type: String,
      required: false,
      default: __('Comment'),
    },
    markdownPreviewPath: {
      type: String,
      required: true,
    },
    newCommentTemplatePaths: {
      type: Array,
      required: false,
      default: () => [],
    },
    autocompleteDataSources: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isNewDiscussion: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemState: {
      type: String,
      required: false,
      default: STATE_OPEN,
    },
    autofocus: {
      type: Boolean,
      required: false,
      default: false,
    },
    isDiscussionLocked: {
      type: Boolean,
      required: false,
      default: false,
    },
    isWorkItemConfidential: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemIid: {
      type: String,
      required: false,
      default: null,
    },
    isDiscussionInternal: {
      type: Boolean,
      required: false,
      default: false,
    },
    isDiscussionResolved: {
      type: Boolean,
      required: false,
      default: false,
    },
    isDiscussionResolvable: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasReplies: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasEmailParticipantsWidget: {
      type: Boolean,
      required: false,
      default: false,
    },
    parentId: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      commentText: getDraft(this.autosaveKey) || this.initialValue || '',
      updateInProgress: false,
      isNoteInternal: false,
      toggleResolveChecked: this.isDiscussionResolved,
      emailParticipants: [],
      workItem: {},
      isMeasuringCommentTemperature: false,
    };
  },
  computed: {
    formFieldProps() {
      return {
        'aria-label': this.ariaLabel,
        placeholder: __('Write a comment or drag your files here…'),
        id: 'work-item-add-or-edit-comment',
        name: 'work-item-add-or-edit-comment',
      };
    },
    commentButtonTextComputed() {
      return this.isNoteInternal ? this.$options.i18n.addInternalNote : this.commentButtonText;
    },
    docsLinks() {
      return this.workItemType === WORK_ITEM_TYPE_VALUE_TASK
        ? {
            confidential_issues_docs_path: DOCS_WORK_ITEM_CONFIDENTIAL_TASKS_PATH,
            locked_discussion_docs_path: DOCS_WORK_ITEM_LOCKED_TASKS_PATH,
          }
        : {
            confidential_issues_docs_path: DOCS_WORK_ITEM_CONFIDENTIAL_OKRS_PATH,
            locked_discussion_docs_path: DOCS_WORK_ITEM_LOCKED_OKRS_PATH,
          };
    },
    getWorkItemData() {
      return {
        confidential: this.isWorkItemConfidential,
        discussion_locked: this.isDiscussionLocked,
        issue_email_participants: this.emailParticipants,
        ...this.docsLinks,
      };
    },
    workItemTypeKey() {
      return capitalizeFirstCharacter(this.workItemType).replace(' ', '');
    },
    showResolveDiscussionToggle() {
      return !this.isNewDiscussion && this.isDiscussionResolvable && this.hasReplies;
    },
    resolveCheckboxLabel() {
      return this.isDiscussionResolved ? __('Unresolve thread') : __('Resolve thread');
    },
    canMarkNoteAsInternal() {
      return this.workItem?.userPermissions?.markNoteAsInternal;
    },
    canUpdate() {
      return this.workItem?.userPermissions?.updateWorkItem;
    },
    showInternalNoteCheckbox() {
      return this.canMarkNoteAsInternal && this.isNewDiscussion;
    },
    currentUserId() {
      return window.gon.current_user_id;
    },
  },
  apollo: {
    emailParticipants: {
      query: workItemEmailParticipantsByIidQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
        };
      },
      skip() {
        // Don't request email participants if the widget is not available
        return !this.workItemIid || !this.hasEmailParticipantsWidget;
      },
      error() {
        this.$emit('error', i18n.fetchError);
      },
      update(data) {
        return (
          findWidget(WIDGET_TYPE_EMAIL_PARTICIPANTS, data?.workspace?.workItem)?.emailParticipants
            ?.nodes || []
        );
      },
    },
    workItem: {
      query: workItemByIidQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
        };
      },
      update(data) {
        return data.workspace.workItem ?? {};
      },
      skip() {
        return !this.workItemIid;
      },
      error() {
        this.$emit('error', i18n.fetchError);
      },
    },
  },
  methods: {
    setCommentText(newText) {
      /**
       * https://gitlab.com/gitlab-org/gitlab/-/issues/388314
       *
       * While the form is saving using meta+enter,
       * avoid updating the data which is cleared after form submission.
       */
      if (!this.isSubmitting) {
        this.commentText = newText;
        updateDraft(this.autosaveKey, this.commentText);
        if (this.commentText) {
          this.$emit('startEditing');
        } else {
          this.$emit('stopEditing');
        }
      }
    },
    async cancelEditing() {
      if (this.commentText && this.commentText !== this.initialValue) {
        const msg = s__('WorkItem|Are you sure you want to cancel editing?');

        const confirmed = await confirmAction(msg, {
          primaryBtnText: __('Discard changes'),
          cancelBtnText: __('Continue editing'),
          primaryBtnVariant: 'danger',
        });

        if (!confirmed) {
          return;
        }
      }

      this.$emit('cancelEditing');
      clearDraft(this.autosaveKey);
    },
    submitForm(shouldMeasureTemperature = true) {
      this.isMeasuringCommentTemperature =
        this.glAbilities.measureCommentTemperature && shouldMeasureTemperature;

      if (this.isMeasuringCommentTemperature) {
        this.$refs.commentTemperature.measureCommentTemperature();
        return;
      }

      if (this.isSubmitting) {
        return;
      }
      if (this.toggleResolveChecked) {
        this.$emit('toggleResolveDiscussion');
      }
      this.$emit('submitForm', {
        commentText: this.commentText,
        isNoteInternal: this.isNoteInternal,
      });
    },
  },
};
</script>

<template>
  <div class="timeline-discussion-body !gl-overflow-visible">
    <div class="note-body !gl-overflow-visible !gl-p-0">
      <form class="common-note-form gfm-form js-main-target-form new-note gl-grow">
        <comment-field-layout
          :with-alert-container="isWorkItemConfidential"
          :is-internal-note="isDiscussionInternal || isNoteInternal"
          :note="commentText"
          :noteable-data="getWorkItemData"
          :noteable-type="workItemTypeKey"
        >
          <markdown-editor
            :value="commentText"
            :render-markdown-path="markdownPreviewPath"
            :markdown-docs-path="$options.constantOptions.markdownDocsPath"
            :new-comment-template-paths="newCommentTemplatePaths"
            :autocomplete-data-sources="autocompleteDataSources"
            :form-field-props="formFieldProps"
            :add-spacing-classes="false"
            use-bottom-toolbar
            supports-quick-actions
            :autofocus="autofocus"
            @input="setCommentText"
            @keydown.meta.enter="submitForm()"
            @keydown.ctrl.enter="submitForm()"
            @keydown.esc.stop="cancelEditing"
          />
        </comment-field-layout>
        <comment-temperature
          v-if="glAbilities.measureCommentTemperature"
          ref="commentTemperature"
          v-model="commentText"
          :item-id="workItemId"
          :item-type="workItemTypeKey"
          :user-id="currentUserId"
          @save="submitForm(false)"
        />
        <div class="note-form-actions" data-testid="work-item-comment-form-actions">
          <div v-if="showResolveDiscussionToggle">
            <label>
              <gl-form-checkbox
                v-model="toggleResolveChecked"
                data-testid="toggle-resolve-checkbox"
              >
                {{ resolveCheckboxLabel }}
              </gl-form-checkbox>
            </label>
          </div>
          <gl-form-checkbox
            v-if="showInternalNoteCheckbox"
            v-model="isNoteInternal"
            class="gl-mb-2"
            data-testid="internal-note-checkbox"
          >
            {{ $options.i18n.internal }}
            <help-icon
              v-gl-tooltip:tooltipcontainer.bottom
              :title="$options.i18n.internalVisibility"
            />
          </gl-form-checkbox>
          <div class="gl-flex gl-gap-3">
            <gl-button
              category="primary"
              variant="confirm"
              data-testid="confirm-button"
              :disabled="!commentText.length || isMeasuringCommentTemperature"
              :loading="isSubmitting"
              @click="submitForm()"
              >{{ commentButtonTextComputed }}
            </gl-button>
            <work-item-state-toggle
              v-if="isNewDiscussion && canUpdate"
              :work-item-id="workItemId"
              :work-item-iid="workItemIid"
              :work-item-state="workItemState"
              :work-item-type="workItemType"
              :full-path="fullPath"
              :has-comment="Boolean(commentText.length)"
              :disabled="Boolean(commentText.lengt) && isMeasuringCommentTemperature"
              :parent-id="parentId"
              can-update
              @submit-comment="submitForm()"
              @error="$emit('error', $event)"
            />
            <gl-button
              v-else
              data-testid="cancel-button"
              category="primary"
              :loading="updateInProgress"
              @click="cancelEditing"
              >{{ $options.i18n.cancelButtonText }}
            </gl-button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>
