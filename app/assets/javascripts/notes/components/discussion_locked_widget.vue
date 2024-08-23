<script>
import { GlLink, GlIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import issuableStateMixin from '../mixins/issuable_state';

export default {
  components: {
    GlIcon,
    GlLink,
  },
  mixins: [issuableStateMixin],
  props: {
    issuableType: {
      required: true,
      type: String,
    },
  },
  computed: {
    issuableDisplayName() {
      return this.issuableType.replace(/_/g, ' ');
    },
    projectArchivedWarning() {
      return __('This project is archived and cannot be commented on.');
    },
    lockedIssueWarning() {
      return sprintf(
        __(
          'The discussion in this %{issuableDisplayName} is locked. Only project members can comment.',
        ),
        { issuableDisplayName: this.issuableDisplayName },
      );
    },
  },
};
</script>

<template>
  <div class="gl-mt-3" data-testid="disabled-comments">
    <span class="issuable-note-warning gl-inline-block gl-w-full gl-rounded-base gl-px-5 gl-py-4">
      <gl-icon :size="16" name="lock" class="icon" />
      <span v-if="isProjectArchived">
        {{ projectArchivedWarning }}
        <gl-link :href="archivedProjectDocsPath" target="_blank" class="learn-more">
          {{ __('Learn more') }}
        </gl-link>
      </span>

      <span v-else>
        {{ lockedIssueWarning }}
        <gl-link :href="lockedIssueDocsPath" target="_blank" class="learn-more">
          {{ __('Learn more') }}
        </gl-link>
      </span>
    </span>
  </div>
</template>
