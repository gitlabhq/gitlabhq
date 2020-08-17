import {
  isLoading,
  isImportingAnyRepo,
  hasIncompatibleRepos,
  hasImportableRepos,
  getImportTarget,
} from '~/import_projects/store/getters';
import { STATUSES } from '~/import_projects/constants';
import state from '~/import_projects/store/state';

const IMPORTED_REPO = {
  importSource: {},
  importedProject: { fullPath: 'some/path' },
};

const IMPORTABLE_REPO = {
  importSource: { id: 'some-id', sanitizedName: 'sanitized' },
  importedProject: null,
  importStatus: STATUSES.NONE,
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
    isLoadingRepos | isLoadingNamespaces | isLoadingValue
    ${false}       | ${false}            | ${false}
    ${true}        | ${false}            | ${true}
    ${false}       | ${true}             | ${true}
    ${true}        | ${true}             | ${true}
  `(
    'isLoading returns $isLoadingValue when isLoadingRepos is $isLoadingRepos and isLoadingNamespaces is $isLoadingNamespaces',
    ({ isLoadingRepos, isLoadingNamespaces, isLoadingValue }) => {
      Object.assign(localState, {
        isLoadingRepos,
        isLoadingNamespaces,
      });

      expect(isLoading(localState)).toBe(isLoadingValue);
    },
  );

  it.each`
    importStatus           | value
    ${STATUSES.NONE}       | ${false}
    ${STATUSES.SCHEDULING} | ${true}
    ${STATUSES.SCHEDULED}  | ${true}
    ${STATUSES.STARTED}    | ${true}
    ${STATUSES.FINISHED}   | ${false}
  `(
    'isImportingAnyRepo returns $value when repo with $importStatus status is available',
    ({ importStatus, value }) => {
      localState.repositories = [{ importStatus }];

      expect(isImportingAnyRepo(localState)).toBe(value);
    },
  );

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
    it('returns true if there are any importable projects ', () => {
      localState.repositories = [IMPORTABLE_REPO, IMPORTED_REPO, INCOMPATIBLE_REPO];

      expect(hasImportableRepos(localState)).toBe(true);
    });

    it('returns false if there are no importable projects', () => {
      localState.repositories = [IMPORTED_REPO, INCOMPATIBLE_REPO];

      expect(hasImportableRepos(localState)).toBe(false);
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
