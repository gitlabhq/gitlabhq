<script>
import { GlLink } from '@gitlab/ui';
import { escape } from 'lodash';
import { __, sprintf } from '~/locale';
import icon from '../../../vue_shared/components/icon.vue';

function buildDocsLinkStart(path) {
  return `<a href="${escape(path)}" target="_blank" rel="noopener noreferrer">`;
}

export default {
  components: {
    icon,
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
    lockedIssueDocsPath: {
      type: String,
      required: false,
      default: '',
    },
    confidentialIssueDocsPath: {
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
    confidentialAndLockedDiscussionText() {
      return sprintf(
        __(
          'This issue is %{confidentialLinkStart}confidential%{linkEnd} and %{lockedLinkStart}locked%{linkEnd}.',
        ),
        {
          confidentialLinkStart: buildDocsLinkStart(this.confidentialIssueDocsPath),
          lockedLinkStart: buildDocsLinkStart(this.lockedIssueDocsPath),
          linkEnd: '</a>',
        },
        false,
      );
    },
  },
};
</script>
<template>
  <div class="issuable-note-warning">
    <icon v-if="!isLockedAndConfidential" :name="warningIcon" :size="16" class="icon inline" />

    <span v-if="isLockedAndConfidential" ref="lockedAndConfidential">
      <span v-html="confidentialAndLockedDiscussionText"></span>
      {{
        __("People without permission will never get a notification and won't be able to comment.")
      }}
    </span>

    <span v-else-if="isConfidential" ref="confidential">
      {{ __('This is a confidential issue.') }}
      {{ __('People without permission will never get a notification.') }}
      <gl-link :href="confidentialIssueDocsPath" target="_blank">
        {{ __('Learn more') }}
      </gl-link>
    </span>

    <span v-else-if="isLocked" ref="locked">
      {{ __('This issue is locked.') }}
      {{ __('Only project members can comment.') }}
      <gl-link :href="lockedIssueDocsPath" target="_blank">
        {{ __('Learn more') }}
      </gl-link>
    </span>
  </div>
</template>
