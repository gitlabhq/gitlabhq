import { s__, n__, __ } from '~/locale';

export const STATUS_OPEN = 'open';
export const STATUS_CLOSED = 'closed';

export const SUCCESS_ALERT = 'success';
export const FAILED_ALERT = 'danger';

export const ERROR_MESSAGE = __('Something went wrong. Please try again.');

export const REPORT_HEADER_I18N = {
  adminProfile: s__('AbuseReport|Admin profile'),
  open: __('Open'),
  closed: __('Closed'),
};

export const ACTIONS_I18N = {
  actions: s__('AbuseReport|Actions'),
  confirm: s__('AbuseReport|Confirm'),
  action: s__('AbuseReport|Action'),
  reason: s__('AbuseReport|Reason'),
  comment: s__('AbuseReport|Comment'),
  closeReport: s__('AbuseReport|Close report'),
  requiredFieldFeedback: __('This field is required.'),
};

export const NO_ACTION = { value: '', text: s__('AbuseReport|No action') };
export const TRUST_REASON = { value: 'trusted', text: s__(`AbuseReport|Confirmed trusted user`) };
export const TRUST_ACTION = { value: 'trust_user', text: s__('AbuseReport|Trust user') };

export const USER_ACTION_OPTIONS = [
  NO_ACTION,
  { value: 'block_user', text: s__('AbuseReport|Block user') },
  { value: 'ban_user', text: s__('AbuseReport|Ban user') },
  TRUST_ACTION,
  { value: 'delete_user', text: s__('AbuseReport|Delete user') },
];

export const REASON_OPTIONS = [
  { value: '', text: '' },
  { value: 'spam', text: s__('AbuseReport|Confirmed spam') },
  { value: 'offensive', text: s__('AbuseReport|Confirmed offensive or abusive behavior') },
  { value: 'phishing', text: s__('AbuseReport|Confirmed phishing') },
  { value: 'crypto', text: s__('AbuseReport|Confirmed crypto mining') },
  {
    value: 'credentials',
    text: s__('AbuseReport|Confirmed posting of personal information or credentials'),
  },
  {
    value: 'copyright',
    text: s__('AbuseReport|Confirmed violation of a copyright or a trademark'),
  },
  { value: 'malware', text: s__('AbuseReport|Confirmed posting of malware') },
  { value: 'other', text: s__('AbuseReport|Something else') },
  { value: 'unconfirmed', text: s__('AbuseReport|Abuse unconfirmed') },
];

export const USER_DETAILS_I18N = {
  createdAt: s__('AbuseReport|Member since'),
  email: s__('AbuseReport|Email'),
  plan: s__('AbuseReport|Tier'),
  verification: s__('AbuseReport|Verification'),
  creditCard: s__('AbuseReport|Credit card'),
  phoneNumber: s__('AbuseReport|Phone number'),
  pastReports: s__('AbuseReport|Past abuse reports'),
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
  reportedFor: s__(
    'AbuseReport|%{reportLinkStart}Reported%{reportLinkEnd} for %{category} %{timeAgo}.',
  ),
  creditCardSimilarRecords: s__(
    'AbuseReport|Card matches %{cardMatchesLinkStart}%{count} accounts%{cardMatchesLinkEnd}',
  ),
  phoneNumberSimilarRecords: s__(
    'AbuseReport|Phone matches %{phoneMatchesLinkStart}%{count} accounts%{phoneMatchesLinkEnd}',
  ),
};

export const REPORTED_CONTENT_I18N = {
  reportTypes: {
    profile: s__('AbuseReport|Reported profile'),
    comment: s__('AbuseReport|Reported comment'),
    issue: s__('AbuseReport|Reported issue'),
    merge_request: s__('AbuseReport|Reported merge request'),
    epic: s__('AbuseReport|Reported epic'),
    unknown: s__('AbuseReport|Reported content'),
  },
  viewScreenshot: s__('AbuseReport|View screenshot'),
  screenshotTitle: s__('AbuseReport|Screenshot of reported abuse'),
  goToType: {
    profile: s__('AbuseReport|Go to profile'),
    comment: s__('AbuseReport|Go to comment'),
    issue: s__('AbuseReport|Go to issue'),
    merge_request: s__('AbuseReport|Go to merge request'),
    epic: s__('AbuseReport|Go to epic'),
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

export const SKELETON_NOTES_COUNT = 5;
