<script>
import { GlDropdown, GlDropdownItem, GlDropdownDivider } from '@gitlab/ui';

import { sprintf } from '~/locale';
import { COMMENT_FORM } from '~/notes/i18n';
import * as constants from '../constants';

export default {
  i18n: COMMENT_FORM,
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
  },
  model: {
    prop: 'noteType',
    event: 'change',
  },
  props: {
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    trackingLabel: {
      type: String,
      required: false,
      default: undefined,
    },
    discussionsRequireResolution: {
      type: Boolean,
      required: false,
      default: false,
    },
    isInternalNote: {
      type: Boolean,
      required: false,
      default: false,
    },
    noteableDisplayName: {
      type: String,
      required: true,
    },
    noteType: {
      type: String,
      required: true,
    },
  },
  computed: {
    isNoteTypeComment() {
      return this.noteType === constants.COMMENT;
    },
    isNoteTypeDiscussion() {
      return this.noteType === constants.DISCUSSION;
    },
    dropdownCommentButtonTitle() {
      const { comment, internalComment } = this.$options.i18n.submitButton;

      return this.isInternalNote ? internalComment : comment;
    },
    dropdownStartThreadButtonTitle() {
      const { startThread, startInternalThread } = this.$options.i18n.submitButton;

      return this.isInternalNote ? startInternalThread : startThread;
    },
    commentButtonTitle() {
      const { comment, internalComment, startThread, startInternalThread } = this.$options.i18n;

      if (this.isInternalNote) {
        return this.noteType === constants.COMMENT ? internalComment : startInternalThread;
      }
      return this.noteType === constants.COMMENT ? comment : startThread;
    },
    startDiscussionDescription() {
      const {
        discussionThatNeedsResolution,
        internalDiscussionThatNeedsResolution,
        discussion,
        internalDiscussion,
      } = this.$options.i18n;

      if (this.isInternalNote) {
        return this.discussionsRequireResolution
          ? internalDiscussionThatNeedsResolution
          : internalDiscussion;
      }
      return this.discussionsRequireResolution ? discussionThatNeedsResolution : discussion;
    },
    commentDescription() {
      const { commentHelp, internalCommentHelp } = this.$options.i18n.submitButton;

      return sprintf(this.isInternalNote ? internalCommentHelp : commentHelp, {
        noteableDisplayName: this.noteableDisplayName,
      });
    },
  },
  methods: {
    handleClick() {
      this.$emit('click');
    },
    setNoteTypeToComment() {
      if (this.noteType !== constants.COMMENT) {
        this.$emit('change', constants.COMMENT);
      }
    },
    setNoteTypeToDiscussion() {
      if (this.noteType !== constants.DISCUSSION) {
        this.$emit('change', constants.DISCUSSION);
      }
    },
  },
};
</script>

<template>
  <gl-dropdown
    split
    :text="commentButtonTitle"
    class="gl-mr-3 js-comment-button js-comment-submit-button comment-type-dropdown"
    category="primary"
    variant="confirm"
    :disabled="disabled"
    data-testid="comment-button"
    data-qa-selector="comment_button"
    :data-track-label="trackingLabel"
    data-track-action="click_button"
    @click="$emit('click')"
  >
    <gl-dropdown-item
      is-check-item
      :is-checked="isNoteTypeComment"
      @click.stop.prevent="setNoteTypeToComment"
    >
      <strong>{{ dropdownCommentButtonTitle }}</strong>
      <p class="gl-m-0">{{ commentDescription }}</p>
    </gl-dropdown-item>
    <gl-dropdown-divider />
    <gl-dropdown-item
      is-check-item
      :is-checked="isNoteTypeDiscussion"
      data-qa-selector="discussion_menu_item"
      @click.stop.prevent="setNoteTypeToDiscussion"
    >
      <strong>{{ dropdownStartThreadButtonTitle }}</strong>
      <p class="gl-m-0">{{ startDiscussionDescription }}</p>
    </gl-dropdown-item>
  </gl-dropdown>
</template>
