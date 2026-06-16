export const PROJECT_ID = 7;

export const createMirror = (overrides = {}) => ({
  id: 42,
  enabled: true,
  url: 'https://example.com/mirror.git',
  direction: 'push',
  lastUpdateStartedAt: '2024-01-01T00:00:00Z',
  lastUpdateAt: '2024-01-01T00:00:00Z',
  lastError: null,
  updateStatus: 'finished',
  sshKeyAuth: false,
  sshPublicKey: null,
  disabled: false,
  ...overrides,
});

export const createPullMirror = (overrides = {}) => ({
  id: 99,
  enabled: true,
  url: 'https://pull.example.com/repo.git',
  direction: 'pull',
  lastUpdateStartedAt: '2024-01-01T00:00:00Z',
  lastUpdateAt: '2024-01-01T00:00:00Z',
  lastError: null,
  updateStatus: 'finished',
  sshKeyAuth: false,
  sshPublicKey: null,
  disabled: false,
  archived: false,
  ...overrides,
});
