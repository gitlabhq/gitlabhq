<script>
import { GlDropdown, GlDropdownDivider, GlDropdownItem, GlDropdownSectionHeader } from '@gitlab/ui';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import { TOP_NAV_INVITE_MEMBERS_COMPONENT } from '~/invite_members/constants';

export default {
  components: {
    GlDropdown,
    GlDropdownDivider,
    GlDropdownItem,
    GlDropdownSectionHeader,
    InviteMembersTrigger,
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
  methods: {
    isInvitedMembers(menuItem) {
      return menuItem.component === TOP_NAV_INVITE_MEMBERS_COMPONENT;
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
        <invite-members-trigger
          v-if="isInvitedMembers(menuItem)"
          :key="`${index}_item_${menuItem.id}`"
          :trigger-element="`dropdown-${menuItem.data.trigger_element}`"
          :display-text="menuItem.title"
          :icon="menuItem.icon"
          :trigger-source="menuItem.data.trigger_source"
        />
        <gl-dropdown-item
          v-else
          :key="`${index}_item_${menuItem.id}`"
          link-class="top-nav-menu-item"
          :href="menuItem.href"
          data-testid="item"
          :data-qa-selector="`${menuItem.title.toLowerCase().replace(' ', '_')}_mobile_button`"
        >
          {{ menuItem.title }}
        </gl-dropdown-item>
      </template>
    </template>
  </gl-dropdown>
</template>
