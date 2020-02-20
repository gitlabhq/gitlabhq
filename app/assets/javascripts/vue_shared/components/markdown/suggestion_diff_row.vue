<script>
export default {
  name: 'SuggestionDiffRow',
  props: {
    line: {
      type: Object,
      required: true,
    },
  },
  computed: {
    displayAsCell() {
      return !(this.line.rich_text || this.line.text);
    },
    lineType() {
      return this.line.type;
    },
  },
};
</script>

<template>
  <tr class="line_holder" :class="lineType">
    <td class="diff-line-num old_line border-top-0 border-bottom-0" :class="lineType">
      {{ line.old_line }}
    </td>
    <td class="diff-line-num new_line border-top-0 border-bottom-0" :class="lineType">
      {{ line.new_line }}
    </td>
    <td class="line_content" :class="[{ 'd-table-cell': displayAsCell }, lineType]">
      <span v-if="line.rich_text" v-html="line.rich_text"></span>
      <span v-else-if="line.text">{{ line.text }}</span>
    </td>
  </tr>
</template>
