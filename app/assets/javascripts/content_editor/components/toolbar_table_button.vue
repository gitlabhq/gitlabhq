<script>
import { GlDisclosureDropdown, GlButton, GlTooltip } from '@gitlab/ui';
import { uniqueId } from 'lodash';
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
    GlDisclosureDropdown,
    GlTooltip,
  },
  data() {
    return {
      toggleId: uniqueId('dropdown-toggle-btn-'),
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
      this.maxRows = clamp(rows + 1, this.maxRows, MAX_ROWS);
      this.maxCols = clamp(cols + 1, this.maxCols, MAX_COLS);
    },
    resetState() {
      this.rows = 1;
      this.cols = 1;
      this.maxRows = MIN_ROWS;
      this.maxCols = MIN_COLS;
    },
    insertTable() {
      this.$emit('insert-table', { rows: this.rows, cols: this.cols });
      this.resetState();
      this.$refs.dropdown.close();
      this.$emit('execute', { contentType: 'table' });
    },
    getButtonLabel(rows, cols) {
      return sprintf(__('Insert a %{rows}×%{cols} table'), { rows, cols });
    },
    onKeydown(key) {
      const delta = {
        ArrowUp: { rows: -1, cols: 0 },
        ArrowDown: { rows: 1, cols: 0 },
        ArrowLeft: { rows: 0, cols: -1 },
        ArrowRight: { rows: 0, cols: 1 },
      }[key] || { rows: 0, cols: 0 };

      const rows = clamp(this.rows + delta.rows, 1, this.maxRows);
      const cols = clamp(this.cols + delta.cols, 1, this.maxCols);

      this.setRowsAndCols(rows, cols);
    },
    setFocus(row, col) {
      this.resetState();

      this.$refs[`table-${row}-${col}`][0].$el.focus();
    },
  },
  MAX_COLS,
  MAX_ROWS,
};
</script>
<template>
  <div class="gl-inline-flex gl-align-middle">
    <gl-disclosure-dropdown
      ref="dropdown"
      :toggle-id="toggleId"
      size="small"
      category="tertiary"
      icon="table"
      no-caret
      :aria-label="__('Insert table')"
      :toggle-text="__('Insert table')"
      positioning-strategy="fixed"
      class="content-editor-table-dropdown gl-mr-2"
      text-sr-only
      :fluid-width="true"
      @shown="setFocus(1, 1)"
      @hidden="resetState"
    >
      <div
        class="gl-p-3 gl-pt-2"
        role="grid"
        :aria-colcount="$options.MAX_COLS"
        :aria-rowcount="$options.MAX_ROWS"
      >
        <div v-for="r of list(maxRows)" :key="r" class="gl-flex" role="row">
          <div v-for="c of list(maxCols)" :key="c" role="gridcell">
            <gl-button
              :ref="`table-${r}-${c}`"
              :class="{ 'active !gl-bg-blue-50': r <= rows && c <= cols }"
              :aria-label="getButtonLabel(r, c)"
              class="table-creator-grid-item gl-m-2 !gl-rounded-none !gl-p-0"
              @mouseover="setRowsAndCols(r, c)"
              @focus="setRowsAndCols(r, c)"
              @click="insertTable()"
              @keydown="onKeydown($event.key)"
            />
          </div>
        </div>
      </div>
      <div class="gl-border-t gl-px-4 gl-pb-2 gl-pt-3">
        {{ getButtonLabel(rows, cols) }}
      </div>
    </gl-disclosure-dropdown>
    <gl-tooltip :target="toggleId" placement="top">{{ __('Insert table') }}</gl-tooltip>
  </div>
</template>
