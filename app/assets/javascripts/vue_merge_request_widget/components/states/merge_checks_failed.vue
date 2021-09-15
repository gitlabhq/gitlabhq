<script>
import { GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import notesEventHub from '~/notes/event_hub';
import StatusIcon from '../mr_widget_status_icon.vue';

export default {
  i18n: {
    pipelineFailed: s__(
      'mrWidget|The pipeline for this merge request did not complete. Push a new commit to fix the failure.',
    ),
    approvalNeeded: s__('mrWidget|You can only merge once this merge request is approved.'),
    unresolvedDiscussions: s__('mrWidget|Merge blocked: all threads must be resolved.'),
  },
  components: {
    StatusIcon,
    GlButton,
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  computed: {
    failedText() {
      if (this.mr.isPipelineFailed) {
        return this.$options.i18n.pipelineFailed;
      } else if (this.mr.approvals && !this.mr.isApproved) {
        return this.$options.i18n.approvalNeeded;
      } else if (this.mr.hasMergeableDiscussionsState) {
        return this.$options.i18n.unresolvedDiscussions;
      }

      return null;
    },
  },
  methods: {
    jumpToFirstUnresolvedDiscussion() {
      notesEventHub.$emit('jumpToFirstUnresolvedDiscussion');
    },
  },
};
</script>

<template>
  <div class="mr-widget-body media gl-flex-wrap">
    <status-icon status="warning" />
    <p class="media-body gl-m-0! gl-font-weight-bold gl-text-black-normal!">
      {{ failedText }}
      <template v-if="failedText == $options.i18n.unresolvedDiscussions">
        <gl-button
          class="gl-ml-3"
          size="small"
          variant="confirm"
          data-testid="jumpToUnresolved"
          @click="jumpToFirstUnresolvedDiscussion"
        >
          {{ s__('mrWidget|Jump to first unresolved thread') }}
        </gl-button>
        <gl-button
          v-if="mr.createIssueToResolveDiscussionsPath"
          :href="mr.createIssueToResolveDiscussionsPath"
          class="gl-ml-3"
          size="small"
          variant="confirm"
          category="secondary"
          data-testid="resolveIssue"
        >
          {{ s__('mrWidget|Create issue to resolve all threads') }}
        </gl-button>
      </template>
    </p>
  </div>
</template>
