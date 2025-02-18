<script>
import { BASE_IMPORT_TABLE_ROW_GRID_CLASSES } from './constants';
/**
 * Basic formatting component for import history table header.
 *
 * This component is just a grid layout wrapper with slots and single optional grid class override prop.
 *
 * Should be used with the `import_history_table_row` component.
 */
export default {
  name: 'ImportHistoryTableHeader',
  props: {
    /** Custom grid column layout (useful for overriding layout for different content). */
    gridClasses: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    appliedGridClasses() {
      return this.gridClasses || BASE_IMPORT_TABLE_ROW_GRID_CLASSES;
    },
  },
  defaultClasses: 'gl-flex gl-flex-grow gl-items-center gl-gap-3  gl-font-bold',
};
</script>

<template>
  <div class="gl-border-t gl-grid gl-gap-5 gl-py-5 gl-pl-5" :class="appliedGridClasses">
    <div :class="$options.defaultClasses">
      <div
        v-if="$scopedSlots.checkbox"
        class="gl-flex gl-h-6 gl-w-6 gl-flex-shrink-0 gl-items-center gl-justify-center"
      >
        <!-- @slot Optionally pass in a checkbox for select-all controls -->
        <slot name="checkbox"></slot>
      </div>
      <!-- @slot The content of the 1st column -->
      <slot name="column-1"></slot>
    </div>
    <div :class="$options.defaultClasses">
      <!-- @slot The content of the 2nd column -->
      <slot name="column-2"></slot>
    </div>
    <div :class="$options.defaultClasses">
      <!-- @slot The content of the 3rd column -->
      <slot name="column-3"></slot>
    </div>
    <div :class="$options.defaultClasses">
      <!-- @slot The content of the 4th column -->
      <slot name="column-4"></slot>
    </div>
  </div>
</template>
