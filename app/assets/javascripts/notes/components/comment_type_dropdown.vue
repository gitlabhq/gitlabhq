<script>
import { GlButtonGroup, GlButton, GlCollapsibleListbox } from '@gitlab/ui';

import { sprintf, __ } from '~/locale';
import { COMMENT_FORM } from '~/notes/i18n';
import * as constants from '../constants';

export default {
  name: 'CommentTypeDropdown',
  i18n: {
    ...COMMENT_FORM,
    toggleSrText: __('Comment type'),
  },
  components: {
    GlButtonGroup,
    GlButton,
    GlCollapsibleListbox,
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
    dropdownItems() {
      return [
        {
          text: this.dropdownCommentButtonTitle,
          description: this.commentDescription,
          value: constants.COMMENT,
        },
        {
          text: this.dropdownStartThreadButtonTitle,
          description: this.startDiscussionDescription,
          value: constants.DISCUSSION,
          qaSelector: 'discussion_menu_item',
        },
      ];
    },
  },
  methods: {
    handleClick() {
      this.$emit('click');
    },
    setNoteType(value) {
      this.$emit('change', value);
    },
  },
};
</script>

<template>
  <!--TODO: Replace button-group workaround once `split` option for new dropdowns is implemented.-->
  <!-- See issue at https://gitlab.com/gitlab-org/gitlab-ui/-/issues/2263-->
  <gl-button-group
    class="js-comment-button js-comment-submit-button comment-type-dropdown gl-w-full gl-mb-3 gl-md-w-auto gl-md-mb-0"
    :data-track-label="trackingLabel"
    data-track-action="click_button"
    data-testid="comment-button"
    data-qa-selector="comment_button"
  >
    <gl-button variant="confirm" :disabled="disabled" @click="handleClick">
      {{ commentButtonTitle }}
    </gl-button>
    <gl-collapsible-listbox
      class="split"
      toggle-class="gl-rounded-top-left-none! gl-rounded-bottom-left-none! gl-pl-1!"
      variant="confirm"
      text-sr-only
      :toggle-text="$options.i18n.toggleSrText"
      :disabled="disabled"
      :items="dropdownItems"
      :selected="noteType"
      @select="setNoteType"
    >
      <template #list-item="{ item }">
        <div :data-qa-selector="item.qaSelector">
          <strong>{{ item.text }}</strong>
          <p class="gl-m-0">{{ item.description }}</p>
        </div>
      </template>
    </gl-collapsible-listbox>
  </gl-button-group>
</template>
