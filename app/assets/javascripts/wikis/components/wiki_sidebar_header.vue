<script>
import { GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'WikiSidebarHeader',
  components: { GlButton },
  inject: ['hasCustomSidebar', 'hasWikiPages', 'editSidebarUrl', 'canCreate', 'isEditingSidebar'],
  props: {
    pagesListExpanded: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    headerClasses() {
      return {
        'wiki-list gl-pl-0': this.hasCustomSidebar,
      };
    },
    editCustomSidebarButtonLabel() {
      return this.hasCustomSidebar
        ? s__('Wiki|Edit custom sidebar')
        : s__('Wiki|Add custom sidebar');
    },
  },
  methods: {
    onWikiSidebarButtonClick() {
      if (!this.hasCustomSidebar) return;
      this.$emit('toggle-pages-list');
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-items-center gl-pb-3 gl-pr-1" :class="headerClasses">
    <gl-button
      category="tertiary"
      icon="chevron-double-lg-left"
      class="toggle-close block gutter-toggle js-sidebar-wiki-toggle-close gl-mr-3 gl-block gl-flex-none !gl-pt-0"
    />
    <div
      class="gl-flex gl-items-center gl-overflow-hidden"
      data-testid="wiki-sidebar-title"
      @click="onWikiSidebarButtonClick"
    >
      <h2 class="gl-my-0 gl-mr-3 gl-whitespace-nowrap gl-text-lg">
        {{ s__('Wiki|Wiki Pages') }}
      </h2>
      <gl-button
        v-if="hasCustomSidebar"
        category="tertiary"
        size="small"
        :icon="pagesListExpanded ? 'chevron-down' : 'chevron-right'"
        class="gl-mr-2"
        data-testid="expand-pages-list"
        :aria-label="s__('Wiki|Show pages')"
        :aria-expanded="pagesListExpanded.toString()"
      />
    </div>
    <div class="gl-flex-1"></div>
    <div class="gl-flex-none">
      <gl-button
        v-if="canCreate"
        :href="editSidebarUrl"
        category="tertiary"
        size="small"
        icon="settings"
        class="has-tooltip gl-border-l gl-pl-3"
        :class="{ active: isEditingSidebar }"
        data-testid="edit-wiki-sidebar-button"
        :title="editCustomSidebarButtonLabel"
        :aria-label="editCustomSidebarButtonLabel"
        @click.stop
      />
    </div>
  </div>
</template>
