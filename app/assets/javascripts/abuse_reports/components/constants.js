import { s__ } from '~/locale';

export const CATEGORY_OPTIONS = [
  { value: 'spam', text: s__("ReportAbuse|They're posting spam or unsolicited content.") },
  { value: 'offensive', text: s__("ReportAbuse|They're being offensive, harassing, or abusive.") },
  { value: 'phishing', text: s__("ReportAbuse|They're phishing or impersonating others.") },
  { value: 'crypto', text: s__("ReportAbuse|They're using GitLab to mine cryptocurrency.") },
  {
    value: 'credentials',
    text: s__("ReportAbuse|They're posting personal information or credentials."),
  },
  { value: 'copyright', text: s__("ReportAbuse|They're violating a copyright or trademark.") },
  { value: 'malware', text: s__("ReportAbuse|They're distributing malware or malicious code.") },
  { value: 'other', text: s__('ReportAbuse|Something else.') },
];
