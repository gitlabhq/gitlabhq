import RepoHelper from './repo_helper';

const RepoTab = {
  template: `
  <li>
    <a href='#' @click.prevent='xClicked(tab)' v-if='!tab.loading'>
      <i class='fa fa-times' :class="{'fa-times':saved, 'dot-circle-o': !saved}"></i>
    </a>
    <a href='#' v-if='!tab.loading' :title='tab.url' @click.prevent='tabClicked(tab)'>{{tab.name}}</a>
    <i v-if='tab.loading' class='fa fa-spinner fa-spin'></i>
  </li>
  `,
  props: {
    name: 'repo-tab',
    tab: Object,
    saved: true,
  },

  methods: {
    tabClicked(file) {
      RepoHelper.setActiveFile(file);
    },

    xClicked(file) {
      RepoHelper.removeFromOpenedFiles(file);
    },
  },
};
export default RepoTab;
