<script>
import { mapGetters } from 'vuex';
import { GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import resolvedStatusMixin from 'ee_else_ce/batch_comments/mixins/resolved_status';
import Icon from '~/vue_shared/components/icon.vue';
import ReplyButton from './note_actions/reply_button.vue';

export default {
  name: 'NoteActions',
  components: {
    Icon,
    ReplyButton,
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [resolvedStatusMixin],
  props: {
    authorId: {
      type: Number,
      required: true,
    },
    noteId: {
      type: [String, Number],
      required: true,
    },
    noteUrl: {
      type: String,
      required: false,
      default: '',
    },
    accessLevel: {
      type: String,
      required: false,
      default: '',
    },
    reportAbusePath: {
      type: String,
      required: false,
      default: null,
    },
    showReply: {
      type: Boolean,
      required: true,
    },
    canEdit: {
      type: Boolean,
      required: true,
    },
    canAwardEmoji: {
      type: Boolean,
      required: true,
    },
    canDelete: {
      type: Boolean,
      required: true,
    },
    canResolve: {
      type: Boolean,
      required: false,
      default: false,
    },
    resolvable: {
      type: Boolean,
      required: false,
      default: false,
    },
    isResolved: {
      type: Boolean,
      required: false,
      default: false,
    },
    isResolving: {
      type: Boolean,
      required: false,
      default: false,
    },
    resolvedBy: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    canReportAsAbuse: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['getUserDataByProp']),
    shouldShowActionsDropdown() {
      return this.currentUserId && (this.canEdit || this.canReportAsAbuse);
    },
    showDeleteAction() {
      return this.canDelete && !this.canReportAsAbuse && !this.noteUrl;
    },
    isAuthoredByCurrentUser() {
      return this.authorId === this.currentUserId;
    },
    currentUserId() {
      return this.getUserDataByProp('id');
    },
  },
  methods: {
    onEdit() {
      this.$emit('handleEdit');
    },
    onDelete() {
      this.$emit('handleDelete');
    },
    onResolve() {
      this.$emit('handleResolve');
    },
    closeTooltip() {
      this.$nextTick(() => {
        this.$root.$emit('bv::hide::tooltip');
      });
    },
  },
};
</script>

<template>
  <div class="note-actions">
    <span v-if="accessLevel" class="note-role user-access-role">{{ accessLevel }}</span>
    <div v-if="canResolve" class="note-actions-item">
      <button
        ref="resolveButton"
        v-gl-tooltip
        :class="{ 'is-disabled': !resolvable, 'is-active': isResolved }"
        :title="resolveButtonTitle"
        :aria-label="resolveButtonTitle"
        type="button"
        class="line-resolve-btn note-action-button"
        @click="onResolve"
      >
        <template v-if="!isResolving">
          <icon :name="isResolved ? 'check-circle-filled' : 'check-circle'" />
        </template>
        <gl-loading-icon v-else inline />
      </button>
    </div>
    <div v-if="canAwardEmoji" class="note-actions-item">
      <a
        v-gl-tooltip
        :class="{ 'js-user-authored': isAuthoredByCurrentUser }"
        class="note-action-button note-emoji-button js-add-award js-note-emoji"
        href="#"
        title="Add reaction"
        data-position="right"
      >
        <icon class="link-highlight award-control-icon-neutral" name="slight-smile" />
        <icon class="link-highlight award-control-icon-positive" name="smiley" />
        <icon class="link-highlight award-control-icon-super-positive" name="smiley" />
      </a>
    </div>
    <reply-button
      v-if="showReply"
      ref="replyButton"
      class="js-reply-button"
      @startReplying="$emit('startReplying')"
    />
    <div v-if="canEdit" class="note-actions-item">
      <button
        v-gl-tooltip
        type="button"
        title="Edit comment"
        class="note-action-button js-note-edit btn btn-transparent qa-note-edit-button"
        @click="onEdit"
      >
        <icon name="pencil" class="link-highlight" />
      </button>
    </div>
    <div v-if="showDeleteAction" class="note-actions-item">
      <button
        v-gl-tooltip
        type="button"
        title="Delete comment"
        class="note-action-button js-note-delete btn btn-transparent"
        @click="onDelete"
      >
        <icon name="remove" class="link-highlight" />
      </button>
    </div>
    <div v-else-if="shouldShowActionsDropdown" class="dropdown more-actions note-actions-item">
      <button
        v-gl-tooltip
        type="button"
        title="More actions"
        class="note-action-button more-actions-toggle btn btn-transparent"
        data-toggle="dropdown"
        @click="closeTooltip"
      >
        <icon class="icon" name="ellipsis_v" />
      </button>
      <ul class="dropdown-menu more-actions-dropdown dropdown-open-left">
        <li v-if="canReportAsAbuse">
          <a :href="reportAbusePath">{{ __('Report abuse to admin') }}</a>
        </li>
        <li v-if="noteUrl">
          <button
            :data-clipboard-text="noteUrl"
            type="button"
            class="btn-default btn-transparent js-btn-copy-note-link"
          >
            {{ __('Copy link') }}
          </button>
        </li>
        <li v-if="canEdit">
          <button
            class="btn btn-transparent js-note-delete js-note-delete"
            type="button"
            @click.prevent="onDelete"
          >
            <span class="text-danger">{{ __('Delete comment') }}</span>
          </button>
        </li>
      </ul>
    </div>
  </div>
</template>
