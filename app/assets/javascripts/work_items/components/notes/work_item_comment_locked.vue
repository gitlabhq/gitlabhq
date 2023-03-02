<script>
import { GlLink, GlIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { TASK_TYPE_NAME } from '~/work_items/constants';

export default {
  components: {
    GlIcon,
    GlLink,
  },
  props: {
    workItemType: {
      required: false,
      type: String,
      default: TASK_TYPE_NAME,
    },
    isProjectArchived: {
      required: false,
      type: Boolean,
      default: false,
    },
  },
  constantOptions: {
    archivedProjectDocsPath: helpPagePath('user/project/settings/index.md', {
      anchor: 'archive-a-project',
    }),
    lockedIssueDocsPath: helpPagePath('user/discussions/index.md', {
      anchor: 'prevent-comments-by-locking-the-discussion',
    }),
    projectArchivedWarning: __('This project is archived and cannot be commented on.'),
  },
  computed: {
    issuableDisplayName() {
      return this.workItemType.replace(/_/g, ' ');
    },
    lockedIssueWarning() {
      return sprintf(
        __('This %{issuableDisplayName} is locked. Only project members can comment.'),
        { issuableDisplayName: this.issuableDisplayName },
      );
    },
  },
};
</script>

<template>
  <div class="disabled-comment gl-text-center gl-relative gl-mt-3">
    <span
      class="issuable-note-warning gl-display-inline-block gl-w-full gl-px-5 gl-py-4 gl-rounded-base"
    >
      <gl-icon name="lock" class="gl-mr-2" />
      <template v-if="isProjectArchived">
        {{ $options.constantOptions.projectArchivedWarning }}
        <gl-link :href="$options.constantOptions.archivedProjectDocsPath" class="learn-more">
          {{ __('Learn more') }}
        </gl-link>
      </template>

      <template v-else>
        {{ lockedIssueWarning }}
        <gl-link :href="$options.constantOptions.lockedIssueDocsPath" class="learn-more">
          {{ __('Learn more') }}
        </gl-link>
      </template>
    </span>
  </div>
</template>
