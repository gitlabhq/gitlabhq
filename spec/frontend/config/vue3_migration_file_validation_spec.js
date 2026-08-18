import {
  VUE3_MIGRATION_FLAG_PREFIX,
  validateVue3MigrationFile,
} from '../../../config/helpers/vue3_migration_file_validation';

describe('validateVue3MigrationFile', () => {
  const rollout = (featureFlag) => ({ status: 'rollout', feature_flag: featureFlag });

  it('accepts a rollout entry whose flag carries the prefix', () => {
    expect(validateVue3MigrationFile(rollout('vue3_migrate_jobs'))).toEqual([]);
  });

  it('accepts a migrated entry, which declares no flag', () => {
    expect(validateVue3MigrationFile({ status: 'migrated' })).toEqual([]);
  });

  describe('feature flag prefix', () => {
    it.each(['jobs', 'migrate_jobs', 'vue3_jobs', 'vue2_migrate_jobs', 'my_vue3_migrate_jobs'])(
      'rejects %p because it does not start with the prefix',
      (featureFlag) => {
        expect(validateVue3MigrationFile(rollout(featureFlag))).toEqual([
          `\`feature_flag\` must start with \`${VUE3_MIGRATION_FLAG_PREFIX}\` (got ${JSON.stringify(
            featureFlag,
          )})`,
        ]);
      },
    );

    it('reports the missing flag error rather than the prefix error when the flag is absent', () => {
      expect(validateVue3MigrationFile({ status: 'rollout' })).toEqual([
        '`feature_flag` is required when status is `rollout`',
      ]);
    });

    it('does not apply to a migrated entry, where any flag is already rejected', () => {
      expect(validateVue3MigrationFile({ status: 'migrated', feature_flag: 'jobs' })).toEqual([
        '`feature_flag` must be absent when status is `migrated`',
      ]);
    });
  });
});
