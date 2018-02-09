<script>
  import { mapGetters } from 'vuex';
  import emojiSmiling from 'icons/_emoji_slightly_smiling_face.svg';
  import emojiSmile from 'icons/_emoji_smile.svg';
  import emojiSmiley from 'icons/_emoji_smiley.svg';
  import editSvg from 'icons/_icon_pencil.svg';
  import ellipsisSvg from 'icons/_ellipsis_v.svg';
  import loadingIcon from '~/vue_shared/components/loading_icon.vue';
  import tooltip from '~/vue_shared/directives/tooltip';

  export default {
    name: 'NoteActions',
    directives: {
      tooltip,
    },
    components: {
      loadingIcon,
    },
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
    },
    computed: {
      ...mapGetters([
        'getUserDataByProp',
      ]),
      shouldShowActionsDropdown() {
        return this.currentUserId && (this.canEdit || this.canReportAsAbuse);
      },
      canAddAwardEmoji() {
        return this.currentUserId;
      },
      isAuthoredByCurrentUser() {
        return this.authorId === this.currentUserId;
      },
      currentUserId() {
        return this.getUserDataByProp('id');
      },
    },
    created() {
      this.emojiSmiling = emojiSmiling;
      this.emojiSmile = emojiSmile;
      this.emojiSmiley = emojiSmiley;
      this.editSvg = editSvg;
      this.ellipsisSvg = ellipsisSvg;
    },
    methods: {
      onEdit() {
        this.$emit('handleEdit');
      },
      onDelete() {
        this.$emit('handleDelete');
      },
    },
  };
</script>

<template>
  <div class="note-actions">
    <span
      v-if="accessLevel"
      class="note-role user-access-role">
      {{ accessLevel }}
    </span>
    <div
      v-if="canAddAwardEmoji"
      class="note-actions-item">
      <a
        v-tooltip
        :class="{ 'js-user-authored': isAuthoredByCurrentUser }"
        class="note-action-button note-emoji-button js-add-award js-note-emoji"
        data-position="right"
        data-placement="bottom"
        data-container="body"
        href="#"
        title="Add reaction"
      >
        <loading-icon :inline="true" />
        <span
          v-html="emojiSmiling"
          class="link-highlight award-control-icon-neutral">
        </span>
        <span
          v-html="emojiSmiley"
          class="link-highlight award-control-icon-positive">
        </span>
        <span
          v-html="emojiSmile"
          class="link-highlight award-control-icon-super-positive">
        </span>
      </a>
    </div>
    <div
      v-if="canEdit"
      class="note-actions-item">
      <button
        @click="onEdit"
        v-tooltip
        type="button"
        title="Edit comment"
        class="note-action-button js-note-edit btn btn-transparent"
        data-container="body"
        data-placement="bottom">
        <span
          v-html="editSvg"
          class="link-highlight">
        </span>
      </button>
    </div>
    <div
      v-if="shouldShowActionsDropdown"
      class="dropdown more-actions note-actions-item">
      <button
        v-tooltip
        type="button"
        title="More actions"
        class="note-action-button more-actions-toggle btn btn-transparent"
        data-toggle="dropdown"
        data-container="body"
        data-placement="bottom">
        <span
          class="icon"
          v-html="ellipsisSvg">
        </span>
      </button>
      <ul class="dropdown-menu more-actions-dropdown dropdown-open-left">
        <li v-if="canReportAsAbuse">
          <a :href="reportAbusePath">
            Report as abuse
          </a>
        </li>
        <li v-if="canEdit">
          <button
            @click.prevent="onDelete"
            class="btn btn-transparent js-note-delete js-note-delete"
            type="button">
            <span class="text-danger">
              Delete comment
            </span>
          </button>
        </li>
      </ul>
    </div>
  </div>
</template>
