import RepoHelper from './repo_helper'

let RepoTab = {
  template: `
  <li>
    <a href='#' @click.prevent='xClicked(tab)'>
      <i class="fa fa-times" :class="{'fa-times':saved, 'dot-circle-o': !saved}"></i>
    </a>
    <a href='#' :title='tab.url' @click.prevent='tabClicked(tab)'>{{tab.name}}</a>
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
    }
  }
};
export default RepoTab;