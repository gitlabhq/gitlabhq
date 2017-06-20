let RepoFile = {
  template: `
  <li>
    <i class='fa' :class='file.icon'></i>
    <a :href='file.url' @click.prevent='linkClicked(file)'>{{file.name}}</a>
  </li>
  `,
  props: {
    name: 'repo-file',
    file: Object,
  },

  methods: {
    linkClicked(file) {
      this.$emit('linkclicked', file);
    }
  }
};
export default RepoFile;
