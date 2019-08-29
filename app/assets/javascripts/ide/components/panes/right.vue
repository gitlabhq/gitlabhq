<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import _ from 'underscore';
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
    ...mapState(['currentMergeRequestId', 'clientsidePreviewEnabled']),
    ...mapState('rightPane', ['isOpen', 'currentView']),
    ...mapGetters(['packageJson']),
    ...mapGetters('rightPane', ['isActiveView', 'isAliveView']),
    showLivePreview() {
      return this.packageJson && this.clientsidePreviewEnabled;
    },
    defaultTabs() {
      return [
        {
          show: this.currentMergeRequestId,
          title: __('Merge Request'),
          views: [rightSidebarViews.mergeRequestInfo],
          icon: 'text-description',
        },
        {
          show: true,
          title: __('Pipelines'),
          views: [rightSidebarViews.pipelines, rightSidebarViews.jobsDetail],
          icon: 'rocket',
        },
        {
          show: this.showLivePreview,
          title: __('Live preview'),
          views: [rightSidebarViews.clientSidePreview],
          icon: 'live-preview',
        },
      ];
    },
    tabs() {
      return this.defaultTabs.concat(this.extensionTabs).filter(tab => tab.show);
    },
    tabViews() {
      return _.flatten(this.tabs.map(tab => tab.views));
    },
    aliveTabViews() {
      return this.tabViews.filter(view => this.isAliveView(view.name));
    },
  },
  methods: {
    ...mapActions('rightPane', ['toggleOpen', 'open']),
    clickTab(e, tab) {
      e.target.blur();

      if (this.isActiveTab(tab)) {
        this.toggleOpen();
      } else {
        this.open(tab.views[0]);
      }
    },
    isActiveTab(tab) {
      return tab.views.some(view => this.isActiveView(view.name));
    },
  },
};
</script>

<template>
  <div class="multi-file-commit-panel ide-right-sidebar" data-qa-selector="ide_right_sidebar">
    <resizable-panel
      v-show="isOpen"
      :collapsible="false"
      :initial-width="350"
      :min-size="350"
      :class="`ide-right-sidebar-${currentView}`"
      side="right"
      class="multi-file-commit-panel-inner"
    >
      <div
        v-for="tabView in aliveTabViews"
        v-show="isActiveView(tabView.name)"
        :key="tabView.name"
        class="h-100"
      >
        <component :is="tabView.component || tabView.name" />
      </div>
    </resizable-panel>
    <nav class="ide-activity-bar">
      <ul class="list-unstyled">
        <li v-for="tab of tabs" :key="tab.title">
          <button
            v-tooltip
            :title="tab.title"
            :aria-label="tab.title"
            :class="{
              active: isActiveTab(tab) && isOpen,
            }"
            data-container="body"
            data-placement="left"
            :data-qa-selector="`${tab.title.toLowerCase()}_tab_button`"
            class="ide-sidebar-link is-right"
            type="button"
            @click="clickTab($event, tab)"
          >
            <icon :size="16" :name="tab.icon" />
          </button>
        </li>
      </ul>
    </nav>
  </div>
</template>
