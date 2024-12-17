<script>
import { GlTooltipDirective, GlSprintf } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import SnippetDescription from './snippet_description_view.vue';

export default {
  name: 'SnippetTitle',
  components: {
    TimeAgoTooltip,
    GlSprintf,
    SnippetDescription,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
  <div data-testid="snippet-description">
    <snippet-description v-if="snippet.description" :description="snippet.descriptionHtml" />

    <small
      v-if="snippet.updatedAt !== snippet.createdAt"
      class="edited-text gl-mt-4 gl-inline-block gl-text-subtle"
    >
      <gl-sprintf :message="__('Edited %{timeago}')">
        <template #timeago>
          <time-ago-tooltip :time="snippet.updatedAt" tooltip-placement="bottom" />
        </template>
      </gl-sprintf>
    </small>
  </div>
</template>
