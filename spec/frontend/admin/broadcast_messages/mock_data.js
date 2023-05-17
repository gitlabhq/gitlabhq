const generateMockMessage = (id) => ({
  id,
  delete_path: `/admin/broadcast_messages/${id}.js`,
  edit_path: `/admin/broadcast_messages/${id}/edit`,
  starts_at: new Date().toISOString(),
  ends_at: new Date().toISOString(),
  broadcast_type: 'banner',
  dismissable: true,
  message: 'YEET',
  theme: 'indigo',
  status: 'Expired',
  target_path: '*/welcome',
  target_roles: 'Maintainer, Owner',
  type: 'Banner',
});

export const generateMockMessages = (n) =>
  [...Array(n).keys()].map((id) => generateMockMessage(id + 1));

export const MOCK_MESSAGES = generateMockMessages(5).map((id) => generateMockMessage(id));

export const MOCK_TARGET_ACCESS_LEVELS = [
  ['Guest', 10],
  ['Reporter', 20],
  ['Developer', 30],
  ['Maintainer', 40],
  ['Owner', 50],
];
