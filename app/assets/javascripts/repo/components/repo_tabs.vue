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
    id="tabs"
    class="list-unstyled"
  >
    <repo-tab
      v-for="tab in openFiles"
      :key="tab.id"
      :tab="tab"
    />
    <li class="tabs-divider" />
  </ul>
</template>
