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
<<<<<<< HEAD
    xClicked(file) {
=======
    tabClosed(file) {
>>>>>>> upstream/master
      Store.removeFromOpenedFiles(file);
    },
  },
};

export default RepoTabs;
</script>

<template>
<<<<<<< HEAD
<ul
  v-if="isMini"
  id="tabs">
  <repo-tab v-for="tab in openedFiles" :key="tab.id" :tab="tab" :class="{'active' : tab.active}" @xclicked="xClicked"/>
=======
<ul id="tabs">
  <repo-tab
    v-for="tab in openedFiles"
    :key="tab.id"
    :tab="tab"
    :class="{'active' : tab.active}"
    @tabclosed="tabClosed"
  />
>>>>>>> upstream/master
  <li class="tabs-divider" />
</ul>
</template>
