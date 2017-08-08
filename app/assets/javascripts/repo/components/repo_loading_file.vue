<script>
const RepoLoadingFile = {
  props: {
    loading: {
      type: Object,
      required: false,
      default: {},
    },
    hasFiles: {
      type: Boolean,
      required: false,
      default: false,
    },
    isMini: {
      type: Boolean,
      required: false,
      default: false,
    },
  },

  methods: {
    lineOfCode(n) {
      return `line-of-code-${n}`;
    },
  },
};

export default RepoLoadingFile;
</script>

<template>
  <tr v-if="loading.tree && !hasFiles" class="loading-file">
    <td>
      <div class="animation-container animation-container-small">
        <div v-for="n in 6" :class="lineOfCode(n)" :key="n" />
      </div>
    </td>

    <td v-if="!isMini" class="hidden-sm hidden-xs">
      <div class="animation-container">
        <div v-for="n in 6" :class="lineOfCode(n)" :key="n" />
      </div>
    </td>

    <td v-if="!isMini" class="hidden-xs">
      <div class="animation-container animation-container-small">
        <div v-for="n in 6" :class="lineOfCode(n)" :key="n" />
      </div>
    </td>
  </tr>
</template>
