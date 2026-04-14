import { s__ } from '~/locale';

// TODO: Consider extracting a shared CI status-to-icon mapping with
// app/assets/javascripts/ci/common/private/jobs_filtered_search/tokens/job_status_token.vue
// https://gitlab.com/gitlab-org/gitlab/-/work_items/594932
const statusMap = {
  created: { icon: 'status_created', text: s__('CiStatusText|Created') },
  waiting_for_resource: { icon: 'status-waiting', text: s__('CiStatusText|Waiting') },
  preparing: { icon: 'status_preparing', text: s__('CiStatusText|Preparing') },
  waiting_for_callback: { icon: 'status_pending', text: s__('CiStatusText|Waiting') },
  pending: { icon: 'status_pending', text: s__('CiStatusText|Pending') },
  running: { icon: 'status_running', text: s__('CiStatusText|Running') },
  success: { icon: 'status_success', text: s__('CiStatusText|Passed') },
  failed: { icon: 'status_failed', text: s__('CiStatusText|Failed') },
  canceling: { icon: 'status_canceled', text: s__('CiStatusText|Canceling') },
  canceled: { icon: 'status_canceled', text: s__('CiStatusText|Canceled') },
  skipped: { icon: 'status_skipped', text: s__('CiStatusText|Skipped') },
  manual: { icon: 'status_manual', text: s__('CiStatusText|Manual') },
  scheduled: { icon: 'status_scheduled', text: s__('CiStatusText|Scheduled') },
};

export const ciStatusToIcon = (status) => {
  if (status == null) return null;
  const normalized = String(status).toLowerCase();
  return statusMap[normalized] || null;
};
