<script>
import { mapGetters, mapState } from 'vuex';
import { __ } from '~/locale';
import CollapsibleSidebar from './collapsible_sidebar.vue';
import { rightSidebarViews } from '../../constants';
import MergeRequestInfo from '../merge_requests/info.vue';
import PipelinesList from '../pipelines/list.vue';
import JobsDetail from '../jobs/detail.vue';
import Clientside from '../preview/clientside.vue';

export default {
  name: 'RightPane',
  components: {
    CollapsibleSidebar,
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
    ...mapGetters(['packageJson']),
    showLivePreview() {
      return this.packageJson && this.clientsidePreviewEnabled;
    },
    rightExtensionTabs() {
      return [
        {
          show: Boolean(this.currentMergeRequestId),
          title: __('Merge Request'),
          views: [{ component: MergeRequestInfo, ...rightSidebarViews.mergeRequestInfo }],
          icon: 'text-description',
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
        ...this.extensionTabs,
      ];
    },
  },
};
</script>

<template>
  <collapsible-sidebar :extension-tabs="rightExtensionTabs" side="right" :width="350" />
</template>
