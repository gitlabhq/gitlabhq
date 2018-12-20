import Vue from 'vue';
import { mapState } from 'vuex';
import diffsApp from './components/app.vue';

export default function initDiffsApp(store) {
  return new Vue({
    el: '#js-diffs-app',
    name: 'MergeRequestDiffs',
    components: {
      diffsApp,
    },
    store,
    data() {
      const { dataset } = document.querySelector(this.$options.el);

      return {
        endpoint: dataset.endpoint,
        projectPath: dataset.projectPath,
        helpPagePath: dataset.helpPagePath,
        currentUser: JSON.parse(dataset.currentUserData) || {},
        changesEmptyStateIllustration: dataset.changesEmptyStateIllustration,
      };
    },
    computed: {
      ...mapState({
        activeTab: state => state.page.activeTab,
      }),
    },
    render(createElement) {
      return createElement('diffs-app', {
        props: {
          endpoint: this.endpoint,
          currentUser: this.currentUser,
          projectPath: this.projectPath,
          helpPagePath: this.helpPagePath,
          shouldShow: this.activeTab === 'diffs',
          changesEmptyStateIllustration: this.changesEmptyStateIllustration,
        },
      });
    },
  });
}
