<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { __ } from '~/locale';
import { rightSidebarViews, SIDEBAR_INIT_WIDTH, SIDEBAR_NAV_WIDTH } from '../../constants';
import JobsDetail from '../jobs/detail.vue';
import PipelinesList from '../pipelines/list.vue';
import ResizablePanel from '../resizable_panel.vue';
import TerminalView from '../terminal/view.vue';
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
    ...mapState(['currentMergeRequestId']),
    ...mapState('rightPane', ['isOpen']),
    rightExtensionTabs() {
      return [
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
          show: this.isTerminalVisible,
          title: __('Terminal'),
          views: [{ component: TerminalView, ...rightSidebarViews.terminal }],
          icon: 'terminal',
        },
      ];
    },
  },
  WIDTH,
};
</script>

<template>
  <resizable-panel
    class="gl-flex gl-overflow-hidden"
    side="right"
    :initial-width="$options.WIDTH"
    :min-size="$options.WIDTH"
    :resizable="isOpen"
  >
    <collapsible-sidebar class="gl-w-full" :extension-tabs="rightExtensionTabs" side="right" />
  </resizable-panel>
</template>
