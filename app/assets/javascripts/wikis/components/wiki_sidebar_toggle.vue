<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import { toggleWikiSidebar } from '~/wikis/utils/sidebar_toggle';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  name: 'WikiSidebarToggle',
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    action: {
      type: String,
      required: true,
      validator: (action) => ['open', 'close'].includes(action),
    },
  },
  computed: {
    icon() {
      const iconOpen = this.glFeatures.wikiFloatingSidebarToggle ? 'sidebar' : 'list-bulleted';
      return this.action === 'open' ? iconOpen : 'chevron-double-lg-left';
    },
    title() {
      return this.action === 'open' ? __('Open sidebar') : __('Close sidebar');
    },
    category() {
      if (this.glFeatures.wikiFloatingSidebarToggle && this.action === 'open') {
        return 'secondary';
      }
      return 'tertiary';
    },
    cssClass() {
      return `toggle-action-${this.action}`;
    },
  },
  methods: {
    toggleWikiSidebar,
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip
    data-testid="wiki-sidebar-toggle"
    class="wiki-sidebar-toggle"
    :class="cssClass"
    :icon="icon"
    :category="category"
    :title="title"
    :aria-label="title"
    @click="toggleWikiSidebar"
  />
</template>
