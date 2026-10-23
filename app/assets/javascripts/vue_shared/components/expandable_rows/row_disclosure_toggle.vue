<script>
import { GlButton } from '@gitlab/ui';
import { __, sprintf } from '~/locale';

const INDENT_PER_LEVEL_REM = 2;

/**
 * The first cell of an expandable table row: a chevron that expands or collapses the row,
 * followed by the cell's content, indented by the row's depth.
 */
export default {
  name: 'RowDisclosureToggle',
  components: {
    GlButton,
  },
  props: {
    /**
     * Names the row for the toggle's accessible label, as in "Rows under Platform".
     */
    label: {
      type: String,
      required: true,
    },
    expandable: {
      type: Boolean,
      required: false,
      default: false,
    },
    expanded: {
      type: Boolean,
      required: false,
      default: false,
    },
    /**
     * Nesting level, 0 for a top-level row.
     */
    depth: {
      type: Number,
      required: false,
      default: 0,
    },
    /**
     * Names the parent row of a nested row. Screen readers don't see the indent, so they
     * get "Under Platform" after the content instead.
     */
    parentLabel: {
      type: String,
      required: false,
      default: '',
    },
    /**
     * DOM ids of the row's child rows, for the toggle's `aria-controls`. Applied only while
     * expanded, because collapsed child rows aren't rendered.
     */
    childRowIds: {
      type: Array,
      required: false,
      default: () => [],
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['toggle'],
  computed: {
    // The name stays the same in both states, so `aria-expanded` alone announces the state.
    toggleLabel() {
      return sprintf(__('Rows under %{name}'), { name: this.label }, false);
    },
    parentText() {
      return this.depth && this.parentLabel
        ? sprintf(__('Under %{name}'), { name: this.parentLabel }, false)
        : '';
    },
    ariaControls() {
      return this.expanded && this.childRowIds.length ? this.childRowIds.join(' ') : null;
    },
    indentStyle() {
      return this.depth ? { paddingInlineStart: `${this.depth * INDENT_PER_LEVEL_REM}rem` } : null;
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-items-center gl-gap-2" :style="indentStyle">
    <!-- aria-expanded stays a string: Vue 2 drops a bound `false`, taking the collapsed state out of the DOM. -->
    <gl-button
      v-if="expandable"
      :icon="expanded ? 'chevron-down' : 'chevron-right'"
      :aria-label="toggleLabel"
      :aria-expanded="expanded ? 'true' : 'false'"
      :aria-controls="ariaControls"
      :loading="loading"
      category="tertiary"
      size="small"
      data-testid="row-disclosure-toggle"
      @click="$emit('toggle')"
    />
    <!-- Holds the toggle's space, a small button's 24px, so rows without one stay aligned. -->
    <span
      v-else
      class="gl-h-6 gl-w-6 gl-shrink-0"
      aria-hidden="true"
      data-testid="row-disclosure-placeholder"
    ></span>
    <div class="gl-min-w-0">
      <slot></slot>
      <span v-if="parentText" class="gl-sr-only" data-testid="row-disclosure-parent">{{
        parentText
      }}</span>
    </div>
  </div>
</template>
