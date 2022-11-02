<script>
import { mapGetters, mapState } from 'vuex';
import { __ } from '~/locale';
import { rightSidebarViews, SIDEBAR_INIT_WIDTH, SIDEBAR_NAV_WIDTH } from '../../constants';
import JobsDetail from '../jobs/detail.vue';
import PipelinesList from '../pipelines/list.vue';
import Clientside from '../preview/clientside.vue';
import ResizablePanel from '../resizable_panel.vue';
import TerminalView from '../terminal/view.vue';
import SwitchEditorsView from '../switch_editors/switch_editors_view.vue';
import CollapsibleSidebar from './collapsible_sidebar.vue';

// Need to add the width of the nav buttons since the resizable container contains those as well
const WIDTH = SIDEBAR_INIT_WIDTH + SIDEBAR_NAV_WIDTH;

export default {
  name: 'RightPane',
  components: {
    CollapsibleSidebar,
    ResizablePanel,
  },
  computed: {
    ...mapState('terminal', { isTerminalVisible: 'isVisible' }),
    ...mapState(['currentMergeRequestId', 'clientsidePreviewEnabled', 'canUseNewWebIde']),
    ...mapGetters(['packageJson']),
    ...mapState('rightPane', ['isOpen']),
    showLivePreview() {
      return this.packageJson && this.clientsidePreviewEnabled;
    },
    rightExtensionTabs() {
      return [
        {
          show: this.canUseNewWebIde,
          title: __('Switch editors'),
          views: [{ component: SwitchEditorsView, ...rightSidebarViews.switchEditors }],
          icon: 'bullhorn',
        },
        {
          show: true,
          title: __('Pipelines'),
          views: [
            { component: PipelinesList, ...rightSidebarViews.pipelines },
            { component: JobsDetail, ...rightSidebarViews.jobsDetail },
          ],
          icon: 'rocket',
        },
        {
          show: this.showLivePreview,
          title: __('Live preview'),
          views: [{ component: Clientside, ...rightSidebarViews.clientSidePreview }],
          icon: 'live-preview',
        },
        {
          show: this.isTerminalVisible,
          title: __('Terminal'),
          views: [{ component: TerminalView, ...rightSidebarViews.terminal }],
          icon: 'terminal',
        },
      ];
    },
  },
  WIDTH,
  SWITCH_EDITORS_VIEW_NAME: rightSidebarViews.switchEditors.name,
};
</script>

<template>
  <resizable-panel
    class="gl-display-flex gl-overflow-hidden"
    side="right"
    :initial-width="$options.WIDTH"
    :min-size="$options.WIDTH"
    :resizable="isOpen"
  >
    <collapsible-sidebar
      class="gl-w-full"
      :extension-tabs="rightExtensionTabs"
      :init-open-view="$options.SWITCH_EDITORS_VIEW_NAME"
      side="right"
    />
  </resizable-panel>
</template>
