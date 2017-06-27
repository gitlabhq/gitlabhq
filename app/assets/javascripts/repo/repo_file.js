let RepoFile = {
  template: `
  <li>
    <div class='col-md-4'>
      <i class='fa' :class='file.icon'></i>
      <a :href='file.url' @click.prevent='linkClicked(file)'>{{file.name}}</a>
    </div>
    <div class="col-md-4">
      <span>{{JSON.stringify(file)}}</span>
    </div>
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
