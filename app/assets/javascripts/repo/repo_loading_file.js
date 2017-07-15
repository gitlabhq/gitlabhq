const RepoLoadingFile = {
  template: `
  <tr v-if='loading.tree && !hasFiles'>
    <td>
      <div class="animation-container animation-container-small">
        <div class="line-of-code-1"></div>
        <div class="line-of-code-2"></div>
        <div class="line-of-code-3"></div>
        <div class="line-of-code-4"></div>
        <div class="line-of-code-5"></div>
        <div class="line-of-code-6"></div>
      </div>
    </td>
    <td v-if="!isMini">
      <div class="animation-container">
        <div class="line-of-code-1"></div>
        <div class="line-of-code-2"></div>
        <div class="line-of-code-3"></div>
        <div class="line-of-code-4"></div>
        <div class="line-of-code-5"></div>
        <div class="line-of-code-6"></div>
      </div>
    </td>
    <td v-if="!isMini">
      <div class="animation-container animation-container-small">
        <div class="line-of-code-1"></div>
        <div class="line-of-code-2"></div>
        <div class="line-of-code-3"></div>
        <div class="line-of-code-4"></div>
        <div class="line-of-code-5"></div>
        <div class="line-of-code-6"></div>
      </div>
    </td>
  </tr>
  `,
  props: {
    loading: Object,
    hasFiles: Boolean,
    isMini: Boolean,
  },
};
export default RepoLoadingFile;
