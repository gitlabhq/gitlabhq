<script>
import { GlButton, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import { hasDecorationIcon, decorationIconStyle } from '~/work_items/board/grouping';

export default {
  name: 'ColumnHeader',
  collapsedVerticalTextStyle: { writingMode: 'vertical-rl' },
  i18n: {
    collapse: __('Collapse'),
    expand: __('Expand'),
  },
  components: {
    GlButton,
    GlIcon,
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
  },
  emits: ['toggle-collapse'],
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
  },
};
</script>

<template>
  <div
    class="gl-flex gl-gap-3"
    :class="
      collapsed ? 'gl-flex-col gl-items-center gl-py-4 gl-pb-6' : 'gl-h-9 gl-items-center gl-px-3'
    "
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
  </div>
</template>
