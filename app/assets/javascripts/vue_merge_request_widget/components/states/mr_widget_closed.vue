<script>
import api from '~/api';
import showGlobalToast from '~/vue_shared/plugins/global_toast';

import MrWidgetAuthorTime from '../mr_widget_author_time.vue';
import StateContainer from '../state_container.vue';

import {
  MR_WIDGET_CLOSED_REOPEN,
  MR_WIDGET_CLOSED_REOPENING,
  MR_WIDGET_CLOSED_RELOADING,
  MR_WIDGET_CLOSED_REOPEN_FAILURE,
} from '../../i18n';

export default {
  name: 'MRWidgetClosed',
  components: {
    MrWidgetAuthorTime,
    StateContainer,
  },
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

      return [
        {
          text: this.reopenText,
          loading: this.isPending || this.isReloading,
          onClick: this.reopen,
          testId: 'extension-actions-reopen-button',
        },
      ];
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
  <state-container status="closed" :actions="actions" is-collapsible>
    <mr-widget-author-time
      :action-text="s__('mrWidget|Closed by')"
      :author="mr.metrics.closedBy"
      :date-title="mr.metrics.closedAt"
      :date-readable="mr.metrics.readableClosedAt"
    />
  </state-container>
</template>
