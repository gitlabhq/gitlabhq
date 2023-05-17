<script>
import { GlAccordion, GlAccordionItem, GlSkeletonLoader } from '@gitlab/ui';
import { isLoggedIn } from '~/lib/utils/common_utils';

import { s__ } from '~/locale';
import Participants from '~/sidebar/components/participants/participants.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { ACTIVE_DISCUSSION_SOURCE_TYPES } from '../constants';
import updateActiveDiscussionMutation from '../graphql/mutations/update_active_discussion.mutation.graphql';
import { extractDiscussions, extractParticipants } from '../utils/design_management_utils';
import DesignDiscussion from './design_notes/design_discussion.vue';
import DesignNoteSignedOut from './design_notes/design_note_signed_out.vue';
import DesignTodoButton from './design_todo_button.vue';

export default {
  components: {
    DesignDiscussion,
    DesignNoteSignedOut,
    Participants,
    GlAccordion,
    GlAccordionItem,
    GlSkeletonLoader,
    DesignTodoButton,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    projectPath: {
      default: '',
    },
    issueIid: {
      default: '',
    },
    registerPath: {
      default: '',
    },
    signInPath: {
      default: '',
    },
  },
  props: {
    design: {
      type: Object,
      required: true,
    },
    resolvedDiscussionsExpanded: {
      type: Boolean,
      required: true,
    },
    markdownPreviewPath: {
      type: String,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      discussionWithOpenForm: '',
      isLoggedIn: isLoggedIn(),
    };
  },
  computed: {
    discussions() {
      return extractDiscussions(this.design.discussions);
    },
    issue() {
      return {
        ...this.design.issue,
        webPath: this.design.issue?.webPath.substr(1),
      };
    },
    discussionParticipants() {
      return extractParticipants(this.issue.participants?.nodes || []);
    },
    resolvedDiscussions() {
      return this.discussions.filter((discussion) => discussion.resolved);
    },
    hasResolvedDiscussions() {
      return this.resolvedDiscussions.length > 0;
    },
    resolvedDiscussionsTitle() {
      return `${this.$options.i18n.resolveCommentsToggleText} (${this.resolvedDiscussions.length})`;
    },
    unresolvedDiscussions() {
      return this.discussions.filter((discussion) => !discussion.resolved);
    },
    isResolvedDiscussionsExpanded: {
      get() {
        return this.resolvedDiscussionsExpanded;
      },
      set(isExpanded) {
        this.$emit('toggleResolvedComments', isExpanded);
      },
    },
  },
  mounted() {
    if (!this.isResolvedCommentsPopoverHidden && this.$refs.resolvedComments) {
      this.$refs.resolvedComments.$el.scrollIntoView();
    }
  },
  methods: {
    handleSidebarClick() {
      this.updateActiveDiscussion();
    },
    updateActiveDiscussion(id) {
      this.$apollo.mutate({
        mutation: updateActiveDiscussionMutation,
        variables: {
          id,
          source: ACTIVE_DISCUSSION_SOURCE_TYPES.discussion,
        },
      });
    },
    closeCommentForm() {
      this.comment = '';
      this.$emit('closeCommentForm');
    },
    updateDiscussionWithOpenForm(id) {
      this.discussionWithOpenForm = id;
    },
  },
  i18n: {
    resolveCommentsToggleText: s__('DesignManagement|Resolved Comments'),
  },
};
</script>

<template>
  <div class="image-notes gl-pt-0" @click.self="handleSidebarClick">
    <div
      class="gl-py-4 gl-mb-4 gl-display-flex gl-justify-content-space-between gl-align-items-center gl-border-b-1 gl-border-b-solid gl-border-b-gray-100"
    >
      <span>{{ __('To Do') }}</span>
      <design-todo-button :design="design" @error="$emit('todoError', $event)" />
    </div>
    <h2 class="gl-font-weight-bold gl-mt-0">
      {{ issue.title }}
    </h2>
    <a
      class="gl-text-gray-400 gl-text-decoration-none gl-mb-6 gl-display-block"
      :href="issue.webUrl"
      >{{ issue.webPath }}</a
    >
    <participants
      :participants="discussionParticipants"
      :show-participant-label="false"
      class="gl-mb-4"
    />
    <gl-skeleton-loader v-if="isLoading" />
    <template v-else>
      <h2
        v-if="isLoggedIn && unresolvedDiscussions.length === 0"
        class="new-discussion-disclaimer gl-font-base gl-m-0 gl-mb-4"
        data-testid="new-discussion-disclaimer"
      >
        {{ s__("DesignManagement|Click the image where you'd like to start a new discussion") }}
      </h2>
      <design-note-signed-out
        v-if="!isLoggedIn"
        class="gl-mb-4"
        :register-path="registerPath"
        :sign-in-path="signInPath"
        :is-add-discussion="true"
      />
      <design-discussion
        v-for="discussion in unresolvedDiscussions"
        :key="discussion.id"
        :discussion="discussion"
        :design-id="$route.params.id"
        :noteable-id="design.id"
        :markdown-preview-path="markdownPreviewPath"
        :register-path="registerPath"
        :sign-in-path="signInPath"
        :resolved-discussions-expanded="resolvedDiscussionsExpanded"
        :discussion-with-open-form="discussionWithOpenForm"
        data-testid="unresolved-discussion"
        @create-note-error="$emit('onDesignDiscussionError', $event)"
        @update-note-error="$emit('updateNoteError', $event)"
        @delete-note-error="$emit('deleteNoteError', $event)"
        @resolve-discussion-error="$emit('resolveDiscussionError', $event)"
        @update-active-discussion="updateActiveDiscussion(discussion.notes[0].id)"
        @open-form="updateDiscussionWithOpenForm"
      />
      <gl-accordion v-if="hasResolvedDiscussions" :header-level="3" class="gl-mb-5">
        <gl-accordion-item
          v-model="isResolvedDiscussionsExpanded"
          :title="resolvedDiscussionsTitle"
          header-class="gl-mb-5!"
        >
          <design-discussion
            v-for="discussion in resolvedDiscussions"
            :key="discussion.id"
            :discussion="discussion"
            :design-id="$route.params.id"
            :noteable-id="design.id"
            :markdown-preview-path="markdownPreviewPath"
            :register-path="registerPath"
            :sign-in-path="signInPath"
            :resolved-discussions-expanded="resolvedDiscussionsExpanded"
            :discussion-with-open-form="discussionWithOpenForm"
            data-testid="resolved-discussion"
            @error="$emit('onDesignDiscussionError', $event)"
            @update-note-error="$emit('updateNoteError', $event)"
            @delete-note-error="$emit('deleteNoteError', $event)"
            @open-form="updateDiscussionWithOpenForm"
            @update-active-discussion="updateActiveDiscussion(discussion.notes[0].id)"
          />
        </gl-accordion-item>
      </gl-accordion>
      <slot name="reply-form"></slot>
    </template>
  </div>
</template>
