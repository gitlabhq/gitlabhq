<script>
  import Store from '../stores/repo_store';
  import RepoTab from './repo_tab.vue';
  import RepoMixin from '../mixins/repo_mixin';

  export default {
    mixins: [RepoMixin],
    components: {
      'repo-tab': RepoTab,
    },
    data() {
      return Store;
    },
  };
</script>

<template>
  <ul
    id="tabs"
    class="list-unstyled"
  >
    <repo-tab
      v-for="tab in openedFiles"
      :key="tab.id"
      :tab="tab"
    />
    <li class="tabs-divider" />
  </ul>
</template>
