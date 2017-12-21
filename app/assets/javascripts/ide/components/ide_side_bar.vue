<script>
import { mapState, mapActions } from 'vuex';
import projectTree from './ide_project_tree.vue';
import icon from '../../vue_shared/components/icon.vue';

export default {
  components: {
    projectTree,
    icon,
  },
  computed: {
    ...mapState([
      'projects',
      'leftPanelCollapsed',
    ]),
    currentIcon() {
      return this.leftPanelCollapsed ? 'angle-double-right' : 'angle-double-left';
    },
  },
  methods: {
    ...mapActions([
      'setPanelCollapsedStatus',
    ]),
    toggleCollapsed() {
      this.setPanelCollapsedStatus({
        side: 'left',
        collapsed: !this.leftPanelCollapsed,
      });
    },
  },
};
</script>

<template>
  <div
      class="multi-file-commit-panel"
      :class="{
        'is-collapsed': leftPanelCollapsed,
      }"
    >
    <div class="multi-file-commit-panel-inner">
      <project-tree
        v-for="(project, index) in projects"
        :key="project.id"
        :project="project"/>
    </div>
    <button
      type="button"
      class="btn btn-transparent left-collapse-btn"
      @click="toggleCollapsed"
    >
      <icon
        :name="currentIcon"
        :size="18"
      />
      <span
        v-if="!leftPanelCollapsed"
        class="collapse-text"
      >Collapse sidebar</span>
    </button>
  </div>
</template>
