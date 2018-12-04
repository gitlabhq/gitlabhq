<script>
import { mapActions, mapGetters } from 'vuex';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { truncateSha } from '~/lib/utils/text_utility';
import { s__ } from '~/locale';
import systemNote from '~/vue_shared/components/notes/system_note.vue';
import icon from '~/vue_shared/components/icon.vue';
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
import tooltip from '../../vue_shared/directives/tooltip';

export default {
  name: 'NoteableDiscussion',
  components: {
    icon,
    noteableNote,
    diffWithNote,
    userAvatarLink,
    noteHeader,
    noteSignedOutWidget,
    noteEditedText,
    noteForm,
    toggleRepliesWidget,
    placeholderNote,
    placeholderSystemNote,
    systemNote,
  },
  directives: {
    tooltip,
  },
  mixins: [autosave, noteable, resolvable, discussionNavigation],
  props: {
    discussion: {
      type: Object,
      required: true,
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
      'discussionCount',
      'resolvedDiscussionCount',
      'allDiscussions',
      'unresolvedDiscussionsIdsByDiff',
      'unresolvedDiscussionsIdsByDate',
      'unresolvedDiscussions',
      'unresolvedDiscussionsIdsOrdered',
      'nextUnresolvedDiscussionId',
      'isLastUnresolvedDiscussion',
    ]),
    transformedDiscussion() {
      return {
        ...this.discussion.notes[0],
        truncatedDiffLines: this.discussion.truncated_diff_lines || [],
        truncatedDiffLinesPath: this.discussion.truncated_diff_lines_path,
        diffFile: this.discussion.diff_file,
        diffDiscussion: this.discussion.diff_discussion,
        imageDiffHtml: this.discussion.image_diff_html,
        active: this.discussion.active,
        discussionPath: this.discussion.discussion_path,
        resolved: this.discussion.resolved,
        resolvedBy: this.discussion.resolved_by,
        resolvedByPush: this.discussion.resolved_by_push,
        resolvedAt: this.discussion.resolved_at,
      };
    },
    author() {
      return this.transformedDiscussion.author;
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
      return this.transformedDiscussion.resolvedByPush ? 'Automatically resolved' : 'Resolved';
    },
    hasMultipleUnresolvedDiscussions() {
      return this.unresolvedDiscussions.length > 1;
    },
    showJumpToNextDiscussion() {
      return (
        this.hasMultipleUnresolvedDiscussions &&
        !this.isLastUnresolvedDiscussion(this.discussion.id, this.discussionsByDiffOrder)
      );
    },
    shouldRenderDiffs() {
      const { diffDiscussion, diffFile } = this.transformedDiscussion;

      return diffDiscussion && diffFile && this.renderDiffFile;
    },
    shouldGroupReplies() {
      return !this.shouldRenderDiffs && !this.transformedDiscussion.diffDiscussion;
    },
    shouldRenderHeader() {
      return this.shouldRenderDiffs;
    },
    wrapperComponent() {
      return this.shouldRenderDiffs ? diffWithNote : 'div';
    },
    wrapperComponentProps() {
      if (this.shouldRenderDiffs) {
        return { discussion: convertObjectPropsToCamelCase(this.discussion) };
      }

      return {};
    },
    wrapperClass() {
      return this.isDiffDiscussion ? '' : 'card discussion-wrapper';
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
      const isExpanded = this.discussion.expanded;
      const { diffDiscussion, resolved } = this.transformedDiscussion;
      const isResolvedNonDiffDiscussion = !diffDiscussion && resolved;

      return isExpanded || this.alwaysExpanded || isResolvedNonDiffDiscussion;
    },
<<<<<<< HEAD
    isRepliesCollapsed() {
      const { discussion, isRepliesToggledByUser } = this;
      const { resolved, notes } = discussion;
      const hasReplies = notes.length > 1;

      return (
        (!discussion.diff_discussion && resolved && hasReplies && !isRepliesToggledByUser) || false
=======
    actionText() {
      const commitId = this.discussion.commit_id ? truncateSha(this.discussion.commit_id) : '';
      const linkStart = `<a href="${_.escape(this.discussion.discussion_path)}">`;
      const linkEnd = '</a>';

      let text = s__('MergeRequests|started a discussion');

      if (this.discussion.for_commit) {
        text = s__(
          'MergeRequests|started a discussion on commit %{linkStart}%{commitId}%{linkEnd}',
        );
      } else if (this.discussion.diff_discussion) {
        if (this.discussion.active) {
          text = s__('MergeRequests|started a discussion on %{linkStart}the diff%{linkEnd}');
        } else {
          text = s__(
            'MergeRequests|started a discussion on %{linkStart}an old version of the diff%{linkEnd}',
          );
        }
      }

      return sprintf(
        text,
        {
          commitId,
          linkStart,
          linkEnd,
        },
        false,
>>>>>>> 403430968cf... Merge branch 'winh-collapse-discussions' into 'master'
      );
    },
  },
  watch: {
    isReplying() {
      if (this.isReplying) {
        this.$nextTick(() => {
          // Pass an extra key to separate reply and note edit forms
          this.initAutoSave(this.transformedDiscussion, ['Reply']);
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
  <li
    class="note note-discussion timeline-entry"
    :class="componentClassName"
  >
    <div class="timeline-entry-inner">
      <div class="timeline-content">
        <div
          :data-discussion-id="transformedDiscussion.discussion_id"
          class="discussion js-discussion-container"
        >
          <div
            v-if="shouldRenderHeader"
            class="discussion-header note-wrapper"
          >
            <div class="timeline-icon">
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
              :created-at="transformedDiscussion.created_at"
              :note-id="transformedDiscussion.id"
              :include-toggle="true"
              :expanded="discussion.expanded"
              @toggleHandler="toggleDiscussionHandler"
            >
              <template v-if="transformedDiscussion.diffDiscussion">
                started a discussion on
                <a :href="transformedDiscussion.discussionPath">
                  <template v-if="transformedDiscussion.active">
                    the diff
                  </template>
                  <template v-else>
                    an old version of the diff
                  </template>
                </a>
              </template>
              <template v-else-if="discussion.for_commit">
                started a discussion on commit
                <a :href="discussion.discussion_path">
                  {{ truncateSha(discussion.commit_id) }}
                </a>
              </template>
              <template v-else>
                started a discussion
              </template>
            </note-header>
            <note-edited-text
              v-if="transformedDiscussion.resolved"
              :edited-at="transformedDiscussion.resolvedAt"
              :edited-by="transformedDiscussion.resolvedBy"
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
          <div
            v-if="shouldShowDiscussions"
            class="discussion-body">
            <component
              :is="wrapperComponent"
              v-bind="wrapperComponentProps"
              :class="wrapperClass"
            >
              <div class="discussion-notes">
                <ul class="notes">
                  <template v-if="shouldGroupReplies">
                    <component
                      :is="componentName(initialDiscussion)"
                      :note="componentData(initialDiscussion)"
                      @handleDeleteNote="deleteNoteHandler"
                    >
                      <slot
                        slot="avatar-badge"
                        name="avatar-badge"
                      >
                      </slot>
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
                      @handleDeleteNote="deleteNoteHandler"
                    >
                      <slot
                        v-if="index === 0"
                        slot="avatar-badge"
                        name="avatar-badge"
                      >
                      </slot>
                    </component>
                  </template>
                </ul>
                <div
                  v-if="!isRepliesCollapsed"
                  :class="{ 'is-replying': isReplying }"
                  class="discussion-reply-holder"
                >
                  <template v-if="!isReplying && canReply">
                    <div class="discussion-with-resolve-btn">
                      <button
                        type="button"
                        class="js-vue-discussion-reply btn btn-text-field mr-sm-2 qa-discussion-reply"
                        title="Add a reply"
                        @click="showReplyForm"
                      >
                        Reply...
                      </button>
                      <div v-if="discussion.resolvable">
                        <button
                          type="button"
                          class="btn btn-default mr-sm-2"
                          @click="resolveHandler()"
                        >
                          <i
                            v-if="isResolving"
                            aria-hidden="true"
                            class="fa fa-spinner fa-spin"
                          ></i>
                          {{ resolveButtonTitle }}
                        </button>
                      </div>
                      <div
                        v-if="discussion.resolvable"
                        class="btn-group discussion-actions ml-sm-2"
                        role="group"
                      >
                        <div
                          v-if="!discussionResolved"
                          class="btn-group"
                          role="group">
                          <a
                            v-tooltip
                            :href="discussion.resolve_with_issue_path"
                            :title="s__('MergeRequests|Resolve this discussion in a new issue')"
                            class="new-issue-for-discussion btn
                              btn-default discussion-create-issue-btn"
                            data-container="body"
                          >
                            <icon name="issue-new" />
                          </a>
                        </div>
                        <div
                          v-if="showJumpToNextDiscussion"
                          class="btn-group"
                          role="group">
                          <button
                            v-tooltip
                            class="btn btn-default discussion-next-btn"
                            title="Jump to next unresolved discussion"
                            data-container="body"
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
    </div>
  </li>
</template>
