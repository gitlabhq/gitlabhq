import { __, s__ } from '~/locale';

export const SERVICE_DESK_BOT_USERNAME = 'support-bot';
export const MAX_LIST_SIZE = 10;
export const STATUS_ALL = 'all';
export const STATUS_CLOSED = 'closed';
export const STATUS_OPEN = 'opened';
export const WORKSPACE_PROJECT = 'project';

export const errorFetchingCounts = __('An error occurred while getting issue counts');
export const errorFetchingIssues = __('An error occurred while loading issues');
export const noSearchNoFilterTitle = __('Please select at least one filter to see results');
export const searchPlaceholder = __('Search or filter results...');
export const infoBannerTitle = s__(
  'ServiceDesk|Use Service Desk to connect with your users and offer customer support through email right inside GitLab',
);
export const infoBannerAdminNote = s__('ServiceDesk|Your users can send emails to this address:');
export const infoBannerUserNote = s__(
  'ServiceDesk|Issues created from Service Desk emails will appear here. Each comment becomes part of the email conversation.',
);
export const enableServiceDesk = s__('ServiceDesk|Enable Service Desk');
export const learnMore = __('Learn more');
export const titles = __('Titles');
export const descriptions = __('Descriptions');
export const no = __('No');
export const yes = __('Yes');
