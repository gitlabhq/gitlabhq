<script>
  import { mapGetters } from 'vuex';

  export default {
    computed: {
      ...mapGetters([
        'isCollapsed',
      ]),
    },
    methods: {
      lineOfCode(n) {
        return `skeleton-line-${n}`;
      },
    },
  };
</script>

<template>
  <tr
    class="loading-file"
    aria-label="Loading files"
  >
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
    <template v-if="!isCollapsed">
      <td
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
        class="hidden-xs">
        <div class="animation-container animation-container-small animation-container-right">
          <div
            v-for="n in 6"
            :key="n"
            :class="lineOfCode(n)">
          </div>
        </div>
      </td>
    </template>
  </tr>
</template>
