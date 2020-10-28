<script>
/* eslint-disable vue/no-v-html */
import { GlButton, GlIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';

import notesEventHub from '../event_hub';

export default {
  components: {
    GlButton,
    GlIcon,
  },
  computed: {
    timelineContent() {
      return sprintf(
        __(
          "You're only seeing %{startTag}other activity%{endTag} in the feed. To add a comment, switch to one of the following options.",
        ),
        {
          startTag: `<b>`,
          endTag: `</b>`,
        },
        false,
      );
    },
  },
  methods: {
    selectFilter(value) {
      notesEventHub.$emit('dropdownSelect', value);
    },
  },
};
</script>

<template>
  <li
    class="timeline-entry note note-wrapper discussion-filter-note js-discussion-filter-note"
    data-qa-selector="discussion_filter_container"
  >
    <div class="timeline-icon d-none d-lg-flex">
      <gl-icon name="comment" />
    </div>
    <div class="timeline-content">
      <div ref="timelineContent" v-html="timelineContent"></div>
      <div class="discussion-filter-actions mt-2">
        <gl-button ref="showAllActivity" variant="default" @click="selectFilter(0)">
          {{ __('Show all activity') }}
        </gl-button>
        <gl-button ref="showComments" variant="default" @click="selectFilter(1)">
          {{ __('Show comments only') }}
        </gl-button>
      </div>
    </div>
  </li>
</template>
