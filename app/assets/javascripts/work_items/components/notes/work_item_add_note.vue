<script>
import { GlAlert } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { visitUrl } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import Tracking from '~/tracking';
import { ASC } from '~/notes/constants';
import { __ } from '~/locale';
import { clearDraft } from '~/lib/utils/autosave';
import { findWidget } from '~/issues/list/utils';
import DiscussionReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import ResolveDiscussionButton from '~/notes/components/discussion_resolve_button.vue';
import { updateCacheAfterCreatingNote } from '../../graphql/cache_utils';
import createNoteMutation from '../../graphql/notes/create_work_item_note.mutation.graphql';
import workItemNotesByIidQuery from '../../graphql/notes/work_item_notes_by_iid.query.graphql';
import workItemByIidQuery from '../../graphql/work_item_by_iid.query.graphql';
import { TRACKING_CATEGORY_SHOW, WIDGET_TYPE_EMAIL_PARTICIPANTS, i18n } from '../../constants';
import WorkItemNoteSignedOut from './work_item_note_signed_out.vue';
import WorkItemCommentLocked from './work_item_comment_locked.vue';
import WorkItemCommentForm from './work_item_comment_form.vue';

export default {
  constantOptions: {
    avatarUrl: window.gon.current_user_avatar_url,
  },
  components: {
    DiscussionReplyPlaceholder,
    GlAlert,
    WorkItemNoteSignedOut,
    WorkItemCommentLocked,
    WorkItemCommentForm,
    ResolveDiscussionButton,
  },
  mixins: [Tracking.mixin()],
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    workItemId: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: true,
    },
    discussionId: {
      type: String,
      required: false,
      default: '',
    },
    autofocus: {
      type: Boolean,
      required: false,
      default: false,
    },
    addPadding: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemType: {
      type: String,
      required: true,
    },
    sortOrder: {
      type: String,
      required: false,
      default: ASC,
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
    isDiscussionLocked: {
      type: Boolean,
      required: false,
      default: false,
    },
    isNewDiscussion: {
      type: Boolean,
      required: false,
      default: false,
    },
    isInternalThread: {
      type: Boolean,
      required: false,
      default: false,
    },
    isWorkItemConfidential: {
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
    isResolving: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasReplies: {
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
      addNoteKey: this.generateUniqueId(),
      errorMessages: '',
      messages: '',
      workItem: {},
      isEditing: this.isNewDiscussion,
      isSubmitting: false,
      isSubmittingWithKeydown: false,
    };
  },
  apollo: {
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
  computed: {
    isLoading() {
      return this.$apollo.queries.workItem.loading;
    },
    signedIn() {
      return Boolean(window.gon.current_user_id);
    },
    autosaveKey() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return this.discussionId ? `${this.discussionId}-comment` : `${this.workItemId}-comment`;
    },
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_comment',
        property: `type_${this.workItemType}`,
      };
    },
    timelineEntryInnerClass() {
      return {
        'timeline-entry-inner': this.isNewDiscussion,
      };
    },
    timelineContentClass() {
      return {
        'timeline-content': true,
        '!gl-border-0 !gl-pl-0': !this.addPadding,
      };
    },
    parentClass() {
      return {
        'gl-relative gl-flex gl-items-start gl-flex-wrap sm:gl-flex-nowrap': !this.isEditing,
      };
    },
    isProjectArchived() {
      return this.workItem.archived;
    },
    canCreateNote() {
      return this.workItem.userPermissions?.createNote;
    },
    workItemState() {
      return this.workItem.state;
    },
    commentButtonText() {
      return this.isNewDiscussion ? __('Comment') : __('Reply');
    },
    timelineEntryClass() {
      return {
        'timeline-entry note-form': this.isNewDiscussion,
        // eslint-disable-next-line @gitlab/require-i18n-strings
        '!gl-pb-5 note note-wrapper note-comment discussion-reply-holder clearfix':
          !this.isNewDiscussion,
        'is-replying': this.isEditing,
        'internal-note': this.isInternalThread,
      };
    },
    resolveDiscussionTitle() {
      return this.isDiscussionResolved ? __('Unresolve thread') : __('Resolve thread');
    },
    hasEmailParticipantsWidget() {
      return Boolean(findWidget(WIDGET_TYPE_EMAIL_PARTICIPANTS, this.workItem));
    },
  },
  watch: {
    autofocus: {
      immediate: true,
      handler(focus) {
        if (focus) {
          this.isEditing = true;
        }
      },
    },
  },
  methods: {
    generateUniqueId() {
      // used to rerender work-item-comment-form so the text in the textarea is cleared
      return uniqueId(`work-item-add-note-${this.workItemId}-`);
    },
    async updateWorkItem({ commentText, isNoteInternal = false }) {
      this.isSubmitting = true;
      this.$emit('replying', commentText);
      try {
        this.track('add_work_item_comment');

        const { data } = await this.$apollo.mutate({
          mutation: createNoteMutation,
          variables: {
            input: {
              noteableId: this.workItemId,
              body: commentText,
              discussionId: this.discussionId || null,
              internal: isNoteInternal,
            },
          },
          update: this.onNoteUpdate,
        });
        const { errorMessages, messages } = data.createNote.quickActionsStatus;

        this.errorMessages = errorMessages?.join(' ');
        this.messages = messages?.join(' ');
        this.$emit('replied');
        clearDraft(this.autosaveKey);
        this.cancelEditing();
        this.doFullPageReloadIfIncident(commentText);
      } catch (error) {
        this.$emit('error', error.message);
        Sentry.captureException(error);
      } finally {
        this.isSubmitting = false;
      }
    },
    // Until incidents are fully migrated to work items
    // we need to browse to the detail page again
    // so the legacy detail view is rendered.
    // https://gitlab.com/gitlab-org/gitlab/-/issues/502823
    doFullPageReloadIfIncident(commentText) {
      // Matches quick actions /promote_to incident /promote_to_incident and /type incident case insensitive
      const incidentTypeChangeRegex =
        /\/(promote_to(?:_incident|\s{1,3}incident)|type\s{1,3}incident)(?!\S)/im;

      if (incidentTypeChangeRegex.test(commentText)) {
        visitUrl(this.workItem.webUrl);
      }
    },
    cancelEditing() {
      this.isEditing = this.isNewDiscussion;
      this.addNoteKey = this.generateUniqueId();
      this.$emit('cancelEditing');
    },
    showReplyForm() {
      this.isEditing = true;
      this.$emit('startReplying');
    },
    addDiscussionToCache(cache, newNote) {
      const queryArgs = {
        query: workItemNotesByIidQuery,
        variables: { fullPath: this.fullPath, iid: this.workItemIid },
      };
      const sourceData = cache.readQuery(queryArgs);
      if (!sourceData) {
        return;
      }
      cache.writeQuery({
        ...queryArgs,
        data: updateCacheAfterCreatingNote(sourceData, newNote),
      });
    },
    onNoteUpdate(cache, { data }) {
      this.addDiscussionToCache(cache, data.createNote.note);

      const numErrors = data?.createNote?.errors?.length;

      if (numErrors) {
        const { errors } = data.createNote;

        // TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/503600
        // Refetching widgets as a temporary solution for dynamic updates
        // of the sidebar on changing the work item type
        if (numErrors === 2 && errors[1].includes('"type"')) {
          this.$apollo.queries.workItem.refetch();
          return;
        }

        // TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/346557
        // When a note only contains quick actions,
        // additional "helpful" messages are embedded in the errors field.
        // For instance, a note solely composed of "/assign @foobar" would
        // return a message "Commands only Assigned @root." as an error on creation
        // even though the quick action successfully executed.
        if (
          numErrors === 2 &&
          errors[0].includes('Commands only') &&
          errors[1].includes('Command names')
        ) {
          return;
        }

        throw new Error(data?.createNote?.errors[0]);
      }
    },
  },
};
</script>

<template>
  <li :class="timelineEntryClass">
    <work-item-note-signed-out v-if="!signedIn" />
    <work-item-comment-locked
      v-else-if="!isLoading && !canCreateNote"
      :work-item-type="workItemType"
      :is-project-archived="isProjectArchived"
    />
    <div v-else :class="timelineEntryInnerClass">
      <div :class="timelineContentClass">
        <gl-alert
          v-if="messages"
          class="gl-mb-2"
          data-testid="success-alert"
          @dismiss="messages = ''"
        >
          {{ messages }}
        </gl-alert>
        <gl-alert
          v-if="errorMessages"
          class="gl-mb-2"
          variant="danger"
          data-testid="error-alert"
          @dismiss="errorMessages = ''"
        >
          {{ errorMessages }}
        </gl-alert>
        <div :class="parentClass">
          <work-item-comment-form
            v-if="isEditing"
            :key="addNoteKey"
            :work-item-type="workItemType"
            :aria-label="__('Add a reply')"
            :is-submitting="isSubmitting"
            :autosave-key="autosaveKey"
            :is-new-discussion="isNewDiscussion"
            :autocomplete-data-sources="autocompleteDataSources"
            :markdown-preview-path="markdownPreviewPath"
            :new-comment-template-paths="newCommentTemplatePaths"
            :work-item-state="workItemState"
            :work-item-id="workItemId"
            :autofocus="autofocus"
            :comment-button-text="commentButtonText"
            :is-discussion-internal="isInternalThread"
            :is-discussion-locked="isDiscussionLocked"
            :is-work-item-confidential="isWorkItemConfidential"
            :is-discussion-resolved="isDiscussionResolved"
            :is-discussion-resolvable="isDiscussionResolvable"
            :full-path="fullPath"
            :has-replies="hasReplies"
            :work-item-iid="workItemIid"
            :has-email-participants-widget="hasEmailParticipantsWidget"
            :parent-id="parentId"
            @toggleResolveDiscussion="$emit('resolve')"
            @submitForm="updateWorkItem"
            @cancelEditing="cancelEditing"
            @error="$emit('error', $event)"
            @startEditing="$emit('startEditing')"
            @stopEditing="$emit('stopEditing')"
          />
          <discussion-reply-placeholder
            v-else
            data-testid="note-reply-textarea"
            @focus="showReplyForm"
          />

          <div v-if="!isNewDiscussion && !isEditing" class="discussion-actions">
            <resolve-discussion-button
              v-if="isDiscussionResolvable"
              data-testid="resolve-discussion-button"
              :is-resolving="isResolving"
              :button-title="resolveDiscussionTitle"
              @onClick="$emit('resolve')"
            />
          </div>
        </div>
      </div>
    </div>
  </li>
</template>
