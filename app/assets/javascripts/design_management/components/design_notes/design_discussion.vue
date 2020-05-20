<script>
import { ApolloMutation } from 'vue-apollo';
import ReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import allVersionsMixin from '../../mixins/all_versions';
import createNoteMutation from '../../graphql/mutations/createNote.mutation.graphql';
import getDesignQuery from '../../graphql/queries/getDesign.query.graphql';
import activeDiscussionQuery from '../../graphql/queries/active_discussion.query.graphql';
import DesignNote from './design_note.vue';
import DesignReplyForm from './design_reply_form.vue';
import { updateStoreAfterAddDiscussionComment } from '../../utils/cache_update';
import { ACTIVE_DISCUSSION_SOURCE_TYPES } from '../../constants';

export default {
  components: {
    ApolloMutation,
    DesignNote,
    ReplyPlaceholder,
    DesignReplyForm,
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
    discussionIndex: {
      type: Number,
      required: true,
    },
    markdownPreviewPath: {
      type: String,
      required: false,
      default: '',
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
    },
    onError(err) {
      this.$emit('error', err);
    },
    hideForm() {
      this.isFormRendered = false;
      this.discussionComment = '';
    },
    showForm() {
      this.isFormRendered = true;
    },
  },
  createNoteMutation,
};
</script>

<template>
  <div class="design-discussion-wrapper">
    <div class="badge badge-pill" type="button">{{ discussionIndex }}</div>
    <div
      class="design-discussion bordered-box position-relative"
      data-qa-selector="design_discussion_content"
    >
      <design-note
        v-for="note in discussion.notes"
        :key="note.id"
        :note="note"
        :markdown-preview-path="markdownPreviewPath"
        :class="{ 'gl-bg-blue-50': isDiscussionHighlighted }"
        @error="$emit('updateNoteError', $event)"
      />
      <div class="reply-wrapper">
        <reply-placeholder
          v-if="!isFormRendered"
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
          @error="onError"
        >
          <design-reply-form
            v-model="discussionComment"
            :is-saving="loading"
            :markdown-preview-path="markdownPreviewPath"
            @submitForm="mutate"
            @cancelForm="hideForm"
          />
        </apollo-mutation>
      </div>
    </div>
  </div>
</template>
