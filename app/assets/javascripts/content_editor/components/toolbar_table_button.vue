<script>
import {
  GlDropdown,
  GlDropdownDivider,
  GlDropdownForm,
  GlButton,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { clamp } from '../services/utils';

export const tableContentType = 'table';

const MIN_ROWS = 5;
const MIN_COLS = 5;
const MAX_ROWS = 10;
const MAX_COLS = 10;

export default {
  components: {
    GlButton,
    GlDropdown,
    GlDropdownDivider,
    GlDropdownForm,
  },
  directives: {
    GlTooltip,
  },
  inject: ['tiptapEditor'],
  data() {
    return {
      maxRows: MIN_ROWS,
      maxCols: MIN_COLS,
      rows: 1,
      cols: 1,
    };
  },
  methods: {
    list(n) {
      return new Array(n).fill().map((_, i) => i + 1);
    },
    setRowsAndCols(rows, cols) {
      this.rows = rows;
      this.cols = cols;
      this.maxRows = clamp(rows + 1, MIN_ROWS, MAX_ROWS);
      this.maxCols = clamp(cols + 1, MIN_COLS, MAX_COLS);
    },
    resetState() {
      this.rows = 1;
      this.cols = 1;
    },
    insertTable() {
      this.tiptapEditor
        .chain()
        .focus()
        .insertTable({
          rows: this.rows,
          cols: this.cols,
          withHeaderRow: true,
        })
        .run();

      this.resetState();

      this.$emit('execute', { contentType: 'table' });
    },
    getButtonLabel(rows, cols) {
      return sprintf(__('Insert a %{rows}x%{cols} table.'), { rows, cols });
    },
  },
};
</script>
<template>
  <gl-dropdown
    v-gl-tooltip
    size="small"
    category="tertiary"
    icon="table"
    :title="__('Insert table')"
    :text="__('Insert table')"
    class="content-editor-dropdown"
    right
    text-sr-only
    lazy
  >
    <gl-dropdown-form class="gl-px-3! gl-pb-2!">
      <div v-for="r of list(maxRows)" :key="r" class="gl-display-flex">
        <gl-button
          v-for="c of list(maxCols)"
          :key="c"
          :data-testid="`table-${r}-${c}`"
          :class="{ 'active gl-bg-blue-50!': r <= rows && c <= cols }"
          :aria-label="getButtonLabel(r, c)"
          class="table-creator-grid-item gl-display-inline gl-rounded-0! gl-w-6! gl-h-6! gl-p-0!"
          @mouseover="setRowsAndCols(r, c)"
          @click="insertTable()"
        />
      </div>
      <gl-dropdown-divider class="gl-my-3! gl-mx-n3!" />
      <div class="gl-px-1">
        {{ getButtonLabel(rows, cols) }}
      </div>
    </gl-dropdown-form>
  </gl-dropdown>
</template>
