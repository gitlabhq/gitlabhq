<script>
import CodeCell from './code/index.vue';
import OutputCell from './output/index.vue';

export default {
  components: {
    'code-cell': CodeCell,
    'output-cell': OutputCell,
  },
  props: {
    cell: {
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
    rawInputCode() {
      if (this.cell.source) {
        return this.cell.source.join('');
      }

      return '';
    },
    hasOutput() {
      return this.cell.outputs.length;
    },
    output() {
      return this.cell.outputs[0];
    },
  },
};
</script>

<template>
  <div class="cell">
    <code-cell
      type="input"
      :raw-code="rawInputCode"
      :count="cell.execution_count"
      :code-css-class="codeCssClass" />
    <output-cell
      v-if="hasOutput"
      :count="cell.execution_count"
      :output="output"
      :code-css-class="codeCssClass" />
  </div>
</template>

<style scoped>
.cell {
  flex-direction: column;
}
</style>
