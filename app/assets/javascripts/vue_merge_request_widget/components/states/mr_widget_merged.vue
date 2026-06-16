<script>
import { GlTooltipDirective } from '@gitlab/ui';
import api from '~/api';
import { s__ } from '~/locale';
import { OPEN_REVERT_MODAL, OPEN_CHERRY_PICK_MODAL } from '~/projects/commit/constants';
import modalEventHub from '~/projects/commit/event_hub';
import sourceBranchRemovalMixin from '../../mixins/source_branch_removal';
import { POST_MERGE_DELETE_BRANCH_EVENT } from '../../constants';
import { MR_WIDGET_DELETE_SOURCE_BRANCH } from '../../i18n';
import MrWidgetAuthorTime from '../mr_widget_author_time.vue';
import StateContainer from '../state_container.vue';

export default {
  name: 'MRWidgetMerged',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    MrWidgetAuthorTime,
    StateContainer,
  },
  mixins: [sourceBranchRemovalMixin],
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },

  computed: {
    revertTitle() {
      return s__('mrWidget|Revert this merge request in a new merge request');
    },
    cherryPickTitle() {
      return s__('mrWidget|Cherry-pick this merge request in a new merge request');
    },
    revertLabel() {
      return s__('mrWidget|Revert');
    },
    cherryPickLabel() {
      return s__('mrWidget|Cherry-pick');
    },
    actions() {
      const actionsList = [];

      if (this.mr.revertInForkPath) {
        actionsList.push({
          text: this.revertLabel,
          tooltipText: this.revertTitle,
          href: this.mr.revertInForkPath,
          testId: 'revert-button',
          dataMethod: 'post',
        });
      } else {
        actionsList.push({
          text: this.revertLabel,
          tooltipText: this.revertTitle,
          testId: 'revert-button',
          onClick: () => this.openRevertModal(),
        });
      }

      if (this.mr.canCherryPickInCurrentMR) {
        actionsList.push({
          text: this.cherryPickLabel,
          tooltipText: this.cherryPickTitle,
          testId: 'cherry-pick-button',
          onClick: () => this.openCherryPickModal(),
        });
      } else if (this.mr.cherryPickInForkPath) {
        actionsList.push({
          text: this.cherryPickLabel,
          tooltipText: this.cherryPickTitle,
          href: this.mr.cherryPickInForkPath,
          testId: 'cherry-pick-button',
          dataMethod: 'post',
        });
      }

      if (this.shouldShowRemoveSourceBranch) {
        actionsList.push({
          text: MR_WIDGET_DELETE_SOURCE_BRANCH,
          class: 'js-remove-branch-button',
          onClick: () => this.removeSourceBranch(POST_MERGE_DELETE_BRANCH_EVENT),
        });
      }

      return actionsList;
    },
  },
  mounted() {
    document.dispatchEvent(new CustomEvent('merged:UpdateActions'));
  },
  methods: {
    openRevertModal() {
      api.trackRedisHllUserEvent('i_code_review_post_merge_click_revert');

      modalEventHub.$emit(OPEN_REVERT_MODAL);
    },
    openCherryPickModal() {
      api.trackRedisHllUserEvent('i_code_review_post_merge_click_cherry_pick');

      modalEventHub.$emit(OPEN_CHERRY_PICK_MODAL);
    },
  },
};
</script>
<template>
  <state-container :actions="actions" status="merged">
    <mr-widget-author-time
      :action-text="s__('mrWidget|Merged by')"
      :author="mr.metrics.mergedBy"
      :date-title="mr.metrics.mergedAt"
      :date-readable="mr.metrics.readableMergedAt"
    />
  </state-container>
</template>
