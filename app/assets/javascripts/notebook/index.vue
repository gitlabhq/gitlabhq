<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { MarkdownCell, CodeCell } from './cells';

export default {
  components: {
    CodeCell,
    MarkdownCell,
  },
  props: {
    notebook: {
      type: Object,
      required: true,
    },
  },
  computed: {
    cells() {
      if (this.notebook.worksheets) {
        const data = {
          cells: [],
        };

        return this.notebook.worksheets.reduce((cellData, sheet) => {
          const cellDataCopy = cellData;
          cellDataCopy.cells = cellDataCopy.cells.concat(sheet.cells);
          return cellDataCopy;
        }, data).cells;
      }

      return this.notebook.cells;
    },
    hasNotebook() {
      return Object.keys(this.notebook).length;
    },
  },
  methods: {
    cellType(type) {
      return `${type}-cell`; // eslint-disable-line @gitlab/require-i18n-strings
    },
  },
};
</script>

<template>
  <div v-if="hasNotebook">
    <component
      :is="cellType(cell.cell_type)"
      v-for="(cell, index) in cells"
      :key="index"
      :cell="cell"
    />
  </div>
</template>

<style>
.cell,
.input,
.output {
  display: flex;
  width: 100%;
  margin-bottom: 10px;
}

.output .text-cell {
  overflow-x: auto;
}

.cell pre {
  margin: 0;
  width: 100%;
}
</style>
