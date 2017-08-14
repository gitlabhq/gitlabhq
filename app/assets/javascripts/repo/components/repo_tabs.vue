<script>
import Store from '../stores/repo_store';
import RepoTab from './repo_tab.vue';
import RepoMixin from '../mixins/repo_mixin';

const RepoTabs = {
  mixins: [RepoMixin],

  components: {
    'repo-tab': RepoTab,
  },

  data: () => Store,

  methods: {
    xClicked(file) {
      Store.removeFromOpenedFiles(file);
    },
  },
};

export default RepoTabs;
</script>

<template>
<ul
  v-if="isMini"
  id="tabs">
  <repo-tab v-for="tab in openedFiles" :key="tab.id" :tab="tab" :class="{'active' : tab.active}" @xclicked="xClicked"/>
  <li class="tabs-divider" />
</ul>
</template>
