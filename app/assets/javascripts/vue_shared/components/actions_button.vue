<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownDivider,
  GlLink,
  GlTooltipDirective,
} from '@gitlab/ui';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    actions: {
      type: Array,
      required: true,
    },
    selectedKey: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    hasMultipleActions() {
      return this.actions.length > 1;
    },
    selectedAction() {
      return this.actions.find(x => x.key === this.selectedKey) || this.actions[0];
    },
  },
  methods: {
    handleItemClick(action) {
      this.$emit('select', action.key);
    },
    handleClick(action, evt) {
      return action.handle?.(evt);
    },
  },
};
</script>

<template>
  <gl-dropdown
    v-if="hasMultipleActions"
    v-gl-tooltip="selectedAction.tooltip"
    class="gl-button-deprecated-adapter"
    :text="selectedAction.text"
    :split-href="selectedAction.href"
    split
    @click="handleClick(selectedAction, $event)"
  >
    <template slot="button-content">
      <span class="gl-new-dropdown-button-text" v-bind="selectedAction.attrs">
        {{ selectedAction.text }}
      </span>
    </template>
    <template v-for="(action, index) in actions">
      <gl-dropdown-item
        :key="action.key"
        class="gl-dropdown-item-deprecated-adapter"
        :is-check-item="true"
        :is-checked="action.key === selectedAction.key"
        :secondary-text="action.secondaryText"
        :data-testid="`action_${action.key}`"
        @click="handleItemClick(action)"
      >
        {{ action.text }}
      </gl-dropdown-item>
      <gl-dropdown-divider v-if="index != actions.length - 1" :key="action.key + '_divider'" />
    </template>
  </gl-dropdown>
  <gl-link
    v-else-if="selectedAction"
    v-gl-tooltip="selectedAction.tooltip"
    v-bind="selectedAction.attrs"
    class="btn"
    :href="selectedAction.href"
    @click="handleClick(selectedAction, $event)"
  >
    {{ selectedAction.text }}
  </gl-link>
</template>
