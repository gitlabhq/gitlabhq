<script>
import _ from 'underscore';
import { mapActions, mapGetters } from 'vuex';
import { GlTooltipDirective } from '@gitlab/ui';
import { truncateSha } from '~/lib/utils/text_utility';
import { s__, __, sprintf } from '~/locale';
import systemNote from '~/vue_shared/components/notes/system_note.vue';
import icon from '~/vue_shared/components/icon.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import Flash from '../../flash';
import { SYSTEM_NOTE } from '../constants';
import userAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import noteableNote from './noteable_note.vue';
import noteHeader from './note_header.vue';
import toggleRepliesWidget from './toggle_replies_widget.vue';
import noteSignedOutWidget from './note_signed_out_widget.vue';
import noteEditedText from './note_edited_text.vue';
import noteForm from './note_form.vue';
import diffWithNote from './diff_with_note.vue';
import placeholderNote from '../../vue_shared/components/notes/placeholder_note.vue';
import placeholderSystemNote from '../../vue_shared/components/notes/placeholder_system_note.vue';
import autosave from '../mixins/autosave';
import noteable from '../mixins/noteable';
import resolvable from '../mixins/resolvable';
import discussionNavigation from '../mixins/discussion_navigation';

export default {
  name: 'NoteableDiscussion',
  components: {
    icon,
    noteableNote,
    userAvatarLink,
    noteHeader,
    noteSignedOutWidget,
    noteEditedText,
    noteForm,
    toggleRepliesWidget,
    placeholderNote,
    placeholderSystemNote,
    systemNote,
    TimelineEntryItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [autosave, noteable, resolvable, discussionNavigation],
  props: {
    discussion: {
      type: Object,
      required: true,
    },
    line: {
      type: Object,
      required: false,
      default: null,
    },
    renderDiffFile: {
      type: Boolean,
      required: false,
      default: true,
    },
    alwaysExpanded: {
      type: Boolean,
      required: false,
      default: false,
    },
    discussionsByDiffOrder: {
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
  data() {
    const { diff_discussion: isDiffDiscussion, resolved } = this.discussion;

    return {
      isReplying: false,
      isResolving: false,
      resolveAsThread: true,
      isRepliesCollapsed: Boolean(!isDiffDiscussion && resolved),
    };
  },
  computed: {
    ...mapGetters([
      'getNoteableData',
      'nextUnresolvedDiscussionId',
      'unresolvedDiscussionsCount',
      'hasUnresolvedDiscussions',
      'showJumpToNextDiscussion',
    ]),
    author() {
      return this.initialDiscussion.author;
    },
    canReply() {
      return this.getNoteableData.current_user.can_create_note;
    },
    newNotePath() {
      return this.getNoteableData.create_note_path;
    },
    hasReplies() {
      return this.discussion.notes.length > 1;
    },
    initialDiscussion() {
      return this.discussion.notes.slice(0, 1)[0];
    },
    replies() {
      return this.discussion.notes.slice(1);
    },
    lastUpdatedBy() {
      const { notes } = this.discussion;

      if (notes.length > 1) {
        return notes[notes.length - 1].author;
      }

      return null;
    },
    lastUpdatedAt() {
      const { notes } = this.discussion;

      if (notes.length > 1) {
        return notes[notes.length - 1].created_at;
      }

      return null;
    },
    resolvedText() {
      return this.discussion.resolved_by_push ? __('Automatically resolved') : __('Resolved');
    },
    shouldShowJumpToNextDiscussion() {
      return this.showJumpToNextDiscussion(
        this.discussion.id,
        this.discussionsByDiffOrder ? 'diff' : 'discussion',
      );
    },
    shouldRenderDiffs() {
      return this.discussion.diff_discussion && this.renderDiffFile;
    },
    shouldGroupReplies() {
      return !this.shouldRenderDiffs && !this.discussion.diff_discussion;
    },
    wrapperComponent() {
      return this.shouldRenderDiffs ? diffWithNote : 'div';
    },
    wrapperComponentProps() {
      if (this.shouldRenderDiffs) {
        return { discussion: this.discussion };
      }

      return {};
    },
    componentClassName() {
      if (this.shouldRenderDiffs) {
        if (!this.lastUpdatedAt && !this.discussion.resolved) {
          return 'unresolved';
        }
      }

      return '';
    },
    shouldShowDiscussions() {
      const { expanded, resolved } = this.discussion;
      const isResolvedNonDiffDiscussion = !this.discussion.diff_discussion && resolved;

      return expanded || this.alwaysExpanded || isResolvedNonDiffDiscussion;
    },
    actionText() {
      const linkStart = `<a href="${_.escape(this.discussion.discussion_path)}">`;
      const linkEnd = '</a>';

      let { commit_id: commitId } = this.discussion;
      if (commitId) {
        commitId = `<span class="commit-sha">${truncateSha(commitId)}</span>`;
      }

      const {
        for_commit: isForCommit,
        diff_discussion: isDiffDiscussion,
        active: isActive,
      } = this.discussion;

      let text = s__('MergeRequests|started a discussion');
      if (isForCommit) {
        text = s__(
          'MergeRequests|started a discussion on commit %{linkStart}%{commitId}%{linkEnd}',
        );
      } else if (isDiffDiscussion && commitId) {
        text = isActive
          ? s__('MergeRequests|started a discussion on commit %{linkStart}%{commitId}%{linkEnd}')
          : s__(
              'MergeRequests|started a discussion on an outdated change in commit %{linkStart}%{commitId}%{linkEnd}',
            );
      } else if (isDiffDiscussion) {
        text = isActive
          ? s__('MergeRequests|started a discussion on %{linkStart}the diff%{linkEnd}')
          : s__(
              'MergeRequests|started a discussion on %{linkStart}an old version of the diff%{linkEnd}',
            );
      }

      return sprintf(text, { commitId, linkStart, linkEnd }, false);
    },
    diffLine() {
      if (this.discussion.diff_discussion && this.discussion.truncated_diff_lines) {
        return this.discussion.truncated_diff_lines.slice(-1)[0];
      }

      return this.line;
    },
  },
  watch: {
    isReplying() {
      if (this.isReplying) {
        this.$nextTick(() => {
          // Pass an extra key to separate reply and note edit forms
          this.initAutoSave({ ...this.initialDiscussion, ...this.discussion }, ['Reply']);
        });
      } else {
        this.disposeAutoSave();
      }
    },
  },
  methods: {
    ...mapActions([
      'saveNote',
      'toggleDiscussion',
      'removePlaceholderNotes',
      'toggleResolveNote',
      'expandDiscussion',
    ]),
    truncateSha,
    componentName(note) {
      if (note.isPlaceholderNote) {
        if (note.placeholderType === SYSTEM_NOTE) {
          return placeholderSystemNote;
        }

        return placeholderNote;
      }

      if (note.system) {
        return systemNote;
      }

      return noteableNote;
    },
    componentData(note) {
      return note.isPlaceholderNote ? note.notes[0] : note;
    },
    toggleDiscussionHandler() {
      this.toggleDiscussion({ discussionId: this.discussion.id });
    },
    toggleReplies() {
      this.isRepliesCollapsed = !this.isRepliesCollapsed;
    },
    showReplyForm() {
      this.isReplying = true;
    },
    cancelReplyForm(shouldConfirm, isDirty) {
      if (shouldConfirm && isDirty) {
        const msg = s__('Notes|Are you sure you want to cancel creating this comment?');

        // eslint-disable-next-line no-alert
        if (!window.confirm(msg)) {
          return;
        }
      }

      this.isReplying = false;
      this.resetAutoSave();
    },
    saveReply(noteText, form, callback) {
      const postData = {
        in_reply_to_discussion_id: this.discussion.reply_id,
        target_type: this.getNoteableData.targetType,
        note: { note: noteText },
      };

      if (this.discussion.for_commit) {
        postData.note_project_id = this.discussion.project_id;
      }

      const replyData = {
        endpoint: this.newNotePath,
        flashContainer: this.$el,
        data: postData,
      };

      this.isReplying = false;
      this.saveNote(replyData)
        .then(() => {
          this.resetAutoSave();
          callback();
        })
        .catch(err => {
          this.removePlaceholderNotes();
          this.isReplying = true;
          this.$nextTick(() => {
            const msg = `Your comment could not be submitted!
Please check your network connection and try again.`;
            Flash(msg, 'alert', this.$el);
            this.$refs.noteForm.note = noteText;
            callback(err);
          });
        });
    },
    jumpToNextDiscussion() {
      const nextId = this.nextUnresolvedDiscussionId(
        this.discussion.id,
        this.discussionsByDiffOrder,
      );

      this.jumpToDiscussion(nextId);
    },
    deleteNoteHandler(note) {
      this.$emit('noteDeleted', this.discussion, note);
    },
  },
};
</script>

<template>
  <timeline-entry-item class="note note-discussion" :class="componentClassName">
    <div class="timeline-content">
      <div :data-discussion-id="discussion.id" class="discussion js-discussion-container">
        <div v-if="shouldRenderDiffs" class="discussion-header note-wrapper">
          <div v-once class="timeline-icon">
            <user-avatar-link
              v-if="author"
              :link-href="author.path"
              :img-src="author.avatar_url"
              :img-alt="author.name"
              :img-size="40"
            />
          </div>
          <note-header
            :author="author"
            :created-at="initialDiscussion.created_at"
            :note-id="initialDiscussion.id"
            :include-toggle="true"
            :expanded="discussion.expanded"
            @toggleHandler="toggleDiscussionHandler"
          >
            <span v-html="actionText"></span>
          </note-header>
          <note-edited-text
            v-if="discussion.resolved"
            :edited-at="discussion.resolved_at"
            :edited-by="discussion.resolved_by"
            :action-text="resolvedText"
            class-name="discussion-headline-light js-discussion-headline"
          />
          <note-edited-text
            v-else-if="lastUpdatedAt"
            :edited-at="lastUpdatedAt"
            :edited-by="lastUpdatedBy"
            action-text="Last updated"
            class-name="discussion-headline-light js-discussion-headline"
          />
        </div>
        <div v-if="shouldShowDiscussions" class="discussion-body">
          <component
            :is="wrapperComponent"
            v-bind="wrapperComponentProps"
            class="card discussion-wrapper"
          >
            <div class="discussion-notes">
              <ul class="notes">
                <template v-if="shouldGroupReplies">
                  <component
                    :is="componentName(initialDiscussion)"
                    :note="componentData(initialDiscussion)"
                    :line="line"
                    :help-page-path="helpPagePath"
                    @handleDeleteNote="deleteNoteHandler"
                  >
                    <note-edited-text
                      v-if="discussion.resolved"
                      slot="discussion-resolved-text"
                      :edited-at="discussion.resolved_at"
                      :edited-by="discussion.resolved_by"
                      :action-text="resolvedText"
                      class-name="discussion-headline-light js-discussion-headline discussion-resolved-text"
                    />
                    <slot slot="avatar-badge" name="avatar-badge"></slot>
                  </component>
                  <toggle-replies-widget
                    v-if="hasReplies"
                    :collapsed="isRepliesCollapsed"
                    :replies="replies"
                    @toggle="toggleReplies"
                  />
                  <template v-if="!isRepliesCollapsed">
                    <component
                      :is="componentName(note)"
                      v-for="note in replies"
                      :key="note.id"
                      :note="componentData(note)"
                      :help-page-path="helpPagePath"
                      :line="line"
                      @handleDeleteNote="deleteNoteHandler"
                    />
                  </template>
                </template>
                <template v-else>
                  <component
                    :is="componentName(note)"
                    v-for="(note, index) in discussion.notes"
                    :key="note.id"
                    :note="componentData(note)"
                    :help-page-path="helpPagePath"
                    :line="diffLine"
                    @handleDeleteNote="deleteNoteHandler"
                  >
                    <slot v-if="index === 0" slot="avatar-badge" name="avatar-badge"></slot>
                  </component>
                </template>
              </ul>
              <div
                v-if="!isRepliesCollapsed || !hasReplies"
                :class="{ 'is-replying': isReplying }"
                class="discussion-reply-holder"
              >
                <template v-if="!isReplying && canReply">
                  <div class="discussion-with-resolve-btn">
                    <button
                      type="button"
                      class="js-vue-discussion-reply btn btn-text-field qa-discussion-reply"
                      title="Add a reply"
                      @click="showReplyForm"
                    >
                      Reply...
                    </button>
                    <div v-if="discussion.resolvable">
                      <button
                        type="button"
                        class="btn btn-default ml-sm-2"
                        @click="resolveHandler();"
                      >
                        <i v-if="isResolving" aria-hidden="true" class="fa fa-spinner fa-spin"></i>
                        {{ resolveButtonTitle }}
                      </button>
                    </div>
                    <div
                      v-if="discussion.resolvable"
                      class="btn-group discussion-actions ml-sm-2"
                      role="group"
                    >
                      <div v-if="!discussionResolved" class="btn-group" role="group">
                        <a
                          v-gl-tooltip
                          :href="discussion.resolve_with_issue_path"
                          :title="s__('MergeRequests|Resolve this discussion in a new issue')"
                          class="new-issue-for-discussion btn btn-default discussion-create-issue-btn"
                        >
                          <icon name="issue-new" />
                        </a>
                      </div>
                      <div v-if="shouldShowJumpToNextDiscussion" class="btn-group" role="group">
                        <button
                          v-gl-tooltip
                          class="btn btn-default discussion-next-btn"
                          title="Jump to next unresolved discussion"
                          @click="jumpToNextDiscussion"
                        >
                          <icon name="comment-next" />
                        </button>
                      </div>
                    </div>
                  </div>
                </template>
                <note-form
                  v-if="isReplying"
                  ref="noteForm"
                  :discussion="discussion"
                  :is-editing="false"
                  :line="diffLine"
                  save-button-title="Comment"
                  @handleFormUpdate="saveReply"
                  @cancelForm="cancelReplyForm"
                />
                <note-signed-out-widget v-if="!canReply" />
              </div>
            </div>
          </component>
        </div>
      </div>
    </div>
  </timeline-entry-item>
</template>
