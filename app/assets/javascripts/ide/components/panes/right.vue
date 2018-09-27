<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import { __ } from '~/locale';
import tooltip from '../../../vue_shared/directives/tooltip';
import Icon from '../../../vue_shared/components/icon.vue';
import { rightSidebarViews } from '../../constants';
import PipelinesList from '../pipelines/list.vue';
import JobsDetail from '../jobs/detail.vue';
import MergeRequestInfo from '../merge_requests/info.vue';
import ResizablePanel from '../resizable_panel.vue';
import Clientside from '../preview/clientside.vue';

export default {
  directives: {
    tooltip,
  },
  components: {
    Icon,
    PipelinesList,
    JobsDetail,
    ResizablePanel,
    MergeRequestInfo,
    Clientside,
  },
  props: {
    extensionTabs: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    ...mapState(['rightPane', 'currentMergeRequestId', 'clientsidePreviewEnabled']),
    ...mapGetters(['packageJson']),
    pipelinesActive() {
      return (
        this.rightPane === rightSidebarViews.pipelines ||
        this.rightPane === rightSidebarViews.jobsDetail
      );
    },
    showLivePreview() {
      return this.packageJson && this.clientsidePreviewEnabled;
    },
    defaultTabs() {
      return [
        {
          show: this.currentMergeRequestId,
          title: __('Merge Request'),
          isActive: this.rightPane === rightSidebarViews.mergeRequestInfo,
          view: rightSidebarViews.mergeRequestInfo,
          icon: 'text-description',
        },
        {
          show: true,
          title: __('Pipelines'),
          isActive: this.pipelinesActive,
          view: rightSidebarViews.pipelines,
          icon: 'rocket',
        },
        {
          show: this.showLivePreview,
          title: __('Live preview'),
          isActive: this.rightPane === rightSidebarViews.clientSidePreview,
          view: rightSidebarViews.clientSidePreview,
          icon: 'live-preview',
        },
      ];
    },
    tabs() {
      return this.defaultTabs
        .concat(this.extensionTabs)
        .filter(tab => tab.show);
    },
  },
  methods: {
    ...mapActions(['setRightPane']),
    clickTab(e, view) {
      e.target.blur();

      this.setRightPane(view);
    },
  },
};
</script>

<template>
  <div
    class="multi-file-commit-panel ide-right-sidebar"
  >
    <resizable-panel
      v-if="rightPane"
      :collapsible="false"
      :initial-width="350"
      :min-size="350"
      :class="`ide-right-sidebar-${rightPane}`"
      side="right"
      class="multi-file-commit-panel-inner"
    >
      <component :is="rightPane" />
    </resizable-panel>
    <nav class="ide-activity-bar">
      <ul class="list-unstyled">
        <li
          v-for="tab of tabs"
          :key="tab.title"
        >
          <button
            v-tooltip
            :title="tab.title"
            :aria-label="tab.title"
            :class="{
              active: tab.isActive
            }"
            data-container="body"
            data-placement="left"
            class="ide-sidebar-link is-right"
            type="button"
            @click="clickTab($event, tab.view)"
          >
            <icon
              :size="16"
              :name="tab.icon"
            />
          </button>
        </li>
      </ul>
    </nav>
  </div>
</template>
