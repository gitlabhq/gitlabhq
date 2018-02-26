<script>
  import { mapState, mapActions } from 'vuex';
  import repoCommitSection from './repo_commit_section.vue';
  import icon from '../../vue_shared/components/icon.vue';
  import panelResizer from '../../vue_shared/components/panel_resizer.vue';

  export default {
    components: {
      repoCommitSection,
      icon,
      panelResizer,
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
    data() {
      return {
        width: 340,
      };
    },
    computed: {
      ...mapState([
        'rightPanelCollapsed',
        'changedFiles',
      ]),
      currentIcon() {
        return this.rightPanelCollapsed ? 'angle-double-left' : 'angle-double-right';
      },
      maxSize() {
        return window.innerWidth / 2;
      },
      panelStyle() {
        if (!this.rightPanelCollapsed) {
          return { width: `${this.width}px` };
        }
        return {};
      },
    },
    methods: {
      ...mapActions([
        'setPanelCollapsedStatus',
        'setResizingStatus',
      ]),
      toggleCollapsed() {
        this.setPanelCollapsedStatus({
          side: 'right',
          collapsed: !this.rightPanelCollapsed,
        });
      },
      toggleFullbarCollapsed() {
        if (this.rightPanelCollapsed) {
          this.toggleCollapsed();
        }
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
      'is-collapsed': rightPanelCollapsed,
    }"
    :style="panelStyle"
    @click="toggleFullbarCollapsed"
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
          @click.stop="toggleCollapsed"
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
    <panel-resizer
      :size.sync="width"
      :enabled="!rightPanelCollapsed"
      :start-size="340"
      :min-size="200"
      :max-size="maxSize"
      @resize-start="resizingStarted"
      @resize-end="resizingEnded"
      side="left"
    />
  </div>
</template>
