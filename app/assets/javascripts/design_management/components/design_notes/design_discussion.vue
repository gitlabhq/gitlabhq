<script>
import { ApolloMutation } from 'vue-apollo';
import { GlTooltipDirective, GlIcon, GlLoadingIcon, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import ReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import allVersionsMixin from '../../mixins/all_versions';
import createNoteMutation from '../../graphql/mutations/createNote.mutation.graphql';
import toggleResolveDiscussionMutation from '../../graphql/mutations/toggle_resolve_discussion.mutation.graphql';
import getDesignQuery from '../../graphql/queries/getDesign.query.graphql';
import activeDiscussionQuery from '../../graphql/queries/active_discussion.query.graphql';
import DesignNote from './design_note.vue';
import DesignReplyForm from './design_reply_form.vue';
import { updateStoreAfterAddDiscussionComment } from '../../utils/cache_update';
import { ACTIVE_DISCUSSION_SOURCE_TYPES } from '../../constants';
import ToggleRepliesWidget from './toggle_replies_widget.vue';

export default {
  components: {
    ApolloMutation,
    DesignNote,
    ReplyPlaceholder,
    DesignReplyForm,
    GlIcon,
    GlLoadingIcon,
    GlLink,
    ToggleRepliesWidget,
    TimeAgoTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [allVersionsMixin],
  props: {
    discussion: {
      type: Object,
      required: true,
    },
    noteableId: {
      type: String,
      required: true,
    },
    designId: {
      type: String,
      required: true,
    },
    markdownPreviewPath: {
      type: String,
      required: false,
      default: '',
    },
    resolvedDiscussionsExpanded: {
      type: Boolean,
      required: true,
    },
    discussionWithOpenForm: {
      type: String,
      required: true,
    },
  },
  apollo: {
    activeDiscussion: {
      query: activeDiscussionQuery,
      result({ data }) {
        const discussionId = data.activeDiscussion.id;
        // We watch any changes to the active discussion from the design pins and scroll to this discussion if it exists
        // We don't want scrollIntoView to be triggered from the discussion click itself
        if (
          this.resolvedDiscussionsExpanded &&
          discussionId &&
          data.activeDiscussion.source === ACTIVE_DISCUSSION_SOURCE_TYPES.pin &&
          discussionId === this.discussion.notes[0].id
        ) {
          this.$el.scrollIntoView({
            behavior: 'smooth',
            inline: 'start',
          });
        }
      },
    },
  },
  data() {
    return {
      discussionComment: '',
      isFormRendered: false,
      activeDiscussion: {},
      isResolving: false,
      shouldChangeResolvedStatus: false,
      areRepliesCollapsed: this.discussion.resolved,
    };
  },
  computed: {
    mutationPayload() {
      return {
        noteableId: this.noteableId,
        body: this.discussionComment,
        discussionId: this.discussion.id,
      };
    },
    designVariables() {
      return {
        fullPath: this.projectPath,
        iid: this.issueIid,
        filenames: [this.$route.params.id],
        atVersion: this.designsVersion,
      };
    },
    isDiscussionHighlighted() {
      return this.discussion.notes[0].id === this.activeDiscussion.id;
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
      return !this.discussion.resolved || !this.areRepliesCollapsed;
    },
    resolveIconName() {
      return this.discussion.resolved ? 'check-circle-filled' : 'check-circle';
    },
    isRepliesWidgetVisible() {
      return this.discussion.resolved && this.discussionReplies.length > 0;
    },
    isReplyPlaceholderVisible() {
      return this.areRepliesShown || !this.discussionReplies.length;
    },
    isFormVisible() {
      return this.isFormRendered && this.discussionWithOpenForm === this.discussion.id;
    },
  },
  methods: {
    addDiscussionComment(
      store,
      {
        data: { createNote },
      },
    ) {
      updateStoreAfterAddDiscussionComment(
        store,
        createNote,
        getDesignQuery,
        this.designVariables,
        this.discussion.id,
      );
    },
    onDone() {
      this.discussionComment = '';
      this.hideForm();
      if (this.shouldChangeResolvedStatus) {
        this.toggleResolvedStatus();
      }
    },
    onCreateNoteError(err) {
      this.$emit('createNoteError', err);
    },
    hideForm() {
      this.isFormRendered = false;
      this.discussionComment = '';
    },
    showForm() {
      this.$emit('openForm', this.discussion.id);
      this.isFormRendered = true;
    },
    toggleResolvedStatus() {
      this.isResolving = true;
      this.$apollo
        .mutate({
          mutation: toggleResolveDiscussionMutation,
          variables: { id: this.discussion.id, resolve: !this.discussion.resolved },
        })
        .then(({ data }) => {
          if (data.errors?.length > 0) {
            this.$emit('resolveDiscussionError', data.errors[0]);
          }
        })
        .catch(err => {
          this.$emit('resolveDiscussionError', err);
        })
        .finally(() => {
          this.isResolving = false;
        });
    },
  },
  createNoteMutation,
};
</script>

<template>
  <div class="design-discussion-wrapper">
    <div
      class="badge badge-pill gl-display-flex gl-align-items-center gl-justify-content-center"
      :class="{ resolved: discussion.resolved }"
      type="button"
    >
      {{ discussion.index }}
    </div>
    <ul
      class="design-discussion bordered-box gl-relative gl-p-0 gl-list-style-none"
      data-qa-selector="design_discussion_content"
    >
      <design-note
        :note="firstNote"
        :markdown-preview-path="markdownPreviewPath"
        :is-resolving="isResolving"
        :class="{ 'gl-bg-blue-50': isDiscussionHighlighted }"
        @error="$emit('updateNoteError', $event)"
      >
        <template v-if="discussion.resolvable" #resolveDiscussion>
          <button
            v-gl-tooltip
            :class="{ 'is-active': discussion.resolved }"
            :title="resolveCheckboxText"
            :aria-label="resolveCheckboxText"
            type="button"
            class="line-resolve-btn note-action-button gl-mr-3"
            data-testid="resolve-button"
            @click.stop="toggleResolvedStatus"
          >
            <gl-icon v-if="!isResolving" :name="resolveIconName" data-testid="resolve-icon" />
            <gl-loading-icon v-else inline />
          </button>
        </template>
        <template v-if="discussion.resolved" #resolvedStatus>
          <p class="gl-text-gray-700 gl-font-sm gl-m-0 gl-mt-5" data-testid="resolved-message">
            {{ __('Resolved by') }}
            <gl-link
              class="gl-text-gray-700 gl-text-decoration-none gl-font-sm link-inherit-color"
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
        :class="{ 'gl-bg-blue-50': isDiscussionHighlighted }"
        @error="$emit('updateNoteError', $event)"
      />
      <li v-show="isReplyPlaceholderVisible" class="reply-wrapper">
        <reply-placeholder
          v-if="!isFormVisible"
          class="qa-discussion-reply"
          :button-text="__('Reply...')"
          @onClick="showForm"
        />
        <apollo-mutation
          v-else
          #default="{ mutate, loading }"
          :mutation="$options.createNoteMutation"
          :variables="{
            input: mutationPayload,
          }"
          :update="addDiscussionComment"
          @done="onDone"
          @error="onCreateNoteError"
        >
          <design-reply-form
            v-model="discussionComment"
            :is-saving="loading"
            :markdown-preview-path="markdownPreviewPath"
            @submitForm="mutate"
            @cancelForm="hideForm"
          >
            <template v-if="discussion.resolvable" #resolveCheckbox>
              <label data-testid="resolve-checkbox">
                <input v-model="shouldChangeResolvedStatus" type="checkbox" />
                {{ resolveCheckboxText }}
              </label>
            </template>
          </design-reply-form>
        </apollo-mutation>
      </li>
    </ul>
  </div>
</template>
