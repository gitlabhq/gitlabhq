<script>
import { GlTooltipDirective } from '@gitlab/ui';
import api from '~/api';
import { createAlert } from '~/alert';
import { s__, __ } from '~/locale';
import { OPEN_REVERT_MODAL, OPEN_CHERRY_PICK_MODAL } from '~/projects/commit/constants';
import modalEventHub from '~/projects/commit/event_hub';
import eventHub from '../../event_hub';
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
  props: {
    mr: {
      type: Object,
      required: true,
    },
    service: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isMakingRequest: false,
    };
  },
  computed: {
    shouldShowRemoveSourceBranch() {
      const { sourceBranchRemoved, isRemovingSourceBranch, canRemoveSourceBranch } = this.mr;

      return (
        !sourceBranchRemoved &&
        canRemoveSourceBranch &&
        !this.isMakingRequest &&
        !isRemovingSourceBranch
      );
    },
    shouldShowSourceBranchRemoving() {
      const { sourceBranchRemoved, isRemovingSourceBranch } = this.mr;
      return !sourceBranchRemoved && (isRemovingSourceBranch || this.isMakingRequest);
    },
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
      const actions = [];

      if (this.mr.canRevertInCurrentMR) {
        actions.push({
          text: this.revertLabel,
          tooltipText: this.revertTitle,
          testId: 'revert-button',
          onClick: () => this.openRevertModal(),
        });
      } else if (this.mr.revertInForkPath) {
        actions.push({
          text: this.revertLabel,
          tooltipText: this.revertTitle,
          href: this.mr.revertInForkPath,
          testId: 'revert-button',
          dataMethod: 'post',
        });
      }

      if (this.mr.canCherryPickInCurrentMR) {
        actions.push({
          text: this.cherryPickLabel,
          tooltipText: this.cherryPickTitle,
          testId: 'cherry-pick-button',
          onClick: () => this.openCherryPickModal(),
        });
      } else if (this.mr.cherryPickInForkPath) {
        actions.push({
          text: this.cherryPickLabel,
          tooltipText: this.cherryPickTitle,
          href: this.mr.cherryPickInForkPath,
          testId: 'cherry-pick-button',
          dataMethod: 'post',
        });
      }

      if (this.shouldShowRemoveSourceBranch) {
        actions.push({
          text: s__('mrWidget|Delete source branch'),
          class: 'js-remove-branch-button',
          onClick: () => this.removeSourceBranch(),
        });
      }

      return actions;
    },
  },
  mounted() {
    document.dispatchEvent(new CustomEvent('merged:UpdateActions'));
  },
  methods: {
    removeSourceBranch() {
      this.isMakingRequest = true;

      api.trackRedisHllUserEvent('i_code_review_post_merge_delete_branch');

      this.service
        .removeSourceBranch()
        .then((res) => res.data)
        .then((data) => {
          // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
          // eslint-disable-next-line @gitlab/require-i18n-strings
          if (data.message === 'Branch was deleted') {
            eventHub.$emit('MRWidgetUpdateRequested', () => {
              this.isMakingRequest = false;
            });
          }
        })
        .catch(() => {
          this.isMakingRequest = false;
          createAlert({
            message: __('Something went wrong. Please try again.'),
          });
        });
    },
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
  <state-container :actions="actions" status="merged" is-collapsible>
    <mr-widget-author-time
      :action-text="s__('mrWidget|Merged by')"
      :author="mr.metrics.mergedBy"
      :date-title="mr.metrics.mergedAt"
      :date-readable="mr.metrics.readableMergedAt"
    />
  </state-container>
</template>
