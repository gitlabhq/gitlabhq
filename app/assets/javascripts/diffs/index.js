import Vue from 'vue';
import { mapActions, mapState } from 'vuex';
import { parseBoolean } from '~/lib/utils/common_utils';
import { getParameterValues } from '~/lib/utils/url_utility';
import diffsApp from './components/app.vue';
import { TREE_LIST_STORAGE_KEY } from './constants';

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
    created() {
      const treeListStored = localStorage.getItem(TREE_LIST_STORAGE_KEY);
      const renderTreeList = treeListStored !== null ? parseBoolean(treeListStored) : true;

      this.setRenderTreeList(renderTreeList);
      this.setShowWhitespace({ showWhitespace: getParameterValues('w')[0] !== '1' });
    },
    methods: {
      ...mapActions('diffs', ['setRenderTreeList', 'setShowWhitespace']),
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
