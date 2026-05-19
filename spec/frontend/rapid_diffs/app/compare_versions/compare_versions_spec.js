import { shallowMount } from '@vue/test-utils';
import { GlSprintf } from '@gitlab/ui';
import CompareVersions from '~/rapid_diffs/app/compare_versions/compare_versions.vue';
import CompareDropdownLayout from '~/diffs/components/compare_dropdown_layout.vue';

describe('CompareVersions', () => {
  let wrapper;

  const sourceVersions = [
    {
      id: 3,
      version_index: 3,
      head: false,
      latest: true,
      selected: true,
      href: '/project/-/merge_requests/1/diffs?diff_id=3',
      short_commit_sha: 'abc123',
      commits_count: 3,
      created_at: '2024-01-01T00:00:00Z',
    },
    {
      id: 2,
      version_index: 2,
      head: false,
      latest: false,
      selected: false,
      href: '/project/-/merge_requests/1/diffs?diff_id=2',
      short_commit_sha: 'def456',
      commits_count: 1,
      created_at: '2024-01-02T00:00:00Z',
    },
  ];

  const targetVersions = [
    {
      id: 2,
      version_index: 2,
      head: false,
      latest: false,
      selected: false,
      href: '/project/-/merge_requests/1/diffs?diff_id=3&start_sha=def456',
      short_commit_sha: 'def456',
      created_at: '2024-01-02T00:00:00Z',
    },
    {
      id: 'head',
      version_index: null,
      head: true,
      latest: false,
      selected: true,
      href: '/project/-/merge_requests/1/diffs?diff_head=true',
      branch: 'main',
    },
  ];

  const createComponent = (props = {}) => {
    wrapper = shallowMount(CompareVersions, {
      propsData: {
        sourceVersions,
        targetVersions,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findDropdowns = () => wrapper.findAllComponents(CompareDropdownLayout);
  const findSourceDropdown = () =>
    findDropdowns().wrappers.find((w) => w.attributes('data-testid') === 'source-version-dropdown');
  const findTargetDropdown = () =>
    findDropdowns().wrappers.find((w) => w.attributes('data-testid') === 'target-version-dropdown');
  const findShowLatestVersionButton = () =>
    wrapper.find('[data-testid="show-latest-version-button"]');

  beforeEach(() => {
    createComponent();
  });

  it('renders source version dropdown', () => {
    expect(findSourceDropdown()).toBeDefined();
  });

  it('renders target version dropdown', () => {
    expect(findTargetDropdown()).toBeDefined();
  });

  describe('source versions formatting', () => {
    it('labels latest version correctly', () => {
      const versions = findSourceDropdown().props('versions');

      expect(versions[0]).toMatchObject({
        id: 3,
        versionName: 'latest version',
      });
    });

    it('labels other versions with version index', () => {
      const versions = findSourceDropdown().props('versions');

      expect(versions[1]).toMatchObject({
        id: 2,
        versionName: 'version 2',
      });
    });

    it('formats commits_count to commitsText with pluralization', () => {
      const versions = findSourceDropdown().props('versions');

      expect(versions[0].commitsText).toBe('3 commits,');
      expect(versions[1].commitsText).toBe('1 commit,');
    });

    it('preserves other properties', () => {
      const versions = findSourceDropdown().props('versions');

      expect(versions[0]).toMatchObject({
        selected: true,
        href: '/project/-/merge_requests/1/diffs?diff_id=3',
        short_commit_sha: 'abc123',
      });
    });
  });

  describe('target versions formatting', () => {
    it('labels versioned targets with version index', () => {
      const versions = findTargetDropdown().props('versions');

      expect(versions[0]).toMatchObject({
        id: 2,
        versionName: 'version 2',
      });
    });

    it('only passes title for head/base versions', () => {
      const versions = findTargetDropdown().props('versions');

      expect(versions[1]).toEqual({
        id: 'head',
        selected: true,
        href: '/project/-/merge_requests/1/diffs?diff_head=true',
        versionName: 'main',
      });
    });

    it('passes truncate when selected target is a branch', () => {
      expect(findTargetDropdown().props('truncate')).toBe(true);
    });

    it('does not pass truncate when selected target is a version', () => {
      const versionTargets = [
        {
          id: 2,
          version_index: 2,
          selected: true,
          href: '/project/-/merge_requests/1/diffs?diff_id=2',
          short_commit_sha: 'def456',
          created_at: '2024-01-02T00:00:00Z',
        },
      ];

      createComponent({ targetVersions: versionTargets });

      expect(findTargetDropdown().props('truncate')).toBe(false);
    });

    it('only passes title for base versions', () => {
      const targetVersionsWithBase = [
        {
          id: 'base',
          version_index: null,
          head: false,
          latest: false,
          selected: true,
          href: '/project/-/merge_requests/1/diffs?diff_id=3',
          branch: 'main',
          short_commit_sha: 'abc123',
          created_at: '2024-01-01T00:00:00Z',
        },
      ];

      createComponent({ targetVersions: targetVersionsWithBase });

      const versions = findTargetDropdown().props('versions');

      expect(versions[0]).toEqual({
        id: 'base',
        selected: true,
        href: '/project/-/merge_requests/1/diffs?diff_id=3',
        versionName: 'main',
      });
    });
  });

  describe('show latest version button', () => {
    it('is hidden when the latest source and latest target are selected', () => {
      expect(findShowLatestVersionButton().exists()).toBe(false);
    });

    it('is shown when a non-latest target version is selected', () => {
      const targetVersionsWithCompare = [
        {
          id: 2,
          version_index: 2,
          head: false,
          latest: false,
          selected: true,
          href: '/project/-/merge_requests/1/diffs?diff_id=3&start_sha=def456',
          short_commit_sha: 'def456',
          created_at: '2024-01-02T00:00:00Z',
        },
        {
          id: 'head',
          version_index: null,
          head: true,
          latest: false,
          selected: false,
          href: '/project/-/merge_requests/1/diffs',
          branch: 'main',
        },
      ];

      createComponent({ targetVersions: targetVersionsWithCompare });

      const button = findShowLatestVersionButton();
      expect(button.exists()).toBe(true);
      expect(button.text()).toBe('Show latest version');
      expect(button.attributes('href')).toBe('/project/-/merge_requests/1/diffs');
    });

    it('is shown when a non-latest source version is selected', () => {
      const sourceVersionsWithNonLatest = [
        {
          id: 3,
          version_index: 3,
          head: false,
          latest: true,
          selected: false,
          href: '/project/-/merge_requests/1/diffs?diff_id=3',
          short_commit_sha: 'abc123',
          commits_count: 3,
          created_at: '2024-01-01T00:00:00Z',
        },
        {
          id: 2,
          version_index: 2,
          head: false,
          latest: false,
          selected: true,
          href: '/project/-/merge_requests/1/diffs?diff_id=2',
          short_commit_sha: 'def456',
          commits_count: 1,
          created_at: '2024-01-02T00:00:00Z',
        },
      ];

      createComponent({ sourceVersions: sourceVersionsWithNonLatest });

      const button = findShowLatestVersionButton();
      expect(button.exists()).toBe(true);
      expect(button.text()).toBe('Show latest version');
      expect(button.attributes('href')).toBe('/project/-/merge_requests/1/diffs?diff_head=true');
    });
  });
});
