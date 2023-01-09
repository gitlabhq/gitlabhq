<script>
import { GlAvatar, GlButton } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getDraft, clearDraft, updateDraft } from '~/lib/utils/autosave';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { __, s__ } from '~/locale';
import Tracking from '~/tracking';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { getWorkItemQuery } from '../utils';
import createNoteMutation from '../graphql/create_work_item_note.mutation.graphql';
import { i18n, TRACKING_CATEGORY_SHOW } from '../constants';
import WorkItemNoteSignedOut from './work_item_note_signed_out.vue';
import WorkItemCommentLocked from './work_item_comment_locked.vue';

export default {
  constantOptions: {
    markdownDocsPath: helpPagePath('user/markdown'),
    avatarUrl: window.gon.current_user_avatar_url,
  },
  components: {
    GlAvatar,
    GlButton,
    MarkdownEditor,
    WorkItemNoteSignedOut,
    WorkItemCommentLocked,
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
  },
  data() {
    return {
      workItem: {},
      isEditing: false,
      isSubmitting: false,
      isSubmittingWithKeydown: false,
      commentText: '',
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
      return `${this.workItemId}-comment`;
    },
    canEdit() {
      // maybe this should use `NotePermissions.updateNote`, but if
      // we don't have any notes yet, that permission isn't on WorkItem
      return Boolean(this.workItem?.userPermissions?.updateWorkItem);
    },
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_comment',
        property: `type_${this.workItemType}`,
      };
    },
    workItemType() {
      return this.workItem?.workItemType?.name;
    },
    markdownPreviewPath() {
      return `${gon.relative_url_root || ''}/${this.fullPath}/preview_markdown?target_type=${
        this.workItemType
      }`;
    },
    isProjectArchived() {
      return this.workItem?.project?.archived;
    },
  },
  methods: {
    startEditing() {
      this.isEditing = true;
      this.commentText = getDraft(this.autosaveKey) || '';
    },
    async cancelEditing() {
      if (this.commentText) {
        const msg = s__('WorkItem|Are you sure you want to cancel editing?');

        const confirmed = await confirmAction(msg, {
          primaryBtnText: __('Discard changes'),
          cancelBtnText: __('Continue editing'),
        });

        if (!confirmed) {
          return;
        }
      }

      this.isEditing = false;
      clearDraft(this.autosaveKey);
    },
    async updateWorkItem(event = {}) {
      const { key } = event;

      if (key) {
        this.isSubmittingWithKeydown = true;
      }

      this.isSubmitting = true;

      try {
        this.track('add_work_item_comment');

        const {
          data: { createNote },
        } = await this.$apollo.mutate({
          mutation: createNoteMutation,
          variables: {
            input: {
              noteableId: this.workItem.id,
              body: this.commentText,
            },
          },
        });

        if (createNote.errors?.length) {
          throw new Error(createNote.errors[0]);
        }

        this.isEditing = false;
        clearDraft(this.autosaveKey);
      } catch (error) {
        this.$emit('error', error.message);
        Sentry.captureException(error);
      }

      this.isSubmitting = false;
    },
    setCommentText(newText) {
      this.commentText = newText;
      updateDraft(this.autosaveKey, this.commentText);
    },
  },
};
</script>

<template>
  <li class="timeline-entry">
    <work-item-note-signed-out v-if="!signedIn" />
    <work-item-comment-locked
      v-else-if="!canEdit"
      :work-item-type="workItemType"
      :is-project-archived="isProjectArchived"
    />
    <div v-else class="gl-display-flex gl-align-items-flex-start gl-flex-wrap-nowrap">
      <gl-avatar :src="$options.constantOptions.avatarUrl" :size="32" class="gl-mr-3" />
      <form v-if="isEditing" class="common-note-form gfm-form js-main-target-form gl-flex-grow-1">
        <markdown-editor
          class="gl-mb-3"
          :value="commentText"
          :render-markdown-path="markdownPreviewPath"
          :markdown-docs-path="$options.constantOptions.markdownDocsPath"
          :form-field-aria-label="__('Add a comment')"
          :form-field-placeholder="__('Write a comment or drag your files here…')"
          form-field-id="work-item-add-comment"
          form-field-name="work-item-add-comment"
          enable-autocomplete
          autofocus
          use-bottom-toolbar
          @input="setCommentText"
          @keydown.meta.enter="updateWorkItem"
          @keydown.ctrl.enter="updateWorkItem"
          @keydown.esc="cancelEditing"
        />
        <gl-button
          category="primary"
          variant="confirm"
          :loading="isSubmitting"
          @click="updateWorkItem"
          >{{ __('Comment') }}
        </gl-button>
        <gl-button category="tertiary" class="gl-ml-3" @click="cancelEditing"
          >{{ __('Cancel') }}
        </gl-button>
      </form>
      <gl-button
        v-else
        class="gl-flex-grow-1 gl-justify-content-start! gl-text-secondary!"
        @click="startEditing"
        >{{ __('Add a comment') }}</gl-button
      >
    </div>
  </li>
</template>
