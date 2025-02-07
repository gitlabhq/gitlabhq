<script>
import { GlLink, GlIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { issuableTypeText } from '~/issues/constants';
import { WORK_ITEM_TYPE_VALUE_TASK } from '~/work_items/constants';

export default {
  components: {
    GlIcon,
    GlLink,
  },
  props: {
    workItemType: {
      required: false,
      type: String,
      default: WORK_ITEM_TYPE_VALUE_TASK,
    },
    isProjectArchived: {
      required: false,
      type: Boolean,
      default: false,
    },
  },
  constantOptions: {
    archivedProjectDocsPath: helpPagePath('user/project/working_with_projects', {
      anchor: 'archive-a-project',
    }),
    lockedIssueDocsPath: helpPagePath('user/discussions/_index.md', {
      anchor: 'prevent-comments-by-locking-the-discussion',
    }),
    projectArchivedWarning: __('This project is archived and cannot be commented on.'),
  },
  computed: {
    issuableDisplayName() {
      return this.workItemType.replace(/_/g, ' ');
    },
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
    <template v-if="isProjectArchived">
      {{ $options.constantOptions.projectArchivedWarning }}
      <gl-link :href="$options.constantOptions.archivedProjectDocsPath" class="learn-more">
        {{ __('Learn more.') }}
      </gl-link>
    </template>

    <template v-else>
      {{ lockedIssueWarning }}
      {{ __('Only project members can comment.') }}
      <gl-link :href="$options.constantOptions.lockedIssueDocsPath" class="learn-more">
        {{ __('Learn more.') }}
      </gl-link>
    </template>
  </div>
</template>
