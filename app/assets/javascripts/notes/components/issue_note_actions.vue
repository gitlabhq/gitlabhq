<script>
import emojiSmiling from '../icons/emoji_slightly_smiling_face.svg';
import emojiSmile from '../icons/emoji_smile.svg';
import emojiSmiley from '../icons/emoji_smiley.svg';

export default {
  props: {
    accessLevel: {
      type: String,
      required: true,
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
    editHandler: {
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
};
</script>

<template>
  <div class="note-actions">
    <span class="note-role">
      {{accessLevel}}
    </span>
    <a
      class="note-action-button note-emoji-button js-add-award js-note-emoji js-user-authored has-tooltip" data-position="right"
      href="#"
      title="Add reaction">
        <i
          aria-hidden="true"
          data-hidden="true"
          class="fa fa-spinner fa-spin"></i>
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
    <div class="dropdown more-actions">
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
              class="btn btn-transparent">
              Edit comment
            </button>
          </li>
          <li class="divider"></li>
        </template>
        <li v-if="reportAbusePath">
          <a :href="reportAbusePath">
            Report as abuse
          </a>
        </li>
        <li>
          <a class="js-note-delete">
            <span class="text-danger">
              Delete comment
            </span>
          </a>
        </li>
      </ul>
    </div>
  </div>
</template>
