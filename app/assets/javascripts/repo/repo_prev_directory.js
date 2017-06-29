let RepoPreviousDirectory = {
  template: `
  <tr>
    <td colspan='3'>
      <a href='#' @click.prevent='linkClicked("prev")'>..</a>
    </td>
  </tr>
  `,
  props: {
    name: 'repo-previous-directory',
  },

  methods: {
    linkClicked(file) {
      console.log(this.isTree)
      this.$emit('linkclicked', file);
    }
  }
};
export default RepoPreviousDirectory;