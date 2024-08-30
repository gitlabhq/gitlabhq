<script>
import { GlLink, GlIcon, GlSprintf } from '@gitlab/ui';
import { __, sprintf } from '~/locale';

const noteableTypeText = {
  Issue: __('issue'),
  Epic: __('epic'),
  MergeRequest: __('merge request'),
  Task: __('task'),
  KeyResult: __('key result'),
  Objective: __('objective'),
};

export default {
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
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
      return noteableTypeText[this.noteableType];
    },
    confidentialContextText() {
      return sprintf(__('This is a confidential %{noteableTypeText}.'), {
        noteableTypeText: this.noteableTypeText,
      });
    },
    lockedContextText() {
      return sprintf(__('The discussion in this %{noteableTypeText} is locked.'), {
        noteableTypeText: this.noteableTypeText,
      });
    },
  },
};
</script>
<template>
  <div class="issuable-note-warning" data-testid="issuable-note-warning">
    <gl-icon
      v-if="!isLockedAndConfidential"
      :name="warningIcon"
      :size="16"
      class="icon gl-inline-block"
    />

    <span v-if="isLockedAndConfidential" ref="lockedAndConfidential">
      <span>
        <gl-sprintf
          :message="
            __(
              'This %{noteableTypeText} is %{confidentialLinkStart}confidential%{confidentialLinkEnd} and its %{lockedLinkStart}discussion is locked%{lockedLinkEnd}.',
            )
          "
        >
          <template #noteableTypeText>{{ noteableTypeText }}</template>
          <template #confidentialLink="{ content }">
            <gl-link :href="confidentialNoteableDocsPath" target="_blank">{{ content }}</gl-link>
          </template>
          <template #lockedLink="{ content }">
            <gl-link :href="lockedNoteableDocsPath" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </span>
      {{
        __("People without permission will never get a notification and won't be able to comment.")
      }}
    </span>

    <span v-else-if="isConfidential" ref="confidential">
      {{ confidentialContextText }}
      {{ __('People without permission will never get a notification.') }}
      <gl-link :href="confidentialNoteableDocsPath" target="_blank">{{
        __('Learn more.')
      }}</gl-link>
    </span>

    <span v-else-if="isLocked" ref="locked">
      {{ lockedContextText }}
      {{ __('Only project members can comment.') }}
      <gl-link :href="lockedNoteableDocsPath" target="_blank">{{ __('Learn more.') }}</gl-link>
    </span>
  </div>
</template>
