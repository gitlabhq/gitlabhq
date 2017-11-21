<script>
import { mapGetters } from 'vuex';
import RepoCommitSection from './repo_commit_section.vue';

export default {
  computed: {
    ...mapGetters([
      'isCollapsed',
      'changedFiles',
    ]),
  },
  components: {
    RepoCommitSection,
  },
  created() {
    //window.addEventListener('popstate', this.popHistoryState);
  },
  destroyed() {
    //window.removeEventListener('popstate', this.popHistoryState);
  },
};
</script>

<template>
  <aside aria-live="polite" class="js-issuable-sidebar js-right-sidebar right-sidebar right-sidebar-collapsed" data-signed-in="">
    <div class="issuable-sidebar" data-endpoint="/h5bp/html5-boilerplate/issues/11.json">
      <div class="block issuable-sidebar-header">
        <span class="issuable-header-text hide-collapsed pull-left">
          Todo
        </span>
        <a aria-label="Toggle sidebar" class="gutter-toggle pull-right js-sidebar-toggle" href="#" role="button">
          <i aria-hidden="true" data-hidden="true" class="fa fa-angle-double-left"></i>
        </a>
        <button aria-label="Add todo" class="btn btn-default issuable-header-btn issuable-todo-btn js-issuable-todo pull-right" data-issuable-id="81"
          data-issuable-type="issue" data-mark-text="Mark done" data-todo-text="Add todo" data-url="/h5bp/html5-boilerplate/todos"
          title="Add todo" type="button">
          <span class="issuable-todo-inner js-issuable-todo-inner">Add todo</span>
          <i aria-hidden="true" data-hidden="true" class="fa fa-spin fa-spinner"></i>
        </button>
      </div>
      <div class="block issuable-sidebar-item lock">
        <div class="sidebar-collapsed-icon">
          <svg class="sidebar-item-icon is-active s16" aria-hidden="true">
            <use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="/assets/icons-f1e1e3187fbe3fe3aa42a17cb2558778f1a2ddc2a1914f0ea7ea59d27b4e425c.svg#lock-open"></use>
          </svg>
        </div>
        <div class="title hide-collapsed">
          Lock issue
          <button type="button" class="pull-right lock-edit btn btn-blank">
            Edit
          </button>
        </div>
        <div class="value sidebar-item-value hide-collapsed">
          <!---->
          <div class="no-value sidebar-item-value hide-collapsed">
            <svg class="sidebar-item-icon inline s16" aria-hidden="true">
              <use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="/assets/icons-f1e1e3187fbe3fe3aa42a17cb2558778f1a2ddc2a1914f0ea7ea59d27b4e425c.svg#lock-open"></use>
            </svg>
            Unlocked
          </div>
        </div>
      </div>
      <repo-commit-section v-if="changedFiles.length" />
    </div>
  </aside>
</template>
