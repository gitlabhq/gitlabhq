<script>
  /* eslint-disable comma-dangle, object-shorthand, func-names, quote-props, no-else-return, camelcase, max-len */
  /* global CommentsStore */
  /* global ResolveService */

  import Vue from 'vue';
  import Flash from '~/flash';
  import Icon from '~/vue_shared/components/icon.vue';
  import LoadingIcon from '~/vue_shared/components/loading_icon.vue';

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
    components: {
      Icon,
      LoadingIcon,
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
      buttonClass() {
        return {
          'is-active': this.isResolved,
        };
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
            .tooltip('fixTitle');
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
  export default ResolveBtn;
</script>

<template>
  <div class="note-actions-item">
    <button
      class="note-action-button line-resolve-btn"
      type="button"
      :class="buttonClass"
      :aria-label="buttonText"
      :title="buttonText"
      @click="resolve"
      ref="button"
    >
      <loading-icon
        v-if="loading"
      />
      <icon
          v-else-if="isResolved"
          name="status_success_solid"
      />
      <icon
        v-else
        name="resolve_discussion"
      />
    </button>
  </div>
</template>
