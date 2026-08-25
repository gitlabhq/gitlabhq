import Vue3MigrationManifestPlugin from '../../../../config/plugins/vue3_migration_manifest_plugin';
import { loadVue3Migrations } from '../../../../config/helpers/vue3_migration_loader';

jest.mock('../../../../config/helpers/vue3_migration_loader', () => ({
  ...jest.requireActual('../../../../config/helpers/vue3_migration_loader'),
  loadVue3Migrations: jest.fn(),
}));

describe('Vue3MigrationManifestPlugin', () => {
  const filename = 'test-vue3_migration.json';
  let mockCompilation;
  let mockCompiler;

  beforeEach(() => {
    mockCompilation = {
      getAsset: jest.fn(() => null),
      updateAsset: jest.fn(),
      emitAsset: jest.fn(),
      entrypoints: new Map(),
      errors: [],
    };

    mockCompiler = {
      hooks: {
        emit: {
          tap: jest.fn(),
        },
      },
    };
  });

  const runEmitHook = () => {
    new Vue3MigrationManifestPlugin({ filename }).apply(mockCompiler);
    const emitCallback = mockCompiler.hooks.emit.tap.mock.calls[0][1];
    emitCallback(mockCompilation);
  };

  const getEmittedJson = (emitFn = mockCompilation.emitAsset) => {
    const [emittedFilename, source] = emitFn.mock.calls[0];
    return { emittedFilename, contents: source.source().toString() };
  };

  it('emits only rollout entries, keyed by entry name with their feature flag', () => {
    loadVue3Migrations.mockReturnValue({
      'pages.projects.jobs.show': { status: 'rollout', feature_flag: 'vue3_migrate_jobs' },
      'pages.admin.jobs.index': { status: 'migrated' },
    });

    runEmitHook();

    const { emittedFilename, contents } = getEmittedJson();
    expect(emittedFilename).toBe(filename);
    expect(JSON.parse(contents)).toEqual({
      'pages.projects.jobs.show': { feature_flag: 'vue3_migrate_jobs' },
    });
  });

  it('emits entries sorted by entry name for deterministic builds', () => {
    loadVue3Migrations.mockReturnValue({
      'pages.projects.jobs.show': { status: 'rollout', feature_flag: 'vue3_migrate_jobs' },
      'pages.admin.jobs.index': { status: 'rollout', feature_flag: 'vue3_migrate_jobs' },
    });

    runEmitHook();

    const { contents } = getEmittedJson();
    expect(Object.keys(JSON.parse(contents))).toEqual([
      'pages.admin.jobs.index',
      'pages.projects.jobs.show',
    ]);
  });

  it('emits an empty object when there are no rollout entries', () => {
    loadVue3Migrations.mockReturnValue({});

    runEmitHook();

    const { contents } = getEmittedJson();
    expect(JSON.parse(contents)).toEqual({});
  });

  describe('Vue 3 bundle verification', () => {
    const buildEntrypoints = (...names) => new Map(names.map((name) => [name, {}]));

    beforeEach(() => {
      loadVue3Migrations.mockReturnValue({
        'pages.projects.jobs.show': { status: 'rollout', feature_flag: 'vue3_migrate_jobs' },
      });
    });

    it('fails the build when a built rollout entry has no Vue 3 bundle', () => {
      mockCompilation.entrypoints = buildEntrypoints('pages.projects.jobs.show');

      runEmitHook();

      expect(mockCompilation.errors).toHaveLength(1);
      expect(mockCompilation.errors[0].message).toContain('pages.projects.jobs.show.vue3');
    });

    it('does not fail the build when both bundles were built', () => {
      mockCompilation.entrypoints = buildEntrypoints(
        'pages.projects.jobs.show',
        'pages.projects.jobs.show.vue3',
      );

      runEmitHook();

      expect(mockCompilation.errors).toEqual([]);
    });

    it('does not fail the build for an entry that is not part of this build', () => {
      // An EE-only page in a FOSS build: the YAML is on disk, but neither the
      // Vue 2 nor the Vue 3 entry is generated.
      mockCompilation.entrypoints = buildEntrypoints('pages.projects.merge_requests.show');

      runEmitHook();

      expect(mockCompilation.errors).toEqual([]);
    });

    it('still emits the manifest when verification fails', () => {
      mockCompilation.entrypoints = buildEntrypoints('pages.projects.jobs.show');

      runEmitHook();

      const { contents } = getEmittedJson();
      expect(JSON.parse(contents)).toEqual({
        'pages.projects.jobs.show': { feature_flag: 'vue3_migrate_jobs' },
      });
    });
  });

  it('updates the asset instead of emitting when it already exists', () => {
    loadVue3Migrations.mockReturnValue({});
    mockCompilation.getAsset.mockReturnValue({ name: filename });

    runEmitHook();

    expect(mockCompilation.emitAsset).not.toHaveBeenCalled();
    const { emittedFilename, contents } = getEmittedJson(mockCompilation.updateAsset);
    expect(emittedFilename).toBe(filename);
    expect(JSON.parse(contents)).toEqual({});
  });
});
