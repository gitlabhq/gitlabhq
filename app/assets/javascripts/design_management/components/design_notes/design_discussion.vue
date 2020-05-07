<script>
import { ApolloMutation } from 'vue-apollo';
import ReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import allVersionsMixin from '../../mixins/all_versions';
import createNoteMutation from '../../graphql/mutations/createNote.mutation.graphql';
import getDesignQuery from '../../graphql/queries/getDesign.query.graphql';
import DesignNote from './design_note.vue';
import DesignReplyForm from './design_reply_form.vue';
import { updateStoreAfterAddDiscussionComment } from '../../utils/cache_update';

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
  data() {
    return {
      discussionComment: '',
      isFormRendered: false,
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
      <design-note v-for="note in discussion.notes" :key="note.id" :note="note" />
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
