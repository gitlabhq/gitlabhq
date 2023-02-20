<script>
import { GlAvatar, GlButton } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { clearDraft } from '~/lib/utils/autosave';
import Tracking from '~/tracking';
import { ASC } from '~/notes/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { updateCommentState } from '~/work_items/graphql/cache_utils';
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
    markdownPreviewPath() {
      return `${gon.relative_url_root || ''}/${this.fullPath}/preview_markdown?target_type=${
        this.workItemType
      }`;
    },
    timelineEntryClass() {
      return {
        'timeline-entry gl-mb-3': true,
        'gl-p-4': this.addPadding,
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
      const { queryVariables, fetchByIid } = this;

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
            if (createNoteData.data?.createNote?.errors?.length) {
              throw new Error(createNoteData.data?.createNote?.errors[0]);
            }
            updateCommentState(store, createNoteData, fetchByIid, queryVariables);
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
    <div v-else class="gl-relative gl-display-flex gl-align-items-flex-start gl-flex-wrap-nowrap">
      <gl-avatar :src="$options.constantOptions.avatarUrl" :size="32" class="gl-mr-3" />
      <work-item-comment-form
        v-if="isEditing"
        :work-item-type="workItemType"
        :aria-label="__('Add a comment')"
        :is-submitting="isSubmitting"
        :autosave-key="autosaveKey"
        @submitForm="updateWorkItem"
        @cancelEditing="cancelEditing"
      />
      <gl-button
        v-else
        class="gl-flex-grow-1 gl-justify-content-start! gl-text-secondary!"
        @click="isEditing = true"
        >{{ __('Add a comment') }}</gl-button
      >
    </div>
  </li>
</template>
