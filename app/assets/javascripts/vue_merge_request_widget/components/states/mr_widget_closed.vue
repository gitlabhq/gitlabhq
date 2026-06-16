<script>
import api from '~/api';
import showGlobalToast from '~/vue_shared/plugins/global_toast';

import sourceBranchRemovalMixin from '../../mixins/source_branch_removal';
import { POST_CLOSE_DELETE_BRANCH_EVENT } from '../../constants';
import MrWidgetAuthorTime from '../mr_widget_author_time.vue';
import StateContainer from '../state_container.vue';

import {
  MR_WIDGET_CLOSED_REOPEN,
  MR_WIDGET_CLOSED_REOPENING,
  MR_WIDGET_CLOSED_RELOADING,
  MR_WIDGET_CLOSED_REOPEN_FAILURE,
  MR_WIDGET_DELETE_SOURCE_BRANCH,
} from '../../i18n';

export default {
  name: 'MRWidgetClosed',
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
  data() {
    return {
      isPending: false,
      isReloading: false,
    };
  },
  computed: {
    reopenText() {
      let text = MR_WIDGET_CLOSED_REOPEN;

      if (this.isPending) {
        text = MR_WIDGET_CLOSED_REOPENING;
      } else if (this.isReloading) {
        text = MR_WIDGET_CLOSED_RELOADING;
      }

      return text;
    },
    actions() {
      if (!window.gon?.current_user_id) {
        return [];
      }

      const actionsList = [
        {
          text: this.reopenText,
          loading: this.isPending || this.isReloading,
          onClick: this.reopen,
          testId: 'extension-actions-reopen-button',
        },
      ];

      if (this.shouldShowRemoveSourceBranch) {
        actionsList.push({
          text: MR_WIDGET_DELETE_SOURCE_BRANCH,
          class: 'js-remove-branch-button',
          onClick: () => this.removeSourceBranch(POST_CLOSE_DELETE_BRANCH_EVENT),
        });
      }

      return actionsList;
    },
  },
  methods: {
    reopen() {
      this.isPending = true;

      api
        .updateMergeRequest(this.mr.targetProjectId, this.mr.iid, { state_event: 'reopen' })
        .then(() => {
          this.isReloading = true;

          window.location.reload();
        })
        .catch(() => {
          showGlobalToast(MR_WIDGET_CLOSED_REOPEN_FAILURE);
        })
        .finally(() => {
          this.isPending = false;
        });
    },
  },
};
</script>
<template>
  <state-container status="closed" :actions="actions">
    <mr-widget-author-time
      :action-text="s__('mrWidget|Closed by')"
      :author="mr.metrics.closedBy"
      :date-title="mr.metrics.closedAt"
      :date-readable="mr.metrics.readableClosedAt"
    />
  </state-container>
</template>
