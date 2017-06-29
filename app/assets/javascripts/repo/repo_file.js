let RepoFile = {
  template: `
  <tr>
    <td>
      <i class='fa' :class='file.icon'></i>
      <a :href='file.url' @click.prevent='linkClicked(file)'>{{file.name}}</a>
    </td>
    <td v-if='isTree'>
      <div class='ellipsis'>{{file.lastCommitMessage}}</div>
    </td>
    <td v-if='isTree'>
      <span>{{file.lastCommitUpdate}}</span>
    </td>
  </tr>
  `,
  props: {
    name: 'repo-file',
    file: Object,
    isTree: Boolean
  },

  methods: {
    linkClicked(file) {
      console.log(this.isTree)
      this.$emit('linkclicked', file);
    }
  }
};
export default RepoFile;
