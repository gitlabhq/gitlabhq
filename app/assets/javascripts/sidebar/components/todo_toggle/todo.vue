<script>
import { __ } from '~/locale';
import tooltip from '~/vue_shared/directives/tooltip';
import { GlLoadingIcon } from '@gitlab/ui';

import Icon from '~/vue_shared/components/icon.vue';

const MARK_TEXT = __('Mark as done');
const TODO_TEXT = __('Add a To Do');

export default {
  directives: {
    tooltip,
  },
  components: {
    Icon,
    GlLoadingIcon,
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
        ? 'btn-blank btn-todo sidebar-collapsed-icon dont-change-state'
        : 'btn btn-default btn-todo issuable-header-btn float-right';
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
  <button
    v-tooltip
    :class="buttonClasses"
    :title="buttonTooltip"
    :aria-label="buttonLabel"
    :data-issuable-id="issuableId"
    :data-issuable-type="issuableType"
    type="button"
    data-container="body"
    data-placement="left"
    data-boundary="viewport"
    @click="handleButtonClick"
  >
    <icon
      v-show="collapsedButtonIconVisible"
      :class="collapsedButtonIconClasses"
      :name="collapsedButtonIcon"
    />
    <span v-show="!collapsed" class="issuable-todo-inner">{{ buttonLabel }}</span>
    <gl-loading-icon v-show="isActionActive" :inline="true" />
  </button>
</template>
