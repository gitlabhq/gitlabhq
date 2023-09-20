import { mockLabel1, mockLabel2 } from '../abuse_report/mock_data';

export const mockAbuseReports = [
  {
    category: 'spam',
    createdAt: '2018-10-03T05:46:38.977Z',
    updatedAt: '2022-12-07T06:45:39.977Z',
    reporter: { name: 'Ms. Admin' },
    reportedUser: { name: 'Mr. Abuser' },
    reportPath: '/admin/abuse_reports/1',
    count: 1,
    labels: [mockLabel1, mockLabel2],
  },
  {
    category: 'phishing',
    createdAt: '2018-10-03T05:46:38.977Z',
    updatedAt: '2022-12-07T06:45:39.977Z',
    reporter: { name: 'Ms. Reporter' },
    reportedUser: { name: 'Mr. Phisher' },
    reportPath: '/admin/abuse_reports/2',
    count: 2,
  },
];
