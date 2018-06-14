<script>
import { mapActions, mapState } from 'vuex';
import tooltip from '../../../vue_shared/directives/tooltip';
import Icon from '../../../vue_shared/components/icon.vue';
import { rightSidebarViews } from '../../constants';
import PipelinesList from '../pipelines/list.vue';
import JobsDetail from '../jobs/detail.vue';
import ResizablePanel from '../resizable_panel.vue';

export default {
  directives: {
    tooltip,
  },
  components: {
    Icon,
    PipelinesList,
    JobsDetail,
    ResizablePanel,
  },
  computed: {
    ...mapState(['rightPane']),
    pipelinesActive() {
      return (
        this.rightPane === rightSidebarViews.pipelines ||
        this.rightPane === rightSidebarViews.jobsDetail
      );
    },
  },
  methods: {
    ...mapActions(['setRightPane']),
    clickTab(e, view) {
      e.target.blur();

      this.setRightPane(view);
    },
  },
  rightSidebarViews,
};
</script>

<template>
  <div
    class="multi-file-commit-panel ide-right-sidebar"
  >
    <resizable-panel
      v-if="rightPane"
      class="multi-file-commit-panel-inner"
      :collapsible="false"
      :initial-width="350"
      :min-size="350"
      side="right"
    >
      <component :is="rightPane" />
    </resizable-panel>
    <nav class="ide-activity-bar">
      <ul class="list-unstyled">
        <li>
          <button
            v-tooltip
            data-container="body"
            data-placement="left"
            :title="__('Pipelines')"
            class="ide-sidebar-link is-right"
            :class="{
              active: pipelinesActive
            }"
            type="button"
            @click="clickTab($event, $options.rightSidebarViews.pipelines)"
          >
            <icon
              :size="16"
              name="pipeline"
            />
          </button>
        </li>
      </ul>
    </nav>
  </div>
</template>
