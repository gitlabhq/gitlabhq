<script>
const RepoPreviousDirectory = {
  props: {
    prevUrl: {
      type: String,
      required: true,
    },
  },

  methods: {
    linkClicked(file) {
      this.$emit('linkclicked', file);
    },
  },
};

export default RepoPreviousDirectory;
</script>

<template>
<tr>
  <td colspan="3">
    <a :href="prevUrl" @click.prevent="linkClicked(prevUrl)">..</a>
  </td>
</tr>
</template>
