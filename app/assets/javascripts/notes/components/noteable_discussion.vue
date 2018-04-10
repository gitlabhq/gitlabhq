<script>
import { mapActions, mapGetters } from 'vuex';
import resolveDiscussionsSvg from 'icons/_icon_mr_issue.svg';
import nextDiscussionsSvg from 'icons/_next_discussion.svg';
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
import { scrollToElement } from '../../lib/utils/common_utils';

export default {
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
  },
  directives: {
    tooltip,
  },
  mixins: [autosave, noteable, resolvable],
  props: {
    note: {
      type: Object,
      required: true,
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
      'unresolvedDiscussions',
    ]),
    discussion() {
      return {
        ...this.note.notes[0],
        truncatedDiffLines: this.note.truncated_diff_lines,
        diffFile: this.note.diff_file,
        diffDiscussion: this.note.diff_discussion,
        imageDiffHtml: this.note.image_diff_html,
      };
    },
    author() {
      return this.discussion.author;
    },
    canReply() {
      return this.getNoteableData.current_user.can_create_note;
    },
    newNotePath() {
      return this.getNoteableData.create_note_path;
    },
    lastUpdatedBy() {
      const { notes } = this.note;

      if (notes.length > 1) {
        return notes[notes.length - 1].author;
      }

      return null;
    },
    lastUpdatedAt() {
      const { notes } = this.note;

      if (notes.length > 1) {
        return notes[notes.length - 1].created_at;
      }

      return null;
    },
    hasUnresolvedDiscussion() {
      return this.unresolvedDiscussions.length > 0;
    },
    wrapperComponent() {
      return this.discussion.diffDiscussion && this.discussion.diffFile
        ? diffWithNote
        : 'div';
    },
    wrapperClass() {
      return this.isDiffDiscussion ? '' : 'card';
    },
  },
  mounted() {
    if (this.isReplying) {
      this.initAutoSave(this.discussion.noteable_type);
    }
  },
  updated() {
    if (this.isReplying) {
      if (!this.autosave) {
        this.initAutoSave(this.discussion.noteable_type);
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
    ]),
    componentName(note) {
      if (note.isPlaceholderNote) {
        if (note.placeholderType === SYSTEM_NOTE) {
          return placeholderSystemNote;
        }
        return placeholderNote;
      }

      return noteableNote;
    },
    componentData(note) {
      return note.isPlaceholderNote ? this.note.notes[0] : note;
    },
    toggleDiscussionHandler() {
      this.toggleDiscussion({ discussionId: this.note.id });
    },
    showReplyForm() {
      this.isReplying = true;
    },
    cancelReplyForm(shouldConfirm) {
      if (shouldConfirm && this.$refs.noteForm.isDirty) {
        const msg = 'Are you sure you want to cancel creating this comment?';

        // eslint-disable-next-line no-alert
        if (!confirm(msg)) {
          return;
        }
      }

      this.resetAutoSave();
      this.isReplying = false;
    },
    saveReply(noteText, form, callback) {
      const replyData = {
        endpoint: this.newNotePath,
        flashContainer: this.$el,
        data: {
          in_reply_to_discussion_id: this.note.reply_id,
          target_type: this.noteableType,
          target_id: this.discussion.noteable_id,
          note: { note: noteText },
        },
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
    jumpToDiscussion() {
      const unresolvedIds = this.unresolvedDiscussions.map(d => d.id);
      const index = unresolvedIds.indexOf(this.note.id);

      if (index >= 0 && index !== unresolvedIds.length) {
        const nextId = unresolvedIds[index + 1];
        const el = document.querySelector(`[data-discussion-id="${nextId}"]`);

        if (el) {
          scrollToElement(el);
        }
      }
    },
  },
};
</script>

<template>
  <li
    :data-discussion-id="note.id"
    class="note note-discussion timeline-entry">
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
        <div class="discussion">
          <div class="discussion-header">
            <note-header
              :author="author"
              :created-at="discussion.created_at"
              :note-id="discussion.id"
              :include-toggle="true"
              :expanded="note.expanded"
              @toggleHandler="toggleDiscussionHandler"
              action-text="started a discussion"
              class="discussion"
            />
            <note-edited-text
              v-if="lastUpdatedAt"
              :edited-at="lastUpdatedAt"
              :edited-by="lastUpdatedBy"
              action-text="Last updated"
              class-name="discussion-headline-light js-discussion-headline"
            />
          </div>
          <div
            v-if="note.expanded"
            class="discussion-body">
            <component
              :is="wrapperComponent"
              :discussion="discussion"
              :class="wrapperClass"
            >
              <div class="discussion-notes">
                <ul class="notes">
                  <component
                    v-for="note in note.notes"
                    :is="componentName(note)"
                    :note="componentData(note)"
                    :key="note.id"
                  />
                </ul>
                <div class="discussion-reply-holder">
                  <template v-if="!isReplying && canReply">
                    <div
                      class="btn-group d-flex discussion-with-resolve-btn"
                      role="group">
                      <div
                        class="btn-group"
                        role="group">
                        <button
                          @click="showReplyForm"
                          type="button"
                          class="js-vue-discussion-reply btn btn-text-field"
                          title="Add a reply">Reply...</button>
                      </div>
                      <div
                        v-if="note.resolvable"
                        class="btn-group"
                        role="group">
                        <button
                          @click="resolveHandler()"
                          type="button"
                          class="btn btn-secondary"
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
                        v-if="note.resolvable"
                        class="btn-group discussion-actions"
                        role="group"
                      >
                        <div
                          v-if="!discussionResolved"
                          class="btn-group"
                          role="group">
                          <a
                            :href="note.resolve_with_issue_path"
                            v-tooltip
                            class="new-issue-for-discussion btn
                              btn-secondary discussion-create-issue-btn"
                            title="Resolve this discussion in a new issue"
                            data-container="body"
                          >
                            <span v-html="resolveDiscussionsSvg"></span>
                          </a>
                        </div>
                        <div
                          v-if="hasUnresolvedDiscussion"
                          class="btn-group"
                          role="group">
                          <button
                            @click="jumpToDiscussion"
                            v-tooltip
                            class="btn btn-secondary discussion-next-btn"
                            title="Jump to next unresolved discussion"
                            data-container="body"
                          >
                            <span v-html="nextDiscussionsSvg"></span>
                          </button>
                        </div>
                      </div>
                    </div>
                  </template>
                  <note-form
                    v-if="isReplying"
                    save-button-title="Comment"
                    :note="note"
                    :is-editing="false"
                    @handleFormUpdate="saveReply"
                    @cancelFormEdition="cancelReplyForm"
                    ref="noteForm" />
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
