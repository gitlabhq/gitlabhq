<script>
  import { mapState } from 'vuex';
  import RepoTab from './repo_tab.vue';

  export default {
    components: {
      'repo-tab': RepoTab,
    },
    computed: {
      ...mapState([
        'openFiles',
      ]),
    },
  };
</script>

<template>
  <ul
    class="multi-file-tabs list-unstyled append-bottom-0"
  >
    <repo-tab
      v-for="tab in openFiles"
      :key="tab.key"
      :tab="tab"
    />
  </ul>
</template>
