import mountMirrorTable from '~/mirrors/mount_mirror_table';

describe('mountMirrorTable', () => {
  let instance;

  const mirrorsJson = JSON.stringify([
    {
      id: 1,
      enabled: true,
      url: 'https://example.com/mirror.git',
      direction: 'push',
      last_update_started_at: '2024-01-01T00:00:00Z',
      last_update_at: '2024-01-01T00:00:00Z',
      last_error: null,
      update_status: 'finished',
      ssh_key_auth: false,
      ssh_public_key: null,
    },
  ]);

  const pullMirrorJson = JSON.stringify({
    id: 2,
    enabled: true,
    url: 'https://example.com/pull.git',
    direction: 'pull',
    last_update_started_at: '2024-01-01T00:00:00Z',
    update_status: 'finished',
    mirror_branches_setting: 'all',
  });

  const setFixture = ({ mirrors = mirrorsJson, pullMirror = '' } = {}) => {
    const el = document.createElement('div');
    el.id = 'js-mirror-table';
    el.dataset.mirrors = mirrors;
    el.dataset.projectId = '7';
    el.dataset.settingsEnabled = 'true';
    el.dataset.repositoryMirrorsAvailable = 'false';
    el.dataset.pullMirror = pullMirror;
    document.body.appendChild(el);
  };

  afterEach(() => {
    instance?.$destroy();
    instance = null;
    document.body.innerHTML = '';
  });

  it('returns null when #js-mirror-table is absent', () => {
    expect(mountMirrorTable()).toBeNull();
  });

  it('mounts a Vue instance when #js-mirror-table is present', () => {
    setFixture();

    instance = mountMirrorTable();

    expect(instance).not.toBeNull();
  });

  it('converts snake_case mirror dataset keys to camelCase props', () => {
    setFixture();

    instance = mountMirrorTable();
    const table = instance.$children[0];

    expect(table.initialMirrors[0].lastUpdateStartedAt).toBe('2024-01-01T00:00:00Z');
    expect(table.initialMirrors[0].updateStatus).toBe('finished');
    expect(table.initialMirrors[0].sshKeyAuth).toBe(false);
  });

  it('sets initialPullMirror to null when pull_mirror is an empty string', () => {
    setFixture({ pullMirror: '' });

    instance = mountMirrorTable();
    const table = instance.$children[0];

    expect(table.initialPullMirror).toBeNull();
  });

  it('converts pull mirror dataset keys to camelCase when present', () => {
    setFixture({ pullMirror: pullMirrorJson });

    instance = mountMirrorTable();
    const table = instance.$children[0];

    expect(table.initialPullMirror.mirrorBranchesSetting).toBe('all');
    expect(table.initialPullMirror.lastUpdateStartedAt).toBe('2024-01-01T00:00:00Z');
  });
});
