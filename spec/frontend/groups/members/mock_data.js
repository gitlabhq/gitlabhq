export const membersJsonString =
  '[{"requested_at":null,"can_update":true,"can_remove":true,"can_override":false,"access_level":{"integer_value":50,"string_value":"Owner"},"source":{"id":323,"name":"My group / my subgroup","web_url":"http://127.0.0.1:3000/groups/my-group/my-subgroup"},"user":{"id":1,"name":"Administrator","username":"root","web_url":"http://127.0.0.1:3000/root","avatar_url":"https://www.gravatar.com/avatar/4816142ef496f956a277bedf1a40607b?s=80\u0026d=identicon","blocked":false,"two_factor_enabled":false},"id":524,"created_at":"2020-08-21T21:33:27.631Z","expires_at":null,"using_license":false,"group_sso":false,"group_managed_account":false}]';

export const membersParsed = [
  {
    requestedAt: null,
    canUpdate: true,
    canRemove: true,
    canOverride: false,
    accessLevel: { integerValue: 50, stringValue: 'Owner' },
    source: {
      id: 323,
      name: 'My group / my subgroup',
      webUrl: 'http://127.0.0.1:3000/groups/my-group/my-subgroup',
    },
    user: {
      id: 1,
      name: 'Administrator',
      username: 'root',
      webUrl: 'http://127.0.0.1:3000/root',
      avatarUrl:
        'https://www.gravatar.com/avatar/4816142ef496f956a277bedf1a40607b?s=80&d=identicon',
      blocked: false,
      twoFactorEnabled: false,
    },
    id: 524,
    createdAt: '2020-08-21T21:33:27.631Z',
    expiresAt: null,
    usingLicense: false,
    groupSso: false,
    groupManagedAccount: false,
  },
];
