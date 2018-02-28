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

  computed: {
    showGhostLines() {
      return this.loading.tree && !this.hasFiles;
    },
  },

  methods: {
    lineOfCode(n) {
      return `skeleton-line-${n}`;
    },
  },
};

export default RepoLoadingFile;
</script>

<template>
  <tr
    v-if="showGhostLines"
    class="loading-file">
    <td>
      <div
        class="animation-container animation-container-small">
        <div
          v-for="n in 6"
          :key="n"
          :class="lineOfCode(n)">
        </div>
      </div>
    </td>

    <td
      v-if="!isMini"
      class="hidden-sm hidden-xs">
      <div class="animation-container">
        <div
          v-for="n in 6"
          :key="n"
          :class="lineOfCode(n)">
        </div>
      </div>
    </td>

    <td
      v-if="!isMini"
      class="hidden-xs">
      <div class="animation-container animation-container-small">
        <div
          v-for="n in 6"
          :key="n"
          :class="lineOfCode(n)">
        </div>
      </div>
    </td>
  </tr>
</template>
