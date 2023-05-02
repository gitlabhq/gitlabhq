export const mockAbuseReport = {
  user: {
    username: 'spamuser417',
    name: 'Sp4m User',
    createdAt: '2023-03-29T09:30:23.885Z',
    email: 'sp4m@spam.com',
    lastActivityOn: '2023-04-02',
    avatarUrl: 'https://www.gravatar.com/avatar/a2579caffc69ea5d7606f9dd9d8504ba?s=80&d=identicon',
    path: '/spamuser417',
    adminPath: '/admin/users/spamuser417',
    plan: 'Free',
    verificationState: { email: true, phone: false, creditCard: true },
    creditCard: {
      name: 'S. User',
      similarRecordsCount: 2,
      cardMatchesLink: '/admin/users/spamuser417/card_match',
    },
    otherReports: [
      {
        category: 'offensive',
        createdAt: '2023-02-28T10:09:54.982Z',
        reportPath: '/admin/abuse_reports/29',
      },
      {
        category: 'crypto',
        createdAt: '2023-03-31T11:57:11.849Z',
        reportPath: '/admin/abuse_reports/31',
      },
    ],
    mostUsedIp: null,
    lastSignInIp: '::1',
    snippetsCount: 0,
    groupsCount: 0,
    notesCount: 6,
  },
  reporter: {
    username: 'reporter',
    name: 'R Porter',
    avatarUrl: 'https://www.gravatar.com/avatar/a2579caffc69ea5d7606f9dd9d8504ba?s=80&d=identicon',
    path: '/reporter',
  },
  report: {
    message: 'This is obvious spam',
    reportedAt: '2023-03-29T09:39:50.502Z',
    category: 'spam',
    type: 'comment',
    content:
      '<p data-sourcepos="1:1-1:772" dir="auto">Farmers Toy Sale ON NOW | SHOP CATALOGUE ... 50% off Kids\' Underwear by Hanes ... BUY 1 GET 1 HALF PRICE on Women\'s Clothing by Whistle, Ella Clothing Farmers Toy Sale ON <a href="http://www.farmers.com" rel="nofollow noreferrer noopener" target="_blank">www.farmers.com</a> | SHOP CATALOGUE ... 50% off Kids\' Underwear by Hanes ... BUY 1 GET 1 HALF PRICE on Women\'s Clothing by Whistle, Ella Clothing Farmers Toy Sale ON NOW | SHOP CATALOGUE ... 50% off Kids\' Underwear by Farmers Toy Sale ON NOW | SHOP CATALOGUE ... 50% off Kids\' Underwear by Hanes ... BUY 1 GET 1 HALF PRICE on Women\'s Clothing by Whistle, Ella Clothing Farmers Toy Sale ON <a href="http://www.farmers.com" rel="nofollow noreferrer noopener" target="_blank">www.farmers.com</a> | SHOP CATALOGUE ... 50% off Kids\' Underwear by Hanes ... BUY 1 GET 1 HALF PRICE on Women\'s Clothing by Whistle, Ella Clothing Farmers Toy Sale ON NOW | SHOP CATALOGUE ... 50% off Kids\' Underwear by.</p>',
    url: 'http://localhost:3000/spamuser417/project/-/merge_requests/1#note_1375',
    screenshot:
      '/uploads/-/system/abuse_report/screenshot/27/Screenshot_2023-03-30_at_16.56.37.png',
  },
  actions: {
    reportedUser: { name: 'Sp4m User', createdAt: '2023-03-29T09:30:23.885Z' },
    userBlocked: false,
    blockUserPath: '/admin/users/spamuser417/block',
    removeReportPath: '/admin/abuse_reports/27',
    removeUserAndReportPath: '/admin/abuse_reports/27?remove_user=true',
    redirectPath: '/admin/abuse_reports',
  },
};
