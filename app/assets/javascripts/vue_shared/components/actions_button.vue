<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';

export default {
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
  },
  props: {
    toggleText: {
      type: String,
      required: true,
    },
    actions: {
      type: Array,
      required: true,
    },
    category: {
      type: String,
      required: false,
      default: 'secondary',
    },
    variant: {
      type: String,
      required: false,
      default: 'default',
    },
  },
  methods: {
    handleItemClick(action) {
      return action.handle?.();
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    :variant="variant"
    :category="category"
    :toggle-text="toggleText"
    data-qa-selector="action_dropdown"
  >
    <gl-disclosure-dropdown-group>
      <gl-disclosure-dropdown-item
        v-for="action in actions"
        :key="action.key"
        v-bind="action.attrs"
        :item="action"
        :data-qa-selector="`${action.key}_menu_item`"
        @action="handleItemClick(action)"
      >
        <template #list-item>
          <div class="gl-display-flex gl-flex-direction-column">
            <span class="gl-font-weight-bold gl-mb-2">{{ action.text }}</span>
            <span class="gl-text-gray-700">
              {{ action.secondaryText }}
            </span>
          </div>
        </template>
      </gl-disclosure-dropdown-item>
    </gl-disclosure-dropdown-group>
  </gl-disclosure-dropdown>
</template>
