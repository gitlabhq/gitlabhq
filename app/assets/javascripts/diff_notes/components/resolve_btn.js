/* global CommentsStore */
/* global ResolveService */

import $ from 'jquery';
import Vue from 'vue';
import Flash from '../../flash';

const ResolveBtn = Vue.extend({
  props: {
    noteId: Number,
    discussionId: String,
    resolved: Boolean,
    canResolve: Boolean,
    resolvedBy: String,
    authorName: String,
    authorAvatar: String,
    noteTruncated: String,
  },
  data() {
    return {
      discussions: CommentsStore.state,
      loading: false,
    };
  },
  watch: {
    discussions: {
      handler: 'updateTooltip',
      deep: true,
    },
  },
  computed: {
    discussion() {
      return this.discussions[this.discussionId];
    },
    note() {
      return this.discussion ? this.discussion.getNote(this.noteId) : {};
    },
    buttonText() {
      if (this.isResolved) {
        return `Resolved by ${this.resolvedByName}`;
      } else if (this.canResolve) {
        return 'Mark as resolved';
      }

      return 'Unable to resolve';
    },
    isResolved() {
      if (this.note) {
        return this.note.resolved;
      }

      return false;
    },
    resolvedByName() {
      return this.note.resolved_by;
    },
  },
  methods: {
    updateTooltip() {
      this.$nextTick(() => {
        $(this.$refs.button)
          .tooltip('hide')
          .tooltip('_fixTitle');
      });
    },
    resolve() {
      if (!this.canResolve) return;

      let promise;
      this.loading = true;

      if (this.isResolved) {
        promise = ResolveService.unresolve(this.noteId);
      } else {
        promise = ResolveService.resolve(this.noteId);
      }

      promise
        .then(resp => resp.json())
        .then(data => {
          this.loading = false;

          const resolvedBy = data ? data.resolved_by : null;

          CommentsStore.update(
            this.discussionId,
            this.noteId,
            !this.isResolved,
            resolvedBy,
          );
          this.discussion.updateHeadline(data);
          gl.mrWidget.checkStatus();
          this.updateTooltip();
        })
        .catch(
          () =>
            new Flash(
              'An error occurred when trying to resolve a comment. Please try again.',
            ),
        );
    },
  },
  mounted() {
    $(this.$refs.button).tooltip({
      container: 'body',
    });
  },
  beforeDestroy() {
    CommentsStore.delete(this.discussionId, this.noteId);
  },
  created() {
    CommentsStore.create({
      discussionId: this.discussionId,
      noteId: this.noteId,
      canResolve: this.canResolve,
      resolved: this.resolved,
      resolvedBy: this.resolvedBy,
      authorName: this.authorName,
      authorAvatar: this.authorAvatar,
      noteTruncated: this.noteTruncated,
    });
  },
});

Vue.component('resolve-btn', ResolveBtn);
