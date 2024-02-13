import { s__ } from '~/locale';

export const CATEGORY_OPTIONS = [
  { value: 'spam', text: s__("ReportAbuse|They're posting spam.") },
  { value: 'offensive', text: s__("ReportAbuse|They're being offensive or abusive.") },
  { value: 'phishing', text: s__("ReportAbuse|They're phishing.") },
  { value: 'crypto', text: s__("ReportAbuse|They're crypto mining.") },
  {
    value: 'credentials',
    text: s__("ReportAbuse|They're posting personal information or credentials."),
  },
  { value: 'copyright', text: s__("ReportAbuse|They're violating a copyright or trademark.") },
  { value: 'malware', text: s__("ReportAbuse|They're posting malware.") },
  { value: 'other', text: s__('ReportAbuse|Something else.') },
];
