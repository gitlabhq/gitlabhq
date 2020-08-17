import { isProjectImportable } from '~/import_projects/utils';
import { STATUSES } from '~/import_projects/constants';

describe('import_projects utils', () => {
  describe('isProjectImportable', () => {
    it.each`
      status                 | result
      ${STATUSES.FINISHED}   | ${false}
      ${STATUSES.FAILED}     | ${false}
      ${STATUSES.SCHEDULED}  | ${false}
      ${STATUSES.STARTED}    | ${false}
      ${STATUSES.NONE}       | ${true}
      ${STATUSES.SCHEDULING} | ${false}
    `('returns $result when project is compatible and status is $status', ({ status, result }) => {
      expect(
        isProjectImportable({
          importStatus: status,
          importSource: { incompatible: false },
        }),
      ).toBe(result);
    });

    it('returns false if project is not compatible', () => {
      expect(
        isProjectImportable({
          importStatus: STATUSES.NONE,
          importSource: { incompatible: true },
        }),
      ).toBe(false);
    });
  });
});
