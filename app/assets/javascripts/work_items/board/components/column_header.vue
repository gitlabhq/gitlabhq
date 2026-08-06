<script>
import { GlButton, GlIcon, GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { hasDecorationIcon, decorationIconStyle } from '~/work_items/board/grouping';
import { BOARD_COLUMN_DRAG_HANDLE_CLASS, BOARD_COLUMN_NO_DRAG_CLASS } from '../constants';

export default {
  name: 'ColumnHeader',
  collapsedVerticalTextStyle: { writingMode: 'vertical-rl' },
  dragHandleClass: BOARD_COLUMN_DRAG_HANDLE_CLASS,
  noDragClass: BOARD_COLUMN_NO_DRAG_CLASS,
  i18n: {
    collapse: __('Collapse'),
    expand: __('Expand'),
    actions: s__('WorkItemBoard|Column actions'),
    moveLeft: s__('WorkItemBoard|Move left'),
    moveRight: s__('WorkItemBoard|Move right'),
  },
  components: {
    GlButton,
    GlIcon,
    GlDisclosureDropdown,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    value: {
      type: Object,
      required: true,
    },
    // Grouping-strategy descriptor of how to render this column's value, e.g.
    // `{ type: 'icon', name, color }`. See board/grouping/index.js.
    decoration: {
      type: Object,
      required: true,
    },
    count: {
      type: Number,
      required: true,
    },
    collapsed: {
      type: Boolean,
      required: false,
      default: false,
    },
    controlsId: {
      type: String,
      required: false,
      default: '',
    },
    reorderable: {
      type: Boolean,
      required: false,
      default: false,
    },
    canMoveLeft: {
      type: Boolean,
      required: false,
      default: false,
    },
    canMoveRight: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['toggle-collapse', 'move-column'],
  computed: {
    showIcon() {
      return hasDecorationIcon(this.decoration);
    },
    iconColorStyle() {
      return decorationIconStyle(this.decoration);
    },
    toggleLabel() {
      return this.collapsed ? this.$options.i18n.expand : this.$options.i18n.collapse;
    },
    showActionsMenu() {
      return this.reorderable && !this.collapsed;
    },
    actionItems() {
      // `move-column` carries a delta (columns to shift by): -1 = left, +1 = right.
      // A delta keeps board_view's handler position-agnostic and leaves room to
      // add larger jumps (e.g. move to start/end) later without new event types.
      return [
        {
          text: this.$options.i18n.moveLeft,
          icon: 'arrow-left',
          action: () => this.$emit('move-column', -1),
          extraAttrs: { disabled: !this.canMoveLeft },
        },
        {
          text: this.$options.i18n.moveRight,
          icon: 'arrow-right',
          action: () => this.$emit('move-column', 1),
          extraAttrs: { disabled: !this.canMoveRight },
        },
      ];
    },
  },
};
</script>

<template>
  <div
    class="gl-flex gl-gap-3"
    :class="[
      collapsed ? 'gl-flex-col gl-items-center gl-py-4 gl-pb-6' : 'gl-h-9 gl-items-center gl-px-3',
      { [$options.dragHandleClass]: reorderable, 'gl-cursor-grab': reorderable },
    ]"
    data-testid="column-header"
  >
    <gl-button
      v-gl-tooltip
      category="tertiary"
      size="small"
      :icon="collapsed ? 'chevron-right' : 'chevron-down'"
      :title="toggleLabel"
      :aria-label="toggleLabel"
      :aria-expanded="collapsed ? 'false' : 'true'"
      :aria-controls="controlsId || null"
      class="gl-shrink-0"
      data-testid="column-collapse-toggle"
      @click="$emit('toggle-collapse')"
    />
    <gl-icon
      v-if="showIcon"
      :name="decoration.name"
      :size="12"
      :style="iconColorStyle"
      class="gl-shrink-0"
      :class="{ 'gl-rotate-90': collapsed }"
    />
    <h3
      data-testid="column-header-name"
      class="gl-m-0 gl-min-w-0 gl-truncate gl-text-base gl-font-bold"
      :class="{ 'gl-mr-2': !collapsed }"
      :style="collapsed ? $options.collapsedVerticalTextStyle : null"
    >
      {{ value.name }}
    </h3>
    <span
      data-testid="column-header-count"
      class="gl-flex gl-shrink-0 gl-items-center gl-gap-1 gl-text-sm gl-font-bold gl-text-subtle"
      :style="collapsed ? $options.collapsedVerticalTextStyle : null"
    >
      <gl-icon name="work-items" :size="16" :class="{ 'gl-rotate-90': collapsed }" />
      {{ count }}
    </span>
    <gl-disclosure-dropdown
      v-if="showActionsMenu"
      :items="actionItems"
      :toggle-text="$options.i18n.actions"
      :class="$options.noDragClass"
      class="gl-ml-auto gl-shrink-0"
      icon="ellipsis_v"
      category="tertiary"
      size="small"
      placement="bottom-end"
      no-caret
      text-sr-only
      data-testid="column-actions-menu"
    />
  </div>
</template>
