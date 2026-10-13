<script>
export default {
  name: 'FormatText',
  props: {
    value: {
      type: [String, Number],
      required: true,
    },
    // A prop rather than the field's `tdClass`, because `.gl-table tr td` pins
    // `font-weight: normal` and outranks a utility class on the cell itself.
    bold: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>
<template>
  <span :class="{ 'gl-font-bold': bold }">{{ value }}</span>
</template>
