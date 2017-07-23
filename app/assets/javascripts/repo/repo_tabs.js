import Vue from 'vue';
import Store from './repo_store';
import RepoTab from './repo_tab.vue';
import RepoMiniMixin from './repo_mini_mixin';

export default class RepoTabs {
  constructor(el) {
    // RepoTabs.styleTabsForWindows();
    this.initVue(el);
  }

  initVue(el) {
    this.vue = new Vue({
      el,
      mixins: [RepoMiniMixin],
      components: {
        'repo-tab': RepoTab,
      },
      data: () => Store,

      methods: {
        isOverflow() {
          let tabs = document.getElementById('tabs');
          if(tabs) {
            return tabs.scrollWidth > tabs.offsetWidth;
          } 
        }
      },

      watch: {
        openedFiles() {
          Vue.nextTick(() => {
            this.tabsOverflow = this.isOverflow();  
          });
        }
      }
    });
  }

  // static styleTabsForWindows() {
  //   const scrollWidth = Number(document.body.dataset.scrollWidth);
  //   Store.scrollWidth = scrollWidth;
  // }
}
