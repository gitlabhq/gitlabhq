<script>
import { GlDeprecatedButton } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import { __, sprintf } from '~/locale';

import notesEventHub from '../event_hub';

export default {
  components: {
    GlDeprecatedButton,
    Icon,
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
  <li class="timeline-entry note note-wrapper discussion-filter-note js-discussion-filter-note">
    <div class="timeline-icon d-none d-lg-flex">
      <icon name="comment" />
    </div>
    <div class="timeline-content">
      <div ref="timelineContent" v-html="timelineContent"></div>
      <div class="discussion-filter-actions mt-2">
        <gl-deprecated-button ref="showAllActivity" variant="default" @click="selectFilter(0)">
          {{ __('Show all activity') }}
        </gl-deprecated-button>
        <gl-deprecated-button ref="showComments" variant="default" @click="selectFilter(1)">
          {{ __('Show comments only') }}
        </gl-deprecated-button>
      </div>
    </div>
  </li>
</template>
