<script>
import { GlButton } from '@gitlab/ui';
import notesEventHub from '~/notes/event_hub';
import statusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'UnresolvedDiscussions',
  components: {
    statusIcon,
    GlButton,
  },
  props: {
    mr: {
      type: Object,
      required: true,
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
    <status-icon :show-disabled-button="true" status="warning" />
    <div class="media-body">
      <span class="gl-ml-3 gl-font-weight-bold gl-display-block gl-w-100">{{
        s__('mrWidget|Merge blocked: all threads must be resolved.')
      }}</span>
      <gl-button
        data-testid="jump-to-first"
        class="gl-ml-3"
        size="small"
        icon="comment-next"
        @click="jumpToFirstUnresolvedDiscussion"
      >
        {{ s__('mrWidget|Jump to first unresolved thread') }}
      </gl-button>
      <gl-button
        v-if="mr.createIssueToResolveDiscussionsPath"
        :href="mr.createIssueToResolveDiscussionsPath"
        class="js-create-issue gl-ml-3"
        size="small"
        icon="issue-new"
      >
        {{ s__('mrWidget|Resolve all threads in new issue') }}
      </gl-button>
    </div>
  </div>
</template>
