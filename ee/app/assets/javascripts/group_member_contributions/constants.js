import { __ } from '~/locale';

const COLUMNS = [
  { name: 'fullname', text: __('Name') },
  { name: 'push', text: __('Pushed') },
  { name: 'issuesCreated', text: __('Opened issues') },
  { name: 'issuesClosed', text: __('Closed issues') },
  { name: 'mergeRequestsCreated', text: __('Opened MR') },
  { name: 'mergeRequestsMerged', text: __('Accepted MR') },
  { name: 'totalEvents', text: __('Total Contributions') },
];

export default COLUMNS;
