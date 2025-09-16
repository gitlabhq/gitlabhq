<script>
import { GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'WikiDiscussionLocked',
  components: {
    GlIcon,
  },
  inject: ['containerType', 'isContainerArchived'],
  computed: {
    archivedContainerWarning() {
      if (this.containerType === 'group') {
        return __('This group is archived and cannot be commented on.');
      }
      return __('This project is archived and cannot be commented on.');
    },
  },
};
</script>

<template>
  <div class="gl-mt-3" data-testid="disabled-comments">
    <span class="issuable-note-warning gl-inline-block gl-w-full gl-rounded-lg gl-px-5 gl-py-4">
      <gl-icon :size="16" name="lock" class="icon" />
      <span v-if="isContainerArchived">
        {{ archivedContainerWarning }}
      </span>

      <span v-else>
        {{ __('The discussion in this Wiki is locked. Only project members can comment.') }}
      </span>
    </span>
  </div>
</template>
