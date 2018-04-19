<script>
import icon from '~/vue_shared/components/icon.vue';
import panelResizer from '~/vue_shared/components/panel_resizer.vue';
import repoCommitSection from './repo_commit_section.vue';
import ResizablePanel from './resizable_panel.vue';

export default {
  components: {
    repoCommitSection,
    icon,
    panelResizer,
    ResizablePanel,
  },
  props: {
    noChangesStateSvgPath: {
      type: String,
      required: true,
    },
    committedStateSvgPath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <resizable-panel
    :collapsible="true"
    :initial-width="340"
    side="right"
  >
    <div
      class="multi-file-commit-panel-section"
    >
      <repo-commit-section
        :no-changes-state-svg-path="noChangesStateSvgPath"
        :committed-state-svg-path="committedStateSvgPath"
      />
    </div>
  </resizable-panel>
</template>
