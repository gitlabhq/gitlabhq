<script>
import { GlTruncateText } from '@gitlab/ui';
import { __ } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  name: 'ProjectListItemDescription',
  i18n: {
    showMore: __('Show more'),
    showLess: __('Show less'),
  },
  truncateTextToggleButtonProps: { class: '!gl-text-sm' },
  components: {
    GlTruncateText,
  },
  directives: {
    SafeHtml,
  },
  props: {
    project: {
      type: Object,
      required: true,
    },
  },
  computed: {
    showDescription() {
      return this.project.descriptionHtml && !this.project.archived;
    },
  },
};
</script>

<template>
  <gl-truncate-text
    v-if="showDescription"
    :lines="2"
    :mobile-lines="2"
    :show-more-text="$options.i18n.showMore"
    :show-less-text="$options.i18n.showLess"
    :toggle-button-props="$options.truncateTextToggleButtonProps"
    class="gl-mt-2 gl-max-w-88"
  >
    <div
      v-safe-html="project.descriptionHtml"
      class="md md-child-content-text-subtle gl-text-sm"
      data-testid="project-description"
    ></div>
  </gl-truncate-text>
</template>
