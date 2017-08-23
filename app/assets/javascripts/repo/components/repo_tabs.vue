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
    tabClosed(file) {
      Store.removeFromOpenedFiles(file);
    },
  },
};

export default RepoTabs;
</script>

<template>
<ul id="tabs">
  <repo-tab
    v-for="tab in openedFiles"
    :key="tab.id"
    :tab="tab"
    :class="{'active' : tab.active}"
    @tabclosed="tabClosed"
  />
  <li class="tabs-divider" />
</ul>
</template>
