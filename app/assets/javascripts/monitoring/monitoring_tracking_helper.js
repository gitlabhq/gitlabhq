import Tracking from '~/tracking';

const trackDashboardLoad = ({ label, value }) =>
  Tracking.event(document.body.dataset.page, 'dashboard_fetch', {
    label,
    property: 'count',
    value,
  });

export default trackDashboardLoad;
