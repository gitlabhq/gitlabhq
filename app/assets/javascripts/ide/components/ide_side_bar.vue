<script>
  import { mapState, mapGetters } from 'vuex';
  import icon from '~/vue_shared/components/icon.vue';
  import panelResizer from '~/vue_shared/components/panel_resizer.vue';
  import skeletonLoadingContainer from '~/vue_shared/components/skeleton_loading_container.vue';
  import projectTree from './ide_project_tree.vue';
  import ResizablePanel from './resizable_panel.vue';

  export default {
    components: {
      projectTree,
      icon,
      panelResizer,
      skeletonLoadingContainer,
      ResizablePanel,
    },
    computed: {
      ...mapState([
        'loading',
      ]),
      ...mapGetters([
        'projectsWithTrees',
      ]),
    },
  };
</script>

<template>
  <resizable-panel
    :collapsible="false"
    :initial-width="290"
    side="left"
  >
    <div class="multi-file-commit-panel-inner">
      <template v-if="loading">
        <div
          class="multi-file-loading-container"
          v-for="n in 3"
          :key="n"
        >
          <skeleton-loading-container />
        </div>
      </template>
      <project-tree
        v-for="project in projectsWithTrees"
        :key="project.id"
        :project="project"
      />
    </div>
  </resizable-panel>
</template>
