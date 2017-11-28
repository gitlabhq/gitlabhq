<script>
import { mapGetters } from 'vuex';
import RepoCommitSection from './repo_commit_section.vue';

export default {
  computed: {
    ...mapGetters([
      'changedFiles',
    ]),
  },
  components: {
    RepoCommitSection,
  },
};
</script>

<template>
  <aside aria-live="polite" class="js-issuable-sidebar js-right-sidebar right-sidebar right-sidebar-collapsed" data-signed-in="">
    <div class="issuable-sidebar" data-endpoint="/h5bp/html5-boilerplate/issues/11.json">
      <div class="block issuable-sidebar-header">
        <span class="issuable-header-text hide-collapsed pull-left">
          IDE
        </span>
        <a aria-label="Toggle sidebar" class="gutter-toggle pull-right js-sidebar-toggle" href="#" role="button">
          <i aria-hidden="true" data-hidden="true" class="fa fa-angle-double-left"></i>
        </a>
      </div>
      
      <repo-commit-section v-if="changedFiles.length" />
    </div>
  </aside>
</template>
