<script>
import emojiSmiling from 'icons/_emoji_slightly_smiling_face.svg';
import emojiSmile from 'icons/_emoji_smile.svg';
import emojiSmiley from 'icons/_emoji_smiley.svg';

export default {
  props: {
    authorId: {
      type: Number,
      required: true,
    },
    noteId: {
      type: Number,
      required: true,
    },
    accessLevel: {
      type: String,
      required: false,
      default: '',
    },
    reportAbusePath: {
      type: String,
      required: true,
    },
    canEdit: {
      type: Boolean,
      required: true,
    },
    canDelete: {
      type: Boolean,
      required: true,
    },
    canReportAsAbuse: {
      type: Boolean,
      required: true,
    },
    editHandler: {
      type: Function,
      required: true,
    },
    deleteHandler: {
      type: Function,
      required: true,
    },
  },
  data() {
    return {
      emojiSmiling,
      emojiSmile,
      emojiSmiley,
    };
  },
  computed: {
    shouldShowActionsDropdown() {
      return window.gon.current_user_id && (this.canEdit || this.canReportAsAbuse);
    },
    canAddAwardEmoji() {
      return window.gon.current_user_id;
    },
    isAuthoredByMe() {
      return this.authorId === window.gon.current_user_id;
    },
  },
};
</script>

<template>
  <div class="note-actions">
    <span
      v-if="accessLevel"
      class="note-role">
      {{accessLevel}}
    </span>
    <a
      v-if="canAddAwardEmoji"
      :class="{ 'js-user-authored': isAuthoredByMe }"
      class="note-action-button note-emoji-button js-add-award js-note-emoji has-tooltip"
      data-position="right"
      href="#"
      title="Add reaction">
        <span
          v-html="emojiSmiling"
          class="link-highlight award-control-icon-neutral"></span>
        <span
          v-html="emojiSmiley"
          class="link-highlight award-control-icon-positive"></span>
        <span
          v-html="emojiSmile"
          class="link-highlight award-control-icon-super-positive"></span>
    </a>
    <div
      v-if="shouldShowActionsDropdown"
      class="dropdown more-actions">
      <button
        type="button"
        title="More actions"
        class="note-action-button more-actions-toggle has-tooltip btn btn-transparent"
        data-toggle="dropdown"
        data-container="body">
          <i
            aria-hidden="true"
            class="fa fa-ellipsis-v icon"></i>
      </button>
      <ul class="dropdown-menu more-actions-dropdown dropdown-open-left">
        <template v-if="canEdit">
          <li>
            <button
              @click="editHandler"
              type="button"
              class="btn btn-transparent js-note-edit">
              Edit comment
            </button>
          </li>
          <li class="divider"></li>
        </template>
        <li v-if="canReportAsAbuse">
          <a :href="reportAbusePath">
            Report as abuse
          </a>
        </li>
        <li>
          <a
            v-if="canEdit"
            @click.prevent="deleteHandler"
            class="js-note-delete js-note-delete"
            href="#">
            <span class="text-danger">
              Delete comment
            </span>
          </a>
        </li>
      </ul>
    </div>
  </div>
</template>
