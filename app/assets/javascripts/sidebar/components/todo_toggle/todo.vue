<script>
import { __ } from '~/locale';
import tooltip from '~/vue_shared/directives/tooltip';

import Icon from '~/vue_shared/components/icon.vue';

const MARK_TEXT = __('Mark todo as done');
const TODO_TEXT = __('Add todo');

export default {
  directives: {
    tooltip,
  },
  components: {
    Icon,
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
      return this.collapsed ?
        'btn-blank btn-todo sidebar-collapsed-icon dont-change-state' :
        'btn btn-default btn-todo issuable-header-btn float-right';
    },
    buttonLabel() {
      return this.isTodo ? MARK_TEXT : TODO_TEXT;
    },
    collapsedButtonIconClasses() {
      return this.isTodo ? 'todo-undone' : '';
    },
    collapsedButtonIcon() {
      return this.isTodo ? 'todo-done' : 'todo-add';
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
    :title="buttonLabel"
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
      v-show="collapsed"
      :css-classes="collapsedButtonIconClasses"
      :name="collapsedButtonIcon"
    />
    <span
      v-show="!collapsed"
      class="issuable-todo-inner"
    >
      {{ buttonLabel }}
    </span>
    <gl-loading-icon
      v-show="isActionActive"
      :inline="true"
    />
  </button>
</template>
