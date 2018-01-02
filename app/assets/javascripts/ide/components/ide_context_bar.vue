<script>
import { mapGetters, mapState, mapActions } from 'vuex';
import repoCommitSection from './repo_commit_section.vue';
import icon from '../../vue_shared/components/icon.vue';

export default {
  components: {
    repoCommitSection,
    icon,
  },
  computed: {
    ...mapState([
      'rightPanelCollapsed',
    ]),
    ...mapGetters([
      'changedFiles',
    ]),
    currentIcon() {
      return this.rightPanelCollapsed ? 'angle-double-left' : 'angle-double-right';
    },
  },
  methods: {
    ...mapActions([
      'setPanelCollapsedStatus',
    ]),
    toggleCollapsed() {
      this.setPanelCollapsedStatus({
        side: 'right',
        collapsed: !this.rightPanelCollapsed,
      });
    },
  },
};
</script>

<template>
  <div
    class="multi-file-commit-panel"
    :class="{
      'is-collapsed': rightPanelCollapsed,
    }"
  >
    <div 
      class="multi-file-commit-panel-section">
      <header
        class="multi-file-commit-panel-header"
        :class="{
            'is-collapsed': rightPanelCollapsed,
          }"
        >
        <div
          class="multi-file-commit-panel-header-title"
          v-if="!rightPanelCollapsed">
          <icon
            name="list-bulleted"
            :size="18"
          />
          Staged
        </div>
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
      <repo-commit-section 
        class=""/>
    </div>
  </div>
</template>
