let RepoLoadingFile = {
  template: `
  <tr v-if='loading.tree && !hasFiles'>
    <td>
      <div class="animation-container animation-container-small">
        <div v-for="n in 6" :class="lineOfCode(n)"></div>
      </div>
    </td>
    <td v-if="!isMini" class='hidden-sm hidden-xs'>
      <div class="animation-container">
        <div v-for="n in 6" :class="lineOfCode(n)"></div>
      </div>
    </td>
    <td v-if="!isMini" class='hidden-xs'>
      <div class="animation-container animation-container-small">
        <div v-for="n in 6" :class="lineOfCode(n)"></div>
      </div>
    </td>
  </tr>
  `,
  
  methods: {
    lineOfCode(n) {
      return `line-of-code-${n}`;
    }
  },

  props: {
    loading: Object,
    hasFiles: Boolean,
    isMini: Boolean
  }
};
export default RepoLoadingFile;