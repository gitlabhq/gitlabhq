const generateMockMessage = (id) => ({
  id,
  delete_path: `/admin/broadcast_messages/${id}.js`,
  edit_path: `/admin/broadcast_messages/${id}/edit`,
  starts_at: new Date().toISOString(),
  ends_at: new Date().toISOString(),
  preview: '<div>YEET</div>',
  status: 'Expired',
  target_path: '*/welcome',
  target_roles: 'Maintainer, Owner',
  type: 'Banner',
});

export const generateMockMessages = (n) =>
  [...Array(n).keys()].map((id) => generateMockMessage(id + 1));

export const MOCK_MESSAGES = generateMockMessages(5).map((id) => generateMockMessage(id));
