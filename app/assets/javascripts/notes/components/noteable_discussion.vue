<script>
import _ from 'underscore';
import { mapActions, mapGetters } from 'vuex';
import resolveDiscussionsSvg from 'icons/_icon_mr_issue.svg';
import nextDiscussionsSvg from 'icons/_next_discussion.svg';
import { convertObjectPropsToCamelCase, scrollToElement } from '~/lib/utils/common_utils';
import { truncateSha } from '~/lib/utils/text_utility';
import systemNote from '~/vue_shared/components/notes/system_note.vue';
import Flash from '../../flash';
import { SYSTEM_NOTE } from '../constants';
import userAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import noteableNote from './noteable_note.vue';
import noteHeader from './note_header.vue';
import noteSignedOutWidget from './note_signed_out_widget.vue';
import noteEditedText from './note_edited_text.vue';
import noteForm from './note_form.vue';
import diffWithNote from './diff_with_note.vue';
import placeholderNote from '../../vue_shared/components/notes/placeholder_note.vue';
import placeholderSystemNote from '../../vue_shared/components/notes/placeholder_system_note.vue';
import autosave from '../mixins/autosave';
import noteable from '../mixins/noteable';
import resolvable from '../mixins/resolvable';
import tooltip from '../../vue_shared/directives/tooltip';

export default {
  name: 'NoteableDiscussion',
  components: {
    noteableNote,
    diffWithNote,
    userAvatarLink,
    noteHeader,
    noteSignedOutWidget,
    noteEditedText,
    noteForm,
    placeholderNote,
    placeholderSystemNote,
    systemNote,
  },
  directives: {
    tooltip,
  },
  mixins: [autosave, noteable, resolvable],
  props: {
    discussion: {
      type: Object,
      required: true,
    },
    renderHeader: {
      type: Boolean,
      required: false,
      default: true,
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
  },
  data() {
    return {
      isReplying: false,
      isResolving: false,
      resolveAsThread: true,
    };
  },
  computed: {
    ...mapGetters([
      'getNoteableData',
      'discussionCount',
      'resolvedDiscussionCount',
      'allDiscussions',
      'unresolvedDiscussions',
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
    shouldRenderDiffs() {
      const { diffDiscussion, diffFile } = this.transformedDiscussion;

      return diffDiscussion && diffFile && this.renderDiffFile;
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
  },
  mounted() {
    if (this.isReplying) {
      this.initAutoSave(this.transformedDiscussion);
    }
  },
  updated() {
    if (this.isReplying) {
      if (!this.autosave) {
        this.initAutoSave(this.transformedDiscussion);
      } else {
        this.setAutoSave();
      }
    }
  },
  created() {
    this.resolveDiscussionsSvg = resolveDiscussionsSvg;
    this.nextDiscussionsSvg = nextDiscussionsSvg;
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
      return note.isPlaceholderNote ? this.discussion.notes[0] : note;
    },
    toggleDiscussionHandler() {
      this.toggleDiscussion({ discussionId: this.discussion.id });
    },
    showReplyForm() {
      this.isReplying = true;
    },
    cancelReplyForm(shouldConfirm) {
      if (shouldConfirm && this.$refs.noteForm.isDirty) {
        // eslint-disable-next-line no-alert
        if (!window.confirm('Are you sure you want to cancel creating this comment?')) {
          return;
        }
      }

      this.resetAutoSave();
      this.isReplying = false;
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
      const discussionIds = this.allDiscussions.map(d => d.id);
      const unresolvedIds = this.unresolvedDiscussions.map(d => d.id);
      const currentIndex = discussionIds.indexOf(this.discussion.id);
      const remainingAfterCurrent = discussionIds.slice(currentIndex + 1);
      const nextIndex = _.findIndex(remainingAfterCurrent, id => unresolvedIds.indexOf(id) > -1);

      if (nextIndex > -1) {
        const nextId = remainingAfterCurrent[nextIndex];
        const el = document.querySelector(`[data-discussion-id="${nextId}"]`);

        if (el) {
          this.expandDiscussion({ discussionId: nextId });
          scrollToElement(el);
        }
      }
    },
  },
};
</script>

<template>
  <li class="note note-discussion timeline-entry">
    <div class="timeline-entry-inner">
      <div class="timeline-icon">
        <user-avatar-link
          :link-href="author.path"
          :img-src="author.avatar_url"
          :img-alt="author.name"
          :img-size="40"
        />
      </div>
      <div class="timeline-content">
        <div
          :data-discussion-id="transformedDiscussion.discussion_id"
          class="discussion js-discussion-container"
        >
          <div
            v-if="renderHeader"
            class="discussion-header"
          >
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
            v-if="discussion.expanded || alwaysExpanded"
            class="discussion-body">
            <component
              :is="wrapperComponent"
              v-bind="wrapperComponentProps"
              :class="wrapperClass"
            >
              <div class="discussion-notes">
                <ul class="notes">
                  <component
                    v-for="note in discussion.notes"
                    :is="componentName(note)"
                    :note="componentData(note)"
                    :key="note.id"
                  />
                </ul>
                <div
                  :class="{ 'is-replying': isReplying }"
                  class="discussion-reply-holder"
                >
                  <template v-if="!isReplying && canReply">
                    <div
                      class="btn-group d-flex discussion-with-resolve-btn"
                      role="group">
                      <div
                        class="btn-group w-100"
                        role="group">
                        <button
                          type="button"
                          class="js-vue-discussion-reply btn btn-text-field mr-2"
                          title="Add a reply"
                          @click="showReplyForm">Reply...</button>
                      </div>
                      <div
                        v-if="discussion.resolvable"
                        class="btn-group"
                        role="group">
                        <button
                          type="button"
                          class="btn btn-default mr-2"
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
                        class="btn-group discussion-actions"
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
                            <span v-html="resolveDiscussionsSvg"></span>
                          </a>
                        </div>
                        <div
                          v-if="hasMultipleUnresolvedDiscussions"
                          class="btn-group"
                          role="group">
                          <button
                            v-tooltip
                            class="btn btn-default discussion-next-btn"
                            title="Jump to next unresolved discussion"
                            data-container="body"
                            @click="jumpToNextDiscussion"
                          >
                            <span v-html="nextDiscussionsSvg"></span>
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
                    @cancelForm="cancelReplyForm" />
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
