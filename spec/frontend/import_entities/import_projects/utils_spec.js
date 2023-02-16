import { STATUSES } from '~/import_entities/constants';
import {
  isProjectImportable,
  isIncompatible,
  getImportStatus,
} from '~/import_entities/import_projects/utils';

describe('import_projects utils', () => {
  const COMPATIBLE_PROJECT = {
    importSource: { incompatible: false },
  };

  const INCOMPATIBLE_PROJECT = {
    importSource: { incompatible: true },
    importedProject: null,
  };

  describe('isProjectImportable', () => {
    it.each`
      status                 | result
      ${STATUSES.FINISHED}   | ${false}
      ${STATUSES.FAILED}     | ${true}
      ${STATUSES.SCHEDULED}  | ${false}
      ${STATUSES.STARTED}    | ${false}
      ${STATUSES.NONE}       | ${true}
      ${STATUSES.SCHEDULING} | ${false}
    `('returns $result when project is compatible and status is $status', ({ status, result }) => {
      expect(
        isProjectImportable({
          ...COMPATIBLE_PROJECT,
          importedProject: { importStatus: status },
        }),
      ).toBe(result);
    });

    it('returns true if import status is not defined', () => {
      expect(isProjectImportable({ importSource: {} })).toBe(true);
    });

    it('returns false if project is not compatible', () => {
      expect(isProjectImportable(INCOMPATIBLE_PROJECT)).toBe(false);
    });
  });

  describe('isIncompatible', () => {
    it('returns true for incompatible project', () => {
      expect(isIncompatible(INCOMPATIBLE_PROJECT)).toBe(true);
    });

    it('returns false for compatible project', () => {
      expect(isIncompatible(COMPATIBLE_PROJECT)).toBe(false);
    });
  });

  describe('getImportStatus', () => {
    it('returns actual status when project status is provided', () => {
      expect(
        getImportStatus({
          ...COMPATIBLE_PROJECT,
          importedProject: { importStatus: STATUSES.FINISHED },
        }),
      ).toBe(STATUSES.FINISHED);
    });

    it('returns NONE as status if import status is not provided', () => {
      expect(getImportStatus(COMPATIBLE_PROJECT)).toBe(STATUSES.NONE);
    });
  });
});
