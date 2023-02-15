<script>
import { GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import notesEventHub from '~/notes/event_hub';
import BoldText from '~/vue_merge_request_widget/components/bold_text.vue';
import StateContainer from '../state_container.vue';

const message = s__('mrWidget|%{boldStart}Merge blocked:%{boldEnd} all threads must be resolved.');

export default {
  name: 'UnresolvedDiscussions',
  message,
  components: {
    BoldText,
    GlButton,
    StateContainer,
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
  <state-container :mr="mr" status="failed">
    <span class="gl-ml-3 gl-w-100 gl-flex-grow-1 gl-md-mr-3 gl-ml-0! gl-text-body!">
      <bold-text :message="$options.message" />
    </span>
    <template #actions>
      <gl-button
        data-testid="jump-to-first"
        class="gl-align-self-start gl-vertical-align-top"
        size="small"
        variant="confirm"
        category="primary"
        @click="jumpToFirstUnresolvedDiscussion"
      >
        {{ s__('mrWidget|Jump to first unresolved thread') }}
      </gl-button>
      <gl-button
        v-if="mr.createIssueToResolveDiscussionsPath"
        :href="mr.createIssueToResolveDiscussionsPath"
        class="js-create-issue gl-align-self-start gl-vertical-align-top"
        size="small"
        variant="confirm"
        category="secondary"
      >
        {{ s__('mrWidget|Create issue to resolve all threads') }}
      </gl-button>
    </template>
  </state-container>
</template>
