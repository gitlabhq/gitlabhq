<script>
import { GlButton } from '@gitlab/ui';

/**
 * Basic formatting component for import history table rows.
 *
 * This component is just a grid layout wrapper with slots and a few props to control their visibility.
 *
 * Should be used with the `import_history_table_header` component.
 */
export default {
  name: 'ImportHistoryTableRow',
  components: {
    GlButton,
  },
  props: {
    /** Specifies if the table row is nested under another table row (e.g. a nested row of a folder). */
    isNested: {
      type: Boolean,
      required: false,
      default: false,
    },
    /** Controls whether the toggle button will be shown, or a the contents of the `checkbox` slot if its not shown. */
    showToggle: {
      type: Boolean,
      required: true,
    },
    /** Custom grid column layout (useful for overriding layout for different content). */
    gridClasses: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      expanded: false,
    };
  },
  computed: {
    appliedGridClasses() {
      return this.gridClasses || 'md:gl-grid-cols-[repeat(2,1fr),200px,200px]';
    },
  },
  methods: {
    toggleExpand() {
      this.expanded = !this.expanded;
    },
  },
  defaultClasses: '',
};
</script>

<template>
  <div data-testid="import-history-table-row" class="gl-border-t gl-p-5 gl-px-0 gl-pb-0">
    <div
      data-testid="import-history-table-row-main"
      class="gl-grid gl-gap-5 gl-pl-5"
      :class="appliedGridClasses"
    >
      <div
        class="gl-flex gl-items-start gl-gap-3"
        :class="[$options.defaultClasses, isNested && 'gl-pl-7']"
      >
        <gl-button
          v-if="showToggle"
          size="small"
          :aria-label="expanded ? __('Collapse') : __('Expand')"
          :icon="expanded ? 'chevron-down' : 'chevron-right'"
          @click="toggleExpand"
        />
        <div
          v-else
          class="gl-flex gl-h-6 gl-w-6 gl-flex-shrink-0 gl-items-center gl-justify-center"
        >
          <!-- @slot Optionally use to provide a checkbox to show when `showToggle` is false for selecting the row -->
          <slot name="checkbox"></slot>
        </div>
        <div class="gl-flex-grow">
          <!-- @slot The content of the 1st column -->
          <slot name="column-1"></slot>
        </div>
      </div>
      <div :class="$options.defaultClasses">
        <div>
          <!-- @slot The content of the 2nd column -->
          <slot name="column-2"></slot>
        </div>
      </div>
      <div :class="$options.defaultClasses">
        <div>
          <!-- @slot The content of the 3rd column -->
          <slot name="column-3"></slot>
        </div>
      </div>
      <div :class="$options.defaultClasses">
        <div>
          <!-- @slot The content of the 4th column -->
          <slot name="column-4"></slot>
        </div>
      </div>
    </div>
    <div class="gl-pt-5">
      <div v-if="expanded" data-testid="import-history-table-row-expanded">
        <!-- @slot Optionally provide a nested row -->
        <slot name="nested-row"></slot>
        <div
          v-if="$scopedSlots['expanded-content'] && !$scopedSlots['nested-row']"
          data-testid="import-history-table-row-expanded-content"
          class="gl-border-t gl-bg-subtle gl-p-5 gl-pl-9 gl-transition-all"
          :class="isNested && 'gl-pl-12'"
        >
          <!-- @slot Optionally provide expanded content -->
          <slot name="expanded-content"></slot>
        </div>
      </div>
    </div>
  </div>
</template>
