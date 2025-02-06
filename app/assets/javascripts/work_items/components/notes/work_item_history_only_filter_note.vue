<script>
import { GlButton, GlIcon, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

import {
  WORK_ITEM_NOTES_FILTER_ALL_NOTES,
  WORK_ITEM_NOTES_FILTER_ONLY_COMMENTS,
} from '~/work_items/constants';

export default {
  WORK_ITEM_NOTES_FILTER_ALL_NOTES,
  WORK_ITEM_NOTES_FILTER_ONLY_COMMENTS,
  i18n: {
    information: s__(
      "WorkItem|You're only seeing %{boldStart}other activity%{boldEnd} in the feed. To add a comment, switch to one of the following options.",
    ),
  },
  components: {
    GlButton,
    GlIcon,
    GlSprintf,
  },
  methods: {
    selectFilter(value) {
      this.$emit('changeFilter', value);
    },
  },
};
</script>

<template>
  <li class="timeline-entry note note-wrapper discussion-filter-note">
    <div
      class="gl-float-left -gl-mt-1 gl-ml-2 gl-flex gl-h-6 gl-w-6 gl-items-center gl-justify-center gl-rounded-full gl-bg-strong gl-text-subtle"
    >
      <gl-icon name="comment" />
    </div>
    <div class="timeline-content gl-pl-8">
      <gl-sprintf :message="$options.i18n.information">
        <template #bold="{ content }">
          <b>{{ content }}</b>
        </template>
      </gl-sprintf>

      <div class="discussion-filter-actions">
        <gl-button
          class="gl-mr-2 gl-mt-3"
          data-testid="show-all-activity"
          @click="selectFilter($options.WORK_ITEM_NOTES_FILTER_ALL_NOTES)"
        >
          {{ __('Show all activity') }}
        </gl-button>
        <gl-button
          class="gl-mt-3"
          data-testid="show-comments-only"
          @click="selectFilter($options.WORK_ITEM_NOTES_FILTER_ONLY_COMMENTS)"
        >
          {{ __('Show comments only') }}
        </gl-button>
      </div>
    </div>
  </li>
</template>
