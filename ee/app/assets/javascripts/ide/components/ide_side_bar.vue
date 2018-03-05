<script>
  import { mapState, mapActions } from 'vuex';
  import icon from '~/vue_shared/components/icon.vue';
  import panelResizer from '~/vue_shared/components/panel_resizer.vue';
  import skeletonLoadingContainer from '~/vue_shared/components/skeleton_loading_container.vue';
  import projectTree from './ide_project_tree.vue';

  export default {
    components: {
      projectTree,
      icon,
      panelResizer,
      skeletonLoadingContainer,
    },
    data() {
      return {
        width: 290,
      };
    },
    computed: {
      ...mapState([
        'loading',
        'projects',
        'leftPanelCollapsed',
      ]),
      currentIcon() {
        return this.leftPanelCollapsed ? 'angle-double-right' : 'angle-double-left';
      },
      maxSize() {
        return window.innerWidth / 2;
      },
      panelStyle() {
        if (!this.leftPanelCollapsed) {
          return { width: `${this.width}px` };
        }
        return {};
      },
      showLoading() {
        return this.loading;
      },
    },
    methods: {
      ...mapActions([
        'setPanelCollapsedStatus',
        'setResizingStatus',
      ]),
      toggleCollapsed() {
        this.setPanelCollapsedStatus({
          side: 'left',
          collapsed: !this.leftPanelCollapsed,
        });
      },
      resizingStarted() {
        this.setResizingStatus(true);
      },
      resizingEnded() {
        this.setResizingStatus(false);
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
    :style="panelStyle"
  >
    <div class="multi-file-commit-panel-inner">
      <template v-if="showLoading">
        <div
          class="multi-file-loading-container"
          v-for="n in 3"
          :key="n"
        >
          <skeleton-loading-container />
        </div>
      </template>
      <project-tree
        v-for="project in projects"
        :key="project.id"
        :project="project"
      />
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
      >
        Collapse sidebar
      </span>
    </button>
    <panel-resizer
      :size.sync="width"
      :enabled="!leftPanelCollapsed"
      :start-size="290"
      :min-size="200"
      :max-size="maxSize"
      @resize-start="resizingStarted"
      @resize-end="resizingEnded"
      side="right"
    />
  </div>
</template>
