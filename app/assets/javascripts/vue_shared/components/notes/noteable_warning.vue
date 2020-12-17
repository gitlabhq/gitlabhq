<script>
/* eslint-disable vue/no-v-html */
import { GlLink, GlIcon } from '@gitlab/ui';
import { escape } from 'lodash';
import { __, sprintf } from '~/locale';

function buildDocsLinkStart(path) {
  return `<a href="${escape(path)}" target="_blank" rel="noopener noreferrer">`;
}

const NoteableTypeText = {
  Issue: __('issue'),
  Epic: __('epic'),
  MergeRequest: __('merge request'),
};

export default {
  components: {
    GlIcon,
    GlLink,
  },
  props: {
    isLocked: {
      type: Boolean,
      default: false,
      required: false,
    },
    isConfidential: {
      type: Boolean,
      default: false,
      required: false,
    },
    noteableType: {
      type: String,
      required: false,
      // eslint-disable-next-line @gitlab/require-i18n-strings
      default: 'Issue',
    },
    lockedNoteableDocsPath: {
      type: String,
      required: false,
      default: '',
    },
    confidentialNoteableDocsPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    warningIcon() {
      if (this.isConfidential) return 'eye-slash';
      if (this.isLocked) return 'lock';

      return '';
    },
    isLockedAndConfidential() {
      return this.isConfidential && this.isLocked;
    },
    noteableTypeText() {
      return NoteableTypeText[this.noteableType];
    },
    confidentialAndLockedDiscussionText() {
      return sprintf(
        __(
          'This %{noteableTypeText} is %{confidentialLinkStart}confidential%{linkEnd} and %{lockedLinkStart}locked%{linkEnd}.',
        ),
        {
          noteableTypeText: this.noteableTypeText,
          confidentialLinkStart: buildDocsLinkStart(this.confidentialNoteableDocsPath),
          lockedLinkStart: buildDocsLinkStart(this.lockedNoteableDocsPath),
          linkEnd: '</a>',
        },
        false,
      );
    },
    confidentialContextText() {
      return sprintf(__('This is a confidential %{noteableTypeText}.'), {
        noteableTypeText: this.noteableTypeText,
      });
    },
    lockedContextText() {
      return sprintf(__('This %{noteableTypeText} is locked.'), {
        noteableTypeText: this.noteableTypeText,
      });
    },
  },
};
</script>
<template>
  <div class="issuable-note-warning" data-testid="confidential-warning">
    <gl-icon v-if="!isLockedAndConfidential" :name="warningIcon" :size="16" class="icon inline" />

    <span v-if="isLockedAndConfidential" ref="lockedAndConfidential">
      <span v-html="confidentialAndLockedDiscussionText"></span>
      {{
        __("People without permission will never get a notification and won't be able to comment.")
      }}
    </span>

    <span v-else-if="isConfidential" ref="confidential">
      {{ confidentialContextText }}
      {{ __('People without permission will never get a notification.') }}
      <gl-link :href="confidentialNoteableDocsPath" target="_blank">{{ __('Learn more') }}</gl-link>
    </span>

    <span v-else-if="isLocked" ref="locked">
      {{ lockedContextText }}
      {{ __('Only project members can comment.') }}
      <gl-link :href="lockedNoteableDocsPath" target="_blank">{{ __('Learn more') }}</gl-link>
    </span>
  </div>
</template>
