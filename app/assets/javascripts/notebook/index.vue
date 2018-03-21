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
    codeCssClass: {
      type: String,
      required: false,
      default: '',
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
      return `${type}-cell`;
    },
  },
};
</script>

<template>
  <div v-if="hasNotebook">
    <component
      v-for="(cell, index) in cells"
      :is="cellType(cell.cell_type)"
      :cell="cell"
      :key="index"
      :code-css-class="codeCssClass"
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

.cell pre {
  margin: 0;
  width: 100%;
}
</style>
