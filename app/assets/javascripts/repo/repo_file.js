const RepoFile = {
  template: `
  <tr v-if='!loading.tree || hasFiles'>
    <td>
      <i class='fa' :class='file.icon' :style='{"margin-left": file.level * 10 + "px"}'></i>
      <a :href='file.url' @click.prevent='linkClicked(file)' :title='file.url'>{{file.name}}</a>
    </td>
    <td v-if='!isMini'>
      <div class='ellipsis'>{{file.lastCommitMessage}}</div>
    </td>
    <td v-if='!isMini'>
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
  },

  methods: {
    linkClicked(file) {
      this.$emit('linkclicked', file);
    },
  },
};
export default RepoFile;
