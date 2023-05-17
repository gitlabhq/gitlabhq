import { s__, n__ } from '~/locale';

export const REPORT_HEADER_I18N = {
  adminProfile: s__('AbuseReport|Admin profile'),
};

export const USER_DETAILS_I18N = {
  createdAt: s__('AbuseReport|Member since'),
  email: s__('AbuseReport|Email'),
  plan: s__('AbuseReport|Tier'),
  verification: s__('AbuseReport|Verification'),
  creditCard: s__('AbuseReport|Credit card'),
  otherReports: s__('AbuseReport|Abuse reports'),
  normalLocation: s__('AbuseReport|Normal location'),
  lastSignInIp: s__('AbuseReport|Last login'),
  snippets: s__('AbuseReport|Snippets'),
  groups: s__('AbuseReport|Groups'),
  notes: s__('AbuseReport|Comments'),
  snippetsCount: (count) => n__(`%d snippet`, `%d snippets`, count),
  groupsCount: (count) => n__(`%d group`, `%d groups`, count),
  notesCount: (count) => n__(`%d comment`, `%d comments`, count),
  verificationMethods: {
    email: s__('AbuseReport|Email'),
    phone: s__('AbuseReport|Phone'),
    creditCard: s__('AbuseReport|Credit card'),
  },
  otherReport: s__(
    'AbuseReport|%{reportLinkStart}Reported%{reportLinkEnd} for %{category} %{timeAgo}.',
  ),
  registeredWith: s__('AbuseReport|Registered with name %{name}.'),
  similarRecords: s__(
    'AbuseReport|Card matches %{cardMatchesLinkStart}%{count} accounts%{cardMatchesLinkEnd}',
  ),
};

export const REPORTED_CONTENT_I18N = {
  reportTypes: {
    profile: s__('AbuseReport|Reported profile'),
    comment: s__('AbuseReport|Reported comment'),
    issue: s__('AbuseReport|Reported issue'),
    merge_request: s__('AbuseReport|Reported merge request'),
    unknown: s__('AbuseReport|Reported content'),
  },
  viewScreenshot: s__('AbuseReport|View screenshot'),
  screenshotTitle: s__('AbuseReport|Screenshot of reported abuse'),
  goToType: {
    profile: s__('AbuseReport|Go to profile'),
    comment: s__('AbuseReport|Go to comment'),
    issue: s__('AbuseReport|Go to issue'),
    merge_request: s__('AbuseReport|Go to merge request'),
    unknown: s__('AbuseReport|Go to content'),
  },
  reportedBy: s__('AbuseReport|Reported by'),
  deletedReporter: s__('AbuseReport|No user found'),
};

export const HISTORY_ITEMS_I18N = {
  activity: s__('AbuseReport|Activity'),
  reportedByForCategory: s__('AbuseReport|Reported by %{name} for %{category}.'),
  deletedReporter: s__('AbuseReport|No user found'),
};
