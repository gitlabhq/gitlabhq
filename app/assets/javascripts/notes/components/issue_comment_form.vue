<script>
/* global Flash */

import UserAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import MarkdownField from '../../vue_shared/components/markdown/field.vue';

export default {
  props: {},
  data() {
    return {
      note: '',
      markdownPreviewUrl: '',
      markdownDocsUrl: '',

      // FIXME: @fatihacet - Fix the mock data below.
      noteType: 'comment',
      issueState: 'open',
      endpoint: '/gitlab-org/gitlab-ce/notes',
      author: {
        avatar_url: 'http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
        id: 1,
        name: 'Administrator',
        path: '/root',
        state: 'active',
        username: 'root',
      },
    };
  },
  components: {
    UserAvatarLink,
    MarkdownField,
  },
  computed: {
    commentButtonTitle() {
      return this.noteType === 'comment' ? 'Comment' : 'Start discussion';
    },
    issueActionButtonTitle() {
      if (this.note.length) {
        const actionText = this.issueState === 'open' ? 'close' : 'reopen';

        return this.noteType === 'comment' ? `Comment & ${actionText} issue` : `Start discussion & ${actionText} issue`;
      }

      return this.issueState === 'open' ? 'Close issue' : 'Reopen issue';
    },
  },
  methods: {
    handleSave() {
      const data = {
        endpoint: `${this.endpoint}?full_data=1`,
        noteData: {
          target_type: 'issue',
          target_id: '89',
          note: {
            noteable_type: 'Issue',
            noteable_id: 89,
            note: this.note,
          }
        },
      };

      if (this.noteType === 'discussion') {
        data.noteData.note.type = 'DiscussionNote';
      }

      this.$store.dispatch('createNewNote', data)
        .then(() => {
          this.discard();
        })
        .catch(() => {
          new Flash('Something went wrong while adding your comment. Please try again.'); // eslint-disable-line
        });
    },
    discard() {
      this.note = '';
      this.$refs.textarea.focus();
    },
    setNoteType(type) {
      this.noteType = type;
    },
  },
  mounted() {
    const issuableDataEl = document.getElementById('js-issuable-app-initial-data');
    const issueData = JSON.parse(issuableDataEl.innerHTML.replace(/&quot;/g, '"'));
    const { markdownDocs, markdownPreviewUrl } = issueData;

    this.markdownDocsUrl = markdownDocs;
    this.markdownPreviewUrl = markdownPreviewUrl;
  },
};
</script>

<template>
  <ul class="notes notes-form timeline new-note">
    <li class="timeline-entry">
      <div class="timeline-icon hidden-xs hidden-sm">
        <user-avatar-link
          :linkHref="author.path"
          :imgSrc="author.avatar_url"
          :imgAlt="author.name"
          :imgSize="40" />
      </div>
      <div class="timeline-content timeline-content-form common-note-form">
        <markdown-field
          :markdown-preview-url="markdownPreviewUrl"
          :markdown-docs="markdownDocsUrl"
          :addSpacingClasses="false">
          <textarea
            id="note-body"
            class="note-textarea js-gfm-input js-autosize markdown-area"
            data-supports-slash-commands="true"
            data-supports-quick-actions="true"
            aria-label="Description"
            v-model="note"
            ref="textarea"
            slot="textarea"
            placeholder="Write a comment or drag your files here..."
            @keydown.meta.enter="handleSave">
          </textarea>
        </markdown-field>
        <div class="note-form-actions clearfix">
          <div class="pull-left btn-group append-right-10 comment-type-dropdown js-comment-type-dropdown">
            <input
              @click="handleSave"
              :disabled="!note.length"
              :value="commentButtonTitle"
              class="btn btn-nr btn-create comment-btn js-comment-button js-comment-submit-button"
              type="submit" />
            <button
              :disabled="!note.length"
              name="button"
              type="button"
              class="btn btn-nr comment-btn note-type-toggle js-note-new-discussion"
              data-toggle="dropdown"
              aria-label="Open comment type dropdown">
              <i
                aria-hidden="true"
                class="fa fa-caret-down toggle-icon"></i>
            </button>
            <ul
              class="dropdown-menu note-type-dropdown dropdown-open-top">
              <li
                :class="{ 'item-selected': noteType === 'comment' }"
                @click.prevent="setNoteType('comment')">
                <a href="#">
                  <i
                    aria-hidden="true"
                    class="fa fa-check"></i>
                  <div class="description">
                    <strong>Comment</strong>
                    <p>
                      Add a general comment to this issue.
                    </p>
                  </div>
                </a>
              </li>
              <li class="divider"></li>
              <li
                :class="{ 'item-selected': noteType === 'discussion' }"
                @click.prevent="setNoteType('discussion')">
                <a href="#">
                  <i
                    aria-hidden="true"
                    class="fa fa-check"></i>
                  <div class="description">
                    <strong>Start discussion</strong>
                    <p>
                      Discuss a specific suggestion or question.
                    </p>
                  </div>
                </a>
              </li>
            </ul>
          </div>
          <a
            :class="{'btn-reopen': issueState === 'closed', 'btn-close': issueState === 'open'}"
            class="btn btn-nr btn-comment">
            {{issueActionButtonTitle}}
          </a>
          <a
            v-if="note.length"
            @click="discard"
            class="btn btn-cancel js-note-discard"
            role="button">
            Discard draft
          </a>
        </div>
      </div>
    </li>
  </ul>
</template>
