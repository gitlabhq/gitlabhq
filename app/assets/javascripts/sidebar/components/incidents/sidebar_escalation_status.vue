<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { logError } from '~/lib/logger';
import EscalationStatus from 'ee_else_ce/sidebar/components/incidents/escalation_status.vue';
import { INCIDENTS_I18N as i18n } from '../../constants';
import { escalationStatusQuery, escalationStatusMutation } from '../../queries/constants';
import { getStatusLabel } from '../../utils';
import SidebarEditableItem from '../sidebar_editable_item.vue';

export default {
  i18n,
  components: {
    EscalationStatus,
    SidebarEditableItem,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    iid: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    issuableType: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      status: null,
      isUpdating: false,
    };
  },
  apollo: {
    status: {
      query() {
        return escalationStatusQuery;
      },
      variables() {
        return {
          fullPath: this.projectPath,
          iid: this.iid,
        };
      },
      update(data) {
        return data.workspace?.issuable?.escalationStatus;
      },
      error(error) {
        const message = this.$options.i18n.fetchError;
        createAlert({ message });
        logError(message, error);
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.status.loading;
    },
    currentStatusLabel() {
      return getStatusLabel(this.status);
    },
    tooltipText() {
      return `${this.$options.i18n.title}: ${this.currentStatusLabel}`;
    },
  },
  methods: {
    updateStatus(status) {
      this.isUpdating = true;
      this.closeSidebar();
      return this.$apollo
        .mutate({
          mutation: escalationStatusMutation,
          variables: {
            status,
            iid: this.iid,
            projectPath: this.projectPath,
          },
        })
        .then(({ data: { issueSetEscalationStatus } }) => {
          this.status = issueSetEscalationStatus.issue.escalationStatus;
        })
        .catch((error) => {
          const message = this.$options.i18n.updateError;
          createAlert({ message });
          logError(message, error);
        })
        .finally(() => {
          this.isUpdating = false;
        });
    },
    closeSidebar() {
      this.close();
      this.$refs.editable.collapse();
    },
    open() {
      this.$refs.escalationStatus.show();
    },
    close() {
      this.$refs.escalationStatus.hide();
    },
  },
};
</script>

<template>
  <sidebar-editable-item
    ref="editable"
    :title="$options.i18n.title"
    :initial-loading="isLoading"
    :loading="isUpdating"
    @open="open"
    @close="close"
  >
    <template #default>
      <escalation-status ref="escalationStatus" :value="status" @input="updateStatus" />
    </template>
    <template #collapsed>
      <div
        v-gl-tooltip.viewport.left="tooltipText"
        class="sidebar-collapsed-icon"
        data-testid="status-icon"
      >
        <gl-icon name="status" :size="16" />
      </div>
      <span class="hide-collapsed gl-text-subtle">{{ currentStatusLabel }}</span>
    </template>
  </sidebar-editable-item>
</template>
