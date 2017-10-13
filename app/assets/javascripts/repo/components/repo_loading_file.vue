<script>
  import repoMixin from '../mixins/repo_mixin';

  export default {
    mixins: [
      repoMixin,
    ],
    methods: {
      lineOfCode(n) {
        return `skeleton-line-${n}`;
      },
    },
  };
</script>

<template>
  <tr
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
      <div class="animation-container animation-container-small animation-container-right">
        <div
          v-for="n in 6"
          :key="n"
          :class="lineOfCode(n)">
        </div>
      </div>
    </td>
  </tr>
</template>
