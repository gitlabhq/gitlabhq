<script>
import { mapGetters } from 'vuex';
import RepoCommitSection from './repo_commit_section.vue';
import icon from '../../vue_shared/components/icon.vue';

export default {
  components: {
    RepoCommitSection,
    icon,
  },
  data() {
    return {
      collapsed: true,
    };
  },
  computed: {
    ...mapGetters([
      'changedFiles',
    ]),
    currentIcon() {
      return this.collapsed ? 'angle-double-left' : 'angle-double-right';
    }
  },
  methods: {
    toggleCollapsed() {
      this.collapsed = !this.collapsed;
    },
  },
};
</script>

<template>
  <div
    class="multi-file-commit-panel"
    :class="{
      'is-collapsed': collapsed,
    }"
  >
    <div 
      class="multi-file-commit-panel-section"
      @click="toggleCollapsed"
    >
      <header
        class="multi-file-commit-panel-header"
        :class="{
          'is-collapsed': collapsed,
          }"
        >
        <button
          type="button"
          class="btn btn-transparent multi-file-commit-panel-collapse-btn"
          @click="toggleCollapsed"
        >
          <icon
            :name="currentIcon"
            :size="18"
          />
        </button>
      </header>
      <div>
      </div>
      <repo-commit-section 
        :collapsed="collapsed"
        class=""/>
    </div>
  </div>
</template>
