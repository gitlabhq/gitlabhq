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
      'loading',
      'projects',
      'leftBarCollapsed',
    ]),
    currentIcon() {
      return this.leftBarCollapsed ? 'angle-double-right' : 'angle-double-left';
    }, 
  },
  methods: {
    ...mapActions([
      'setLeftBarCollapsedStatus',
    ]),
    toggleCollapsed() {
      this.setLeftBarCollapsedStatus(!this.leftBarCollapsed);
    },
  },
};
</script>

<template>
<div
    class="multi-file-commit-panel"
    :class="{
      'is-collapsed': leftBarCollapsed,
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
      v-if="!leftBarCollapsed"
      class="collapse-text"
    >Collapse sidebar</span>
  </button>
</div>
</template>
