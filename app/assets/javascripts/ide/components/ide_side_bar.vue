<script>
import { mapState } from 'vuex';
import ProjectTree from './ide_project_tree.vue';
import icon from '../../vue_shared/components/icon.vue';

export default {
  components: {
    ProjectTree,
    icon,
  },
  data() {
    return {
      collapsed: false,
    };
  },
  computed: {
    ...mapState([
      'loading',
      'projects',
    ]),
    currentIcon() {
      return this.collapsed ? 'angle-double-right' : 'angle-double-left';
    }, 
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
  <div class="multi-file-commit-panel-inner-scroll">
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
      v-if="!collapsed"
      class="collapse-text"
    >Collapse sidebar</span>
  </button>
</div>
</template>
