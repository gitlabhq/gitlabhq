const RepoPreviousDirectory = {
  template: `
  <tr>
    <td colspan='3'>
      <a :href='prevurl' @click.prevent='linkClicked(prevurl)'>..</a>
    </td>
  </tr>
  `,
  props: {
    name: 'repo-previous-directory',
    prevurl: String,
  },

  methods: {
    linkClicked(file) {
      this.$emit('linkclicked', file);
    },
  },
};
export default RepoPreviousDirectory;
