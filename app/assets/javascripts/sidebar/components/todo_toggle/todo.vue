<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton, GlLoadingIcon, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

const MARK_TEXT = __('Mark as done');
const TODO_TEXT = __('Add a to-do item');

export default {
  components: {
    GlButton,
    GlIcon,
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    issuableId: {
      type: Number,
      required: true,
    },
    issuableType: {
      type: String,
      required: true,
    },
    isTodo: {
      type: Boolean,
      required: false,
      default: true,
    },
    isActionActive: {
      type: Boolean,
      required: false,
      default: false,
    },
    collapsed: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    buttonClasses() {
      return this.collapsed
        ? 'sidebar-collapsed-icon js-dont-change-state'
        : 'issuable-header-btn gl-float-right';
    },
    buttonVariant() {
      return this.collapsed ? 'link' : 'default';
    },
    buttonLabel() {
      return this.isTodo ? MARK_TEXT : TODO_TEXT;
    },
    buttonTooltip() {
      return !this.collapsed ? undefined : this.buttonLabel;
    },
    collapsedButtonIconClasses() {
      return this.isTodo ? 'todo-undone' : '';
    },
    collapsedButtonIcon() {
      return this.isTodo ? 'todo-done' : 'todo-add';
    },
    collapsedButtonIconVisible() {
      return this.collapsed && !this.isActionActive;
    },
  },
  methods: {
    handleButtonClick() {
      this.$emit('toggleTodo');
    },
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip.left.viewport
    :class="buttonClasses"
    :variant="buttonVariant"
    :title="buttonTooltip"
    :aria-label="buttonLabel"
    :data-issuable-id="issuableId"
    :data-issuable-type="issuableType"
    size="small"
    type="button"
    @click="handleButtonClick"
  >
    <gl-icon
      v-show="collapsedButtonIconVisible"
      :class="collapsedButtonIconClasses"
      :name="collapsedButtonIcon"
    />
    <span v-if="!collapsed" class="issuable-todo-inner">{{ buttonLabel }}</span>
    <gl-loading-icon v-if="isActionActive" size="sm" inline />
  </gl-button>
</template>
