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
    <td class="line_content" :class="lineType">
      <span v-if="line.rich_text" v-html="line.rich_text"></span>
      <span v-else-if="line.text">{{ line.text }}</span>
      <!-- TODO: replace this hack with zero-width whitespace when we have rich_text from BE -->
      <span v-else>&#8203;</span>
    </td>
  </tr>
</template>
