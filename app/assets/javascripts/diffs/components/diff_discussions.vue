<script>
import { mapActions } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import noteableDiscussion from '../../notes/components/noteable_discussion.vue';

export default {
  components: {
    noteableDiscussion,
    Icon,
  },
  props: {
    discussions: {
      type: Array,
      required: true,
    },
    line: {
      type: Object,
      required: false,
      default: null,
    },
    shouldCollapseDiscussions: {
      type: Boolean,
      required: false,
      default: false,
    },
    renderAvatarBadge: {
      type: Boolean,
      required: false,
      default: false,
    },
    helpPagePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  methods: {
    ...mapActions(['toggleDiscussion']),
    ...mapActions('diffs', ['removeDiscussionsFromDiff']),
    deleteNoteHandler(discussion) {
      if (discussion.notes.length <= 1) {
        this.removeDiscussionsFromDiff(discussion);
      }
    },
    isExpanded(discussion) {
      return this.shouldCollapseDiscussions ? discussion.expanded : true;
    },
  },
};
</script>

<template>
  <div>
    <div
      v-for="(discussion, index) in discussions"
      :key="discussion.id"
      :class="{
        collapsed: !isExpanded(discussion),
      }"
      class="discussion-notes diff-discussions position-relative"
    >
      <ul :data-discussion-id="discussion.id" class="notes">
        <template v-if="shouldCollapseDiscussions">
          <button
            :class="{
              'diff-notes-collapse': discussion.expanded,
              'btn-transparent badge badge-pill': !discussion.expanded,
            }"
            type="button"
            class="js-diff-notes-toggle"
            @click="toggleDiscussion({ discussionId: discussion.id })"
          >
            <icon v-if="discussion.expanded" name="collapse" class="collapse-icon" />
            <template v-else>
              {{ index + 1 }}
            </template>
          </button>
        </template>
        <noteable-discussion
          v-show="isExpanded(discussion)"
          :discussion="discussion"
          :render-diff-file="false"
          :discussions-by-diff-order="true"
          :line="line"
          :help-page-path="helpPagePath"
          @noteDeleted="deleteNoteHandler"
        >
          <span v-if="renderAvatarBadge" slot="avatar-badge" class="badge badge-pill">
            {{ index + 1 }}
          </span>
        </noteable-discussion>
      </ul>
    </div>
  </div>
</template>
