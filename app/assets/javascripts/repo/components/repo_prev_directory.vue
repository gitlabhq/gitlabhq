<script>
import RepoMixin from '../mixins/repo_mixin';

const RepoPreviousDirectory = {
  props: {
    prevUrl: {
      type: String,
      required: true,
    },
  },

  mixins: [RepoMixin],

  computed: {
    colSpanCondition() {
      return this.isMini ? undefined : 3;
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
<tr class="prev-directory">
  <td
    :colspan="colSpanCondition"
    @click.prevent="linkClicked(prevUrl)">
    <a :href="prevUrl">..</a>
  </td>
</tr>
</template>
