let RepoFile = {
  template: `
  <tr v-if='!loading.tree || hasFiles' :class='{"active": activeFile.url === file.url}'>
    <td>
      <i class='fa' :class='file.icon' :style='{"margin-left": file.level * 10 + "px"}'></i>
      <a :href='file.url' @click.prevent='linkClicked(file)' class='repo-file-name' :title='file.url'>{{file.name}}</a>
    </td>
    <td v-if='!isMini' class='hidden-sm hidden-xs'>
      <div class='commit-message'>{{file.lastCommitMessage}}</div>
    </td>
    <td v-if='!isMini' class='hidden-xs'>
      <span>{{file.lastCommitUpdate}}</span>
    </td>
  </tr>
  `,
  props: {
    name: 'repo-file',
    file: Object,
    isTree: Boolean,
    isMini: Boolean,
    loading: Object,
    hasFiles: Boolean,
    activeFile: Object
  },

  methods: {
    linkClicked(file) {
      this.$emit('linkclicked', file);
    }
  }
};
export default RepoFile;
