import { STATUSES } from '~/import_entities/constants';
import {
  isImportingAnyRepo,
  hasIncompatibleRepos,
  hasImportableRepos,
  importAllCount,
  getImportTarget,
} from '~/import_entities/import_projects/store/getters';
import state from '~/import_entities/import_projects/store/state';

const IMPORTED_REPO = {
  importSource: {},
  importedProject: { fullPath: 'some/path', importStatus: STATUSES.FINISHED },
};

const IMPORTABLE_REPO = {
  importSource: { id: 'some-id', sanitizedName: 'sanitized' },
  importedProject: null,
};

const INCOMPATIBLE_REPO = {
  importSource: { incompatible: true },
};

describe('import_projects store getters', () => {
  let localState;

  beforeEach(() => {
    localState = state();
  });

  it.each`
    importStatus           | value
    ${STATUSES.NONE}       | ${false}
    ${STATUSES.SCHEDULING} | ${true}
    ${STATUSES.SCHEDULED}  | ${true}
    ${STATUSES.STARTED}    | ${true}
    ${STATUSES.FINISHED}   | ${false}
  `(
    'isImportingAnyRepo returns $value when project with $importStatus status is available',
    ({ importStatus, value }) => {
      localState.repositories = [{ importedProject: { importStatus } }];

      expect(isImportingAnyRepo(localState)).toBe(value);
    },
  );

  it('isImportingAnyRepo returns false when project with no defined importStatus status is available', () => {
    localState.repositories = [{ importSource: {} }];

    expect(isImportingAnyRepo(localState)).toBe(false);
  });

  describe('hasIncompatibleRepos', () => {
    it('returns true if there are any incompatible projects', () => {
      localState.repositories = [IMPORTABLE_REPO, IMPORTED_REPO, INCOMPATIBLE_REPO];

      expect(hasIncompatibleRepos(localState)).toBe(true);
    });

    it('returns false if there are no incompatible projects', () => {
      localState.repositories = [IMPORTABLE_REPO, IMPORTED_REPO];

      expect(hasIncompatibleRepos(localState)).toBe(false);
    });
  });

  describe('hasImportableRepos', () => {
    it('returns true if there are any importable projects', () => {
      localState.repositories = [IMPORTABLE_REPO, IMPORTED_REPO, INCOMPATIBLE_REPO];

      expect(hasImportableRepos(localState)).toBe(true);
    });

    it('returns false if there are no importable projects', () => {
      localState.repositories = [IMPORTED_REPO, INCOMPATIBLE_REPO];

      expect(hasImportableRepos(localState)).toBe(false);
    });
  });

  describe('importAllCount', () => {
    it('returns count of available importable projects', () => {
      localState.repositories = [
        IMPORTABLE_REPO,
        IMPORTABLE_REPO,
        IMPORTED_REPO,
        INCOMPATIBLE_REPO,
      ];

      expect(importAllCount(localState)).toBe(2);
    });
  });

  describe('getImportTarget', () => {
    it('returns default value if no custom target available', () => {
      localState.defaultTargetNamespace = 'default';
      localState.repositories = [IMPORTABLE_REPO];

      expect(getImportTarget(localState)(IMPORTABLE_REPO.importSource.id)).toStrictEqual({
        newName: IMPORTABLE_REPO.importSource.sanitizedName,
        targetNamespace: localState.defaultTargetNamespace,
      });
    });

    it('returns custom import target if available', () => {
      const fakeTarget = { newName: 'something', targetNamespace: 'ns' };
      localState.repositories = [IMPORTABLE_REPO];
      localState.customImportTargets[IMPORTABLE_REPO.importSource.id] = fakeTarget;

      expect(getImportTarget(localState)(IMPORTABLE_REPO.importSource.id)).toStrictEqual(
        fakeTarget,
      );
    });
  });
});
