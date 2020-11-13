<script>
import Cookies from 'js-cookie';
import { GlCollapse, GlButton, GlPopover } from '@gitlab/ui';
import { s__ } from '~/locale';
import { parseBoolean } from '~/lib/utils/common_utils';
import updateActiveDiscussionMutation from '../graphql/mutations/update_active_discussion.mutation.graphql';
import { extractDiscussions, extractParticipants } from '../utils/design_management_utils';
import { ACTIVE_DISCUSSION_SOURCE_TYPES } from '../constants';
import DesignDiscussion from './design_notes/design_discussion.vue';
import Participants from '~/sidebar/components/participants/participants.vue';
import DesignTodoButton from './design_todo_button.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    DesignDiscussion,
    Participants,
    GlCollapse,
    GlButton,
    GlPopover,
    DesignTodoButton,
  },
  mixins: [glFeatureFlagsMixin()],
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
  },
  data() {
    return {
      isResolvedCommentsPopoverHidden: parseBoolean(Cookies.get(this.$options.cookieKey)),
      discussionWithOpenForm: '',
    };
  },
  inject: {
    projectPath: {
      default: '',
    },
    issueIid: {
      default: '',
    },
  },
  computed: {
    discussions() {
      return extractDiscussions(this.design.discussions);
    },
    issue() {
      return {
        ...this.design.issue,
        webPath: this.design.issue.webPath.substr(1),
      };
    },
    discussionParticipants() {
      return extractParticipants(this.issue.participants.nodes);
    },
    resolvedDiscussions() {
      return this.discussions.filter(discussion => discussion.resolved);
    },
    unresolvedDiscussions() {
      return this.discussions.filter(discussion => !discussion.resolved);
    },
    resolvedCommentsToggleIcon() {
      return this.resolvedDiscussionsExpanded ? 'chevron-down' : 'chevron-right';
    },
  },
  watch: {
    isResolvedCommentsPopoverHidden(newVal) {
      if (!newVal) {
        this.$refs.resolvedComments.scrollIntoView();
      }
    },
  },
  mounted() {
    if (!this.isResolvedCommentsPopoverHidden && this.$refs.resolvedComments) {
      this.$refs.resolvedComments.$el.scrollIntoView();
    }
  },
  methods: {
    handleSidebarClick() {
      this.isResolvedCommentsPopoverHidden = true;
      Cookies.set(this.$options.cookieKey, 'true', { expires: 365 * 10 });
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
  resolveCommentsToggleText: s__('DesignManagement|Resolved Comments'),
  cookieKey: 'hide_design_resolved_comments_popover',
};
</script>

<template>
  <div class="image-notes gl-pt-0" @click="handleSidebarClick">
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
    <h2
      v-if="unresolvedDiscussions.length === 0"
      class="new-discussion-disclaimer gl-font-base gl-m-0 gl-mb-4"
      data-testid="new-discussion-disclaimer"
    >
      {{ s__("DesignManagement|Click the image where you'd like to start a new discussion") }}
    </h2>
    <design-discussion
      v-for="discussion in unresolvedDiscussions"
      :key="discussion.id"
      :discussion="discussion"
      :design-id="$route.params.id"
      :noteable-id="design.id"
      :markdown-preview-path="markdownPreviewPath"
      :resolved-discussions-expanded="resolvedDiscussionsExpanded"
      :discussion-with-open-form="discussionWithOpenForm"
      data-testid="unresolved-discussion"
      @create-note-error="$emit('onDesignDiscussionError', $event)"
      @update-note-error="$emit('updateNoteError', $event)"
      @resolve-discussion-error="$emit('resolveDiscussionError', $event)"
      @click.native.stop="updateActiveDiscussion(discussion.notes[0].id)"
      @open-form="updateDiscussionWithOpenForm"
    />
    <template v-if="resolvedDiscussions.length > 0">
      <gl-button
        id="resolved-comments"
        ref="resolvedComments"
        data-testid="resolved-comments"
        :icon="resolvedCommentsToggleIcon"
        variant="link"
        class="link-inherit-color gl-text-body gl-text-decoration-none gl-font-weight-bold gl-mb-4"
        @click="$emit('toggleResolvedComments')"
        >{{ $options.resolveCommentsToggleText }} ({{ resolvedDiscussions.length }})
      </gl-button>
      <gl-popover
        v-if="!isResolvedCommentsPopoverHidden"
        :show="!isResolvedCommentsPopoverHidden"
        target="resolved-comments"
        container="popovercontainer"
        placement="top"
        :title="s__('DesignManagement|Resolved Comments')"
      >
        <p>
          {{
            s__(
              'DesignManagement|Comments you resolve can be viewed and unresolved by going to the "Resolved Comments" section below',
            )
          }}
        </p>
        <a
          href="https://docs.gitlab.com/ee/user/project/issues/design_management.html#resolve-design-threads"
          rel="noopener noreferrer"
          target="_blank"
          >{{ s__('DesignManagement|Learn more about resolving comments') }}</a
        >
      </gl-popover>
      <gl-collapse :visible="resolvedDiscussionsExpanded" class="gl-mt-3">
        <design-discussion
          v-for="discussion in resolvedDiscussions"
          :key="discussion.id"
          :discussion="discussion"
          :design-id="$route.params.id"
          :noteable-id="design.id"
          :markdown-preview-path="markdownPreviewPath"
          :resolved-discussions-expanded="resolvedDiscussionsExpanded"
          :discussion-with-open-form="discussionWithOpenForm"
          data-testid="resolved-discussion"
          @error="$emit('onDesignDiscussionError', $event)"
          @updateNoteError="$emit('updateNoteError', $event)"
          @openForm="updateDiscussionWithOpenForm"
          @click.native.stop="updateActiveDiscussion(discussion.notes[0].id)"
        />
      </gl-collapse>
    </template>
    <slot name="reply-form"></slot>
  </div>
</template>
