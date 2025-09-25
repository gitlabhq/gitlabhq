<script>
import { GlLink, GlIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { issuableTypeText } from '~/issues/constants';
import { WORK_ITEM_TYPE_NAME_TASK } from '~/work_items/constants';

export default {
  components: {
    GlIcon,
    GlLink,
  },
  props: {
    workItemType: {
      required: false,
      type: String,
      default: WORK_ITEM_TYPE_NAME_TASK,
    },
  },
  constantOptions: {
    lockedIssueDocsPath: helpPagePath('user/discussions/_index.md', {
      anchor: 'prevent-comments-by-locking-the-discussion',
    }),
  },
  computed: {
    lockedIssueWarning() {
      return sprintf(__('The discussion in this %{noteableTypeText} is locked.'), {
        noteableTypeText: this.noteableTypeText,
      });
    },
    noteableTypeText() {
      return issuableTypeText[this.workItemType];
    },
  },
};
</script>

<template>
  <div class="issuable-note-warning gl-relative gl-rounded-base gl-py-4">
    <gl-icon name="lock" class="gl-mr-2" />
    {{ lockedIssueWarning }}
    {{ __('Only project members can comment.') }}
    <gl-link :href="$options.constantOptions.lockedIssueDocsPath" class="learn-more">
      {{ __('Learn more.') }}
    </gl-link>
  </div>
</template>
