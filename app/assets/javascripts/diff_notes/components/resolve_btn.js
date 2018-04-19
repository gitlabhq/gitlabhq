/* eslint-disable comma-dangle, object-shorthand, func-names, quote-props, no-else-return, camelcase, max-len */
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
  data: function () {
    return {
      discussions: CommentsStore.state,
      loading: false
    };
  },
  watch: {
    'discussions': {
      handler: 'updateTooltip',
      deep: true
    }
  },
  computed: {
    discussion: function () {
      return this.discussions[this.discussionId];
    },
    note: function () {
      return this.discussion ? this.discussion.getNote(this.noteId) : {};
    },
    buttonText: function () {
      if (this.isResolved) {
        return `Resolved by ${this.resolvedByName}`;
      } else if (this.canResolve) {
        return 'Mark as resolved';
      } else {
        return 'Unable to resolve';
      }
    },
    isResolved: function () {
      if (this.note) {
        return this.note.resolved;
      } else {
        return false;
      }
    },
    resolvedByName: function () {
      return this.note.resolved_by;
    },
  },
  methods: {
    updateTooltip: function () {
      this.$nextTick(() => {
        $(this.$refs.button)
          .tooltip('hide')
          .tooltip('_fixTitle');
      });
    },
    resolve: function () {
      if (!this.canResolve) return;

      let promise;
      this.loading = true;

      if (this.isResolved) {
        promise = ResolveService
          .unresolve(this.noteId);
      } else {
        promise = ResolveService
          .resolve(this.noteId);
      }

      promise
        .then(resp => resp.json())
        .then((data) => {
          this.loading = false;

          const resolved_by = data ? data.resolved_by : null;

          CommentsStore.update(this.discussionId, this.noteId, !this.isResolved, resolved_by);
          this.discussion.updateHeadline(data);
          gl.mrWidget.checkStatus();
          document.dispatchEvent(new CustomEvent('refreshVueNotes'));

          this.updateTooltip();
        })
        .catch(() => new Flash('An error occurred when trying to resolve a comment. Please try again.'));
    }
  },
  mounted: function () {
    $(this.$refs.button).tooltip({
      container: 'body'
    });
  },
  beforeDestroy: function () {
    CommentsStore.delete(this.discussionId, this.noteId);
  },
  created: function () {
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
  }
});

Vue.component('resolve-btn', ResolveBtn);
