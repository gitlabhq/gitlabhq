<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import { toggleWikiSidebar } from '~/wikis/utils/sidebar_toggle';

export default {
  name: 'WikiSidebarToggle',
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    action: {
      type: String,
      required: true,
      validator: (action) => ['open', 'close'].includes(action),
    },
  },
  computed: {
    icon() {
      return this.action === 'open' ? 'list-bulleted' : 'chevron-double-lg-left';
    },
    title() {
      return this.action === 'open' ? __('Open sidebar') : __('Close sidebar');
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
    class="wiki-sidebar-header-toggle"
    :icon="icon"
    category="tertiary"
    :title="title"
    :aria-label="title"
    @click="toggleWikiSidebar"
  />
</template>
