import { isSafeURL } from '~/lib/utils/url_utility';

const isRunbookUrlValid = (runbookUrl) => {
  if (!runbookUrl) {
    return true;
  }
  return isSafeURL(runbookUrl);
};

// Prop validator for alert information, expecting an object like the example below.
//
// {
//   '/root/autodevops-deploy/prometheus/alerts/16.json?environment_id=37': {
//     alert_path: "/root/autodevops-deploy/prometheus/alerts/16.json?environment_id=37",
//     metricId: '1',
//     operator: ">",
//     query: "rate(http_requests_total[5m])[30m:1m]",
//     threshold: 0.002,
//     title: "Core Usage (Total)",
//     runbookUrl: "https://www.gitlab.com/my-project/-/wikis/runbook"
//   }
// }
export function alertsValidator(value) {
  return Object.keys(value).every((key) => {
    const alert = value[key];
    return (
      alert.alert_path &&
      key === alert.alert_path &&
      alert.metricId &&
      typeof alert.metricId === 'string' &&
      alert.operator &&
      typeof alert.threshold === 'number' &&
      isRunbookUrlValid(alert.runbookUrl)
    );
  });
}

// Prop validator for query information, expecting an array like the example below.
//
// [
//   {
//     metricId: '16',
//     label: 'Total Cores'
//   },
//   {
//     metricId: '17',
//     label: 'Sub-total Cores'
//   }
// ]
export function queriesValidator(value) {
  return value.every(
    (query) =>
      query.metricId && typeof query.metricId === 'string' && typeof query.label === 'string',
  );
}
