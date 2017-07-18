const RepoPreviousDirectory = {
  template: `
  <tr>
    <td colspan='3'>
      <a :href='prevUrl' @click.prevent='linkClicked(prevUrl)'>..</a>
    </td>
  </tr>
  `,
  props: {
    name: 'repo-previous-directory',
    prevUrl: String,
  },

  methods: {
    linkClicked(file) {
      this.$emit('linkclicked', file);
    },
  },
};
export default RepoPreviousDirectory;
