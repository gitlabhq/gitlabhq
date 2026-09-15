import { generateEntries, applyVue3Migrations } from '../../../config/webpack.helpers';
import { loadVue3Migrations } from '../../../config/helpers/vue3_migration_loader';

jest.mock('../../../config/helpers/vue3_migration_loader', () => ({
  ...jest.requireActual('../../../config/helpers/vue3_migration_loader'),
  loadVue3Migrations: jest.fn(),
}));

describe('generateEntries - Vue 3 migration handling', () => {
  // A real CE page entry so the test exercises the actual entry
  // generation; its migration state is mocked so assertions don't depend
  // on the repository's rollout progress.
  const entryName = 'pages.admin.jobs.index';
  const defaultEntries = ['./main'];

  const generate = () => generateEntries(defaultEntries).entries;

  it('leaves entries without a migration untouched', () => {
    loadVue3Migrations.mockReturnValue({});

    const entries = generate();

    expect(entries[entryName]).not.toContainEqual(expect.stringContaining('?vue3'));
    expect(entries).not.toHaveProperty(`${entryName}.vue3`);
  });

  describe('with status rollout', () => {
    beforeEach(() => {
      loadVue3Migrations.mockReturnValue({
        [entryName]: { status: 'rollout', feature_flag: 'some_flag' },
      });
    });

    it('emits a .vue3 sibling with infected paths', () => {
      const entries = generate();
      const sibling = entries[`${entryName}.vue3`];

      expect(sibling).toBeDefined();

      const pagePaths = sibling.filter((p) => !defaultEntries.includes(p));
      expect(pagePaths).not.toEqual([]);
      expect(pagePaths.every((p) => p.endsWith('?vue3'))).toBe(true);
    });

    it('keeps the original Vue 2 entry uninfected', () => {
      const entries = generate();

      expect(entries[entryName]).not.toContainEqual(expect.stringContaining('?vue3'));
    });
  });

  describe('with status migrated', () => {
    beforeEach(() => {
      loadVue3Migrations.mockReturnValue({
        [entryName]: { status: 'migrated' },
      });
    });

    it('infects the original entry in place instead of emitting a sibling', () => {
      const entries = generate();

      expect(entries).not.toHaveProperty(`${entryName}.vue3`);

      const [bootstrap, ...pagePaths] = entries[entryName];
      expect(bootstrap).toBe('./main');
      expect(pagePaths).not.toEqual([]);
      expect(pagePaths.every((p) => p.endsWith('?vue3'))).toBe(true);
    });
  });
});

describe('applyVue3Migrations - global bundles', () => {
  // Global bundles are declared as plain strings in
  // `config/helpers/entry_points.js`, not as the arrays page entries use.
  const entries = { performance_bar: './entrypoints/performance_bar.js' };

  it('leaves a bundle without a migration untouched', () => {
    expect(applyVue3Migrations(entries, { migrations: {} })).toEqual(entries);
  });

  it('emits a .vue3 sibling for a rollout, keeping the string shape', () => {
    const migrations = { performance_bar: { status: 'rollout', feature_flag: 'some_flag' } };

    expect(applyVue3Migrations(entries, { migrations })).toEqual({
      performance_bar: './entrypoints/performance_bar.js',
      'performance_bar.vue3': './entrypoints/performance_bar.js?vue3',
    });
  });

  it('infects a migrated bundle in place', () => {
    const migrations = { performance_bar: { status: 'migrated' } };

    expect(applyVue3Migrations(entries, { migrations })).toEqual({
      performance_bar: './entrypoints/performance_bar.js?vue3',
    });
  });

  it('does not modify the entry map it is given', () => {
    const migrations = { performance_bar: { status: 'rollout', feature_flag: 'some_flag' } };
    applyVue3Migrations(entries, { migrations });

    expect(entries).toEqual({ performance_bar: './entrypoints/performance_bar.js' });
  });

  it('never infects the shared bootstrap', () => {
    const migrations = { default: { status: 'rollout', feature_flag: 'some_flag' } };
    const result = applyVue3Migrations(
      { default: ['./main'] },
      {
        defaultEntries: ['./main'],
        migrations,
      },
    );

    expect(result['default.vue3']).toEqual(['./main']);
  });
});
