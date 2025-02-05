<script>
import { GlButton, GlLink, GlTooltipDirective, GlFormCheckbox } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import highlightCurrentUser from '~/behaviors/markdown/highlight_current_user';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { getLocationHash } from '~/lib/utils/url_utility';
import DesignNotePin from '~/vue_shared/components/design_management/design_note_pin.vue';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { updateGlobalTodoCount } from '~/sidebar/utils';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { TYPENAME_NOTE, TYPENAME_DISCUSSION } from '~/graphql_shared/constants';
import activeDiscussionQuery from '../graphql/client/active_design_discussion.query.graphql';
import createNoteMutation from '../graphql/create_note.mutation.graphql';
import getDesignQuery from '../graphql/design_details.query.graphql';
import toggleResolveDiscussionMutation from '../graphql/toggle_resolve_discussion.mutation.graphql';
import destroyNoteMutation from '../graphql/destroy_note.mutation.graphql';
import { hasErrors } from '../cache_updates';

import {
  ACTIVE_DISCUSSION_SOURCE_TYPES,
  ADD_DISCUSSION_COMMENT_ERROR,
  DELETE_NOTE_ERROR,
  RESOLVE_NOTE_ERROR,
} from '../constants';
import DesignNoteSignedOut from './design_note_signed_out.vue';
import DiscussionReplyPlaceholder from './discussion_reply_placeholder.vue';
import DesignReplyForm from './design_reply_form.vue';
import DesignNote from './design_note.vue';
import ToggleRepliesWidget from './toggle_replies_widget.vue';

export default {
  isLoggedIn: isLoggedIn(),
  i18n: {
    deleteNote: {
      confirmationText: __('Are you sure you want to delete this comment?'),
      primaryModalBtnText: __('Delete comment'),
    },
  },
  components: {
    DesignNote,
    DesignNotePin,
    DiscussionReplyPlaceholder,
    DesignReplyForm,
    DesignNoteSignedOut,
    GlFormCheckbox,
    GlButton,
    GlLink,
    TimeAgoTooltip,
    ToggleRepliesWidget,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    discussion: {
      type: Object,
      required: true,
    },
    noteableId: {
      type: String,
      required: true,
    },
    discussionWithOpenForm: {
      type: String,
      required: true,
    },
    registerPath: {
      type: String,
      required: true,
    },
    signInPath: {
      type: String,
      required: true,
    },
    resolvedDiscussionsExpanded: {
      type: Boolean,
      required: true,
    },
    markdownPreviewPath: {
      type: String,
      required: false,
      default: '',
    },
    designVariables: {
      type: Object,
      required: true,
    },
  },
  apollo: {
    activeDesignDiscussion: {
      query: activeDiscussionQuery,
      result({ data }) {
        if (this.discussion.resolved && !this.resolvedDiscussionsExpanded) {
          return;
        }

        this.$nextTick(() => {
          // We watch any changes to the active discussion from the design pins and scroll to this discussion if it exists.
          // We don't want scrollIntoView to be triggered from the discussion click itself.
          if (this.$el && this.shouldScrollToDiscussion(data.activeDesignDiscussion)) {
            this.$el.scrollIntoView({
              behavior: 'smooth',
              inline: 'start',
            });
          }
        });
      },
    },
  },
  data() {
    return {
      isFormRendered: false,
      noteToDelete: null,
      isResolving: false,
      shouldChangeResolvedStatus: false,
      areRepliesCollapsed: this.discussion.resolved,
      activeDesignDiscussion: {},
    };
  },
  computed: {
    mutationVariables() {
      return {
        noteableId: this.noteableId,
        discussionId: this.discussion.id,
      };
    },
    resolveCheckboxText() {
      return this.discussion.resolved
        ? s__('DesignManagement|Unresolve thread')
        : s__('DesignManagement|Resolve thread');
    },
    firstNote() {
      return this.discussion.notes[0];
    },
    discussionReplies() {
      return this.discussion.notes.slice(1);
    },
    areRepliesShown() {
      return !this.areRepliesCollapsed;
    },
    resolveIconName() {
      return this.discussion.resolved ? 'check-circle-filled' : 'check-circle';
    },
    isRepliesWidgetVisible() {
      return this.discussionReplies.length > 0;
    },
    isDiscussionActive() {
      return this.discussion.notes.some(({ id }) => {
        return (
          id === this.activeDesignDiscussion.id ||
          getLocationHash()?.includes(getIdFromGraphQLId(id))
        );
      });
    },
    isReplyPlaceholderVisible() {
      return this.areRepliesShown || !this.discussionReplies.length;
    },
    isFormVisible() {
      return this.isFormRendered && this.discussionWithOpenForm === this.discussion.id;
    },
    designsVersion() {
      return this.$route.query.version
        ? `gid://gitlab/DesignManagement::Version/${this.$route.query.version}`
        : null;
    },
  },
  mounted() {
    this.$nextTick(() => {
      highlightCurrentUser(this.$el.querySelectorAll('.gfm-project_member'));
      if (this.isDiscussionActive) {
        this.$el.scrollIntoView({
          behavior: 'smooth',
          inline: 'start',
        });
      }
    });
  },
  updated() {
    this.$nextTick(() => {
      highlightCurrentUser(this.$el.querySelectorAll('.gfm-project_member'));
    });
  },
  methods: {
    onSubmitComplete({ data: { createNote } }) {
      if (hasErrors(createNote)) {
        createAlert({ message: ADD_DISCUSSION_COMMENT_ERROR });
      } else {
        /**
         * https://gitlab.com/gitlab-org/gitlab/-/issues/388314
         *
         * Hide the form once the create note mutation is completed.
         */
        this.hideForm();
      }

      if (this.shouldChangeResolvedStatus) {
        this.toggleResolvedStatus();
      }
    },
    shouldScrollToDiscussion(activeDesignDiscussion) {
      const ALLOWED_ACTIVE_DISCUSSION_SOURCES = [
        ACTIVE_DISCUSSION_SOURCE_TYPES.pin,
        ACTIVE_DISCUSSION_SOURCE_TYPES.url,
      ];
      const { source } = activeDesignDiscussion;
      return ALLOWED_ACTIVE_DISCUSSION_SOURCES.includes(source) && this.isDiscussionActive;
    },
    hideForm() {
      this.isFormRendered = false;
    },
    showForm() {
      this.$emit('open-form', this.discussion.id);
      this.isFormRendered = true;
    },
    async toggleResolvedStatus() {
      this.isResolving = true;

      /**
       * Get previous todo count
       */
      const { defaultClient: client } = this.$apollo.provider.clients;

      const sourceData = client.readQuery({
        query: getDesignQuery,
        variables: this.designVariables,
      });

      const currentDesign = sourceData.designManagement.designAtVersion.design;
      const prevTodoCount = currentDesign.currentUserTodos?.nodes?.length || 0;

      try {
        await this.$apollo.mutate({
          mutation: toggleResolveDiscussionMutation,
          variables: { id: this.discussion.id, resolve: !this.discussion.resolved },
          update: ({ data }) => {
            if (data.errors?.length > 0) {
              this.$emit('resolve-discussion-error', data.errors[0]);
            }
            const newTodoCount =
              data?.discussionToggleResolve?.discussion?.noteable?.currentUserTodos?.nodes
                ?.length || 0;
            updateGlobalTodoCount(newTodoCount - prevTodoCount);
          },
        });
      } catch (error) {
        this.$emit('resolve-discussion-error', RESOLVE_NOTE_ERROR);
        Sentry.captureException(error);
      } finally {
        this.isResolving = false;
      }
    },
    async showDeleteNoteConfirmationModal(note) {
      const isLast = note?.discussion?.notes?.nodes.length === 1;
      this.noteToDelete = { ...note, isLast };

      const confirmed = await confirmAction(this.$options.i18n.deleteNote.confirmationText, {
        primaryBtnVariant: 'danger',
        primaryBtnText: this.$options.i18n.deleteNote.primaryModalBtnText,
      });

      if (confirmed) {
        await this.deleteNote();
      }
    },
    async deleteNote() {
      const { id, discussion, isLast } = this.noteToDelete;
      try {
        await this.$apollo.mutate({
          mutation: destroyNoteMutation,
          variables: {
            input: {
              id,
            },
          },
          update: (cache, { data }) => {
            const { errors } = data.destroyNote;

            if (errors?.length) {
              this.$emit('delete-note-error', errors[0]);
            }

            const objectToIdentify = isLast
              ? { __typename: TYPENAME_DISCUSSION, id: discussion?.id }
              : { __typename: TYPENAME_NOTE, id };

            cache.modify({
              id: cache.identify(objectToIdentify),
              fields: (_, { DELETE }) => DELETE,
            });
            cache.gc();
          },
          optimisticResponse: {
            destroyNote: {
              note: null,
              errors: [],
              __typename: 'DestroyNotePayload',
            },
          },
        });
      } catch (error) {
        this.$emit('delete-note-error', DELETE_NOTE_ERROR);
        Sentry.captureException(error);
      }
    },
  },
  createNoteMutation,
};
</script>

<template>
  <div class="design-discussion-wrapper" @click="$emit('update-active-discussion')">
    <design-note-pin :is-resolved="discussion.resolved" :label="discussion.index" />
    <ul
      class="design-discussion gl-border gl-relative gl-list-none gl-rounded-base gl-border-section gl-p-0"
      :class="{ 'gl-bg-blue-50': isDiscussionActive }"
      data-testid="design-discussion-content"
    >
      <design-note
        :note="firstNote"
        :markdown-preview-path="markdownPreviewPath"
        :is-resolving="isResolving"
        is-discussion
        :noteable-id="noteableId"
        :design-variables="designVariables"
        @delete-note="showDeleteNoteConfirmationModal($event)"
      >
        <template v-if="$options.isLoggedIn && discussion.resolvable" #resolve-discussion>
          <gl-button
            v-gl-tooltip
            :aria-label="resolveCheckboxText"
            :icon="resolveIconName"
            :title="resolveCheckboxText"
            :loading="isResolving"
            category="tertiary"
            data-testid="resolve-button"
            @click="toggleResolvedStatus"
          />
        </template>
        <template v-if="discussion.resolved" #resolved-status>
          <p class="gl-m-0 gl-mt-5 gl-text-sm gl-text-subtle" data-testid="resolved-message">
            {{ __('Resolved by') }}
            <gl-link
              class="link-inherit-color gl-text-sm gl-text-subtle gl-no-underline"
              :href="discussion.resolvedBy.webUrl"
              target="_blank"
              >{{ discussion.resolvedBy.name }}</gl-link
            >
            <time-ago-tooltip :time="discussion.resolvedAt" tooltip-placement="bottom" />
          </p>
        </template>
      </design-note>
      <toggle-replies-widget
        v-if="isRepliesWidgetVisible"
        :collapsed="areRepliesCollapsed"
        :replies="discussionReplies"
        @toggle="areRepliesCollapsed = !areRepliesCollapsed"
      />
      <design-note
        v-for="note in discussionReplies"
        v-show="areRepliesShown"
        :key="note.id"
        :note="note"
        :markdown-preview-path="markdownPreviewPath"
        :is-resolving="isResolving"
        :noteable-id="noteableId"
        :is-discussion="false"
        :design-variables="designVariables"
        @delete-note="showDeleteNoteConfirmationModal($event)"
      />
      <li
        v-show="isReplyPlaceholderVisible"
        class="reply-wrapper discussion-reply-holder"
        :class="{ 'gl-bg-subtle': !$options.isLoggedIn }"
      >
        <template v-if="!$options.isLoggedIn">
          <design-note-signed-out :register-path="registerPath" :sign-in-path="signInPath" />
        </template>
        <template v-else>
          <discussion-reply-placeholder v-if="!isFormVisible" @focus="showForm" />
          <design-reply-form
            v-else
            :design-note-mutation="$options.createNoteMutation"
            :mutation-variables="mutationVariables"
            :markdown-preview-path="markdownPreviewPath"
            :noteable-id="noteableId"
            :discussion-id="discussion.id"
            :is-discussion="false"
            @note-submit-complete="onSubmitComplete"
            @cancel-form="hideForm"
          >
            <template v-if="discussion.resolvable" #resolve-checkbox>
              <gl-form-checkbox
                v-model="shouldChangeResolvedStatus"
                class="-gl-mb-3 gl-mt-5"
                data-testid="resolve-checkbox"
              >
                {{ resolveCheckboxText }}
              </gl-form-checkbox>
            </template>
          </design-reply-form>
        </template>
      </li>
    </ul>
  </div>
</template>
