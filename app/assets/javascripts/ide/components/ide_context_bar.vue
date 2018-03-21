<script>
import { mapActions, mapGetters, mapState } from 'vuex';
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
  computed: {
    ...mapState(['changedFiles', 'rightPanelCollapsed']),
    ...mapGetters(['currentIcon']),
  },
  methods: {
    ...mapActions(['setPanelCollapsedStatus']),
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
      <header
        class="multi-file-commit-panel-header"
        :class="{
          'is-collapsed': rightPanelCollapsed,
        }"
      >
        <div
          class="multi-file-commit-panel-header-title"
          v-if="!rightPanelCollapsed"
        >
          <div
            v-if="changedFiles.length"
          >
            <icon
              name="list-bulleted"
              :size="18"
            />
            Staged
          </div>
        </div>
        <button
          type="button"
          class="btn btn-transparent multi-file-commit-panel-collapse-btn"
          @click.stop="setPanelCollapsedStatus({
            side: 'right',
            collapsed: !rightPanelCollapsed,
          })"
        >
          <icon
            :name="currentIcon"
            :size="18"
          />
        </button>
      </header>
      <repo-commit-section
        :no-changes-state-svg-path="noChangesStateSvgPath"
        :committed-state-svg-path="committedStateSvgPath"
      />
    </div>
  </resizable-panel>
</template>
