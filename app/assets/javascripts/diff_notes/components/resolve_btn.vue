<script>
  import tooltip from '../../vue_shared/directives/tooltip';
  import statusSuccessSvg from '../icons/status_success.svg';

  export default {
    directives: {
      tooltip,
    },
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
    computed: {
      discussion() {
        return this.discussions[this.discussionId];
      },
      note() {
        return this.discussion ? this.discussion.getNote(this.noteId) : {};
      },
      buttonText() {
        if (this.isResolved) {
          return `Resolved by ${this.note.resolved_by}`;
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
    },
    methods: {
      resolve() {
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
          })
          .catch(() => new Flash('An error occurred when trying to resolve a comment. Please try again.'));
      }
    },
    beforeDestroy() {
      CommentsStore.delete(this.discussionId, this.noteId);
    },
    created() {
      this.statusSuccessSvg = statusSuccessSvg;

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
  };
</script>

<template>
  <button v-tooltip
    data-container="body"
    class="note-action-button line-resolve-btn"
    type="button"
    :class="{ 'is-active': isResolved, 'is-disabled': !canResolve }"
    :aria-label="buttonText"
    :title="buttonText"
    v-show="canResolve || resolved"
    @click="resolve">
    <i class="fa fa-spin fa-spinner loading"
      v-if="loading"
      aria-hidden="true"
      aria-label="Loading">
    </i>
    <span v-html="statusSuccessSvg"
      v-else>
    </span>
  </button>
</template>
