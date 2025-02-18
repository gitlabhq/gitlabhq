<script>
import { GlButton, GlIcon, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

import notesEventHub from '../event_hub';

export default {
  i18n: {
    information: s__(
      "Notes|You're only seeing %{boldStart}other activity%{boldEnd} in the feed. To add a comment, switch to one of the following options.",
    ),
  },
  components: {
    GlButton,
    GlIcon,
    GlSprintf,
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
    data-testid="discussion-filter-container"
  >
    <div
      class="gl-float-left -gl-mt-1 gl-ml-2 gl-flex gl-h-6 gl-w-6 gl-items-center gl-justify-center gl-rounded-full gl-bg-strong gl-text-subtle"
    >
      <gl-icon name="comment" />
    </div>
    <div class="timeline-content gl-pl-8">
      <div data-testid="discussion-filter-timeline-content">
        <gl-sprintf :message="$options.i18n.information">
          <template #bold="{ content }">
            <b>{{ content }}</b>
          </template>
        </gl-sprintf>
      </div>
      <div class="discussion-filter-actions gl-mt-3 gl-flex">
        <gl-button variant="default" class="gl-mr-3" @click="selectFilter(0)">
          {{ __('Show all activity') }}
        </gl-button>
        <gl-button variant="default" @click="selectFilter(1)">
          {{ __('Show comments only') }}
        </gl-button>
      </div>
    </div>
  </li>
</template>
