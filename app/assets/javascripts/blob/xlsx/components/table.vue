<template>
  <div class="table-responsive">
    <table
      class="table table-striped table-bordered xlsx-table">
      <thead>
        <tr>
          <th></th>
          <th
            v-for="name in sheet.columns">
            {{ name }}
          </th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="(row, index) in sheet.rows"
          :id="index + 1"
          :class="{ hll: currentLineNumber === index + 1 }">
          <td class="text-right">
            <a
              :href="linePath(index)"
              @click="updateCurrentLineNumber(index)">
              {{ index + 1 }}
            </a>
          </td>
          <td v-for="val in row">
            {{ val }}
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>
export default {
  name: 'XLSXTable',
  props: {
    sheet: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      currentLineNumber: -1,
    };
  },
  methods: {
    linePath(index) {
      const hash = location.hash
        .replace('#', '')
        .replace(/-?L(\d+)$/g, '');

      if (hash !== '') {
        return `#${hash}-L${index + 1}`;
      }

      return `#L${index + 1}`;
    },
    updateCurrentLineNumber(index) {
      this.currentLineNumber = index + 1;
    },
    getCurrentLineNumberFromUrl() {
      const hash = location.hash
        .replace('#', '')
        .split('-')
        .pop();

      this.currentLineNumber = parseInt(hash.replace('L', ''), 10);
    },
  },
  watch: {
    sheet: {
      handler() {
        this.getCurrentLineNumberFromUrl();
      },
      deep: true,
    },
  },
  created() {
    this.getCurrentLineNumberFromUrl();
  },
  mounted() {
    $.scrollTo(`#${this.currentLineNumber}`);
  },
};
</script>
