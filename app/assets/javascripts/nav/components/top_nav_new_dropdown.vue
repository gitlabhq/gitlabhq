<script>
import { GlDropdown, GlDropdownDivider, GlDropdownItem, GlDropdownSectionHeader } from '@gitlab/ui';

export default {
  components: {
    GlDropdown,
    GlDropdownDivider,
    GlDropdownItem,
    GlDropdownSectionHeader,
  },
  props: {
    viewModel: {
      type: Object,
      required: true,
    },
  },
  computed: {
    sections() {
      return this.viewModel.menu_sections || [];
    },
    showHeaders() {
      return this.sections.length > 1;
    },
  },
};
</script>

<template>
  <gl-dropdown
    toggle-class="top-nav-menu-item"
    icon="plus"
    :text="viewModel.title"
    category="tertiary"
    text-sr-only
    no-caret
    right
  >
    <template v-for="({ title, menu_items }, index) in sections">
      <gl-dropdown-divider v-if="index > 0" :key="`${index}_divider`" data-testid="divider" />
      <gl-dropdown-section-header v-if="showHeaders" :key="`${index}_header`" data-testid="header">
        {{ title }}
      </gl-dropdown-section-header>
      <template v-for="menuItem in menu_items">
        <gl-dropdown-item
          :key="`${index}_item_${menuItem.id}`"
          link-class="top-nav-menu-item"
          :href="menuItem.href"
          data-testid="item"
        >
          {{ menuItem.title }}
        </gl-dropdown-item>
      </template>
    </template>
  </gl-dropdown>
</template>
