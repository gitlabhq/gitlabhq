<script>
import { GlLink, GlIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';

export default {
  name: 'WikiDiscussionLocked',
  components: {
    GlIcon,
    GlLink,
  },
  inject: ['containerType', 'isContainerArchived', 'archivedProjectDocsPath', 'lockedWikiDocsPath'],
  computed: {
    archivedContainerWarning() {
      if (this.containerType === 'group') {
        return __('This group has been scheduled for deletion and cannot be commented on.');
      }
      return __('This project is archived and cannot be commented on.');
    },
    lockedDiscussionWarning() {
      return sprintf(
        __('The discussion in this Wiki is locked. Only project members can comment.'),
      );
    },
  },
};
</script>

<template>
  <div class="gl-mt-3" data-testid="disabled-comments">
    <span class="issuable-note-warning gl-inline-block gl-w-full gl-rounded-base gl-px-5 gl-py-4">
      <gl-icon :size="16" name="lock" class="icon" />
      <span v-if="isContainerArchived">
        {{ archivedContainerWarning }}
        <gl-link :href="archivedProjectDocsPath" target="_blank" class="learn-more">
          {{ __('Learn more') }}
        </gl-link>
      </span>

      <span v-else>
        {{ lockedDiscussionWarning }}
        <gl-link :href="lockedWikiDocsPath" target="_blank" class="learn-more">
          {{ __('Learn more') }}
        </gl-link>
      </span>
    </span>
  </div>
</template>
