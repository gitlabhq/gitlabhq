<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';

export default {
  components: {
    GlEmptyState,
    GlButton,
  },
  props: {
    enableAlertManagementPath: {
      type: String,
      required: true,
    },
    userCanEnableAlertManagement: {
      type: Boolean,
      required: true,
    },
    emptyAlertSvgPath: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div>
    <gl-empty-state
      :title="s__('AlertManagement|Surface alerts in GitLab')"
      :svg-path="emptyAlertSvgPath"
    >
      <template #description>
        <div class="d-block">
          <span>{{
            s__(
              'AlertManagement|Display alerts from all your monitoring tools directly within GitLab. Streamline the investigation of your alerts and the escalation of alerts to incidents.',
            )
          }}</span>
          <a href="/help/user/project/operations/alert_management.html" target="_blank">
            {{ s__('AlertManagement|More information') }}
          </a>
        </div>
        <div v-if="userCanEnableAlertManagement" class="d-block center pt-4">
          <gl-button category="primary" variant="success" :href="enableAlertManagementPath">
            {{ s__('AlertManagement|Authorize external service') }}
          </gl-button>
        </div>
      </template>
    </gl-empty-state>
  </div>
</template>
