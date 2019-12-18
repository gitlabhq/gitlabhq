<script>
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { GlSprintf } from '@gitlab/ui';

export default {
  components: {
    TimeAgoTooltip,
    GlSprintf,
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
    <div v-if="snippet.description" class="description" data-qa-selector="snippet_description">
      <div class="md">{{ snippet.description }}</div>
    </div>

    <small v-if="snippet.updatedAt !== snippet.createdAt" class="edited-text">
      <gl-sprintf message="Edited %{timeago}">
        <template #timeago>
          <time-ago-tooltip :time="snippet.updatedAt" tooltip-placement="bottom" />
        </template>
      </gl-sprintf>
    </small>
  </div>
</template>
