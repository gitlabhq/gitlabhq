<script>
import { GlDropdown, GlDropdownDivider, GlDropdownForm, GlButton } from '@gitlab/ui';
import { Editor as TiptapEditor } from '@tiptap/vue-2';
import { __, sprintf } from '~/locale';
import { clamp } from '../services/utils';

export const tableContentType = 'table';

const MIN_ROWS = 3;
const MIN_COLS = 3;
const MAX_ROWS = 8;
const MAX_COLS = 8;

export default {
  components: {
    GlDropdown,
    GlDropdownDivider,
    GlDropdownForm,
    GlButton,
  },
  props: {
    tiptapEditor: {
      type: TiptapEditor,
      required: true,
    },
  },
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
  <gl-dropdown size="small" category="tertiary" icon="table">
    <gl-dropdown-form class="gl-px-3! gl-w-auto!">
      <div class="gl-w-auto!">
        <div v-for="c of list(maxCols)" :key="c" class="gl-display-flex">
          <gl-button
            v-for="r of list(maxRows)"
            :key="r"
            :data-testid="`table-${r}-${c}`"
            :class="{ 'gl-bg-blue-50!': r <= rows && c <= cols }"
            :aria-label="getButtonLabel(r, c)"
            class="gl-display-inline! gl-px-0! gl-w-5! gl-h-5! gl-rounded-0!"
            @mouseover="setRowsAndCols(r, c)"
            @click="insertTable()"
          />
        </div>
        <gl-dropdown-divider />
        {{ getButtonLabel(rows, cols) }}
      </div>
    </gl-dropdown-form>
  </gl-dropdown>
</template>
