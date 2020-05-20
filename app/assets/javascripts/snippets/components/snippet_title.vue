<script>
import { GlSprintf } from '@gitlab/ui';

import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import SnippetDescription from './snippet_description_view.vue';

export default {
  components: {
    TimeAgoTooltip,
    GlSprintf,
    SnippetDescription,
  },
  props: {
    snippet: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <div class="snippet-header limited-header-width">
    <h2 class="snippet-title prepend-top-0 mb-3" data-qa-selector="snippet_title">
      {{ snippet.title }}
    </h2>

    <snippet-description v-if="snippet.description" :description="snippet.descriptionHtml" />

    <small v-if="snippet.updatedAt !== snippet.createdAt" class="edited-text">
      <gl-sprintf :message="__('Edited %{timeago}')">
        <template #timeago>
          <time-ago-tooltip :time="snippet.updatedAt" tooltip-placement="bottom" />
        </template>
      </gl-sprintf>
    </small>
  </div>
</template>
