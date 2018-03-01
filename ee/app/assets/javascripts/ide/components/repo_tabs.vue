<script>
  import { mapActions, mapState } from 'vuex';
  import RepoTab from './repo_tab.vue';

  export default {
    components: {
      'repo-tab': RepoTab,
    },
    data() {
      return {
        showShadow: false,
      };
    },
    computed: {
      ...mapState([
        'openFiles',
        'viewer',
      ]),
    },
    methods: {
      ...mapActions([
        'updateViewer',
      ]),
    },
    updated() {
      if (!this.$refs.tabsScroller) return;

      this.showShadow = this.$refs.tabsScroller.scrollWidth > this.$refs.tabsScroller.offsetWidth;
    },
  };
</script>

<template>
  <div class="multi-file-tabs">
    <ul
      class="list-unstyled append-bottom-0"
      ref="tabsScroller"
    >
      <repo-tab
        v-for="tab in openFiles"
        :key="tab.key"
        :tab="tab"
      />
    </ul>
    <div
      class="dropdown"
      :class="{
        shadow: showShadow,
      }"
    >
      <button class="btn btn-primary btn-sm" data-toggle="dropdown">
        <template v-if="viewer === 'editor'">
          Editing
        </template>
        <template v-else>
          Reviewing
        </template>
        <i class="fa fa-chevron-down"></i>
      </button>
      <div class="dropdown-menu dropdown-menu-selectable dropdown-open-left">
        <ul>
          <li>
            <a
              href="#"
              @click.prevent="updateViewer('editor')"
              :class="{
                'is-active': viewer === 'editor',
              }"
            >
              <strong class="dropdown-menu-inner-title">Editing</strong>
              <span class="dropdown-menu-inner-content">
                View and edit lines
              </span>
            </a>
          </li>
          <li>
            <a
              href="#"
              @click.prevent="updateViewer('diff')"
              :class="{
                'is-active': viewer === 'diff',
              }"
            >
              <strong class="dropdown-menu-inner-title">Reviewing</strong>
              <span class="dropdown-menu-inner-content">
                Compare changes with the last commit
              </span>
            </a>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>
