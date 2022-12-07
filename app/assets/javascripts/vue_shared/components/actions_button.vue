<script>
import { GlDropdown, GlDropdownItem, GlDropdownDivider, GlButton, GlTooltip } from '@gitlab/ui';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlButton,
    GlTooltip,
  },
  props: {
    id: {
      type: String,
      required: false,
      default: '',
    },
    actions: {
      type: Array,
      required: true,
    },
    selectedKey: {
      type: String,
      required: false,
      default: '',
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
    showActionTooltip: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    hasMultipleActions() {
      return this.actions.length > 1;
    },
    selectedAction() {
      return this.actions.find((x) => x.key === this.selectedKey) || this.actions[0];
    },
  },
  methods: {
    handleItemClick(action) {
      this.$emit('select', action.key);
    },
    handleClick(action, evt) {
      this.$emit('actionClicked', { action });
      return action.handle?.(evt);
    },
  },
};
</script>

<template>
  <span>
    <gl-dropdown
      v-if="hasMultipleActions"
      :id="id"
      :text="selectedAction.text"
      :split-href="selectedAction.href"
      :variant="variant"
      :category="category"
      split
      data-qa-selector="action_dropdown"
      @click="handleClick(selectedAction, $event)"
    >
      <template #button-content>
        <span class="gl-dropdown-button-text" v-bind="selectedAction.attrs">
          {{ selectedAction.text }}
        </span>
      </template>
      <template v-for="(action, index) in actions">
        <gl-dropdown-item
          :key="action.key"
          is-check-item
          :is-checked="action.key === selectedAction.key"
          :secondary-text="action.secondaryText"
          :data-qa-selector="`${action.key}_menu_item`"
          :data-testid="`action_${action.key}`"
          @click="handleItemClick(action)"
        >
          <span class="gl-font-weight-bold">{{ action.text }}</span>
        </gl-dropdown-item>
        <gl-dropdown-divider v-if="index != actions.length - 1" :key="action.key + '_divider'" />
      </template>
    </gl-dropdown>
    <gl-button
      v-else-if="selectedAction"
      :id="id"
      v-bind="selectedAction.attrs"
      :variant="variant"
      :category="category"
      :href="selectedAction.href"
      @click="handleClick(selectedAction, $event)"
    >
      {{ selectedAction.text }}
    </gl-button>
    <gl-tooltip v-if="selectedAction.tooltip && showActionTooltip" :target="id">
      {{ selectedAction.tooltip }}
    </gl-tooltip>
  </span>
</template>
