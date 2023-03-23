<script>
import { GlAvatar, GlButton } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { clearDraft } from '~/lib/utils/autosave';
import Tracking from '~/tracking';
import { ASC } from '~/notes/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { getWorkItemQuery } from '../../utils';
import createNoteMutation from '../../graphql/notes/create_work_item_note.mutation.graphql';
import { TRACKING_CATEGORY_SHOW, i18n } from '../../constants';
import WorkItemNoteSignedOut from './work_item_note_signed_out.vue';
import WorkItemCommentLocked from './work_item_comment_locked.vue';
import WorkItemCommentForm from './work_item_comment_form.vue';

export default {
  constantOptions: {
    avatarUrl: window.gon.current_user_avatar_url,
  },
  components: {
    GlAvatar,
    GlButton,
    WorkItemNoteSignedOut,
    WorkItemCommentLocked,
    WorkItemCommentForm,
  },
  mixins: [glFeatureFlagMixin(), Tracking.mixin()],
  props: {
    workItemId: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    fetchByIid: {
      type: Boolean,
      required: false,
      default: false,
    },
    queryVariables: {
      type: Object,
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
    autocompleteDataSources: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      workItem: {},
      isEditing: false,
      isSubmitting: false,
      isSubmittingWithKeydown: false,
    };
  },
  apollo: {
    workItem: {
      query() {
        return getWorkItemQuery(this.fetchByIid);
      },
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return this.fetchByIid ? data.workspace.workItems.nodes[0] : data.workItem;
      },
      skip() {
        return !this.queryVariables.id && !this.queryVariables.iid;
      },
      error() {
        this.$emit('error', i18n.fetchError);
      },
    },
  },
  computed: {
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
    isLockedOutOrSignedOut() {
      return !this.signedIn || !this.canUpdate;
    },
    lockedOutUserWarningInReplies() {
      return this.addPadding && this.isLockedOutOrSignedOut;
    },
    timelineEntryClass() {
      return {
        'timeline-entry gl-mb-3 note note-wrapper note-comment': true,
        'gl-bg-gray-10 gl-rounded-bottom-left-base gl-rounded-bottom-right-base gl-p-5! gl-mx-n3 gl-mb-n2!': this
          .lockedOutUserWarningInReplies,
      };
    },
    timelineEntryInnerClass() {
      return {
        'timeline-entry-inner': true,
        'gl-pb-3': this.addPadding,
      };
    },
    timelineContentClass() {
      return {
        'timeline-content': true,
        'gl-border-0! gl-pl-0!': !this.addPadding,
      };
    },
    parentClass() {
      return {
        'gl-relative gl-display-flex gl-align-items-flex-start gl-flex-wrap-nowrap': !this
          .isEditing,
      };
    },
    isProjectArchived() {
      return this.workItem?.project?.archived;
    },
    canUpdate() {
      return this.workItem?.userPermissions?.updateWorkItem;
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
    async updateWorkItem(commentText) {
      this.isSubmitting = true;
      this.$emit('replying', commentText);

      try {
        this.track('add_work_item_comment');

        await this.$apollo.mutate({
          mutation: createNoteMutation,
          variables: {
            input: {
              noteableId: this.workItemId,
              body: commentText,
              discussionId: this.discussionId || null,
            },
          },
          update(store, createNoteData) {
            const numErrors = createNoteData.data?.createNote?.errors?.length;

            if (numErrors) {
              const { errors } = createNoteData.data.createNote;

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

              throw new Error(createNoteData.data?.createNote?.errors[0]);
            }
          },
        });
        clearDraft(this.autosaveKey);
        this.$emit('replied');
        this.cancelEditing();
      } catch (error) {
        this.$emit('error', error.message);
        Sentry.captureException(error);
      }

      this.isSubmitting = false;
    },
    cancelEditing() {
      this.isEditing = false;
      this.$emit('cancelEditing');
    },
  },
};
</script>

<template>
  <li :class="timelineEntryClass">
    <work-item-note-signed-out v-if="!signedIn" />
    <work-item-comment-locked
      v-else-if="!canUpdate"
      :work-item-type="workItemType"
      :is-project-archived="isProjectArchived"
    />
    <div v-else :class="timelineEntryInnerClass">
      <div class="timeline-avatar gl-float-left">
        <gl-avatar :src="$options.constantOptions.avatarUrl" :size="32" class="gl-mr-3" />
      </div>
      <div :class="timelineContentClass">
        <div :class="parentClass">
          <work-item-comment-form
            v-if="isEditing"
            :work-item-type="workItemType"
            :aria-label="__('Add a reply')"
            :is-submitting="isSubmitting"
            :autosave-key="autosaveKey"
            :autocomplete-data-sources="autocompleteDataSources"
            :markdown-preview-path="markdownPreviewPath"
            @submitForm="updateWorkItem"
            @cancelEditing="cancelEditing"
          />
          <gl-button
            v-else
            class="gl-flex-grow-1 gl-justify-content-start! gl-text-secondary!"
            @click="isEditing = true"
            >{{ __('Add a reply') }}</gl-button
          >
        </div>
      </div>
    </div>
  </li>
</template>
