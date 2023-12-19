<script>
import { GlIcon, GlTooltipDirective, GlSprintf } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import SnippetDescription from './snippet_description_view.vue';

export default {
  name: 'SnippetTitle',
  i18n: {
    hiddenTooltip: s__('Snippets|This snippet is hidden because its author has been banned'),
    hiddenAriaLabel: __('Hidden'),
  },
  components: {
    GlIcon,
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
  <div class="snippet-header limited-header-width gl-py-3">
    <div class="gl-display-flex">
      <span
        v-if="snippet.hidden"
        class="gl-bg-orange-50 gl-text-orange-600 gl-h-6 gl-w-6 border-radius-default gl-line-height-24 gl-text-center gl-mr-3 gl-mt-2"
      >
        <gl-icon
          v-gl-tooltip.bottom
          name="spam"
          :title="$options.i18n.hiddenTooltip"
          :aria-label="$options.i18n.hiddenAriaLabel"
        />
      </span>

      <h2 class="snippet-title gl-mt-0 gl-mb-5" data-testid="snippet-title-content">
        {{ snippet.title }}
      </h2>
    </div>

    <snippet-description v-if="snippet.description" :description="snippet.descriptionHtml" />

    <small
      v-if="snippet.updatedAt !== snippet.createdAt"
      class="edited-text gl-text-secondary gl-display-inline-block gl-mt-4"
    >
      <gl-sprintf :message="__('Edited %{timeago}')">
        <template #timeago>
          <time-ago-tooltip :time="snippet.updatedAt" tooltip-placement="bottom" />
        </template>
      </gl-sprintf>
    </small>
  </div>
</template>
